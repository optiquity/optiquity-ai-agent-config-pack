# scripts/lib/per-entry/_lib.sh — shared parser + stream-shape constants
# for the per-entry split helpers (BD-164).
#
# Sourced by per-entry/decompose.sh, per-entry/mirror-generate.sh,
# per-entry/toc-regenerate.sh. Holds:
#   - Hard-coded stream-shape table (5 streams; entry regex + state
#     vocabulary + grammar field labels are hard-coded per integration
#     parent §7.5 — only the supporting-file basename list is read at
#     runtime from `_rules.md`).
#   - Per-entry HTML-comment back-pointer add/strip (Addendum #2 §2;
#     line-1-only, ABOVE the byte-identical span).
#   - `_rules.md` runtime read for the supporting-file basename list.
#   - Standard helpers (read-only `pe_die`, idempotent atomic write).
#
# Architecture:
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md
#     §4.2 (Layer 2 strip discipline)
#     §7.5 (`_rules.md` runtime-read scope split)
#     §13.3 (signal-6 carve-out — helpers in scripts/lib/)
#   maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md
#     §3 (per-entry directory shape, 5 streams)
#     §6.2 (mirror generator contract — deterministic + idempotent)
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md
#     §2 (line-1 HTML-comment ONLY back-pointer)
#
# Public API (consumed by sibling helpers):
#   - pe_stream_for_path <abs_dir>            -> echoes stream key
#   - pe_canonical_mirror_for_stream <key>    -> echoes mirror filename
#   - pe_entry_regex_for_stream <key>         -> echoes entry-file regex
#   - pe_supporting_files_known_for_stream <k> -> echoes space-separated list
#   - pe_supporting_files_admitted <stream_dir> -> echoes admitted list (from _rules.md)
#   - pe_backpointer_line <stream_dir> <id>   -> echoes the HTML-comment line
#   - pe_strip_backpointer_stdin              -> filter: strips line-1 back-pointer
#   - pe_die <msg>                            -> stderr + exit 1
#
# Bash 3.2 + macOS BSD utility compatible. NO associative arrays, NO &>,
# NO GNU-only flags.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ─────────────────────────────────────────────────────────────────
# Constants — the five stream tuples
# ─────────────────────────────────────────────────────────────────
#
# Each stream has 4 attributes. Bash 3.2 has no associative arrays;
# we use parallel arrays indexed by position. Lookups walk the array
# (5 entries — O(1) effectively).
#
# Position 0: stream key (matches the directory basename in the canonical
#   path; for pack streams pack-self uses this key).
# Position 1: canonical mirror filename (relative to repo root for pack
#   streams, relative to docs/project/ for project streams).
# Position 2: entry-file regex (portable extended-regex subset accepted
#   by both BSD `grep -E` and Python `re.compile`; see
#   `pe_list_entry_files` for the BSD-grep use site and
#   decompose.sh / toc-regenerate.sh for the Python use sites).
# Position 3: known supporting-file basenames the helpers can emit
#   (space-separated). Anything not in this list is SKIP per integration
#   parent §7.5 final paragraph.
#
# Stream ordering: pack/backlog, pack/changelog, project/backlog,
# project/implementation-plan, project/changelog. (Ordering is not
# load-bearing; it just needs to be deterministic.)
PE_STREAM_KEYS="pack-backlog pack-changelog project-backlog project-implementation-plan project-changelog"

