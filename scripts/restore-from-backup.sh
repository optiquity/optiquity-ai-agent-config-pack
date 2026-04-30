#!/usr/bin/env bash
# scripts/restore-from-backup.sh — invert a v9.3-to-v10.0 migration backup
# directory layout into a project-tree shape suitable for re-running migration.
#
# The migration's S3/S5 stages flatten a few paths when copying files into
# `$BACKUP_DIR/`. Specifically: docs/pack/ files are copied with their slashes
# replaced by `-`, so `docs/pack/PLATFORM-SKILLS.md` becomes
# `docs-pack-PLATFORM-SKILLS.md` at the backup root. Everything else is copied
# preserving its relative path.
#
# This helper inverts that flattening: given a backup directory and a target
# directory, it reconstructs the project tree that existed before the
# migration ran. It is read-only with respect to the backup and writes only
# to the target.
#
# Reference: V10-MIGRATION-FIX-DESIGN.md Part 7.1 + OQ-2; planner C2.
#
# Usage:
#   scripts/restore-from-backup.sh <backup-dir> <target-dir>
#   scripts/restore-from-backup.sh --dry-run <backup-dir> <target-dir>
#
# Arguments:
#   <backup-dir>  Absolute or relative path to a directory containing the
#                 contents of `.pack-migration-backup/v9.3-to-v10.0/`.
#   <target-dir>  Empty directory (or one to be created) where the inverted
#                 tree is written.
#
# Exit codes:
#   0  success
#   1  argument error or backup directory missing
#   2  target directory not empty (refuses to merge into existing tree)

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
    shift
fi

if [[ $# -ne 2 ]]; then
    echo "usage: $0 [--dry-run] <backup-dir> <target-dir>" >&2
    exit 1
fi

BACKUP_DIR="$1"
TARGET_DIR="$2"

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "error: backup directory not found: $BACKUP_DIR" >&2
    exit 1
fi

# Refuse to merge into a non-empty target. Caller can mktemp -d a fresh dir.
if [[ -d "$TARGET_DIR" ]] && [[ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
    echo "error: target directory is not empty: $TARGET_DIR" >&2
    echo "       refusing to merge backup into existing files; use a fresh dir." >&2
    exit 2
fi

mkdir -p "$TARGET_DIR"
BACKUP_DIR="$(cd "$BACKUP_DIR" && pwd)"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Migration metadata files to skip — these belong to the migration run, not
# to the project's pre-migration state.
SKIP_FILES=(
    "report.md"
    "status.txt"
    "postrun-pending"
    "stage-S0.done"
    "stage-S1.done"
    "stage-S2.done"
    "stage-S3.done"
    "stage-S4.done"
    "stage-S5.done"
    "stage-S6.done"
    "stage-S7.done"
)

is_skipped() {
    local name="$1"
    for skip in "${SKIP_FILES[@]}"; do
        [[ "$name" == "$skip" ]] && return 0
    done
    return 1
}

# Map a backup-relative path to its inverted project-relative path.
# The only known flattening is `docs-pack-<NAME>` → `docs/pack/<NAME>`. All
# other paths are identity. If the convention grows in the future, add more
# rules here.
invert_path() {
    local rel="$1"
    case "$rel" in
        docs-pack-*)
            echo "docs/pack/${rel#docs-pack-}"
            ;;
        *)
            echo "$rel"
            ;;
    esac
}

copy_or_print() {
    local src="$1" dst="$2"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  $src -> $dst"
    else
        mkdir -p "$(dirname "$dst")"
        cp -p "$src" "$dst"
    fi
}

count=0
skipped=0

# Walk every regular file in the backup. Use `find -print0` to handle paths
# with whitespace.
while IFS= read -r -d '' file; do
    rel="${file#$BACKUP_DIR/}"
    base="$(basename "$rel")"

    if is_skipped "$base" && [[ "$rel" == "$base" ]]; then
        skipped=$((skipped + 1))
        continue
    fi

    inverted_rel=$(invert_path "$rel")
    dst="$TARGET_DIR/$inverted_rel"
    copy_or_print "$file" "$dst"
    count=$((count + 1))
done < <(find "$BACKUP_DIR" -type f -print0)

if [[ $DRY_RUN -eq 1 ]]; then
    echo "(dry-run) would restore $count files; $skipped migration-metadata files skipped."
else
    echo "restored $count files to $TARGET_DIR; $skipped migration-metadata files skipped."
fi
