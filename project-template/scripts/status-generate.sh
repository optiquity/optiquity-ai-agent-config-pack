#!/usr/bin/env bash
# status-generate.sh — the deterministic, marker-delimited, never-SSOT
# STATUS.md dashboard generator.
#
# Target file: docs/project/STATUS.md (the live working-snapshot dashboard;
# NEVER source of truth — the per-entry trees under docs/project/ and the
# pm-session-state.json snapshot are the canonical sources).
#
# Generated-sections shape (marker grammar, namespaced STATUS-GEN /
# STATUS-HAND — disjoint from every other marker namespace in the tree):
#
#   <!-- STATUS-GEN:BEGIN <section> -->   ...generated...   <!-- STATUS-GEN:END <section> -->
#   <!-- STATUS-HAND:BEGIN -->            ...PM prose...    <!-- STATUS-HAND:END -->
#
# Sections generated (classes 1a / 1b / 2):
#   phases     class 1a — one row per phase EPIC (Phase | Title | Status |
#              Target | Groupings). Status = the phase `Status:` FIELD via
#              grp_phase_status_map; Target = the phase's own `Target:`
#              field via grp_phase_target_map (em-dash when absent);
#              Title = flat-file title link (docs/project/-relative, GitHub
#              anchor grammar); Groupings = the three-state cell from
#              grp_reverse_map — real-grouping links / `none (declared)`
#              (GRP-000 member) / `—` (member of nothing = the PENDING
#              ask). The PENDING ask excludes superseded phases (a
#              superseded orphan renders `none (superseded)`, never the
#              ask; deferred orphans stay listed as pending).
#   groupings  class 1b — one row per REAL grouping, header pinned
#              `Grouping | Kind | Status | % complete | Target | Member
#              phases`; Status / fraction / percent / Target come from the
#              grp_rollup_map machine row (flags + percent rendered via the
#              lib's grp_render_flags / grp_render_pct helpers).
#   frontier   class 2 — the resume frontier rendered FROM
#              docs/project/pm-session-state.json (SOURCE only; the
#              snapshot is never written); absent snapshot renders the
#              fresh-session line.
# Class 3 (hand section) is seeded ONCE with a placeholder and preserved
# byte-identical on every regen.
#
# All grouping/phase derivations come from the shared groupings-lib.sh —
# this script re-parses NO phase Status:/Target: grammar and NO grouping
# entry grammar (it reads phase files only for the H2 title, and the
# snapshot only as JSON).
#
# Modes:
#   (default)  regenerate: create docs/project/STATUS.md if absent (seeding
#              the hand section); regenerate the STATUS-GEN sections in
#              place when markers are present. A marker-LESS existing file
#              is REFUSED (wrap the content in STATUS-HAND markers, then
#              re-run — the generator adopts a well-formed hand-only file).
#   --check    gate CLASS 1 ONLY: regenerate the phases + groupings
#              sections in memory and diff against the file; exit non-zero
#              on drift. The frontier section is checked for MARKER
#              INTEGRITY only (never content-diffed); the hand section is
#              ignored. SKIPs (exit 0, notice) when STATUS.md is absent or
#              marker-less.
#
# Exit codes: 0 ok / SKIP; 1 drift, marker-integrity failure, refusal, or
# a groupings-lib typed error; 2 usage.
#
# Deterministic: same tree + same snapshot => byte-identical output (no
# timestamps). Bash 3.2 + BSD utils compatible; rendering runs in one
# embedded python3 pass (python3 is already a project dependency).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="generate"
if [ "$#" -gt 0 ]; then
    case "$1" in
        --check) MODE="check" ;;
        -h|--help)
            sed -n '2,62p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "status-generate: unknown argument '$1' (usage: status-generate.sh [--check])" >&2
            exit 2
            ;;
    esac
    if [ "$#" -gt 1 ]; then
        echo "status-generate: too many arguments (usage: status-generate.sh [--check])" >&2
        exit 2
    fi
fi

OUT="$ROOT_DIR/docs/project/STATUS.md"
IPD="$ROOT_DIR/docs/project/implementation-plan"
GDIR="$ROOT_DIR/docs/project/groupings"
SNAP="$ROOT_DIR/docs/project/pm-session-state.json"
PMCHAT="$ROOT_DIR/docs/pack/PM-CHAT.md"

