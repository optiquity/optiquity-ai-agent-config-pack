#!/usr/bin/env bash
# groupings.sh — the groupings query CLI (read-only).
#
# Five verbs over the shared derivation library `groupings-lib.sh`
# (sourced sibling). This script is PRESENTATION ONLY: every derivation
# (scan, reverse lookup, derived status, derived target, dependency
# edges, order, cascade, implied bounds, counts) comes from the library;
# nothing is re-derived here. There is no write path.
#
# Verbs:
#   list
#       All REAL groupings, ID ascending, one row:
#         GRP-NNN — <Kind> — <derived> D/A (P%) [flags] — <target> —
#         <Title> — <members-csv|->
#       The reserved GRP-000 never gets a row; when it exists the tail
#       line `declared stays-ungrouped: K` reports the living
#       declared-ungrouped count (superseded members excluded). Empty
#       tree: `(no groupings)`, exit 0. With -q: the machine rollup rows
#       verbatim (`GRP-NNN <derived> <D>/<A> <pct|-> b=N d=N s=N u=N
#       tgt=<token|-|unknown> t=K`), no tail line.
#   list-membership <phase-N|GRP-NNN>
#       phase-N: grouping IDs containing the phase, one per line
#       (GRP-000 included; may be empty; exit 0). GRP-NNN: the detail
#       view — header
#         GRP-NNN — <Title> — <Kind> — <derived> D/A (P%) [flags]
#         — <target> t=K/N
#       (N = A-D; a poisoned target renders `— unknown` bare; no target
#       suffix when no member declares) above the member list, one
#       phase-N per line. GRP-000: count-only header (the
#       declared-ungrouped ledger derives no status and no target).
#       With -q the grouping arm emits the machine rollup row + members;
#       GRP-000 has no machine row — the library's reserved refusal
#       surfaces verbatim.
#   deps
#       Derived inter-grouping edges `GRP-A -> GRP-B` (A must precede
#       B), derived at query time from member-phase dependency fields;
#       with -q: `GRP-A GRP-B` rows verbatim. Empty tree:
#       `(no groupings)`, exit 0.
#   deps --deferral
#       The deferral/supersession cascade view: the library's source /
#       poisoned rows (per-phase edge attribution, grouping
#       annotations), each followed by an indented target annotation
#         tgt=<declared|-|unknown> impl=<implied|-|unknown> via=<phase-N|->
#       then one row per affected real grouping:
#         grouping GRP-NNN poisoned-max=<token|-|unknown>
#       poisoned-max = max over DECLARED targets of the grouping's
#       non-absorbing marked members (done and superseded members never
#       count; `unknown` iff a counted member carries an illegal
#       `Target:` or is absent from the epic-keyed target map
#       (never-legible); `future-unassigned` participates; implied
#       bounds never enter). No cascade: `(no deferral cascade)`, exit 0
#       (suppressed under -q).
#   order
#       Derived grouping execution order; mutually-dependent groupings
#       print as one `interleaved:` cluster row. Empty tree:
#       `(no groupings)`, exit 0.
#   shared-with <GRP-NNN>
#       Real groupings sharing >=1 member phase with the argument
#       (argument excluded), one per line. GRP-000 is refused
#       (reserved).
#
# Contracts (the client-side SSOTs):
#   docs/project/groupings/_rules.md — grouping entries; the reserved
#     GRP-000 declared-ungrouped ledger.
#   docs/project/implementation-plan/_rules.md `## Entry schema` — the
#     status-enum / target-enum vocabularies; target-enum declaration
#     order IS the ordinal scale (read at call time, never hardcoded).
#   Dependency edges: the four-field grammar — `Blockers` /
#     `Dependencies` / `Prerequisite` contribute prereq edges,
#     `Unblocks` contributes dependent edges — parsed once in the
#     library's single edge-parse point.
#
# Typed errors: ONE line on stderr, exit 1.
#   groupings-lib: ERROR(<code>): <msg>   library errors, surfaced
#                                         VERBATIM (never re-wrapped)
#   groupings: ERROR(<code>): <msg>       argument-shape errors caught
#                                         at dispatch; also the list
#                                         join-integrity check (a REAL
#                                         grouping missing its rollup
#                                         row = parse — never a silent
#                                         row-drop)
# Codes: unknown-id / bad-ref / no-tree / parse / reserved.
# Usage errors (missing/unknown verb, bad flag): usage on stderr,
# exit 2.
#
# Usage:
#   groupings.sh <list|list-membership|deps|order|shared-with>
#                [<phase-N|GRP-NNN>] [-q] [--deferral] [--root DIR]
#
# --root DIR overrides the project root (default: this script's parent
# directory's parent). Trees: docs/project/groupings +
# docs/project/implementation-plan under the root. Output is stdout
# rows only — deterministic and byte-stable.
set -uo pipefail

