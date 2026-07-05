#!/usr/bin/env bash
# target-sweep.sh — release-boundary target enumerations (read-only).
#
# The PM invokes this at a declared release boundary (procedure:
# docs/pack/PM-CHAT.md "Release-boundary target sweep"). Each verb prints
# one deterministic enumeration of the implementation-plan tree's phase
# `Target:` claims. The tool NEVER edits a phase file — there is no write
# path and no apply mode; dispositions are per-phase user decisions and
# every phase-file edit is a PM-session act with per-edit approval.
#
# Verbs (rows are `phase-N <literal-value>`, phase-number ascending):
#   enumerate      every phase-epic carrying `Target:`, ALL statuses.
#                  The value is emitted VERBATIM (legality is the
#                  validation gate's job, not this tool's).
#   overdue        sweep-scope phases whose Target equals the FIRST
#                  target-enum token (`current` under the shipped enum).
#   re-encode-set  sweep-scope phases whose Target equals the SECOND
#                  token (`next-release`) — the mechanical
#                  next-release-to-current re-encode input.
#   kind-set       sweep-scope phases whose Target is an interior token
#                  after the second and before the last (`next-minor` /
#                  `next-major` under the shipped enum) — the once-asked
#                  release-kind question's input.
#
# Sweep scope (overdue / re-encode-set / kind-set): non-done AND
# non-superseded phases — spent claims, by completion or supersession,
# are never re-encoded. `enumerate` alone lists all statuses.
#
# Vocabulary is schema-driven: the target-enum tokens are read from the
# tree's own `_rules.md` (`## Entry schema` block). Declaration order is
# the ordinal scale, so the filters key on token POSITION, never on
# hardcoded names. `Entry-Type:` / `Status:` / `Target:` are parsed with
# the same labeled-line grammar the shipped validation gate uses (bold /
# plain / bullet label forms; the value is the FIRST matching line's
# text after the colon, trimmed, surrounding asterisks stripped). Parts
# are never enumerated (epic-only; a part inherits its parent phase's
# target by containment).
#
# Usage:
#   target-sweep.sh <enumerate|overdue|re-encode-set|kind-set> [impl-plan-dir]
#
# impl-plan-dir defaults to docs/project/implementation-plan under the
# project root (this script's parent directory's parent). Exit 0 on a
# clean run, including an empty enumeration; exit 2 on a usage error, a
# missing tree, or a filter verb with no usable target-enum vocabulary.
# Output is stdout rows only — deterministic and byte-stable (sorted
# numeric discovery, no timestamps).
set -euo pipefail

usage() {
  echo "usage: target-sweep.sh <enumerate|overdue|re-encode-set|kind-set> [impl-plan-dir]"
}

err() { echo "target-sweep: $*" >&2; }

VERB=""
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  enumerate|overdue|re-encode-set|kind-set) VERB="$1" ;;
  "") usage >&2; exit 2 ;;
  *) err "unknown verb '${1}'"; usage >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIR="${2:-$ROOT_DIR/docs/project/implementation-plan}"

if [ ! -d "$DIR" ]; then
  err "no implementation-plan tree at $DIR"
  exit 2
fi

# ── Labeled-line field grammar (the gate's twin) ───────────────────────────
# Mirrors the shipped validate-docs.sh conformance grammar:
#   ^\s*(?:[-*]\s*)?\*{0,2}FIELD\*{0,2}\s*:(.*)$   (first match wins)
# value = text after the colon, trimmed, surrounding '*' stripped, trimmed.
_RX_PRE='^[[:space:]]*([-*][[:space:]]*)?\*{0,2}'
_RX_POST='\*{0,2}[[:space:]]*:'

field_present() { # $1=file $2=field-label
  grep -q -E "${_RX_PRE}$2${_RX_POST}" "$1" 2>/dev/null
}

