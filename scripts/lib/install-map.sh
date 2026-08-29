# scripts/lib/install-map.sh — shell-side reader for the client install map.
#
# The install map is the ONE declaration of what the pack installs to clients.
# It lives as two comment blocks in `scripts/init-project.sh`; this library is
# how shell consumers READ it. No consumer re-declares the map.
#
# Do NOT add a shebang — this file is sourced, not executed.
#
# Placement: this is a PACK-side library. `init-project.sh` and
# `migrate-v10-to-v11.sh` source it at RUNTIME, so it is a pack-operation
# dependency; it must never move to `project-template/scripts/` or become a
# client-shipped file, and it is absent from the install map by construction.
#
# The map is PARSED, never sourced: `init-project.sh` has a `main()` and side
# effects, so executing it to read a comment block is not an option.
#
# ENTRY POINTS
#   install_map_explicit_rows
#       One line per explicit row:  pack_rel<TAB>proj_rel<TAB>stages_csv<TAB>class
#   install_map_glob_rows
#       Same shape, one line per family row; the DEST keeps its `{a,b,c}`
#       group UNEXPANDED.
#   install_map_dispatch_set <token>
#       `pack_rel:proj_rel:class` for every row whose [stage:] contains
#       <token>. Family rows are expanded to concrete files and their DEST
#       brace groups fanned out. `class` is EMPTY for `[class:self]`
#       (self-classify: the copy site passes no class argument).
#   install_map_declared_dests [<token>]
#       Every declared client-relative DEST, expanded and fanned out,
#       optionally filtered to <token>. Derivable WITHOUT running an install.
#   install_map_source_for_dest <proj_rel>
#       Reverse lookup: the pack SOURCE a client-relative path is copied from.
#       Prints nothing and returns 1 when no row maps it. A family row's `*`
#       matches within ONE path segment, so a NESTED path under a one-level
#       family DEST does not resolve.
#
# `install_map_declared_dests` and `install_map_dispatch_set` read the SAME
# resolution core, so for a given token their DEST sets cannot disagree.
#
# CANDIDATE SET: a family row expands to git-TRACKED REGULAR FILES only.
# Both filters are load-bearing and neither subsumes the other:
#   * regular-file — a bare existence test also admits a DIRECTORY, and every
#     DEST pattern is a file pattern; a directory reaching a copy site is a
#     type error one layer down.
#   * git-tracked — `.gitignore`, at the pack root and under
#     `project-template/`, expects build and OS artifacts (`__pycache__/`,
#     `.DS_Store`) inside the very directories these rows glob. A raw
#     filesystem glob would ship them to every client, so the candidate set
#     comes from `git ls-files`, never from the filesystem alone.
# The tracked filter is LENIENT when the root is not a git work tree: the
# tests point `INSTALL_MAP_PACK` at synthetic `mktemp -d` roots, where the
# regular-file filter still bars directories. At real install time the root
# IS a work tree — `init-project.sh` resolves it through `detect_pack_path`,
# which reports `not-a-repo` unless `git rev-parse --git-dir` succeeds, and
# dies with EXIT_PACK_INVALID on anything but `valid`.
#
# ERRORS (rc 1, message on stderr — a caller cannot proceed on a half-parsed
# map and must `die`):
#   * either block's START or END marker not present exactly once;
#   * a family row whose pattern matches ZERO tracked regular files;
#   * a family row whose SOURCE and DEST wildcard counts disagree, or which
#     carries more than one wildcard per side.
#
# COST: the map is parsed ONCE per pack root into memoised shell strings, in a
# single pass over `init-project.sh` with no subprocess per row. The tracked
# set costs ONE `git ls-files`, also memoised per root — never a subprocess
# per candidate path.

