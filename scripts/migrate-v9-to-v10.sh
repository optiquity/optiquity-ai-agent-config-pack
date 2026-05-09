#!/usr/bin/env bash
# migrate-v9-to-v10.sh — disposition-driven migration from v9.3 to v10.0
# pack content. Per V10-MIGRATION-FIX-DESIGN.md (BD-059), every text-class
# file the migration touches is classified via the four-case three-way
# classifier (BASE = v9.3 pack baseline, OURS = project pre-migration,
# THEIRS = v10 pack template) and dispatched per its classification token.
# Real merges produce a `<file>.v9-customized` sidecar alongside the
# migrated file plus a structured three-way diff under
# `$BACKUP_DIR/diffs/`. The S7 report renders directly from
# `$BACKUP_DIR/dispositions.tsv` so the structural-truthfulness invariant
# holds: the report cannot diverge from the disposition record because
# both are the same data.
#
# Per V10-DESIGN §6.8, the migration is eight stages S0..S7. Each stage
# writes a sentinel under $BACKUP_DIR; a resumed run skips completed
# stages. S0 pre-flight implements the B4 sentinel-cleanup flow: if any
# prior-run sentinels exist in the backup dir, prompt
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
readonly DISPOSITIONS_FILE="$BACKUP_DIR/dispositions.tsv"
readonly DIFFS_DIR="$BACKUP_DIR/diffs"
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

# ── Source shared libraries ────────────────────────────────────────────────

if [[ ! -f "$SCRIPT_DIR/lib/detect.sh" ]]; then
    die "missing shared detection library: $SCRIPT_DIR/lib/detect.sh"
fi
# shellcheck source=lib/detect.sh
source "$SCRIPT_DIR/lib/detect.sh"

if [[ ! -f "$SCRIPT_DIR/lib/three-way.sh" ]]; then
    die "missing three-way classifier library: $SCRIPT_DIR/lib/three-way.sh"
fi
# shellcheck source=lib/three-way.sh
source "$SCRIPT_DIR/lib/three-way.sh"

# ── Disposition machinery ──────────────────────────────────────────────────

# Append a disposition record to $DISPOSITIONS_FILE.
#   $1 disposition (report-level token)
#   $2 file class (e.g. C1, A1, K1)
#   $3 relative path (target side)
#   $4 sidecar path (or "-")
#   $5 diff path (or "-")
#   $6 notes (or "-")
record_disposition() {
    local disp="$1" fc="$2" path="$3" sidecar="${4:--}" diff="${5:--}" notes="${6:--}"
    mkdir -p "$BACKUP_DIR"
    if [[ ! -f "$DISPOSITIONS_FILE" ]]; then
        printf '# disposition\tfile_class\tpath\tsidecar\tdiff\tnotes\n' > "$DISPOSITIONS_FILE"
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$disp" "$fc" "$path" "$sidecar" "$diff" "$notes" >> "$DISPOSITIONS_FILE"
}

# Map classifier token (12 possible) to report-level disposition (5 canonical
# per V10-MIGRATION-FIX-DESIGN.md Part 3.11).
report_disposition_for() {
    case "$1" in
        unchanged-pack)                 echo "unchanged-pack" ;;
        pack-update-applied|new-file-in-pack)
                                        echo "pack-update-applied" ;;
        merged-with-customization)      echo "merged-with-customization" ;;
        real-merge-required|project-shadows-new-pack)
                                        echo "customization-detected-needs-reconciliation" ;;
        removed-by-pack-clean|removed-by-pack-customized)
                                        echo "removed-by-design" ;;
        project-only-file)              echo "project-only-file" ;;
        project-deleted-pack-kept)      echo "project-deleted-pack-kept" ;;
        removed-everywhere)             echo "removed-everywhere" ;;
        *)                              echo "$1" ;;
    esac
}

# Write a structured three-way diff to $DIFFS_DIR/<flat>.three-way.diff.
# Echoes the path written, or "-" if no inputs were diffable.
#   $1 base (path or "")
#   $2 ours (path or "")
#   $3 theirs (path or "")
#   $4 relative target path (used to derive flat filename)
write_three_way_diff() {
    local base="$1" ours="$2" theirs="$3" rel="$4"
    mkdir -p "$DIFFS_DIR"
    local flat="${rel//\//-}"
    flat="${flat#.}"
    local out="$DIFFS_DIR/${flat}.three-way.diff"
    {
        echo "# Three-way diff for $rel"
        echo "# BASE   = v9.3 pack baseline"
        echo "# OURS   = project pre-migration"
        echo "# THEIRS = v10 pack template"
        echo
        echo "## BASE → OURS (project edits since v9.3)"
        echo
        if [[ -n "$base" && -f "$base" && -n "$ours" && -f "$ours" ]]; then
            diff -u "$base" "$ours" || true
        else
            echo "(one or both inputs absent: base=${base:-<none>} ours=${ours:-<none>})"
        fi
        echo
        echo "## BASE → THEIRS (pack edits v9.3 → v10)"
        echo
        if [[ -n "$base" && -f "$base" && -n "$theirs" && -f "$theirs" ]]; then
            diff -u "$base" "$theirs" || true
        else
            echo "(one or both inputs absent: base=${base:-<none>} theirs=${theirs:-<none>})"
        fi
    } > "$out"
    echo "$out"
}

# Extract pack v9.3 baseline of a file into a tmpfile. Echo the tmpfile
# path on stdout, or empty string if the file did not exist at v9.3.
# Caller is responsible for `rm -f` on the returned path.
v93_baseline_to_tmp() {
    local pack_path="$1"
    local tmp
    tmp=$(mktemp)
    if git -C "$PACK" show "v9.3:$pack_path" > "$tmp" 2>/dev/null; then
        echo "$tmp"
    else
        rm -f "$tmp"
        echo ""
    fi
}

