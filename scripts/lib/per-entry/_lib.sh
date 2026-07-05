# scripts/lib/per-entry/_lib.sh — shared parser + stream-shape constants
# for the per-entry split helpers (BD-164).
#
# No-mirror model (all streams): the per-entry tree + `_toc.md` is the
# SOLE source of truth and readable form for the backlog / changelog
# streams. There is NO regenerated monolithic mirror.
#
# Sourced by per-entry/decompose.sh, per-entry/toc-regenerate.sh. Holds:
#   - Hard-coded stream-shape table (6 streams; entry regex + state
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
#     §6.2 (per-entry parsing contract)
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md
#     §2 (line-1 HTML-comment ONLY back-pointer)
#
# Public API (consumed by sibling helpers):
#   - pe_stream_for_path <abs_dir>            -> echoes stream key
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
# Constants — the six stream tuples
# ─────────────────────────────────────────────────────────────────
#
# Each stream has a key plus 3 attributes. Bash 3.2 has no associative
# arrays; `pe__stream_attr` resolves an attribute by string key per
# stream. Lookups walk the 6-stream `case` (O(1) effectively).
#
# Stream key: matches the directory basename in the canonical path; for
#   pack streams pack-self uses this key.
# entry-regex: entry-file regex (portable extended-regex subset accepted
#   by both BSD `grep -E` and Python `re.compile`; see
#   `pe_list_entry_files` for the BSD-grep use site and
#   decompose.sh / toc-regenerate.sh for the Python use sites).
# support: known supporting-file basenames the helpers can emit
#   (space-separated). Anything not in this list is SKIP per integration
#   parent §7.5 final paragraph.
# dir-suffix: the trailing path segment used to resolve a stream from a
#   directory path (see `pe_stream_for_path`).
#
# Stream ordering: pack/backlog, pack/changelog, project/backlog,
# project/implementation-plan, project/changelog, project/groupings.
# (Ordering is not load-bearing; it just needs to be deterministic.)
PE_STREAM_KEYS="pack-backlog pack-changelog project-backlog project-implementation-plan project-changelog project-groupings"

pe__stream_attr() {
    # $1 = stream key, $2 = attr key (entry-regex, support, dir-suffix)
    case "$1" in
        pack-backlog)
            case "$2" in
                # BD-211: canonical filename is `BD-NNN.md` — NO letter
                # suffix (a sub-part is an in-body section, not a suffixed
                # entry). The former suffix sub-entries were folded into
                # their base BD-167/BD-169 entries as in-body sections.
                entry-regex) printf '^BD-[0-9]+\.md$' ;;
                support) printf '_rules.md _intro.md _toc.md' ;;
                dir-suffix) printf 'backlog' ;;
            esac
            ;;
        pack-changelog)
            case "$2" in
                # BD-203 A3/CHANGE 2: per-release granularity — one `vN.md`
                # file per major release (`v11.md`, `v7.md`).
                entry-regex) printf '^v[0-9]+\.md$' ;;
                support) printf '_rules.md _intro.md _toc.md' ;;
                dir-suffix) printf 'changelog' ;;
            esac
            ;;
        project-backlog)
            case "$2" in
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
                entry-regex) printf '^phase-[0-9]+\.md$' ;;
                # `_index.md` is the generated+validated dependency-derived
                # serial order (impl-plan only); it is ADMITTED here as a
                # KNOWN-supporting sidecar exactly as `_toc.md` is, so the
                # "no stray sidecar" validator legs do not flag it.
                support) printf '_rules.md _intro.md _toc.md _index.md' ;;
                dir-suffix) printf 'docs/project/implementation-plan' ;;
            esac
            ;;
        project-changelog)
            case "$2" in
                # Slug is OPTIONAL per sidecar §3.5 (OT convention typically
                # carries a slug, but the design does not lock it). The
                # decompose `id_extract` bare-date fall-back returns
                # `YYYY-MM-DD.md` for unannotated H3 anchors; this regex
                # admits both shapes. Mirrored in toc-regenerate.sh:88.
                entry-regex) printf '^[0-9]{4}-[0-9]{2}-[0-9]{2}(-.+)?\.md$' ;;
                support) printf '_rules.md _intro.md _toc.md' ;;
                dir-suffix) printf 'docs/project/changelog' ;;
            esac
            ;;
        project-groupings)
            # BD-262: the fourth project-side stream (groupings of phases).
            # TIGHTENED entry regex: exactly three digits zero-padded through
            # GRP-999, then unpadded four-plus digits from GRP-1000 — kills
            # the `GRP-0000` masquerade while admitting `GRP-1000` (enforces
            # the contract's exactly-3-digits-until-999 numbering sentence).
            # Mirrored in toc-regenerate.sh and in the shipped stream
            # contract project-template/docs/project/groupings/_rules.md.
            # No `_index.md` (groupings are orderless) and no `_kinds.md`
            # (the Kind enum is fixed in the immutable `_rules.md`).
            case "$2" in
                entry-regex) printf '^GRP-([0-9]{3}|[1-9][0-9]{3,})\.md$' ;;
                support) printf '_rules.md _intro.md _toc.md' ;;
                dir-suffix) printf 'docs/project/groupings' ;;
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

# ─────────────────────────────────────────────────────────────────
# Shared utilities
# ─────────────────────────────────────────────────────────────────

# Stderr message + exit 1.
pe_die() {
    printf 'per-entry: ERROR: %s\n' "$*" >&2
    exit 1
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

# Sort entry filenames deterministically. Pack-changelog and
# project-changelog have version- or date-prefixed names that sort
# correctly under standard `LC_ALL=C sort`. BD-NNN / TD-NNN /
# phase-N / GRP-NNN also sort correctly under `LC_ALL=C sort` because
# they share a fixed prefix and a numeric tail (with consistent zero-
# padding for BD/TD per sidecar §3.1 and for GRP through GRP-999 per
# the groupings stream contract; the TOC regenerator orders entries by
# NUMERIC id within groups, so its output is numeric-correct past any
# padding boundary).
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