has_markers() {
    grep -q -e 'STATUS-GEN:' -e 'STATUS-HAND:' "$1"
}

# ── SKIP / REFUSE arms that need no tree derivation ────────────────────
if [ "$MODE" = "check" ]; then
    if [ ! -f "$OUT" ]; then
        echo "status-generate: SKIP — docs/project/STATUS.md absent (nothing to check; run scripts/status-generate.sh to create it)"
        exit 0
    fi
    if ! has_markers "$OUT"; then
        echo "status-generate: SKIP — docs/project/STATUS.md carries no STATUS-GEN/STATUS-HAND markers (not generator-managed; run scripts/status-generate.sh to adopt it)"
        exit 0
    fi
else
    if [ -f "$OUT" ] && ! has_markers "$OUT"; then
        echo "status-generate: ERROR(marker-less): docs/project/STATUS.md exists without STATUS-GEN/STATUS-HAND markers — refusing to overwrite hand-authored content." >&2
        echo "status-generate: wrap the existing content in '<!-- STATUS-HAND:BEGIN -->' / '<!-- STATUS-HAND:END -->' marker lines (everything inside the pair), then re-run scripts/status-generate.sh to adopt it." >&2
        exit 1
    fi
fi

# ── The shared derivations (groupings-lib.sh is the single parse point) ─
# shellcheck disable=SC1090
. "$SCRIPT_DIR/groupings-lib.sh"

SMAP="$(grp_phase_status_map "$IPD")"
TMAP="$(grp_phase_target_map "$IPD")"
RMAP="$(grp_reverse_map "$GDIR")"
ROLL="$(grp_rollup_map "$GDIR" "$IPD")"
REAL="$(grp_real "$GDIR")"