# Generic dispatch for a single text-class file. The file's BASE/OURS/THEIRS
# are classified and then acted on per disposition. DEST is the project
# target path; CLASS is the file class for reporting; LABEL is a short
# human-readable label printed during execution.
#
#   $1 file class (e.g. C1, A1)
#   $2 base path (or "")
#   $3 ours path (or "")
#   $4 theirs path (or "")
#   $5 dest path (project-relative; written/removed as needed)
#   $6 label (informational)
dispatch_text_file() {
    local cls="$1" base="$2" ours="$3" theirs="$4" dest="$5"
    local label="${6:-$dest}"
    local classification rep
    classification=$(three_way_classify "$base" "$ours" "$theirs")
    rep=$(report_disposition_for "$classification")

    case "$classification" in
        unchanged-pack)
            record_disposition "$rep" "$cls" "$dest" "-" "-" "-"
            ;;
        pack-update-applied|new-file-in-pack)
            mkdir -p "$(dirname "$dest")"
            cp "$theirs" "$dest"
            record_disposition "$rep" "$cls" "$dest" "-" "-" "-"
            ;;
        merged-with-customization)
            # base != ours but base == theirs: pack didn't change v9.3 → v10,
            # so keep ours unchanged.
            record_disposition "$rep" "$cls" "$dest" "-" "-" "kept project edits"
            ;;
        real-merge-required|project-shadows-new-pack)
            mkdir -p "$(dirname "$dest")"
            local sidecar="${dest}.v9-customized"
            local diff_path
            # CRITICAL ORDERING: write the three-way diff FIRST and copy
            # ours to the sidecar BEFORE overwriting dest with theirs.
            # When dest == ours (in-place dispatch — the common case),
            # `cp "$theirs" "$dest"` overwrites ours; subsequent reads of
            # ours would yield theirs content. Reversing the order
            # preserves ours for the diff and the sidecar.
            diff_path=$(write_three_way_diff "$base" "$ours" "$theirs" "$dest")
            cp "$ours" "$sidecar"
            cp "$theirs" "$dest"
            record_disposition "$rep" "$cls" "$dest" "$sidecar" "$diff_path" "-"
            ;;
        removed-by-pack-clean)
            [[ -f "$dest" ]] && rm "$dest"
            record_disposition "$rep" "$cls" "$dest" "-" "-" "v10 retired (no project edits)"
            ;;
        removed-by-pack-customized)
            local sidecar="${dest}.v9-customized"
            cp "$ours" "$sidecar"
            [[ -f "$dest" ]] && rm "$dest"
            record_disposition "$rep" "$cls" "$dest" "$sidecar" "-" "v10 retired; project edits preserved in sidecar"
            ;;
        project-only-file)
            record_disposition "$rep" "$cls" "$dest" "-" "-" "preserved as project-only"
            ;;
        project-deleted-pack-kept)
            record_disposition "$rep" "$cls" "$dest" "-" "-" "honoring project deletion (pack still ships)"
            ;;
        removed-everywhere)
            # silent no-op — file already absent on both sides.
            ;;
        *)
            warn "unhandled classification '$classification' for $dest (label: $label)"
            ;;
    esac
}

# Dispatch a structured config file (JSON or TOML) using the appropriate
# merge helper on real-merge-required. The helper performs key-level merge
# preserving project edits while applying pack v10 schema additions. On
# clean merge → disposition `merged-with-customization`. On reconciliation
# warnings → disposition `customization-detected-needs-reconciliation`
# with a `.v9-customized` sidecar of the project pre-migration file. On
# helper error → falls back to Pattern P (sidecar) — same as
# dispatch_text_file.
#
#   $1 file class (K1..K4)
#   $2 base path (or "")
#   $3 ours path (or "")
#   $4 theirs path (or "")
#   $5 dest path
#   $6 format ("json" or "toml")
dispatch_structured_config() {
    local cls="$1" base="$2" ours="$3" theirs="$4" dest="$5" fmt="$6"
    local classification rep
    classification=$(three_way_classify "$base" "$ours" "$theirs")
    rep=$(report_disposition_for "$classification")

    case "$classification" in
        unchanged-pack)
            record_disposition "$rep" "$cls" "$dest" "-" "-" "-"
            return 0
            ;;
        merged-with-customization)
            record_disposition "$rep" "$cls" "$dest" "-" "-" "no pack update; project edits kept"
            return 0
            ;;
        pack-update-applied|new-file-in-pack)
            mkdir -p "$(dirname "$dest")"
            cp "$theirs" "$dest"
            record_disposition "$rep" "$cls" "$dest" "-" "-" "-"
            return 0
            ;;
        real-merge-required|project-shadows-new-pack)
            local helper
            case "$fmt" in
                json) helper="$PACK/scripts/merge-json.py" ;;
                toml) helper="$PACK/scripts/merge-toml.py" ;;
                *)
                    warn "unknown structured format '$fmt' for $dest; falling back to text dispatch"
                    dispatch_text_file "$cls" "$base" "$ours" "$theirs" "$dest"
                    return 0
                    ;;
            esac
            mkdir -p "$(dirname "$dest")" "$DIFFS_DIR"
            local flat="${dest//\//-}"
            local stderr_log="$DIFFS_DIR/${flat#.}.merge-warnings.log"

            # Same cp-order discipline as dispatch_text_file: write the
            # merge to a tmpfile so $ours stays intact for diff and
            # sidecar even when $ours == $dest. Without this, helper
            # exit-2 (warnings) and helper error paths would write
            # post-merge content to the sidecar instead of the project's
            # pre-migration content.
            local merged_tmp
            merged_tmp=$(mktemp)

            local rc=0
            python3 "$helper" "${base:-}" "$ours" "$theirs" --output "$merged_tmp" \
                2> "$stderr_log" || rc=$?

            local diff_path
            diff_path=$(write_three_way_diff "$base" "$ours" "$theirs" "$dest")

            case "$rc" in
                0)
                    cp "$merged_tmp" "$dest"
                    record_disposition "merged-with-customization" "$cls" "$dest" "-" "$diff_path" "structured merge clean (key-level)"
                    rm -f "$stderr_log"
                    ;;
                2)
                    cp "$ours" "${dest}.v9-customized"
                    cp "$merged_tmp" "$dest"
                    record_disposition "customization-detected-needs-reconciliation" "$cls" "$dest" "${dest}.v9-customized" "$diff_path" "structured merge with reconciliation warnings (see $stderr_log)"
                    ;;
                *)
                    cp "$ours" "${dest}.v9-customized"
                    cp "$theirs" "$dest"
                    record_disposition "customization-detected-needs-reconciliation" "$cls" "$dest" "${dest}.v9-customized" "$diff_path" "structured merge errored (rc=$rc); fell back to sidecar (see $stderr_log)"
                    ;;
            esac
            rm -f "$merged_tmp"
            return 0
            ;;
        removed-by-pack-clean|removed-by-pack-customized|removed-everywhere|project-deleted-pack-kept|project-only-file)
            # Configs aren't normally retired; route through text dispatch
            # for the auxiliary cases (sidecar + record).
            dispatch_text_file "$cls" "$base" "$ours" "$theirs" "$dest"
            return 0
            ;;
        *)
            warn "unhandled classification '$classification' for structured config $dest"
            return 0
            ;;
    esac
}

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
        die "v9.3 tag not resolvable in $PACK — required for three-way classification"
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

    # 7. Stray x- files inside pack skill subdirectories. With C3's S2
    # rewrite, x-* siblings inside skill dirs are now legitimate (per
    # OQ-6(a)) — strays are ONLY x- files placed where the project should
    # have created an x-prefixed top-level skill dir, not a sibling of
    # SKILL.md. We retain the warning but make it informational.
    local stray_file
    for tool in claude codex gemini; do
        if [[ -d ".${tool}/skills" ]]; then
            while IFS= read -r stray_file; do
                [[ -z "$stray_file" ]] && continue
                say "  note: x- file inside pack skill directory will be preserved as a sibling: $stray_file"
            done < <(find ".${tool}/skills" -mindepth 2 -name "x-*" 2>/dev/null)
        fi
    done

    # 8. Create backup dir + .gitignore entry.
    mkdir -p "$BACKUP_DIR"
    if [[ -f .gitignore ]] && ! grep -Fxq ".pack-migration-backup/" .gitignore; then
        printf '\n.pack-migration-backup/\n' >> .gitignore
    elif [[ ! -f .gitignore ]]; then
        printf '.pack-migration-backup/\n' > .gitignore
    fi

    # 9. Ensure project .gitignore keeps `.env.example` files trackable.
    # v9.3 projects' .gitignore typically has `.env.*` (which matches
    # `.env.example`) but lacks the `!.env.example` negation. v10 ships
    # `.env.example` as a tracked pack template (Gemini AGENT_CAPABILITIES,
    # future per-tool examples). Without the negation, the migration's
    # new `.env.example` files are silently ignored by git.
    #
    # If .gitignore has `.env.*` (or wildcard equivalent) without a
    # following `!.env.example`, append the negation immediately after.
    # Idempotent — safe to run on every migration. Project-agnostic.
    if [[ -f .gitignore ]]; then
        if grep -qE '^[[:space:]]*\.env\.\*[[:space:]]*$' .gitignore \
            && ! grep -qE '^[[:space:]]*!\.env\.example[[:space:]]*$' .gitignore; then
            # Append negation right after the first `.env.*` line.
            local tmp_gi
            tmp_gi=$(mktemp)
            awk '
                { print }
                /^[[:space:]]*\.env\.\*[[:space:]]*$/ && !done {
                    print "# But .env.example is a committed template (no secrets); always tracked."
                    print "!.env.example"
                    done = 1
                }
            ' .gitignore > "$tmp_gi"
            mv "$tmp_gi" .gitignore
            say "  added !.env.example exception to .gitignore (v9.3→v10 schema fix)"
        fi
    fi

    # Initialize the dispositions log header.
    record_disposition "_header_only" "_init" "_init" "-" "-" "-" >/dev/null 2>&1 || true

    write_sentinel "S0"
    say "S0 complete."
}