usage() {
  cat <<'EOF'
usage: groupings.sh <verb> [<ref>] [-q] [--deferral] [--root DIR]
verbs:
  list                    all real groupings + the GRP-000 tail line
  list-membership <ref>   phase-N -> grouping IDs; GRP-NNN -> detail view
  deps [--deferral]       derived inter-grouping edges; --deferral = the
                          deferral/supersession cascade view
  order                   derived execution order (interleaved: clusters)
  shared-with <GRP-NNN>   real groupings sharing >=1 member phase
flags:
  -q          machine rows (library row grammars verbatim)
  --root DIR  project root (default: this script's parent dir's parent)
EOF
}

err_usage() { printf 'groupings: %s\n' "$1" >&2; usage >&2; exit 2; }
cli_err()   { printf 'groupings: ERROR(%s): %s\n' "$1" "$2" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=groupings-lib.sh
. "$SCRIPT_DIR/groupings-lib.sh"

TAB="$(printf '\t')"

VERB=""
REF=""
QUIET=0
DEFERRAL=0
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  list|list-membership|deps|order|shared-with) VERB="$1"; shift ;;
  "") err_usage "missing verb" ;;
  *) err_usage "unknown verb '${1}'" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    -q) QUIET=1 ;;
    --deferral) DEFERRAL=1 ;;
    --root)
      [ $# -ge 2 ] || err_usage "--root requires a directory"
      ROOT="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) err_usage "unknown flag '$1'" ;;
    *)
      [ -z "$REF" ] || err_usage "unexpected extra argument '$1'"
      REF="$1" ;;
  esac
  shift
done

case "$VERB" in
  list|deps|order)
    [ -z "$REF" ] || err_usage "$VERB takes no reference argument" ;;
esac
if [ "$DEFERRAL" -eq 1 ] && [ "$VERB" != "deps" ]; then
  err_usage "--deferral applies to deps only"
fi

GDIR="$ROOT/docs/project/groupings"
IDIR="$ROOT/docs/project/implementation-plan"

# ── Small lookup helpers (presentation joins over library rows) ────────
map_val() {  # map_val <key> <rows "key value [...]"> -> field 2 of match
  printf '%s\n' "$2" | awk -v k="$1" '$1 == k { print $2; exit }'
}

scan_row() {  # scan_row <GRP-NNN> <grp_scan rows> -> the full TAB row
  printf '%s\n' "$2" | awk -F'\t' -v id="$1" '$1 == id { print; exit }'
}