# Augment each machine rollup row with the lib-rendered display flags and
# percent (grp_render_flags / grp_render_pct stay the ONE presentation
# implementation): `<machine row>\t<flags>\t<rendered-pct>`.
ROLL_AUG=""
TAB="$(printf '\t')"
while IFS= read -r row; do
    [ -z "$row" ] && continue
    # shellcheck disable=SC2086
    set -- $row
    fl="$(grp_render_flags "${5#b=}" "${6#d=}" "${7#s=}" "${8#u=}")"
    rp="$(grp_render_pct "$4")"
    ROLL_AUG="${ROLL_AUG}${row}${TAB}${fl}${TAB}${rp}
"
done <<ROLLEOF
$ROLL
ROLLEOF

export SG_MODE="$MODE" SG_OUT="$OUT" SG_IPD="$IPD" SG_SNAP="$SNAP" \
    SG_PMCHAT="$PMCHAT" SG_ROOTNAME="$(basename "$ROOT_DIR")" \
    SG_SMAP="$SMAP" SG_TMAP="$TMAP" SG_RMAP="$RMAP" SG_ROLL="$ROLL_AUG" \
    SG_REAL="$REAL"

python3 - <<'PYEOF'
import json
import os
import re
import sys

MODE = os.environ["SG_MODE"]
OUT = os.environ["SG_OUT"]
IPD = os.environ["SG_IPD"]
SNAP = os.environ["SG_SNAP"]
PMCHAT = os.environ["SG_PMCHAT"]
ROOTNAME = os.environ["SG_ROOTNAME"]

GEN_SECTIONS = ("phases", "groupings", "frontier")
CLASS1_SECTIONS = ("phases", "groupings")
HAND_BEGIN = "<!-- STATUS-HAND:BEGIN -->"
HAND_END = "<!-- STATUS-HAND:END -->"
HAND_SEED = "(PM judgment — next actions, risks, notes)"
DISCLAIMER = (
    "<!-- Working snapshot — never source of truth. The STATUS-GEN "
    "sections are generated by scripts/status-generate.sh; the canonical "
    "sources are the per-entry trees under docs/project/ (backlog/, "
    "implementation-plan/, groupings/ — each with its generated index) "
    "and the pm-session-state.json snapshot. Edits to STATUS.md must not "
    "contradict the per-entry trees; if they disagree, the per-entry "
    "trees win. Hand-authored content lives only between the STATUS-HAND "
    "markers. -->"
)


def gen_begin(name):
    return "<!-- STATUS-GEN:BEGIN %s -->" % name


def gen_end(name):
    return "<!-- STATUS-GEN:END %s -->" % name


def err(msg):
    sys.stderr.write("status-generate: %s\n" % msg)


def rows_of(env, nfields, sep=None):
    out = []
    for line in os.environ.get(env, "").splitlines():
        if not line.strip():
            continue
        parts = line.split(sep, nfields - 1)
        out.append(parts)
    return out


# ── Lib-row consumption (no grammar re-parse: rows are the lib API) ────
smap_rows = rows_of("SG_SMAP", 2)              # phase-N <token>
tmap = {p[0]: p[1] for p in rows_of("SG_TMAP", 2)}
rmap = {p[0]: p[1].split(",") for p in rows_of("SG_RMAP", 2)}
real_rows = rows_of("SG_REAL", 5, "\t")        # gid kind flag members title
real_by_id = {r[0]: r for r in real_rows}
roll_rows = rows_of("SG_ROLL", 3, "\t")        # machine-row \t flags \t pct


# ── Presentation helpers ────────────────────────────────────────────────
def anchor_of(heading):
    """The PM-CHAT GitHub-anchor grammar: lowercase; specials (em-dash,
    backticks, colons, parentheses, periods, asterisks, slashes) removed;
    each whitespace char becomes a hyphen (an em-dash between spaces
    leaves `--`)."""
    h = heading.lower()
    h = re.sub(r"[^\w\s-]", "", h)
    return re.sub(r"\s", "-", h)


def title_link(num):
    """The flat-file title-link cell: `[Title](implementation-plan/
    phase-N.md#anchor)` — docs/project/-relative. Title = the text after
    the first ` — ` of the entry's first H2; falls back to the bare
    phase token when no H2 is readable (link without a fragment)."""
    path = os.path.join(IPD, "phase-%s.md" % num)
    heading = None
    try:
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                if line.startswith("## "):
                    heading = line[3:].strip()
                    break
    except OSError:
        heading = None
    if not heading:
        return "[phase-%s](implementation-plan/phase-%s.md)" % (num, num)
    title = heading.split(" — ", 1)[1] if " — " in heading else heading
    title = title.replace("|", "\\|")
    return "[%s](implementation-plan/phase-%s.md#%s)" % (
        title, num, anchor_of(heading))


def grouping_link(gid):
    return "[%s](groupings/%s.md)" % (gid, gid)


def member_links(members_csv):
    toks = [t for t in members_csv.split(",") if t]
    if not toks:
        return "—"
    return ", ".join(
        "[%s](implementation-plan/%s.md)" % (t, t) for t in toks)


def groupings_cell(num, status_tok):
    """The three-state class-1a cell (single source: grp_reverse_map):
    real-grouping links / `none (declared)` (GRP-000 member) / `—`
    (member of nothing = the PENDING ask). The PENDING ask excludes
    superseded phases (nudge-silence): a superseded orphan renders
    `none (superseded)`; deferred orphans stay pending."""
    ids = rmap.get("phase-%s" % num, [])
    real_ids = [g for g in ids if g != "GRP-000"]
    if real_ids:
        return ", ".join(grouping_link(g) for g in real_ids)
    if "GRP-000" in ids:
        return "none (declared)"
    if status_tok == "superseded":
        return "none (superseded)"
    return "—"


def dash_when_absent(tok):
    return "—" if tok == "-" else tok


# ── Class 1a — the phases table ─────────────────────────────────────────
def build_phases_section():
    lines = ["## Phases", "",
             "| Phase | Title | Status | Target | Groupings |",
             "|---|---|---|---|---|"]
    if not smap_rows:
        lines.append("| (no phases) | — | — | — | — |")
    for token, st in smap_rows:
        num = token.split("-", 1)[1]
        lines.append("| %s | %s | %s | %s | %s |" % (
            token, title_link(num), st,
            dash_when_absent(tmap.get(token, "-")),
            groupings_cell(num, st)))
    return lines


# ── Class 1b — the groupings table (REAL set; pinned header) ────────────
def build_groupings_section():
    lines = ["## Groupings", "",
             "| Grouping | Kind | Status | % complete | Target "
             "| Member phases |",
             "|---|---|---|---|---|---|"]
    if not roll_rows:
        lines.append("| (no groupings declared) | — | — | — | — | — |")
    for parts in roll_rows:
        machine = parts[0].split()
        flags = parts[1] if len(parts) > 1 else ""
        pct = parts[2] if len(parts) > 2 else "—"
        gid, derived, frac = machine[0], machine[1], machine[2]
        tgt = machine[8].split("=", 1)[1]
        rec = real_by_id.get(gid)
        kind = rec[1] if rec else "—"
        members = member_links(rec[3]) if rec else "—"
        status_cell = derived + (" " + flags if flags else "")
        lines.append("| %s | %s | %s | %s %s | %s | %s |" % (
            grouping_link(gid), kind, status_cell, frac, pct,
            dash_when_absent(tgt), members))
    return lines


# ── Class 2 — the resume frontier (snapshot is SOURCE only) ─────────────
def frag(v):
    if v is None:
        return "—"
    if isinstance(v, str):
        return v if v.strip() else "—"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, list):
        return ", ".join(frag(x) for x in v) if v else "—"
    if isinstance(v, dict):
        return "; ".join(
            "%s: %s" % (k, frag(v[k])) for k in v) if v else "—"
    return json.dumps(v)