# ── Stage S1 — pack agents (per-tool, per-agent classifier) ────────────────

stage_s1_agents() {
    say "── S1 — replace pack agents ──"
    if sentinel_exists "S1"; then say "S1 sentinel present — skipping."; return 0; fi

    mkdir -p "$BACKUP_DIR/.claude/agents" "$BACKUP_DIR/.codex/agents" "$BACKUP_DIR/.gemini/agents"

    local tool src_ext dst_dir pack_src cls
    for tool in claude codex gemini; do
        case "$tool" in
            codex)  src_ext="toml"; cls="A2" ;;
            gemini) src_ext="md";   cls="A3" ;;
            *)      src_ext="md";   cls="A1" ;;
        esac
        pack_src="$PACK/project-template/.${tool}/agents"
        dst_dir=".${tool}/agents"
        mkdir -p "$dst_dir"

        for f in "$pack_src"/*."${src_ext}"; do
            [[ -e "$f" ]] || continue
            local name
            name=$(basename "$f")
            local rel=".${tool}/agents/${name}"
            local pack_repo_path="project-template/${rel}"
            local base_tmp
            base_tmp=$(v93_baseline_to_tmp "$pack_repo_path")

            local ours="$dst_dir/$name"
            local theirs="$f"

            # Backup current project file (if any) before touching.
            if [[ -f "$ours" ]]; then
                cp "$ours" "$BACKUP_DIR/.${tool}/agents/$name"
            fi

            if [[ -f "$ours" ]]; then
                dispatch_text_file "$cls" "$base_tmp" "$ours" "$theirs" "$ours" "$rel"
            else
                dispatch_text_file "$cls" "$base_tmp" "" "$theirs" "$ours" "$rel"
            fi

            [[ -n "$base_tmp" && -f "$base_tmp" ]] && rm -f "$base_tmp"
        done
        # x-*."${src_ext}" files in dst_dir are intentionally left untouched.
    done

    write_sentinel "S1"
    say "S1 complete."
}

# ── Stage S2 — pack skills (per-skill classifier; siblings preserved) ──────

stage_s2_skills() {
    say "── S2 — replace pack skills ──"
    if sentinel_exists "S2"; then say "S2 sentinel present — skipping."; return 0; fi

    mkdir -p "$BACKUP_DIR/.claude/skills" "$BACKUP_DIR/.codex/skills" "$BACKUP_DIR/.gemini/skills"

    local tool dst_dir pack_src cls preserved_count=0
    for tool in claude codex gemini; do
        case "$tool" in
            codex)  cls="L2" ;;
            gemini) cls="L3" ;;
            *)      cls="L1" ;;
        esac
        pack_src="$PACK/project-template/skills"
        dst_dir=".${tool}/skills"
        mkdir -p "$dst_dir"

        local skill_dir skill_name
        for skill_dir in "$pack_src"/*/; do
            [[ -d "$skill_dir" ]] || continue
            skill_name=$(basename "$skill_dir")
            local proj_skill_dir="$dst_dir/$skill_name"
            local rel=".${tool}/skills/${skill_name}/SKILL.md"

            # Back up the entire current skill dir tree (including any siblings).
            if [[ -d "$proj_skill_dir" ]]; then
                mkdir -p "$BACKUP_DIR/.${tool}/skills"
                cp -r "$proj_skill_dir" "$BACKUP_DIR/.${tool}/skills/"
            fi

            mkdir -p "$proj_skill_dir"

            local pack_skill_md="$skill_dir/SKILL.md"
            local proj_skill_md="$proj_skill_dir/SKILL.md"
            local pack_repo_path="project-template/skills/${skill_name}/SKILL.md"
            local base_tmp
            base_tmp=$(v93_baseline_to_tmp "$pack_repo_path")

            if [[ -f "$proj_skill_md" ]]; then
                dispatch_text_file "$cls" "$base_tmp" "$proj_skill_md" "$pack_skill_md" "$proj_skill_md" "$rel"
            else
                dispatch_text_file "$cls" "$base_tmp" "" "$pack_skill_md" "$proj_skill_md" "$rel"
            fi

            [[ -n "$base_tmp" && -f "$base_tmp" ]] && rm -f "$base_tmp"

            # Sibling preservation (OQ-6(b)): non-SKILL.md, non-x-* siblings
            # inside the project skill dir are NOT pack-roster files; they
            # were already backed up above and remain in place untouched.
            # x-* siblings are equally preserved. Count them for the report.
            local sibling
            while IFS= read -r sibling; do
                [[ -z "$sibling" ]] && continue
                preserved_count=$((preserved_count + 1))
                local sib_rel=".${tool}/skills/${skill_name}/$(basename "$sibling")"
                record_disposition "project-only-file" "$cls" "$sib_rel" "-" "-" "skill-dir sibling preserved"
                # Exclude SKILL.md (handled above) AND any sidecars the
                # current migration just created at this path
                # (`SKILL.md.v9-customized`). Without this exclusion, the
                # sibling-preservation find would double-count newly-created
                # sidecars as "project-only files" — they're already correctly
                # tracked under "Reconciliation required".
            done < <(find "$proj_skill_dir" -mindepth 1 -maxdepth 1 \
                         ! -name "SKILL.md" \
                         ! -name "*.v9-customized" \
                         2>/dev/null)
        done
        # x-*/ skill directories in dst_dir are intentionally left untouched
        # (top-level project skills).
    done

    if (( preserved_count > 0 )); then
        say "  preserved $preserved_count skill-dir sibling file(s) across the three tool trees"
    fi

    write_sentinel "S2"
    say "S2 complete."
}

