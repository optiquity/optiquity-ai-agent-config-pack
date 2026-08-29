# scripts/lib/pack-provenance.sh — pack-provenance probe + baseline-reachability gate.
#
# Answers one question about a file already installed in a client project:
# **is its current content a blob THIS pack has ever held at the given pack
# SOURCE path?** A `yes` proves the file is pack-authored (an older pack
# release the client never touched), so the caller may use it as the merge
# BASE. A `no` proves nothing about the client — it only means the pack cannot
# prove authorship — so the caller keeps its existing routing (preserve the
# client's bytes in a sidecar and ask for reconciliation).
#
# Do NOT add a shebang — this file is sourced, not executed.
#
# Pack-side by dependency direction: `scripts/init-project.sh` sources this at
# runtime. It is NOT a `project-template/scripts/` file and must never become
# one.
#
# ENTRY POINTS
#
#   pack_provenance_init [<pack>]
#       Build the historical blob index ONCE and memoise it.
#       rc 0 = index ready.   rc 2 = usage error or object walk failed.
#       Safe to call repeatedly; rebuilds only when <pack> changes.
#
#   pack_provenance_baseline_reachable [<pack>]
#       The whole-run availability gate. rc 0 = the baseline anchor resolves in
#       <pack>.   rc 1 = it does not: prints a notice plus the shipped
#       remediation on stderr.   rc 2 = usage error.
#       The anchor is `$PACK_PROVENANCE_BASELINE_REF` (default `v10`).
#
#   pack_provenance_is_pack_authored <pack_source_relpath> <local_file>
#       rc 0 = hash(<local_file>) is a blob the pack has held at
#              <pack_source_relpath>; the matching blob sha is printed on stdout.
#       rc 1 = NOT-FOUND — the pack has never held those bytes at that path.
#       rc 2 = usage error, unreadable file, or hashing failure.
#       rc 1 and rc 2 are deliberately distinct: a NOT-FOUND is a verdict, a
#       rc 2 is a broken probe, and a caller must never route them alike.
#
#   <pack> defaults to `$PACK`.
#
# THE KEY IS THE PACK SOURCE PATH, NEVER THE CLIENT RELPATH.
#   The index is keyed by path-relative-to-the-pack-root
#   (`supporting-docs/METHODOLOGY.md`, `project-template/skills/review/SKILL.md`).
#   The client's installed relpath (`docs/pack/METHODOLOGY.md`,
#   `.claude/skills/review/SKILL.md`) is not a key in the index, so passing one
#   returns NOT-FOUND for every file — a 100% miss rate that looks exactly like
#   "the client customised everything". Callers resolve dest -> source first.
#
# IMPLEMENTATION CONSTRAINTS (each is load-bearing and measured; a
# "simplification" of any one of them regresses a measured finding)
#
#   1. ONE walk, never one per file. A single `git rev-list --all --objects`
#      over the two shipped trees yields 2608 rows in ~55 ms, and the whole
#      index build (walk + filter + sort) measures ~90-155 ms. A per-file walk
#      would multiply that by the size of the dispatch set.
#
#   2. `--all` is load-bearing, not decoration. The baseline is NOT an ancestor
#      of HEAD and hangs off `refs/tags` alone, so a HEAD-only object walk
#      loses 25 of the 2608 rows — including the baseline blobs of the very
#      documents this probe exists to classify.
#
#   3. `--full-history` is specified even though its delta here is ZERO rows
#      (2608 rows with and without it; 1 merge commit out of ~1496). It did NOT
#      fix a live gap. It is a forward guard: if the history ever stops being
#      near-linear, history simplification would silently shrink the index.
#
#   4. `--no-filters` is mandatory, and it changes verdicts. `.gitattributes`
#      carries no `text`/`eol` directive, so stored blobs are the bytes as
#      authored. But a client with `core.autocrlf=input` makes a plain
#      `git hash-object` normalise CRLF away, so a CRLF-mangled file hashes to
#      the pack's own blob sha and is reported PACK-AUTHORED (measured: same
#      sha without the flag, different sha with it). Without `--no-filters` a
#      purely local git setting flips an overwrite-vs-preserve verdict.
#
#   5. The index lives in a shell string, not a temp file. Nothing to leak,
#      nothing to clean up, no cross-run staleness, and the membership test
#      costs no subprocess. The timing edge is small — measured 3.6 ms
#      in-process vs 3.9 ms for `grep -Fqx` against a temp file, ~5% — so the
#      structural reasons above carry this choice, not the speed.
#
#   6. The gate tests REACHABILITY, never shallowness. A clone made without
#      tags is NOT shallow — `git rev-parse --is-shallow-repository` reports
#      `false` — yet it has lost the baseline objects. A shallowness test
#      therefore cannot detect the state that disables this probe, and is never
#      used here.
#
#   7. There is no "git is missing" degradation. `detect_pack_path` rejects a
#      non-repo pack before any caller reaches this library. Baseline
#      reachability is the only thing that degrades.

# Memoised index state. Guarded assignment so re-sourcing does not discard a
# built index.
: "${_PACK_PROVENANCE_INDEX:=}"
: "${_PACK_PROVENANCE_PACK:=}"