def build_frontier_section():
    lines = ["## Resume frontier", ""]
    if not os.path.isfile(SNAP):
        lines.append("no resume frontier — fresh session")
        return lines
    try:
        with open(SNAP, encoding="utf-8") as fh:
            snap = json.load(fh)
        if not isinstance(snap, dict):
            raise ValueError("top-level JSON is not an object")
    except (OSError, ValueError):
        lines.append(
            "resume frontier unreadable — docs/project/"
            "pm-session-state.json is not a JSON object (the snapshot is "
            "the SSOT; repair it — the docs gate's session-state axis "
            "names the contract)")
        return lines
    lines.append("- **Active:** %s" % frag(snap.get("active")))
    lines.append("- **Queue:** %s" % frag(snap.get("queue")))
    lines.append("- **Mode:** %s" % frag(snap.get("parallelization")))
    lines.append("- **Boundary commit:** %s"
                 % frag(snap.get("boundary_commit")))
    return lines


# ── Project name (pm-startup precedent: PM-CHAT.md's first H1) ──────────
def project_name():
    try:
        with open(PMCHAT, encoding="utf-8") as fh:
            for line in fh:
                if line.startswith("# "):
                    return line[2:].split(" — ", 1)[0].strip() or ROOTNAME
    except OSError:
        pass
    return ROOTNAME


# ── Marker machinery ────────────────────────────────────────────────────
def find_pair(lines, begin, end, label, problems):
    bi = [i for i, l in enumerate(lines) if l.strip() == begin]
    ei = [i for i, l in enumerate(lines) if l.strip() == end]
    if len(bi) == 1 and len(ei) == 1 and bi[0] < ei[0]:
        return (bi[0], ei[0])
    if not bi and not ei:
        problems.append("%s marker pair missing" % label)
    elif len(bi) != 1 or len(ei) != 1:
        problems.append(
            "%s markers malformed (%d BEGIN, %d END — exactly one pair "
            "required)" % (label, len(bi), len(ei)))
    else:
        problems.append("%s END marker precedes its BEGIN" % label)
    return None


def check_disjoint(named_pairs, problems):
    """Pair-range disjointness assert: the splice/diff machinery assumes
    sibling (non-overlapping) marker pairs, but two individually
    well-formed pairs can still be INTERLEAVED by hand-edit (each passes
    find_pair: one BEGIN, one END, BEGIN < END). Without this assert the
    overlapping-range splice corrupts the frame at exit 0 on THAT pass —
    so a violation fails THIS pass, typed, before any splice/diff."""
    spans = sorted((p[0], p[1], label)
                   for label, p in named_pairs if p is not None)
    for (b1, e1, l1), (b2, e2, l2) in zip(spans, spans[1:]):
        if b2 < e1:
            problems.append(
                "%s and %s marker pairs interleave (marker pairs must "
                "be disjoint)" % (l1, l2))


def assemble(sections, hand_inner):
    lines = [DISCLAIMER, "# STATUS — %s" % project_name(), ""]
    for name in GEN_SECTIONS:
        lines.append(gen_begin(name))
        lines.extend(sections[name])
        lines.append(gen_end(name))
        lines.append("")
    lines.append(HAND_BEGIN)
    lines.extend(hand_inner)
    lines.append(HAND_END)
    return "\n".join(lines) + "\n"