field_value() { # $1=file $2=field-label → cleaned value on stdout ('' if absent)
  local line
  line="$(grep -m 1 -E "${_RX_PRE}$2${_RX_POST}" "$1" 2>/dev/null || true)"
  if [ -z "$line" ]; then
    return 0
  fi
  printf '%s' "$line" | sed \
    -e 's/^[^:]*://' \
    -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    -e 's/^\*\{1,\}//' -e 's/\*\{1,\}$//' \
    -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# ── Schema-driven vocabulary: target-enum from the tree's own _rules.md ────
RULES="$DIR/_rules.md"
ENUM_LINE=""
if [ -f "$RULES" ]; then
  ENUM_LINE="$(awk '
    /^## Entry schema/ { insec = 1; next }
    /^## /             { insec = 0 }
    insec && /^- target-enum[[:space:]]*:/ {
      sub(/^- target-enum[[:space:]]*:[[:space:]]*/, ""); print; exit
    }
  ' "$RULES")"
fi

# Positional semantics over the declared ordinal scale (declaration order
# IS the scale): token 1 = the overdue window, token 2 = the re-encode
# window, tokens 3..(n-1) = the kind set (the last token is the terminal
# unconstrained window and joins no sweep set).
T_OVERDUE=""
T_REENCODE=""
KIND_TOKENS=""
if [ -n "$ENUM_LINE" ]; then
  # shellcheck disable=SC2086
  set -- $ENUM_LINE
  N=$#
  T_OVERDUE="${1:-}"
  if [ "$N" -ge 2 ]; then
    T_REENCODE="$2"
  fi
  i=0
  for t in "$@"; do
    i=$((i + 1))
    if [ "$i" -ge 3 ] && [ "$i" -lt "$N" ]; then
      KIND_TOKENS="$KIND_TOKENS $t"
    fi
  done
fi

case "$VERB" in
  overdue)
    if [ -z "$T_OVERDUE" ]; then
      err "no target-enum in $RULES — the sweep vocabulary is undefined"
      exit 2
    fi
    ;;
  re-encode-set)
    if [ -z "$T_REENCODE" ]; then
      err "no target-enum (or fewer than two tokens) in $RULES — the sweep vocabulary is undefined"
      exit 2
    fi
    ;;
  kind-set)
    if [ -z "$ENUM_LINE" ]; then
      err "no target-enum in $RULES — the sweep vocabulary is undefined"
      exit 2
    fi
    ;;
esac

in_kind_set() { # $1=value → 0 iff value is a kind token
  local t
  for t in $KIND_TOKENS; do
    if [ "$t" = "$1" ]; then
      return 0
    fi
  done
  return 1
}

# ── One deterministic pass, phase-number ascending ─────────────────────────
NUMS="$(ls "$DIR" 2>/dev/null | sed -n -E 's/^phase-([0-9]+)\.md$/\1/p' | sort -n)"

ROWS=""
COUNT=0
for n in $NUMS; do
  f="$DIR/phase-$n.md"
  if [ ! -f "$f" ]; then
    continue
  fi
  et="$(field_value "$f" "Entry-Type" | tr '[:upper:]' '[:lower:]')"
  if [ "$et" != "phase-epic" ]; then
    continue  # epic-only: parts (and untyped entries) are never enumerated
  fi
  if ! field_present "$f" "Target"; then
    continue
  fi
  tgt="$(field_value "$f" "Target")"

  if [ "$VERB" != "enumerate" ]; then
    st="$(field_value "$f" "Status")"
    if [ "$st" = "done" ] || [ "$st" = "superseded" ]; then
      continue  # spent claims are never re-encoded
    fi
    case "$VERB" in
      overdue)
        if [ "$tgt" != "$T_OVERDUE" ]; then continue; fi ;;
      re-encode-set)
        if [ "$tgt" != "$T_REENCODE" ]; then continue; fi ;;
      kind-set)
        if ! in_kind_set "$tgt"; then continue; fi ;;
    esac
  fi

  row="phase-$n"
  if [ -n "$tgt" ]; then
    row="$row $tgt"
  fi
  ROWS="${ROWS}${row}
"
  COUNT=$((COUNT + 1))
done

if [ "$COUNT" -eq 0 ]; then
  case "$VERB" in
    enumerate)     echo "(no targets)" ;;
    overdue)       echo "(no overdue targets)" ;;
    re-encode-set) echo "(no re-encode targets)" ;;
    kind-set)      echo "(no kind-set targets)" ;;
  esac
else
  printf '%s' "$ROWS"
fi
exit 0