pe__stream_attr() {
    # $1 = stream key, $2 = attr index (1..4: mirror, entry-regex, support, dir-suffix)
    case "$1" in
        pack-backlog)
            case "$2" in
                mirror) printf 'pack-ops/BACKLOG.md' ;;
                entry-regex) printf '^BD-[0-9]+\.md$' ;;
                support) printf '_rules.md _intro.md _toc.md _v8-resolved-archive.md' ;;
                dir-suffix) printf 'backlog' ;;
            esac
            ;;
        pack-changelog)
            case "$2" in
                mirror) printf 'pack-ops/CHANGELOG.md' ;;
                entry-regex) printf '^v[0-9]+\.[0-9]+(-[a-z0-9-]+)?\.md$' ;;
                support) printf '_rules.md _intro.md _toc.md' ;;
                dir-suffix) printf 'changelog' ;;
            esac
            ;;
        project-backlog)
            case "$2" in
                mirror) printf 'docs/project/BACKLOG.md' ;;
                entry-regex) printf '^TD-[0-9]+\.md$' ;;
                support) printf '_rules.md _intro.md _toc.md' ;;
                dir-suffix) printf 'docs/project/backlog' ;;
            esac
            ;;
        project-implementation-plan)
            # Filename regex admits `phase-N.md` only (no `phase-N.M.md`
            # per-task files). Per Addendum #1 §6.4 BD-167 spec override
            # of sidecar §3.4: tasks live INLINE in the phase file. See
            # `decompose.sh:125` for the parallel parser-side comment.
            case "$2" in
                mirror) printf 'docs/project/IMPLEMENTATION-PLAN.md' ;;
                entry-regex) printf '^phase-[0-9]+\.md$' ;;
                support) printf '_rules.md _intro.md _toc.md' ;;
                dir-suffix) printf 'docs/project/implementation-plan' ;;
            esac
            ;;
        project-changelog)
            case "$2" in
                mirror) printf 'docs/project/CHANGELOG.md' ;;
                # Slug is OPTIONAL per sidecar §3.5 (OT convention typically
                # carries a slug, but the design does not lock it). The
                # decompose `id_extract` bare-date fall-back returns
                # `YYYY-MM-DD.md` for unannotated H3 anchors; this regex
                # admits both shapes. Mirrored in toc-regenerate.sh:88.
                entry-regex) printf '^[0-9]{4}-[0-9]{2}-[0-9]{2}(-.+)?\.md$' ;;
                support) printf '_rules.md _intro.md _toc.md _format.md' ;;
                dir-suffix) printf 'docs/project/changelog' ;;
            esac
            ;;
        *)
            return 1
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
# Public lookup helpers
# ─────────────────────────────────────────────────────────────────

pe_canonical_mirror_for_stream() {
    pe__stream_attr "$1" mirror
}

pe_entry_regex_for_stream() {
    pe__stream_attr "$1" entry-regex
}

pe_supporting_files_known_for_stream() {
    pe__stream_attr "$1" support
}

pe_dir_suffix_for_stream() {
    pe__stream_attr "$1" dir-suffix
}