# ── Stage S3 — scripts, agent-run.sh, structured configs ───────────────────

stage_s3_scripts_and_config() {
    say "── S3 — replace scripts, agent-run.sh, configs ──"
    if sentinel_exists "S3"; then say "S3 sentinel present — skipping."; return 0; fi

    # ── scripts/ — per-pack-roster-file classifier; project-only scripts preserved ──
    mkdir -p "$BACKUP_DIR/scripts"
    if [[ -d scripts ]]; then
        cp -r scripts/. "$BACKUP_DIR/scripts/" 2>/dev/null || true
    fi
    mkdir -p scripts

    if [[ -d "$PACK/project-template/scripts" ]]; then
        local f script_name
        for f in "$PACK/project-template/scripts"/*; do
            [[ -e "$f" ]] || continue
            [[ -d "$f" ]] && continue   # skip subdirs (handled separately if needed)
            script_name=$(basename "$f")
            local rel="scripts/${script_name}"
            local pack_repo_path="project-template/${rel}"
            local base_tmp
            base_tmp=$(v93_baseline_to_tmp "$pack_repo_path")

            local ours="$rel"
            local theirs="$f"

            if [[ -f "$ours" ]]; then
                dispatch_text_file "S2" "$base_tmp" "$ours" "$theirs" "$ours" "$rel"
            else
                dispatch_text_file "S2" "$base_tmp" "" "$theirs" "$ours" "$rel"
            fi

            [[ -n "$base_tmp" && -f "$base_tmp" ]] && rm -f "$base_tmp"
            chmod +x "$ours" 2>/dev/null || true
        done
    fi
    # Project-only scripts (those not in pack roster, including x-*.sh) are
    # not deleted by this stage — they were backed up and remain in place.

    # ── agent-run.sh ──
    local rel="agent-run.sh"
    local pack_repo_path="project-template/${rel}"
    local base_tmp
    base_tmp=$(v93_baseline_to_tmp "$pack_repo_path")
    local ours="$rel"
    local theirs="$PACK/project-template/$rel"

    if [[ -f "$ours" ]]; then
        cp "$ours" "$BACKUP_DIR/agent-run.sh"
    fi
    if [[ -f "$theirs" ]]; then
        if [[ -f "$ours" ]]; then
            dispatch_text_file "S1" "$base_tmp" "$ours" "$theirs" "$ours" "$rel"
        else
            dispatch_text_file "S1" "$base_tmp" "" "$theirs" "$ours" "$rel"
        fi
        chmod +x "$ours" 2>/dev/null || true
    fi
    [[ -n "$base_tmp" && -f "$base_tmp" ]] && rm -f "$base_tmp"

    # ── Structured configs (K1..K7): classifier-wrapped with key-level
    # merge for JSON/TOML or text dispatch for text-format configs.
    # K3 (.codex/requirements.toml) added in C4; K5/K6/K7 added in C11
    # for cross-tool capability + MCP parity per BD-059 success criterion. ──
    mkdir -p "$BACKUP_DIR/.codex" "$BACKUP_DIR/.claude" "$BACKUP_DIR/.gemini"

    # K-class files are pack-managed templates and configs. Only files
    # the pack ships under project-template/ go through this loop. The
    # project's actual `.env` file (e.g. `.gemini/.env`) is project-owned
    # and is NEVER touched by migration — only `.env.example` (the pack
    # template) is migrated. This avoids overwriting project secrets.

    local cf
    for cf in \
        .codex/config.toml \
        .codex/config.toml.example \
        .codex/requirements.toml \
        .claude/settings.json \
        .mcp.json.example \
        .gemini/settings.json \
        .gemini/.env.example \
    ; do
        [[ -f "$PACK/project-template/$cf" ]] || continue

        local cls fmt
        case "$cf" in
            .claude/settings.json)      cls="K1"; fmt="json" ;;
            .codex/config.toml)         cls="K2"; fmt="toml" ;;
            .codex/requirements.toml)   cls="K3"; fmt="toml" ;;
            .mcp.json.example)          cls="K4"; fmt="json" ;;
            .gemini/settings.json)      cls="K5"; fmt="json" ;;
            .gemini/.env.example)       cls="K6"; fmt="text" ;;
            .codex/config.toml.example) cls="K7"; fmt="text" ;;
            *)                          cls="K?"; fmt="text" ;;
        esac

        # BASE = v9.3 pack baseline at the same path (since v9.3
        # didn't have these files, this returns empty for K5/K6/K7,
        # which classifier treats as `new-file-in-pack`).
        base_tmp=$(v93_baseline_to_tmp "project-template/${cf}")

        ours="$cf"
        theirs="$PACK/project-template/$cf"

        if [[ -f "$ours" ]]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$cf")"
            cp "$ours" "$BACKUP_DIR/$cf"
        else
            mkdir -p "$(dirname "$cf")"
        fi

        if [[ "$fmt" == "json" || "$fmt" == "toml" ]]; then
            if [[ -f "$ours" ]]; then
                dispatch_structured_config "$cls" "$base_tmp" "$ours" "$theirs" "$ours" "$fmt"
            else
                dispatch_structured_config "$cls" "$base_tmp" "" "$theirs" "$ours" "$fmt"
            fi
        else
            # Text-format configs (e.g., .env, .example templates) go through
            # generic text dispatch — Pattern P with sidecar fallback.
            if [[ -f "$ours" ]]; then
                dispatch_text_file "$cls" "$base_tmp" "$ours" "$theirs" "$ours"
            else
                dispatch_text_file "$cls" "$base_tmp" "" "$theirs" "$ours"
            fi
        fi

        [[ -n "$base_tmp" && -f "$base_tmp" ]] && rm -f "$base_tmp"
    done

    write_sentinel "S3"
    say "S3 complete."
}

# ── Stage S4 — docs/pack/prompts/ (per pack file classifier) ───────────────

stage_s4_prompts_dir() {
    say "── S4 — create docs/pack/prompts/ ──"
    if sentinel_exists "S4"; then say "S4 sentinel present — skipping."; return 0; fi

    mkdir -p docs/pack/prompts
    local src="$PACK/project-template/docs/pack/prompts"
    [[ -d "$src" ]] || die "missing $src in pack"

    local f name rel pack_repo_path base_tmp ours theirs
    for f in "$src"/*.md; do
        [[ -e "$f" ]] || continue
        name=$(basename "$f")
        rel="docs/pack/prompts/${name}"
        pack_repo_path="project-template/${rel}"
        base_tmp=$(v93_baseline_to_tmp "$pack_repo_path")

        ours="$rel"
        theirs="$f"

        # Backup any existing project file at this path before classifier dispatch.
        if [[ -f "$ours" ]]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
            cp "$ours" "$BACKUP_DIR/$rel"
        fi

        if [[ -f "$ours" ]]; then
            dispatch_text_file "P1" "$base_tmp" "$ours" "$theirs" "$ours" "$rel"
        else
            dispatch_text_file "P1" "$base_tmp" "" "$theirs" "$ours" "$rel"
        fi

        [[ -n "$base_tmp" && -f "$base_tmp" ]] && rm -f "$base_tmp"
    done
    # x-*.md prompts in docs/pack/prompts/ are intentionally left untouched.

    write_sentinel "S4"
    say "S4 complete."
}

# ── Stage S5 — trinity + PLATFORM-SKILLS + pack docs (classifier-wrapped) ──

stage_s5_trinity_splice() {
    say "── S5 — splice-merge trinity + pack docs ──"
    if sentinel_exists "S5"; then say "S5 sentinel present — skipping."; return 0; fi

    # ── PLATFORM-SKILLS.md (D2) — classifier + Pattern X splice ──
    local ps_dest="docs/pack/PLATFORM-SKILLS.md"
    local ps_pack="$PACK/project-template/${ps_dest}"
    [[ -f "$ps_pack" ]] || die "missing $ps_pack"
    local ps_pack_repo_path="project-template/${ps_dest}"
    local ps_base
    ps_base=$(v93_baseline_to_tmp "$ps_pack_repo_path")

    if [[ -f "$ps_dest" ]]; then
        mkdir -p "$BACKUP_DIR/docs"
        cp "$ps_dest" "$BACKUP_DIR/docs-pack-PLATFORM-SKILLS.md"

        local ps_classification
        ps_classification=$(three_way_classify "$ps_base" "$ps_dest" "$ps_pack")
        local ps_rep
        ps_rep=$(report_disposition_for "$ps_classification")

        case "$ps_classification" in
            unchanged-pack|merged-with-customization)
                record_disposition "$ps_rep" "D2" "$ps_dest" "-" "-" "no pack update or no project edit"
                ;;
            pack-update-applied|new-file-in-pack)
                cp "$ps_pack" "$ps_dest"
                record_disposition "$ps_rep" "D2" "$ps_dest" "-" "-" "-"
                ;;
            real-merge-required|project-shadows-new-pack)
                # Run the splice helper to preserve Pattern X regions
                # (## Custom agents / ## Custom skills) while taking
                # pack updates elsewhere.
                if python3 "$PACK/scripts/merge-platform-skills.py" \
                        "$ps_pack" "$ps_dest" "$ps_dest.new"; then
                    cp "$ps_dest" "$ps_dest.v9-customized"
                    mv "$ps_dest.new" "$ps_dest"
                    local diff_path
                    diff_path=$(write_three_way_diff "$ps_base" "$BACKUP_DIR/docs-pack-PLATFORM-SKILLS.md" "$ps_pack" "$ps_dest")
                    record_disposition "$ps_rep" "D2" "$ps_dest" "$ps_dest.v9-customized" "$diff_path" "splice ran; review sidecar for content outside Pattern X regions"
                else
                    # Splice failed; degrade to Pattern P sidecar fallback.
                    cp "$ps_dest" "$ps_dest.v9-customized"
                    cp "$ps_pack" "$ps_dest"
                    local diff_path
                    diff_path=$(write_three_way_diff "$ps_base" "$BACKUP_DIR/docs-pack-PLATFORM-SKILLS.md" "$ps_pack" "$ps_dest")
                    record_disposition "$ps_rep" "D2" "$ps_dest" "$ps_dest.v9-customized" "$diff_path" "splice failed; fell back to sidecar"
                fi
                ;;
            removed-by-pack-clean|removed-by-pack-customized|removed-everywhere|project-deleted-pack-kept|project-only-file)
                record_disposition "$ps_rep" "D2" "$ps_dest" "-" "-" "pack does not retire D2; classification $ps_classification unexpected"
                ;;
        esac
    else
        cp "$ps_pack" "$ps_dest"
        record_disposition "pack-update-applied" "D2" "$ps_dest" "-" "-" "no pre-existing project file"
    fi
    [[ -n "$ps_base" && -f "$ps_base" ]] && rm -f "$ps_base"

    # ── Trinity (C1, C2, C3) — classifier-wrapped via merge-trinity.py ──
    # merge-trinity.py runs the B6 Active-skills atomic pre-check across
    # all three files, then the classifier per file. It writes merged
    # outputs to a temp dir and reports per-file dispositions on stdout.
    local trinity_tmp
    trinity_tmp=$(mktemp -d)

    # Backup current trinity files before any write.
    local t
    for t in CLAUDE.md AGENTS.md GEMINI.md; do
        [[ -f "$t" ]] && cp "$t" "$BACKUP_DIR/$t"
    done

    # Stage v9.3 baseline trinity files for the helper.
    local trinity_base_dir
    trinity_base_dir=$(mktemp -d)
    for t in CLAUDE.md AGENTS.md GEMINI.md; do
        local pack_repo_path="project-template/$t"
        if git -C "$PACK" show "v9.3:$pack_repo_path" > "$trinity_base_dir/$t" 2>/dev/null; then
            :
        else
            # No v9.3 baseline — leave file absent in base dir.
            rm -f "$trinity_base_dir/$t"
        fi
    done

    local trinity_dispositions
    if ! trinity_dispositions=$(python3 "$PACK/scripts/merge-trinity.py" \
            --base-dir "$trinity_base_dir" \
            "$PACK/project-template" "." "$trinity_tmp"); then
        rm -rf "$trinity_tmp" "$trinity_base_dir"
        die "merge-trinity.py failed (B6 Active-skills pre-check or other); no trinity files written this run"
    fi

    # Apply per-file results: read classifier disposition and act.
    # Trinity file class labels: C1 = CLAUDE.md, C2 = AGENTS.md, C3 = GEMINI.md.
    while IFS=$'\t' read -r file classification _; do
        [[ -z "$file" ]] && continue
        local cls
        case "$file" in
            CLAUDE.md) cls="C1" ;;
            AGENTS.md) cls="C2" ;;
            GEMINI.md) cls="C3" ;;
            *)         cls="C?" ;;
        esac
        case "$classification" in
            unchanged-pack)
                record_disposition "unchanged-pack" "$cls" "$file" "-" "-" "-"
                ;;
            pack-update-applied|new-file-in-pack|merged-with-customization)
                cp "$trinity_tmp/$file" "$file"
                record_disposition "$(report_disposition_for "$classification")" "$cls" "$file" "-" "-" "-"
                ;;
            real-merge-required|project-shadows-new-pack)
                # Helper has written the spliced (template + Active-skills + Custom-agents) file
                # to $trinity_tmp/<file>. Move it into place and surface a sidecar of the
                # pre-migration project file.
                cp "$trinity_tmp/$file" "$file"
                cp "$BACKUP_DIR/$file" "$file.v9-customized"
                local diff_path
                diff_path=$(write_three_way_diff "$trinity_base_dir/$file" "$BACKUP_DIR/$file" "$PACK/project-template/$file" "$file")
                record_disposition "customization-detected-needs-reconciliation" "$cls" "$file" "$file.v9-customized" "$diff_path" "trinity prose conflict; reconcile per Procedure 5-C in INSTALL-PROCEDURES.md"
                ;;
            *)
                warn "merge-trinity.py reported unexpected classification '$classification' for $file"
                ;;
        esac
    done <<< "$trinity_dispositions"

    rm -rf "$trinity_tmp" "$trinity_base_dir"

    # ── PM-CHAT.md (D1) — classifier-wrapped, Pattern P (sidecar) ──
    local pmc_dest="docs/pack/PM-CHAT.md"
    local pmc_pack="$PACK/project-template/${pmc_dest}"
    if [[ -f "$pmc_pack" ]]; then
        local pmc_pack_repo_path="project-template/${pmc_dest}"
        local pmc_base
        pmc_base=$(v93_baseline_to_tmp "$pmc_pack_repo_path")

        if [[ -f "$pmc_dest" ]]; then
            mkdir -p "$BACKUP_DIR/docs/pack"
            cp "$pmc_dest" "$BACKUP_DIR/docs/pack/PM-CHAT.md"
            dispatch_text_file "D1" "$pmc_base" "$pmc_dest" "$pmc_pack" "$pmc_dest"
        else
            dispatch_text_file "D1" "$pmc_base" "" "$pmc_pack" "$pmc_dest"
        fi

        [[ -n "$pmc_base" && -f "$pmc_base" ]] && rm -f "$pmc_base"
    fi

    # ── METHODOLOGY.md (D3) — pack-owned with detection-only check ──
    # Resolves the F-D + F-C joint case: the canonical project-side path is
    # docs/pack/METHODOLOGY.md (not root). Back up whichever is present,
    # write canonical v10 content to docs/pack/, remove any stale root copy.
    local meth_dest="docs/pack/METHODOLOGY.md"
    local meth_pack="$PACK/supporting-docs/METHODOLOGY.md"
    if [[ -f "$meth_pack" ]]; then
        # Back up project-side current state (if any) for evidence.
        if [[ -f "$meth_dest" ]]; then
            mkdir -p "$BACKUP_DIR/docs/pack"
            cp "$meth_dest" "$BACKUP_DIR/docs/pack/METHODOLOGY.md"
        fi
        if [[ -f METHODOLOGY.md ]]; then
            cp METHODOLOGY.md "$BACKUP_DIR/METHODOLOGY.md"
        fi

        # Detection-only customization check vs v9.3 baseline of methodology.
        # METHODOLOGY is pack-owned; we never auto-merge or sidecar — but if
        # the project had local edits, surface them in the report.
        local meth_v93_tmp
        meth_v93_tmp=$(v93_baseline_to_tmp "supporting-docs/METHODOLOGY.md")
        if [[ -n "$meth_v93_tmp" && -f "$meth_dest" ]] && ! cmp -s "$meth_v93_tmp" "$meth_dest"; then
            record_disposition "merged-with-customization" "D3" "$meth_dest" "$BACKUP_DIR/docs/pack/METHODOLOGY.md" "-" "pack-owned doc; project edits detected and preserved in backup"
        else
            record_disposition "pack-update-applied" "D3" "$meth_dest" "-" "-" "-"
        fi
        [[ -n "$meth_v93_tmp" && -f "$meth_v93_tmp" ]] && rm -f "$meth_v93_tmp"

        mkdir -p docs/pack
        cp "$meth_pack" "$meth_dest"

        if [[ -f METHODOLOGY.md ]]; then
            rm METHODOLOGY.md
            say "  removed stale METHODOLOGY.md at project root (canonical is docs/pack/METHODOLOGY.md)"
            record_disposition "removed-by-design" "D3" "METHODOLOGY.md" "$BACKUP_DIR/METHODOLOGY.md" "-" "v10 canonical location is docs/pack/METHODOLOGY.md"
        fi
    fi

    # ── INSTALL-PROCEDURES.md (D5) — pack-owned, copy to docs/pack/ ──
    # New v10 doc per BD-059 hosting Procedures 5 / 5-C / 5-S / 7. Same
    # pattern as METHODOLOGY: pack-owned, copied to docs/pack/, no merge.
    local instproc_dest="docs/pack/INSTALL-PROCEDURES.md"
    local instproc_pack="$PACK/supporting-docs/INSTALL-PROCEDURES.md"
    if [[ -f "$instproc_pack" ]]; then
        if [[ -f "$instproc_dest" ]]; then
            mkdir -p "$BACKUP_DIR/docs/pack"
            cp "$instproc_dest" "$BACKUP_DIR/docs/pack/INSTALL-PROCEDURES.md"
            record_disposition "pack-update-applied" "D5" "$instproc_dest" "-" "-" "-"
        else
            record_disposition "new-file-in-pack" "D5" "$instproc_dest" "-" "-" "first-time install of INSTALL-PROCEDURES.md"
        fi
        mkdir -p docs/pack
        cp "$instproc_pack" "$instproc_dest"
    fi

    write_sentinel "S5"
    say "S5 complete."
}

# ── Stage S6 — PROMPT-TEMPLATES.md retirement (special-cased D4) ───────────

stage_s6_prompt_templates_diff() {
    say "── S6 — PROMPT-TEMPLATES.md retirement ──"
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
        say "  customization: none — deleting PROMPT-TEMPLATES.md (backup preserved)"
        rm "$proj_file"
        record_disposition "removed-by-design" "D4" "$proj_file" "-" "-" "v10 retires this file class; no project customization"
    else
        say "  customization: divergence detected — preserving as ${proj_file}.v9-customized"
        mv "$proj_file" "${proj_file}.v9-customized"
        record_disposition "removed-by-design" "D4" "$proj_file" "${proj_file}.v9-customized" "-" "v10 retires this file class; project edits preserved (Procedure 5-C.1 in INSTALL-PROCEDURES.md)"
    fi

    write_sentinel "S6"
    say "S6 complete."
}

# ── Stage S7 — render report.md from dispositions.tsv ──────────────────────

stage_s7_report() {
    say "── S7 — write migration report ──"
    if sentinel_exists "S7"; then say "S7 sentinel present — skipping."; return 0; fi

    local report="$BACKUP_DIR/report.md"
    local pack_ver pack_sha script_sha
    pack_ver=$(detect_pack_version "$PACK" | awk -F': ' '{print $2}')
    pack_sha=$(git -C "$PACK" rev-parse --short HEAD 2>/dev/null || echo "<unknown>")
    script_sha=$(sha1sum "${BASH_SOURCE[0]}" 2>/dev/null | awk '{print substr($1, 1, 12)}' || echo "<unknown>")

    # Load dispositions into arrays per report bucket.
    local recon_count=0 merged_count=0 update_count=0 retired_count=0 preserved_count=0
    local recon_lines="" merged_lines="" update_lines="" retired_lines="" preserved_lines=""

    if [[ -f "$DISPOSITIONS_FILE" ]]; then
        while IFS=$'\t' read -r disp fc path sidecar diff notes; do
            # Skip header and bookkeeping rows.
            [[ "$disp" == \#* ]] && continue
            [[ "$disp" == "_header_only" ]] && continue
            [[ -z "$disp" ]] && continue

            case "$disp" in
                customization-detected-needs-reconciliation)
                    recon_count=$((recon_count + 1))
                    recon_lines+="- **\`$path\`** — class $fc"$'\n'
                    [[ "$sidecar" != "-" ]] && recon_lines+="  - Project v9 preserved at: \`$sidecar\`"$'\n'
                    [[ "$diff" != "-" ]]    && recon_lines+="  - Three-way diff: \`$diff\`"$'\n'
                    [[ "$notes" != "-" ]]   && recon_lines+="  - Note: $notes"$'\n'
                    # Per-class sub-procedure routing in INSTALL-PROCEDURES.md.
                    local sub_proc=""
                    case "$fc" in
                        C1|C2|C3) sub_proc="5-C.2 (trinity prose)" ;;
                        D1)       sub_proc="5-C.3 (PM-CHAT.md template-fill)" ;;
                        D2)       sub_proc="5-C.4 (PLATFORM-SKILLS.md Pattern X)" ;;
                        D4)       sub_proc="5-C.1 (PROMPT-TEMPLATES legacy)" ;;
                        K1|K2|K3|K4|K5|K6|K7) sub_proc="5-C.5 (structured configs)" ;;
                        A1|A2|A3) sub_proc="5-C.6 (pack agents)" ;;
                        L1|L2|L3) sub_proc="5-C.6 (pack skills)" ;;
                        S1|S2)    sub_proc="5-C.7 (scripts)" ;;
                        P1)       sub_proc="5-C.8 (per-agent prompts)" ;;
                        *)        sub_proc="5-C (general)" ;;
                    esac
                    recon_lines+="  - Suggested: invoke Procedure $sub_proc from INSTALL-PROCEDURES.md"$'\n'
                    ;;
                merged-with-customization)
                    merged_count=$((merged_count + 1))
                    merged_lines+="- \`$path\` — class $fc; $notes"$'\n'
                    ;;
                pack-update-applied)
                    update_count=$((update_count + 1))
                    update_lines+="- \`$path\` (class $fc)"$'\n'
                    ;;
                removed-by-design)
                    retired_count=$((retired_count + 1))
                    retired_lines+="- \`$path\` — class $fc"$'\n'
                    [[ "$sidecar" != "-" ]] && retired_lines+="  - Sidecar: \`$sidecar\`"$'\n'
                    [[ "$notes" != "-" ]]   && retired_lines+="  - Note: $notes"$'\n'
                    ;;
                project-only-file|project-deleted-pack-kept)
                    preserved_count=$((preserved_count + 1))
                    preserved_lines+="- \`$path\` — class $fc; $notes"$'\n'
                    ;;
            esac
        done < "$DISPOSITIONS_FILE"
    fi

    # Render report.
    {
        echo "# v9.3 → v10.0 migration report"
        echo
        echo "**Date:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "**Pack version:** $pack_ver (commit $pack_sha)"
        echo "**Target project:** $(pwd)"
        echo "**Migration script SHA:** $script_sha"
        echo "**Branch:** $MIGRATION_BRANCH"
        echo "**Disposition summary:** $update_count pack-updates · $merged_count merges · $recon_count reconciliations needed"
        echo
        echo "## Reconciliation required ($recon_count files)"
        echo
        if (( recon_count == 0 )); then
            echo "*None — no project customization conflicted with pack v10 updates.*"
        else
            printf '%s' "$recon_lines"
        fi
        echo
        echo "## Merged with customization ($merged_count files)"
        echo
        if (( merged_count == 0 )); then
            echo "*None.*"
        else
            printf '%s' "$merged_lines"
        fi
        echo
        echo "## Pack updates applied ($update_count files)"
        echo
        if (( update_count == 0 )); then
            echo "*None.*"
        else
            printf '%s' "$update_lines"
        fi
        echo
        echo "## Files retired (removed-by-design — $retired_count files)"
        echo
        if (( retired_count == 0 )); then
            echo "*None.*"
        else
            printf '%s' "$retired_lines"
        fi
        echo
        echo "## Project files preserved (no migration touch — $preserved_count files)"
        echo
        if (( preserved_count == 0 )); then
            echo "*None.*"
        else
            printf '%s' "$preserved_lines"
        fi
        echo
        echo "### x- files preserved"
        echo
        detect_x_files
        echo
        echo "## Improperly-added files (Procedure 5.4 candidates)"
        echo
        detect_improperly_added_files || true
        echo
        echo "## RAG sync required after this migration"
        echo
        echo "v9 → v10 retired or moved several files. If this project has a"
        echo "populated local-rag index from v9 (or earlier), it now contains"
        echo "**orphan** chunks for paths that no longer exist or have moved."
        echo "Orphans are returned by future queries and cite dead paths —"
        echo "confidently-wrong retrievals."
        echo
        echo "**Reconciliation runs automatically on next \`/pm-startup\`** via"
        echo "the new Step 4 in v10's pm-startup skill. The reconciliation"
        echo "compares the index against the manifest in"
        echo "\`docs/pack/PM-CHAT.md\` § RAG ingestion manifest, deletes"
        echo "orphans, re-ingests stale entries, and reports the diff."
        echo
        echo "Expected v9 → v10 orphans (auto-deleted on next \`/pm-startup\`):"
        echo
        echo "- \`PROMPT-TEMPLATES.md\` (root) — retired before v10"
        echo "- \`docs/pack/PROMPT-TEMPLATES.md\` — retired in v10.0"
        echo "- \`METHODOLOGY.md\` (root) — moved to \`docs/pack/METHODOLOGY.md\`"
        echo "- \`ARCHITECTURE.md\` (root) — moved to \`docs/project/ARCHITECTURE.md\`"
        echo
        echo "If your project never ingested any of these, the reconciliation"
        echo "is a no-op (reports \`RAG: 1 ingested, 0 orphans\`; the \`stale\`"
        echo "count may be non-zero on first run if METHODOLOGY.md was edited"
        echo "after the previous machine's last ingest, or \`stale=N/A\` if"
        echo "the local-rag \`list\` verb does not expose ingest timestamps)."
        echo "See \`docs/pack/METHODOLOGY.md\` § RAG index hygiene for the"
        echo "underlying principle."
        echo
        echo "## Next steps"
        echo
        echo "The migration is a single atomic session. The script's mechanical pass is complete; reconciliation runs next, on the same uncommitted working tree, and ends in one commit (success) or a clean rollback (no commit). Do NOT commit before reconciliation completes."
        echo
        echo "1. Read this report top to bottom."
        echo "2. Walk Procedure 5-C from \`docs/pack/INSTALL-PROCEDURES.md\` (or \`supporting-docs/INSTALL-PROCEDURES.md\` in the pack repo). The chat presents each sidecar; you decide keep-pack / keep-project / hand-merge / land in \`## Project addenda\` or \`x-*.md\`. The procedure also reconciles trinity preamble (removes HOW TO USE blocks, restores H1/intro/placeholders) and PM-CHAT.md preamble. Each sidecar is deleted as it is reconciled."
        echo "3. Re-run \`./scripts/bootstrap.sh\` and \`./scripts/validate.sh\` — reconciliation must not introduce regressions."
        echo "4. Confirm working tree is clean: no \`*.v9-customized\` sidecars, no \`[PROJECT_NAME]\` / \`[PLATFORM_TARGETS]\` / \`[TRANSPORT]\` placeholders in trinity or PM-CHAT.md."
        echo "5. **Single commit** on \`$MIGRATION_BRANCH\` capturing the fully reconciled v10 state. Use \`git add -A\` to include new untracked pack files. Suggested message: \`feat: v10 — migrate from v9.3 (script + Procedure 5-C reconciliation)\`."
        echo "6. Follow \`supporting-docs/MIGRATION-v9-to-v10.md\` Steps 5–7 to merge \`$MIGRATION_BRANCH\` into the default branch."
        echo "7. **Run \`/pm-startup\`** in your PM chat (Procedure 5-S triggers automatically). Step 4 reconciles the RAG index against the v10 manifest and sweeps any v9-era orphans. Verify the startup summary's \`RAG:\` line reports \`0 orphans\` (or lists which orphans were removed)."
        echo
        echo "If reconciliation reveals a defect that cannot be resolved in-session, run the rollback commands from MIGRATION-v9-to-v10.md \"Rollback\" sub-section. The migration leaves no committed trace and the repo returns to v9.3 state."
        echo
        echo "## Rollback"
        echo
        echo "See \`supporting-docs/MIGRATION-v9-to-v10.md\` §12 for rollback commands."
        echo "Backup is at \`$BACKUP_DIR/\`. Per-file three-way diffs at \`$DIFFS_DIR/\`."
    } > "$report"

    # Post-migration housekeeping sentinel — triggers Procedure 5-S at next
    # PM-chat /pm-startup. Procedure deletes the sentinel as its final step.
    touch "$BACKUP_DIR/postrun-pending"

    # End-of-run developer-facing summary line.
    say
    if (( recon_count > 0 )); then
        say "Mechanical migration complete. Reconciliation pending — DO NOT COMMIT YET."
        say
        say "Disposition summary: $update_count pack-updates · $merged_count merges · $recon_count reconciliations needed."
        say
        say "$recon_count file(s) need reconciliation. Pre-migration project content is preserved in \`.v9-customized\` sidecars next to each affected file. Sidecars are working-tree artifacts — they are never committed."
        say "Walk Procedure 5-C from \`docs/pack/INSTALL-PROCEDURES.md\` in this same chat session, on this same uncommitted working tree. Each sidecar resolves to keep-pack / keep-project / hand-merge / land in addenda; the sidecar is then deleted."
        say "After all sidecars are resolved and \`bootstrap.sh\` + \`validate.sh\` are clean, make a SINGLE commit on $MIGRATION_BRANCH capturing the fully reconciled state. Or roll back per MIGRATION-v9-to-v10.md if a defect is found."
    else
        say "Migration complete. $update_count pack-updates applied; no reconciliations needed."
        say "Run \`bootstrap.sh\` + \`validate.sh\`, review \`git diff\` and \`$report\`, then commit on branch $MIGRATION_BRANCH."
    fi
    say
    say "Full report:        $report"
    say "Three-way diffs:    $DIFFS_DIR/"

    write_sentinel "S7"
    say "S7 complete."
}

# ── Main ───────────────────────────────────────────────────────────────────

main() {
    say "migrate-v9-to-v10.sh — v9.3 → v10.0 pack migration (disposition-driven)"
    say "target:  $(pwd)"
    say "pack:    ${PACK:-(unset)}"
    say

    stage_s0_preflight
    stage_s1_agents
    stage_s2_skills
    stage_s3_scripts_and_config
    stage_s4_prompts_dir
    stage_s5_trinity_splice
    stage_s6_prompt_templates_diff
    stage_s7_report
}

main "$@"