parse_rollup() {  # parse_rollup <machine row> -> RR_* globals
  # shellcheck disable=SC2086
  set -- $1
  RR_DERIVED=$2; RR_DA=$3; RR_PCT=$4
  RR_B=${5#b=}; RR_D=${6#d=}; RR_S=${7#s=}; RR_U=${8#u=}
  RR_TGT=${9#tgt=}; RR_K=${10#t=}
}

rollup_seg() {  # the display status cluster: <derived> D/A (P%) [flags]
  local seg flags
  seg="$RR_DERIVED $RR_DA $(grp_render_pct "$RR_PCT")"
  flags="$(grp_render_flags "$RR_B" "$RR_D" "$RR_S" "$RR_U")"
  [ -n "$flags" ] && seg="$seg $flags"
  printf '%s' "$seg"
}

# target-enum tokens from the tree's own contract (the landed
# twin-parser posture; declaration order IS the ordinal scale). Read
# only for the poisoned-max presentation join — the library has already
# fail-louded if the vocabulary is unusable. The awk mirrors the
# library parser's accept/reject behavior on the schema line
# (groupings-lib.sh load_target_enum): inside the first `## Entry
# schema` section (scan ends at the next `## ` header), a `- `-prefixed
# line containing a colon matches iff the whitespace-stripped key
# before the FIRST colon equals `target-enum`; the value is the
# whitespace-stripped remainder. Proven mirror plane: the ASCII/POSIX
# whitespace plane PLUS the lib runtime's measured SEPARATOR class
# (CPython str.split whitespace that is NOT a str.splitlines boundary:
# U+001F, U+00A0 NBSP, U+1680, U+2000-U+200A, U+202F, U+205F, U+3000)
# — libsep() maps each to ASCII space so the edge-strip + shell-IFS
# tokenization downstream reproduces the lib's token list (NBSP proven
# composed by the C13 test leg; the lib SPLITS on NBSP, it does not
# pass it through as a value byte). NOT mirrored: the lib's LINE-BREAK
# class (\v \f \r \x1c-\x1e, U+0085, U+2028, U+2029 — str.splitlines
# boundaries): the lib re-breaks the LINE there, a line-structure
# plane this line-oriented awk does not re-split.
ENUM=""
read_enum() {
  ENUM="$(awk '
    function libsep(s) {
      # The lib runtime SEPARATOR class beyond POSIX [[:space:]]/IFS,
      # each UTF-8 sequence (locale-safe: exact bytes in C locale,
      # the exact character in UTF-8 locale) mapped to ASCII space.
      gsub("\037", " ", s)          # U+001F
      gsub("\302\240", " ", s)      # U+00A0 NBSP
      gsub("\341\232\200", " ", s)  # U+1680
      gsub("\342\200\200", " ", s)  # U+2000
      gsub("\342\200\201", " ", s)  # U+2001
      gsub("\342\200\202", " ", s)  # U+2002
      gsub("\342\200\203", " ", s)  # U+2003
      gsub("\342\200\204", " ", s)  # U+2004
      gsub("\342\200\205", " ", s)  # U+2005
      gsub("\342\200\206", " ", s)  # U+2006
      gsub("\342\200\207", " ", s)  # U+2007
      gsub("\342\200\210", " ", s)  # U+2008
      gsub("\342\200\211", " ", s)  # U+2009
      gsub("\342\200\212", " ", s)  # U+200A
      gsub("\342\200\257", " ", s)  # U+202F
      gsub("\342\201\237", " ", s)  # U+205F
      gsub("\343\200\200", " ", s)  # U+3000
      return s
    }
    /^## Entry schema/ { insec = 1; next }
    insec && /^## /    { exit }
    insec && substr($0, 1, 2) == "- " && index($0, ":") > 0 {
      line = substr($0, 3)
      ci = index(line, ":")
      key = libsep(substr(line, 1, ci - 1))
      gsub(/^[[:space:]]+/, "", key); gsub(/[[:space:]]+$/, "", key)
      if (key != "target-enum") next
      val = libsep(substr(line, ci + 1))
      gsub(/^[[:space:]]+/, "", val); gsub(/[[:space:]]+$/, "", val)
      print val
      exit
    }
  ' "$IDIR/_rules.md" 2>/dev/null)"
}

ord_of() {  # ord_of <token> -> ordinal index, -1 when not in the enum
  local i=0 t
  for t in $ENUM; do
    if [ "$t" = "$1" ]; then printf '%s' "$i"; return; fi
    i=$((i + 1))
  done
  printf '%s' "-1"
}

tok_at() {  # tok_at <ordinal> -> token
  local i=0 t
  for t in $ENUM; do
    if [ "$i" -eq "$1" ]; then printf '%s' "$t"; return; fi
    i=$((i + 1))
  done
}

# ── Verbs ───────────────────────────────────────────────────────────────
cmd_list() {
  local scan real rollup nc row memdisp
  scan="$(grp_scan "$GDIR")" || exit 1
  if [ "$QUIET" -eq 1 ]; then
    rollup="$(grp_rollup_map "$GDIR" "$IDIR")" || exit 1
    [ -n "$rollup" ] && printf '%s\n' "$rollup"
    exit 0
  fi
  real="$(printf '%s\n' "$scan" | awk -F'\t' '$3 == "real"')"
  if [ -z "$real" ]; then
    printf '(no groupings)\n'
  else
    rollup="$(grp_rollup_map "$GDIR" "$IDIR")" || exit 1
    # A scanned REAL grouping with no rollup row is a broken library
    # contract (grp_rollup_map is REAL-set-complete): fail LOUD — a
    # silent row-drop at rc=0 would hide the grouping. cli_err fires
    # inside the pipeline subshell; the || exit propagates its rc.
    printf '%s\n' "$real" | while IFS="$TAB" read -r gid kind flag members title; do
      row="$(printf '%s\n' "$rollup" | awk -v id="$gid" '$1 == id { print; exit }')"
      [ -n "$row" ] || cli_err parse \
        "no rollup row for $gid — grp_rollup_map dropped a REAL grouping"
      parse_rollup "$row"
      memdisp="${members:--}"
      printf '%s — %s — %s — %s — %s — %s\n' \
        "$gid" "$kind" "$(rollup_seg)" "$RR_TGT" "$title" "$memdisp"
    done || exit 1
  fi
  if printf '%s\n' "$scan" | awk -F'\t' '$3 == "reserved" { found = 1 } END { exit !found }'; then
    nc="$(grp_nudge_counts "$GDIR" "$IDIR")" || exit 1
    printf 'declared stays-ungrouped: %s\n' "${nc##*K=}"
  fi
  exit 0
}

cmd_list_membership() {
  local out scan line title kind members row hdr d_count a_count nc
  [ -n "$REF" ] || err_usage "list-membership requires <phase-N|GRP-NNN>"
  case "$REF" in
    phase-*)
      out="$(grp_reverse_lookup "$GDIR" "$REF")" || exit 1
      [ -n "$out" ] && printf '%s\n' "$out"
      exit 0
      ;;
    GRP-000)
      if [ "$QUIET" -eq 1 ]; then
        # GRP-000 has no machine row (REAL set only) — the library's
        # reserved rollup refusal surfaces verbatim.
        grp_rollup "$GDIR" "$IDIR" "$REF" || exit 1
        exit 0
      fi
      scan="$(grp_scan "$GDIR")" || exit 1
      line="$(scan_row "$REF" "$scan")"
      [ -n "$line" ] || cli_err unknown-id "no such grouping: $REF"
      title="$(printf '%s\n' "$line" | cut -f5-)"
      members="$(printf '%s\n' "$line" | cut -f4)"
      nc="$(grp_nudge_counts "$GDIR" "$IDIR")" || exit 1
      printf '%s — %s — declared stays-ungrouped: %s\n' \
        "$REF" "$title" "${nc##*K=}"
      [ -n "$members" ] && printf '%s\n' "$members" | tr ',' '\n'
      exit 0
      ;;
    GRP-*)
      row="$(grp_rollup "$GDIR" "$IDIR" "$REF")" || exit 1
      scan="$(grp_scan "$GDIR")" || exit 1
      line="$(scan_row "$REF" "$scan")"
      title="$(printf '%s\n' "$line" | cut -f5-)"
      kind="$(printf '%s\n' "$line" | cut -f2)"
      members="$(printf '%s\n' "$line" | cut -f4)"
      if [ "$QUIET" -eq 1 ]; then
        printf '%s\n' "$row"
      else
        parse_rollup "$row"
        d_count=${RR_DA%%/*}
        a_count=${RR_DA##*/}
        hdr="$REF — $title — $kind — $(rollup_seg)"
        case "$RR_TGT" in
          -) ;;
          unknown) hdr="$hdr — unknown" ;;
          *) hdr="$hdr — $RR_TGT t=$RR_K/$((a_count - d_count))" ;;
        esac
        printf '%s\n' "$hdr"
      fi
      [ -n "$members" ] && printf '%s\n' "$members" | tr ',' '\n'
      exit 0
      ;;
    *)
      cli_err bad-ref "'$REF' is not a phase-N or GRP-NNN reference"
      ;;
  esac
}