# Pack root. `INSTALL_MAP_PACK` overrides (tests point it at a synthetic
# tree); otherwise it is derived from this file's own location.
_install_map_root() {
    if [ -n "${INSTALL_MAP_PACK:-}" ]; then
        printf '%s\n' "$INSTALL_MAP_PACK"
        return 0
    fi
    cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

_install_map_err() {
    printf 'install-map: %s\n' "$1" >&2
    return 1
}

_install_map_ltrim() {
    local s="$1"
    printf '%s' "${s#"${s%%[![:space:]]*}"}"
}

_install_map_trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# Extract `[<name>:<value>]` from a row tail. Prints the value (may be empty).
_install_map_operand() {
    local rest="$1" name="$2" tmp
    case "$rest" in
        *"[$name:"*)
            tmp="${rest#*\[$name:}"
            printf '%s' "${tmp%%\]*}"
            ;;
        *) printf '%s' "" ;;
    esac
}

# Remove every `[...]` group from a row tail, leaving the DEST.
_install_map_strip_operands() {
    local s="$1"
    while :; do
        case "$s" in
            *\[*\]*) s="${s%%\[*}${s#*\]}" ;;
            *) break ;;
        esac
    done
    _install_map_trim "$s"
}

# Count `*` occurrences in $1.
_install_map_star_count() {
    local s="$1" n=0
    while :; do
        case "$s" in
            *\**) n=$((n + 1)); s="${s#*\*}" ;;
            *) break ;;
        esac
    done
    printf '%s' "$n"
}

# Parse ONE block into stdout records `src<TAB>dest<TAB>stages<TAB>class`.
# Single pass; counts the markers as it goes so the exactly-once contract
# costs no extra read. $1 = file, $2 = START marker, $3 = END marker.
_install_map_parse_block() {
    local file="$1" start="$2" end="$3"
    local n_start=0 n_end=0 inside=0
    local line content src rest dest stages cls out=""
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            *"$start"*)
                n_start=$((n_start + 1))
                inside=1
                case "$line" in
                    *"$end"*) n_end=$((n_end + 1)); inside=0 ;;
                esac
                continue
                ;;
            *"$end"*)
                n_end=$((n_end + 1))
                inside=0
                continue
                ;;
        esac
        [ "$inside" -eq 1 ] || continue
        content="$(_install_map_ltrim "$line")"
        case "$content" in
            "#"*) content="$(_install_map_ltrim "${content#\#}")" ;;
            *) continue ;;
        esac
        case "$content" in
            *"->"*) ;;
            *) continue ;;
        esac
        src="$(_install_map_trim "${content%%->*}")"
        [ -n "$src" ] || continue
        rest="${content#*->}"
        stages="$(_install_map_operand "$rest" stage)"
        cls="$(_install_map_operand "$rest" class)"
        dest="$(_install_map_strip_operands "$rest")"
        [ -n "$dest" ] || continue
        out="$out$src	$dest	$stages	$cls
"
    done < "$file"
    if [ "$n_start" -ne 1 ] || [ "$n_end" -ne 1 ]; then
        _install_map_err "marker contract violated in $file: $start x$n_start, $end x$n_end (each must appear exactly once)"
        return 1
    fi
    printf '%s' "$out"
    return 0
}

# Parse both blocks once per pack root and memoise.
_install_map_load() {
    local root
    root="$(_install_map_root)"
    if [ "${_INSTALL_MAP_LOADED_ROOT:-}" = "$root" ]; then
        return 0
    fi
    local init_sh="$root/scripts/init-project.sh"
    if [ ! -f "$init_sh" ]; then
        _install_map_err "no install map: $init_sh not found"
        return 1
    fi
    local explicit globs
    explicit="$(_install_map_parse_block "$init_sh" \
        "_CLIENT_INSTALLED_FILES_START" "_CLIENT_INSTALLED_FILES_END")" || return 1
    globs="$(_install_map_parse_block "$init_sh" \
        "_CLIENT_INSTALLED_GLOBS_START" "_CLIENT_INSTALLED_GLOBS_END")" || return 1
    _INSTALL_MAP_EXPLICIT="$explicit"
    _INSTALL_MAP_GLOBS="$globs"
    _INSTALL_MAP_LOADED_ROOT="$root"
    _install_map_tracked_load "$root"
    return 0
}