def write_out(text):
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(text)


sections = {
    "phases": build_phases_section(),
    "groupings": build_groupings_section(),
    "frontier": build_frontier_section(),
}

# ── Mode: generate ──────────────────────────────────────────────────────
if MODE == "generate":
    if not os.path.isfile(OUT):
        write_out(assemble(sections, [HAND_SEED]))
        print("status-generate: created docs/project/STATUS.md "
              "(hand section seeded)")
        sys.exit(0)

    text = open(OUT, encoding="utf-8").read()
    lines = text.split("\n")
    has_gen = any("STATUS-GEN:" in l for l in lines)
    problems = []
    hand = find_pair(lines, HAND_BEGIN, HAND_END, "STATUS-HAND", problems)

    if not has_gen:
        # Hand-only file (the REFUSE remediation wrap): adopt it — rebuild
        # the generated frame around the preserved hand section. Refuse if
        # non-whitespace content sits OUTSIDE the pair (nothing is ever
        # silently destroyed).
        if hand is None:
            err("ERROR(marker-integrity): " + "; ".join(problems))
            sys.exit(1)
        outside = lines[:hand[0]] + lines[hand[1] + 1:]
        if any(l.strip() for l in outside):
            err("ERROR(marker-integrity): non-whitespace content outside "
                "the STATUS-HAND pair in a file without STATUS-GEN "
                "sections — move it inside the STATUS-HAND markers, then "
                "re-run.")
            sys.exit(1)
        write_out(assemble(sections, lines[hand[0] + 1:hand[1]]))
        print("status-generate: adopted docs/project/STATUS.md "
              "(hand section preserved; generated sections created)")
        sys.exit(0)

    pairs = {}
    for name in GEN_SECTIONS:
        pairs[name] = find_pair(
            lines, gen_begin(name), gen_end(name),
            "STATUS-GEN %s" % name, problems)
    check_disjoint(
        [("STATUS-HAND", hand)]
        + [("STATUS-GEN %s" % n, pairs[n]) for n in GEN_SECTIONS],
        problems)
    if problems:
        err("ERROR(marker-integrity): " + "; ".join(problems))
        sys.exit(1)

    # Splice each generated section in place; every byte outside the
    # three GEN pair interiors is preserved verbatim (class 3 untouched).
    for name in sorted(GEN_SECTIONS,
                       key=lambda n: pairs[n][0], reverse=True):
        b, e = pairs[name]
        lines[b + 1:e] = sections[name]
    new_text = "\n".join(lines)
    if new_text != text:
        write_out(new_text)
        print("status-generate: regenerated the STATUS-GEN sections "
              "in docs/project/STATUS.md")
    else:
        print("status-generate: docs/project/STATUS.md already current")
    sys.exit(0)

# ── Mode: check (class 1 only; frontier = marker integrity only) ────────
text = open(OUT, encoding="utf-8").read()
lines = text.split("\n")
has_gen = any("STATUS-GEN:" in l for l in lines)
problems = []
hand = find_pair(lines, HAND_BEGIN, HAND_END, "STATUS-HAND", problems)

if not has_gen:
    err("STATUS.md carries a STATUS-HAND section but no generated "
        "sections — run scripts/status-generate.sh")
    sys.exit(1)

pairs = {}
for name in GEN_SECTIONS:
    pairs[name] = find_pair(
        lines, gen_begin(name), gen_end(name),
        "STATUS-GEN %s" % name, problems)
check_disjoint(
    [("STATUS-HAND", hand)]
    + [("STATUS-GEN %s" % n, pairs[n]) for n in GEN_SECTIONS],
    problems)
if problems:
    err("ERROR(marker-integrity): " + "; ".join(problems))
    sys.exit(1)

drift = []
for name in CLASS1_SECTIONS:
    b, e = pairs[name]
    if lines[b + 1:e] != sections[name]:
        drift.append(name)
if drift:
    err("STATUS.md class-1 drift in section(s): %s — run "
        "scripts/status-generate.sh to regenerate" % ", ".join(drift))
    sys.exit(1)

print("status-generate: check OK — class-1 sections current, "
      "markers intact")
sys.exit(0)
PYEOF