cmd_deps() {
  local real edges
  real="$(grp_real "$GDIR")" || exit 1
  if [ -z "$real" ]; then
    [ "$QUIET" -eq 0 ] && printf '(no groupings)\n'
    exit 0
  fi
  edges="$(grp_deps "$GDIR" "$IDIR")" || exit 1
  if [ "$QUIET" -eq 1 ]; then
    [ -n "$edges" ] && printf '%s\n' "$edges"
  else
    [ -n "$edges" ] && printf '%s\n' "$edges" | awk '{ print $1 " -> " $2 }'
  fi
  exit 0
}

cmd_deps_deferral() {
  local cas smap tmap imap marked affected row ph tgt irow impl via
  cas="$(grp_cascade "$GDIR" "$IDIR")" || exit 1
  if [ -z "$cas" ]; then
    [ "$QUIET" -eq 0 ] && printf '(no deferral cascade)\n'
    exit 0
  fi
  smap="$(grp_phase_status_map "$IDIR")" || exit 1
  tmap="$(grp_phase_target_map "$IDIR")" || exit 1
  imap="$(grp_implied_target_map "$IDIR")" || exit 1
  read_enum

  # The cascade rows verbatim, each with its target annotation row.
  printf '%s\n' "$cas" | while IFS= read -r row; do
    printf '%s\n' "$row"
    ph="$(printf '%s\n' "$row" | awk '{ print $2 }')"
    # Defensive defaults (one posture, both maps): a cascade phase
    # absent from the epic-keyed lib maps is never-legible = the
    # `unknown` class; `-` would assert a READ, target-absent phase.
    tgt="$(map_val "$ph" "$tmap")"
    [ -n "$tgt" ] || tgt="unknown"
    irow="$(printf '%s\n' "$imap" | awk -v k="$ph" '$1 == k { print $2, $3; exit }')"
    if [ -n "$irow" ]; then
      impl="${irow%% *}"
      via="${irow##* }"
    else
      impl="unknown"
      via="-"
    fi
    printf '  tgt=%s impl=%s via=%s\n' "$tgt" "$impl" "$via"
  done

  # Per-affected-grouping poisoned-max rows: the marked (source +
  # poisoned) member inventory, joined per real grouping.
  marked="$(printf '%s\n' "$cas" | awk '{
    csv = "-"
    for (i = 3; i <= NF; i++) if ($i ~ /^groups=/) csv = substr($i, 8)
    print $2 "\t" csv
  }')"
  affected="$(printf '%s\n' "$marked" | cut -f2 | tr ',' '\n' \
    | grep -v '^-$' | grep -v '^GRP-000$' | sort -u -t- -k2,2n)" || true
  [ -z "$affected" ] && exit 0
  printf '%s\n' "$affected" | while IFS= read -r g; do
    best=-1
    poisoned=0
    while IFS="$TAB" read -r ph csv; do
      case ",$csv," in
        *",$g,"*) ;;
        *) continue ;;
      esac
      st="$(map_val "$ph" "$smap")"
      case "$st" in done|superseded) continue ;; esac
      tv="$(map_val "$ph" "$tmap")"
      # Absent row = never-legible = the `unknown` class (the one
      # posture, same as the annotation-row defaults above); `-` would
      # assert a READ, target-absent phase.
      [ -n "$tv" ] || tv="unknown"
      if [ "$tv" = "unknown" ]; then
        poisoned=1
      elif [ "$tv" != "-" ]; then
        o="$(ord_of "$tv")"
        [ "$o" -gt "$best" ] && best="$o"
      fi
    done <<EOF