install_map_explicit_rows() {
    _install_map_load || return 1
    if [ -n "${_INSTALL_MAP_EXPLICIT:-}" ]; then
        printf '%s\n' "$_INSTALL_MAP_EXPLICIT"
    fi
    return 0
}

install_map_glob_rows() {
    _install_map_load || return 1
    if [ -n "${_INSTALL_MAP_GLOBS:-}" ]; then
        printf '%s\n' "$_INSTALL_MAP_GLOBS"
    fi
    return 0
}

# Fan out a single `{a,b,c}` group in a DEST; echoes the input when absent.
_install_map_fanout() {
    local d="$1" pre tmp members post m oldifs
    case "$d" in
        *\{*\}*)
            pre="${d%%\{*}"
            tmp="${d#*\{}"
            members="${tmp%%\}*}"
            post="${tmp#*\}}"
            oldifs="$IFS"
            IFS=,
            for m in $members; do
                printf '%s%s%s\n' "$pre" "$m" "$post"
            done
            IFS="$oldifs"
            ;;
        *) printf '%s\n' "$d" ;;
    esac
}

# Unique top-level path segment of every family SOURCE pattern. Only family
# expansion consults the tracked set, so these segments bound it exactly.
_install_map_glob_pathspecs() {
    local tab src rest seg seen=" "
    tab="$(printf '\t')"
    while IFS="$tab" read -r src rest; do
        [ -n "$src" ] || continue
        seg="${src%%/*}"
        [ -n "$seg" ] || continue
        case "$seen" in
            *" $seg "*) ;;
            *) printf '%s\n' "$seg"; seen="$seen$seg " ;;
        esac
    done <<GLOBS
${_INSTALL_MAP_GLOBS:-}
GLOBS
}

# Git-tracked path set for a pack root, memoised. ONE `git ls-files` per
# root; membership is then a pure-shell substring test, never a subprocess
# per candidate. Sets _INSTALL_MAP_TRACKED_ACTIVE=0 when the root is not a
# git work tree (or reports nothing), which turns the filter off.
#
# The pathspec is DERIVED from the family rows, never hard-coded — the
# memoised string stays proportional to what family expansion can actually
# match instead of to the whole repo, which keeps every membership scan
# short. Unquoted on purpose: the specs are single path segments, one per
# line, and must word-split into separate arguments.
_install_map_tracked_load() {
    local root="$1" out specs
    if [ "${_INSTALL_MAP_TRACKED_ROOT:-}" = "$root" ]; then
        return 0
    fi
    _INSTALL_MAP_TRACKED=""
    _INSTALL_MAP_TRACKED_ACTIVE=0
    specs="$(_install_map_glob_pathspecs)"
    if out="$(git -C "$root" ls-files -- $specs 2>/dev/null)" && [ -n "$out" ]; then
        # Sentinel newlines on BOTH ends so the membership test can anchor a
        # whole line and never match a path suffix.
        _INSTALL_MAP_TRACKED="
$out
"
        _INSTALL_MAP_TRACKED_ACTIVE=1
    fi
    _INSTALL_MAP_TRACKED_ROOT="$root"
    return 0
}

# True when $2 (root-relative) is git-tracked under root $1, and true for
# everything when the filter is inactive (non-git root — lenient).
_install_map_is_tracked() {
    local nl='
'
    _install_map_tracked_load "$1"
    [ "${_INSTALL_MAP_TRACKED_ACTIVE:-0}" -eq 1 ] || return 0
    case "$_INSTALL_MAP_TRACKED" in
        *"$nl$2$nl"*) return 0 ;;
    esac
    return 1
}