# ── pack_provenance_init [<pack>] ─────────────────────────────────────────────
pack_provenance_init() {
    local pack="${1:-${PACK:-}}"

    if [ -z "$pack" ]; then
        printf 'pack-provenance: no pack path (pass one, or set $PACK)\n' >&2
        return 2
    fi
    if [ ! -d "$pack" ]; then
        printf 'pack-provenance: pack path is not a directory: %s\n' "$pack" >&2
        return 2
    fi

    # Memoised: the index is a property of the pack, so rebuild only on change.
    if [ -n "$_PACK_PROVENANCE_INDEX" ] && [ "$_PACK_PROVENANCE_PACK" = "$pack" ]; then
        return 0
    fi

    local raw
    if ! raw=$(git -C "$pack" rev-list --all --objects --full-history \
                   -- project-template supporting-docs 2>/dev/null); then
        printf 'pack-provenance: object walk failed in %s\n' "$pack" >&2
        return 2
    fi

    # `--objects` emits bare commit shas (one field) interleaved with
    # `<sha> <path>` rows for the trees and blobs under the pathspec. Keep the
    # two-field rows. A tree row can never satisfy a lookup: a lookup key is a
    # FILE path and a tree's path is a directory, so the two never coincide.
    local rows
    rows=$(printf '%s\n' "$raw" | awk 'NF > 1' | LC_ALL=C sort -u)
    if [ -z "$rows" ]; then
        printf 'pack-provenance: object walk produced no rows in %s\n' "$pack" >&2
        return 2
    fi

    # Sentinel newlines at both ends so the membership test matches WHOLE
    # lines only — never a prefix of a longer path.
    _PACK_PROVENANCE_INDEX=$'\n'"$rows"$'\n'
    _PACK_PROVENANCE_PACK="$pack"
    return 0
}

# ── pack_provenance_baseline_reachable [<pack>] ───────────────────────────────
pack_provenance_baseline_reachable() {
    local pack="${1:-${PACK:-}}"
    local ref="${PACK_PROVENANCE_BASELINE_REF:-v10}"

    if [ -z "$pack" ]; then
        printf 'pack-provenance: no pack path (pass one, or set $PACK)\n' >&2
        return 2
    fi
    # Same guard as init, and for the same reason: a pack path that is not a
    # directory is a broken probe (rc 2), never a baseline verdict (rc 1).
    # Without it `git -C` fails, the gate reports NOT-FOUND, and the notice
    # below tells the operator to `git fetch` inside a directory that does not
    # exist.
    if [ ! -d "$pack" ]; then
        printf 'pack-provenance: pack path is not a directory: %s\n' "$pack" >&2
        return 2
    fi

    if git -C "$pack" rev-parse --verify --quiet "${ref}^{commit}" >/dev/null 2>&1; then
        return 0
    fi

    printf 'pack-provenance: baseline ref '\''%s'\'' does not resolve in %s\n' \
        "$ref" "$pack" >&2
    printf 'pack-provenance: this pack clone is missing the baseline objects, so\n' >&2
    printf '  provenance cannot be established and every file falls back to\n' >&2
    printf '  reconciliation routing. A clone made without tags is NOT shallow,\n' >&2
    printf '  so `git rev-parse --is-shallow-repository` cannot see this state.\n' >&2
    printf '  Recover the baseline with:\n' >&2
    printf '      git fetch origin v10:v10\n' >&2
    return 1
}

# ── pack_provenance_is_pack_authored <pack_source_relpath> <local_file> ───────
pack_provenance_is_pack_authored() {
    local relpath="${1:-}" file="${2:-}"

    if [ -z "$relpath" ] || [ -z "$file" ]; then
        printf 'pack-provenance: usage: pack_provenance_is_pack_authored <pack_source_relpath> <local_file>\n' >&2
        return 2
    fi
    if [ ! -f "$file" ]; then
        printf 'pack-provenance: not a readable file: %s\n' "$file" >&2
        return 2
    fi

    # `git -C <pack>` moves the git process's cwd, so a caller-relative path
    # would resolve against the pack instead of the caller. Normalise first.
    case "$file" in
        /*) ;;
        *)
            local _dir _base
            _base=$(basename "$file")
            if ! _dir=$(cd "$(dirname "$file")" 2>/dev/null && pwd); then
                printf 'pack-provenance: cannot resolve path: %s\n' "$file" >&2
                return 2
            fi
            file="$_dir/$_base"
            ;;
    esac

    # One memo, held by pack_provenance_init. Calling it on every probe is what
    # keeps the index tied to the pack the caller actually means: a second memo
    # here would answer from a stale index built for a DIFFERENT pack. init
    # returns immediately when the index already matches, so the cost is two
    # string tests, not a walk.
    pack_provenance_init "${PACK:-$_PACK_PROVENANCE_PACK}" || return 2

    local sha
    if ! sha=$(printf '%s\n' "$file" \
                 | git -C "$_PACK_PROVENANCE_PACK" hash-object --no-filters --stdin-paths 2>/dev/null); then
        printf 'pack-provenance: hash-object failed for %s\n' "$file" >&2
        return 2
    fi
    if [ -z "$sha" ]; then
        printf 'pack-provenance: hash-object returned nothing for %s\n' "$file" >&2
        return 2
    fi

    local nl=$'\n'
    case "$_PACK_PROVENANCE_INDEX" in
        *"${nl}${sha} ${relpath}${nl}"*)
            printf '%s\n' "$sha"
            return 0
            ;;
    esac
    return 1
}