$marked
EOF
    if [ "$poisoned" -eq 1 ]; then
      v="unknown"
    elif [ "$best" -lt 0 ]; then
      v="-"
    else
      v="$(tok_at "$best")"
    fi
    printf 'grouping %s poisoned-max=%s\n' "$g" "$v"
  done
  exit 0
}

cmd_order() {
  local real out
  real="$(grp_real "$GDIR")" || exit 1
  if [ -z "$real" ]; then
    [ "$QUIET" -eq 0 ] && printf '(no groupings)\n'
    exit 0
  fi
  out="$(grp_order "$GDIR" "$IDIR")" || exit 1
  [ -n "$out" ] && printf '%s\n' "$out"
  exit 0
}

cmd_shared_with() {
  local out
  [ -n "$REF" ] || err_usage "shared-with requires <GRP-NNN>"
  out="$(grp_shared_with "$GDIR" "$REF")" || exit 1
  [ -n "$out" ] && printf '%s\n' "$out"
  exit 0
}

case "$VERB" in
  list) cmd_list ;;
  list-membership) cmd_list_membership ;;
  deps)
    if [ "$DEFERRAL" -eq 1 ]; then cmd_deps_deferral; else cmd_deps; fi ;;
  order) cmd_order ;;
  shared-with) cmd_shared_with ;;
esac