# Expand ONE family row to concrete `src<TAB>dest` pairs. The DEST is already
# fanned out by the caller. A zero-match pattern is an ERROR, never a silent
# skip: a family row that matches nothing would drop its whole family from
# every derived consumer without a sound.
#
# Candidates are git-TRACKED REGULAR FILES — see the CANDIDATE SET note in
# the file header for why each filter is load-bearing. A row left with zero
# candidates by these filters still raises the zero-match ERROR, so the
# filters can never silently empty a family.
_install_map_expand() {
    local root="$1" pat="$2" dpat="$3"
    local ns nd pre post dpre dpost abs rel cap found=0
    ns="$(_install_map_star_count "$pat")"
    nd="$(_install_map_star_count "$dpat")"
    if [ "$ns" != "$nd" ] || [ "$ns" -gt 1 ]; then
        _install_map_err "family row wildcard arity unsupported: '$pat' -> '$dpat' (each side must carry exactly one '*')"
        return 1
    fi
    if [ "$ns" -eq 0 ]; then
        if [ ! -f "$root/$pat" ] || ! _install_map_is_tracked "$root" "$pat"; then
            _install_map_err "family row matches nothing: $pat"
            return 1
        fi
        printf '%s\t%s\n' "$pat" "$dpat"
        return 0
    fi
    pre="${pat%%\**}"
    post="${pat#*\*}"
    dpre="${dpat%%\**}"
    dpost="${dpat#*\*}"
    for abs in "$root"/$pat; do
        [ -f "$abs" ] || continue
        rel="${abs#"$root"/}"
        _install_map_is_tracked "$root" "$rel" || continue
        cap="${rel#"$pre"}"
        cap="${cap%"$post"}"
        printf '%s\t%s%s%s\n' "$rel" "$dpre" "$cap" "$dpost"
        found=1
    done
    if [ "$found" -eq 0 ]; then
        _install_map_err "family row matches nothing: $pat"
        return 1
    fi
    return 0
}

# True when a comma-separated stage list contains $2.
_install_map_has_stage() {
    case ",$1," in
        *",$2,"*) return 0 ;;
        *) return 1 ;;
    esac
}

# Shared resolution core: `src<TAB>dest<TAB>class` for every row, family rows
# expanded + fanned out. $1 = stage-token filter ("" = no filter).
# install_map_dispatch_set and install_map_declared_dests BOTH read this, so
# their DEST sets for a given token agree by construction.
_install_map_resolved() {
    local want="$1"
    _install_map_load || return 1
    local root
    root="$(_install_map_root)"
    local tab src dest stages cls d expanded rsrc rdest
    tab="$(printf '\t')"
    while IFS="$tab" read -r src dest stages cls; do
        [ -n "$src" ] || continue
        if [ -n "$want" ]; then
            if ! _install_map_has_stage "$stages" "$want"; then
                continue
            fi
        fi
        if [ "$cls" = "self" ]; then
            cls=""
        fi
        printf '%s\t%s\t%s\n' "$src" "$dest" "$cls"
    done <<EXPLICIT
${_INSTALL_MAP_EXPLICIT:-}
EXPLICIT
    while IFS="$tab" read -r src dest stages cls; do
        [ -n "$src" ] || continue
        if [ -n "$want" ]; then
            if ! _install_map_has_stage "$stages" "$want"; then
                continue
            fi
        fi
        if [ "$cls" = "self" ]; then
            cls=""
        fi
        # Iterate the fan-out via `read`, never `for d in $(...)`: unquoted
        # command substitution would let the shell PATHNAME-EXPAND the `*`
        # still in the DEST pattern against the pack's own tree.
        while IFS= read -r d; do
            [ -n "$d" ] || continue
            expanded="$(_install_map_expand "$root" "$src" "$d")" || return 1
            while IFS="$tab" read -r rsrc rdest; do
                [ -n "$rsrc" ] || continue
                printf '%s\t%s\t%s\n' "$rsrc" "$rdest" "$cls"
            done <<PAIRS
$expanded
PAIRS
        done <<FANOUT
$(_install_map_fanout "$dest")
FANOUT
    done <<GLOBS
${_INSTALL_MAP_GLOBS:-}
GLOBS
    return 0
}