# Resolve a stream key from an absolute directory path.
# Matches by trailing path suffix; prefers the longest matching suffix
# (so e.g. `docs/project/changelog` resolves to project-changelog, not
# the shorter pack-changelog `changelog` suffix).
# $1 = absolute or relative directory path.
pe_stream_for_path() {
    local dir="$1"
    # Normalize: strip trailing slash for suffix match.
    dir="${dir%/}"
    local key best_key="" best_len=0
    for key in $PE_STREAM_KEYS; do
        local suffix
        suffix=$(pe_dir_suffix_for_stream "$key")
        # Suffix match ("/<suffix>" or exactly "<suffix>" for the relative case).
        case "$dir" in
            */"$suffix"|"$suffix")
                # Track the longest-suffix match (more-specific wins).
                if [[ ${#suffix} -gt $best_len ]]; then
                    best_key="$key"
                    best_len=${#suffix}
                fi
                ;;
        esac
    done
    if [[ -n "$best_key" ]]; then
        printf '%s' "$best_key"
        return 0
    fi
    return 1
}

# ─────────────────────────────────────────────────────────────────
# Supporting-file admission (`_rules.md` runtime read)
# ─────────────────────────────────────────────────────────────────
#
# Per integration parent §7.5: helpers read `_rules.md` at runtime ONLY
# for the supporting-file basename list. Unknown basenames are SKIP.
#
# `_rules.md` declares supporting-file basenames in a section. Format
# this helper recognizes (pack-shipped contract per BD-167 templates):
#
#     ## Supporting files
#     - `_rules.md`
#     - `_intro.md`
#     - `_toc.md`
#     - `_v8-resolved-archive.md`
#
# Lines outside this section are ignored. Backticks optional. Each
# bullet item names a single basename. Empty lines OK.
#
# $1 = stream directory containing _rules.md
# Output: space-separated list of admitted basenames (intersection of
#   declared and known); silent if _rules.md absent (helpers can fall
#   back to known list).
pe_supporting_files_admitted() {
    local stream_dir="$1"
    local rules_file="$stream_dir/_rules.md"
    if [[ ! -f "$rules_file" ]]; then
        # No _rules.md → return empty (caller decides what to do; the
        # helpers treat empty as "fall back to hard-coded support set
        # for this stream", since pre-v11.0 clients won't have _rules.md
        # but pre-v11.0 clients also won't have a per-entry tree to
        # invoke us against).
        printf ''
        return 0
    fi
    # Parse `_rules.md` Supporting-files section.
    awk '
        BEGIN { in_section = 0 }
        /^## Supporting files/ { in_section = 1; next }
        /^## / { if (in_section) in_section = 0 }
        in_section && /^- / {
            line = $0
            sub(/^- /, "", line)
            gsub(/`/, "", line)
            sub(/^[ \t]+/, "", line)
            sub(/[ \t]+$/, "", line)
            if (length(line) > 0) {
                if (out == "") { out = line } else { out = out " " line }
            }
        }
        END { if (out != "") print out }
    ' "$rules_file"
}

# Compute the EFFECTIVE supporting-file list a helper should emit for a
# stream: intersection of (admitted-by-_rules.md) and (known-to-helpers).
# Unknown admitted basenames are SKIP per integration parent §7.5.
# When `_rules.md` is absent or has no Supporting-files section, fall
# back to the hard-coded known list (pack-shipped contract default).
#
# $1 = stream key
# $2 = stream directory
pe_supporting_files_effective() {
    local key="$1"
    local stream_dir="$2"
    local known declared
    known=$(pe_supporting_files_known_for_stream "$key")
    declared=$(pe_supporting_files_admitted "$stream_dir")
    if [[ -z "$declared" ]]; then
        printf '%s' "$known"
        return 0
    fi
    # Intersection: emit each declared item iff it appears in the known list.
    local item out=""
    for item in $declared; do
        case " $known " in
            *" $item "*)
                if [[ -z "$out" ]]; then out="$item"; else out="$out $item"; fi
                ;;
            *)
                # Unknown — SKIP silently per §7.5.
                ;;
        esac
    done
    printf '%s' "$out"
}

# ─────────────────────────────────────────────────────────────────
# Per-entry HTML-comment back-pointer (Addendum #2 §2)
# ─────────────────────────────────────────────────────────────────
#
# Shape (line-1 only, ABOVE the bold-header which starts the byte-
# identical span):
#
#   <!-- per-entry source: /backlog/BD-NNN.md; contract: /backlog/_rules.md -->
#
# For project-side streams the path is the project-relative form
# (docs/project/<dir>/<id>.md). Non-dot per Addendum #1 §10.

# Compose the back-pointer line for a per-entry file in <stream_dir>
# with id <id> (e.g., BD-160). Stream-dir is used to derive the
# stream-relative path (we want non-dot prefix per Addendum #1 §10:
# pack streams get a leading slash like "/backlog/"; project streams
# get the project-relative path).
#
# $1 = stream key, $2 = id
pe_backpointer_line() {
    local key="$1"
    local id="$2"
    local suffix
    suffix=$(pe_dir_suffix_for_stream "$key")
    local source_path contract_path
    case "$key" in
        pack-*)
            source_path="/$suffix/$id.md"
            contract_path="/$suffix/_rules.md"
            ;;
        project-*)
            source_path="$suffix/$id.md"
            contract_path="$suffix/_rules.md"
            ;;
    esac
    printf '<!-- per-entry source: %s; contract: %s -->' "$source_path" "$contract_path"
}

# Recognize ANY per-entry back-pointer line (regex shape, used for
# stripping during mirror generation). Returns 0 if stdin first line
# matches, 1 otherwise. Tolerates trailing whitespace on the line
# (editor auto-trim hazard); the back-pointer text proper is anchored
# at line start and ends with `-->`.
pe_first_line_is_backpointer() {
    local first
    IFS= read -r first || return 1
    printf '%s' "$first" \
        | grep -E -q '^<!-- per-entry source: .*; contract: .* -->[[:space:]]*$'
}

# Filter: emit stdin to stdout, dropping the first line iff it matches
# the per-entry back-pointer pattern. Idempotent (a file with no
# back-pointer passes through unchanged). Tolerates trailing whitespace
# on the back-pointer line (editor auto-trim hazard).
pe_strip_backpointer_stdin() {
    awk '
        NR == 1 {
            if ($0 ~ /^<!-- per-entry source: .*; contract: .* -->[ \t]*$/) {
                next
            }
        }
        { print }
    '
}

# Idempotent: prepend back-pointer to file IFF first line is not already
# a back-pointer. Writes the result back atomically. Tolerates trailing
# whitespace on the existing back-pointer line (editor auto-trim hazard).
# $1 = file path, $2 = stream key, $3 = id
pe_ensure_backpointer() {
    local path="$1"
    local key="$2"
    local id="$3"
    local first
    first=$(head -n 1 "$path" 2>/dev/null || true)
    if printf '%s' "$first" \
        | grep -E -q '^<!-- per-entry source: .*; contract: .* -->[[:space:]]*$'; then
        return 0
    fi
    local bp
    bp=$(pe_backpointer_line "$key" "$id")
    local tmp
    # Same-directory mktemp so the final `mv` is an atomic rename within
    # the same filesystem. `mktemp -t` lands under $TMPDIR which is
    # typically a different filesystem from $path — cross-FS `mv` is
    # implemented as `copy + unlink` and is NOT atomic.
    local dir
    dir=$(dirname "$path")
    tmp=$(mktemp "$dir/.per-entry-bp.XXXXXX") || return 1
    printf '%s\n' "$bp" >"$tmp"
    cat "$path" >>"$tmp"
    mv "$tmp" "$path"
}

# ─────────────────────────────────────────────────────────────────
# Shared utilities
# ─────────────────────────────────────────────────────────────────

# Stderr message + exit 1.
pe_die() {
    printf 'per-entry: ERROR: %s\n' "$*" >&2
    exit 1
}

# Stderr warning (non-fatal).
pe_warn() {
    printf 'per-entry: WARNING: %s\n' "$*" >&2
}

# Atomic write: write stdin to <path> via temp file + mv. Idempotent
# under POSIX rename semantics.
# $1 = destination path
pe_write_atomic() {
    local dest="$1"
    local dir
    dir=$(dirname "$dest")
    [[ -d "$dir" ]] || pe_die "destination directory does not exist: $dir"
    local tmp
    tmp=$(mktemp "$dir/.per-entry.XXXXXX") || pe_die "mktemp failed for $dir"
    cat >"$tmp"
    mv "$tmp" "$dest"
}

# True iff stdin is a TTY (interactive context detection per Addendum
# #1 §5.3 — interactive prompts the user; non-interactive returns
# non-zero exit so the BD-095-mode wiring in 19c can interpret).
pe_is_interactive() {
    [[ -t 0 ]] && [[ -t 1 ]]
}

# Sort entry filenames deterministically. Pack-changelog and
# project-changelog have version- or date-prefixed names that sort
# correctly under standard `LC_ALL=C sort`. BD-NNN / TD-NNN /
# phase-N also sort correctly under `LC_ALL=C sort` because they
# share a fixed prefix and a numeric tail (with consistent zero-
# padding for BD/TD per sidecar §3.1).
#
# Stdin: one filename per line. Stdout: deterministically sorted lines.
pe_sort_entries() {
    LC_ALL=C sort
}

# List entry files in <stream_dir> matching the entry regex for <key>.
# Output: one absolute path per line, deterministically sorted.
# $1 = stream key, $2 = stream directory
pe_list_entry_files() {
    local key="$1"
    local stream_dir="$2"
    local regex
    regex=$(pe_entry_regex_for_stream "$key") || pe_die "unknown stream key: $key"
    if [[ ! -d "$stream_dir" ]]; then
        return 0
    fi
    local f base
    for f in "$stream_dir"/*; do
        [[ -f "$f" ]] || continue
        base=$(basename "$f")
        # Skip leading-underscore (supporting files).
        case "$base" in
            _*) continue ;;
        esac
        # Match against the entry regex (portable ERE subset; here matched
        # via BSD `grep -E`; same regex is also accepted by Python
        # `re.compile` in decompose.sh / toc-regenerate.sh).
        if printf '%s\n' "$base" | grep -E -q "$regex"; then
            printf '%s\n' "$f"
        fi
    done | pe_sort_entries
}

# Extract the entry ID from a per-entry filename (drops .md).
# $1 = basename or path
pe_id_from_filename() {
    local base
    base=$(basename "$1")
    printf '%s' "${base%.md}"
}