install_map_dispatch_set() {
    local token="${1:-}"
    if [ -z "$token" ]; then
        _install_map_err "install_map_dispatch_set requires a stage token"
        return 1
    fi
    local rows tab src dest cls
    # Load BEFORE the command substitution below. `$(...)` runs in a SUBSHELL,
    # and so does each nested `_install_map_expand`, so a load performed down
    # there populates a memo that dies with the subshell — the parse would
    # re-run and `git ls-files` would fork once per family expansion. Loading
    # here memoises in the CALLER's shell, which every subshell inherits.
    _install_map_load || return 1
    rows="$(_install_map_resolved "$token")" || return 1
    tab="$(printf '\t')"
    while IFS="$tab" read -r src dest cls; do
        [ -n "$src" ] || continue
        printf '%s:%s:%s\n' "$src" "$dest" "$cls"
    done <<ROWS
$rows
ROWS
    return 0
}

install_map_declared_dests() {
    local token="${1:-}"
    local rows tab src dest cls
    # Memoise in the caller's shell — see install_map_dispatch_set.
    _install_map_load || return 1
    rows="$(_install_map_resolved "$token")" || return 1
    tab="$(printf '\t')"
    while IFS="$tab" read -r src dest cls; do
        [ -n "$dest" ] || continue
        printf '%s\n' "$dest"
    done <<ROWS
$rows
ROWS
    return 0
}

install_map_source_for_dest() {
    local want="${1:-}"
    [ -n "$want" ] || return 1
    _install_map_load || return 1
    local tab src dest stages cls d pre post cap spre spost
    tab="$(printf '\t')"
    while IFS="$tab" read -r src dest stages cls; do
        if [ -n "$src" ] && [ "$dest" = "$want" ]; then
            printf '%s\n' "$src"
            return 0
        fi
    done <<EXPLICIT
${_INSTALL_MAP_EXPLICIT:-}
EXPLICIT
    # Family rows: match the fanned-out DEST pattern and substitute the
    # capture back into the SOURCE pattern. This is what collapses the 1->3
    # skills family — three client paths, one pool source.
    while IFS="$tab" read -r src dest stages cls; do
        [ -n "$src" ] || continue
        # `read`, never `for d in $(...)` — see _install_map_resolved.
        while IFS= read -r d; do
            [ -n "$d" ] || continue
            case "$d" in
                *\**)
                    pre="${d%%\**}"
                    post="${d#*\*}"
                    case "$want" in
                        "$pre"*"$post")
                            cap="${want#"$pre"}"
                            cap="${cap%"$post"}"
                            # `*` matches within ONE path segment and never
                            # crosses `/` — the semantics the forward
                            # direction already has (shell pathname expansion
                            # does not cross `/`) and the semantics the
                            # Python matcher documents. A `case` glob is
                            # unrestricted, so a capture spanning `/` would
                            # reverse-resolve a NESTED dest onto a one-level
                            # family row and return the wrong pack source.
                            case "$cap" in
                                */*) continue ;;
                            esac
                            spre="${src%%\**}"
                            spost="${src#*\*}"
                            printf '%s\n' "${spre}${cap}${spost}"
                            return 0
                            ;;
                    esac
                    ;;
                "$want")
                    printf '%s\n' "$src"
                    return 0
                    ;;
            esac
        done <<FANOUT
$(_install_map_fanout "$dest")
FANOUT
    done <<GLOBS
${_INSTALL_MAP_GLOBS:-}
GLOBS
    return 1
}
