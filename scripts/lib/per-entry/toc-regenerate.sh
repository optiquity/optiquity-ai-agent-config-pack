# scripts/lib/per-entry/toc-regenerate.sh — regenerate `_toc.md` from a
# per-entry tree (BD-164).
#
# Public API:
#   per_entry_regenerate_toc <stream_key> <stream_dir>
#       Regenerate `<stream_dir>/_toc.md` from the entry files in the
#       directory. Per-stream axis per sidecar §5.1 (+ BD-262 groupings):
#           pack-backlog                 grouped by Status: value
#           pack-changelog               grouped by major version
#           project-backlog              grouped by Status: value
#           project-implementation-plan  grouped by phase number
#           project-changelog            grouped by year-month, descending
#           project-groupings            grouped by Kind (alphabetical by
#                                        slug), IDs ascending within group;
#                                        row grammar
#                                        `- GRP-NNN — <Title> (phases: N)`
#       Deterministic + idempotent (re-running on the same input yields
#       byte-identical _toc.md). Shared parsing logic in _lib.sh per
#       sidecar §6.2.
#
# Architecture:
#   maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md
#     §5.1 (TOC axis per stream)
#     §5.2 (regenerator contract — deterministic + idempotent)
#     §6.2 (shared parsing logic invariant)
#
# Bash 3.2 + macOS BSD utility compatible.
#
# Do NOT add a shebang — this file is sourced, not executed.

if ! type pe_die >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fi

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

per_entry_regenerate_toc() {
    local key="$1"
    local stream_dir="$2"

    [[ -n "$key" ]] || pe_die "per_entry_regenerate_toc: stream key required"
    [[ -n "$stream_dir" ]] || pe_die "per_entry_regenerate_toc: stream dir required"

    pe_entry_regex_for_stream "$key" >/dev/null || \
        pe_die "per_entry_regenerate_toc: unknown stream key: $key"
    [[ -d "$stream_dir" ]] || pe_die "per_entry_regenerate_toc: stream dir not found: $stream_dir"

    local toc_path="$stream_dir/_toc.md"
    local toc_tmp
    toc_tmp=$(mktemp "$stream_dir/.per-entry-toc.XXXXXX") || \
        pe_die "per_entry_regenerate_toc: mktemp failed"
    # shellcheck disable=SC2064
    trap "rm -f '$toc_tmp'" EXIT

    PE_TOC_KEY="$key" \
    PE_TOC_DIR="$stream_dir" \
    PE_TOC_OUT="$toc_tmp" \
        python3 - <<'PYEOF' || pe_die "per_entry_regenerate_toc: python parser failed"
import os
import re
import sys

key = os.environ["PE_TOC_KEY"]
stream_dir = os.environ["PE_TOC_DIR"]
out_path = os.environ["PE_TOC_OUT"]

# Stream-axis-name + entry-listing axis.
axis_for_stream = {
    "pack-backlog":                "Status",
    "pack-changelog":              "version",
    "project-backlog":             "Status",
    "project-implementation-plan": "phase",
    "project-changelog":           "year-month",
    "project-groupings":           "Kind",
}
display_name_for_stream = {
    "pack-backlog":                "pack-backlog",
    "pack-changelog":              "pack-changelog",
    "project-backlog":             "project-backlog",
    "project-implementation-plan": "project-implementation-plan",
    "project-changelog":           "project-changelog",
    "project-groupings":           "project-groupings",
}

# Entry-file regex per stream (must mirror _lib.sh hard-coded values).
entry_regex_for_stream = {
    # BD-211: canonical pack-backlog filename `BD-NNN.md` — NO letter
    # suffix (must mirror _lib.sh).
    "pack-backlog":                re.compile(r"^BD-\d+\.md$"),
    # BD-203 A3/CHANGE 2: per-release pack-changelog granularity (`vN.md`).
    "pack-changelog":              re.compile(r"^v\d+\.md$"),
    "project-backlog":             re.compile(r"^TD-\d+\.md$"),
    "project-implementation-plan": re.compile(r"^phase-\d+\.md$"),
    # Mandatory slug (mirrors the _lib.sh project-changelog entry-regex;
    # the stream contract docs/project/changelog/_rules.md § Filename
    # convention is the rule's source).
    "project-changelog":           re.compile(r"^\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.md$"),
    # BD-262: TIGHTENED — exactly 3 digits zero-padded through GRP-999,
    # unpadded 4+ digits from GRP-1000 (kills GRP-0000; mirrors _lib.sh).
    "project-groupings":           re.compile(r"^GRP-(\d{3}|[1-9]\d{3,})\.md$"),
}

# BD-262: per-entry member counts for the groupings row grammar
# `- GRP-NNN — <Title> (phases: N)` (populated by the collection branch).
member_counts = {}

axis = axis_for_stream[key]
display = display_name_for_stream[key]
entry_re = entry_regex_for_stream[key]

# Collect entries.
entries = []  # list of (filename, id, group_label, title)
for name in sorted(os.listdir(stream_dir)):
    if name.startswith("_"):
        continue
    if not entry_re.match(name):
        continue
    path = os.path.join(stream_dir, name)
    try:
        with open(path, "r", encoding="utf-8", newline="") as f:
            text = f.read()
    except OSError:
        continue
    entry_id = name[:-3]  # strip .md

    # Skip line-1 back-pointer when extracting metadata.
    body_lines = text.splitlines()
    if body_lines and re.match(r"^<!-- per-entry source: .*; contract: .* -->$", body_lines[0]):
        body_lines = body_lines[1:]

    # Extract title + group based on stream axis.
    title = ""
    group = ""

    if key in ("pack-backlog", "project-backlog"):
        # Title from the canonical `**ID — Title**` line. BD-211: the ID
        # is `[A-Z]+-\d+` with NO letter suffix and NO pre-em-dash
        # parenthetical (a parenthetical, if present, is TITLE TEXT after
        # the em-dash). Prefix-agnostic `[A-Z]+` serves BD AND TD
        # (CROSS-SURFACE).
        for ln in body_lines:
            m = re.match(r"^\*\*[A-Z]+-\d+ — (.+?)\*\*", ln)
            if m:
                title = m.group(1).strip()
                break
        # Group from `Status:` field.
        for ln in body_lines:
            m = re.match(r"^Status:\s*(\S+)", ln)
            if m:
                group = m.group(1).strip()
                break
        if not group:
            group = "Open"  # default if Status absent

    elif key == "pack-changelog":
        # BD-203 CHANGE 2 — per-release granularity: the entry is one
        # `vN.md` per major release; the body's first header is the
        # `## vN — <date>` H2. Title = whatever follows the version + ` — `.
        for ln in body_lines:
            m = re.match(r"^## (v\d+) — (.+)$", ln)
            if m:
                title = m.group(2).strip()
                break
        # Group: the major version itself (each release is its own group;
        # under per-release granularity each group holds exactly one entry).
        m = re.match(r"^(v\d+)$", entry_id)
        if m:
            group = m.group(1)
        else:
            group = "v?"

    elif key == "project-implementation-plan":
        # Title from `## Phase N — <title>` line.
        for ln in body_lines:
            m = re.match(r"^## Phase \d+ — (.+)$", ln)
            if m:
                title = m.group(1).strip()
                break
        # Group: phase number itself (each phase is its own group).
        m = re.match(r"^phase-(\d+)$", entry_id)
        if m:
            group = f"Phase {m.group(1)}"
        else:
            group = entry_id

    elif key == "project-changelog":
        # Title from `### YYYY-MM-DD — ...` line, taking everything
        # after the first ` — `.
        for ln in body_lines:
            m = re.match(r"^### \d{4}-\d{2}-\d{2} — (.+)$", ln)
            if m:
                title = m.group(1).strip()
                break
        # Group: year-month (first 7 chars of date prefix).
        m = re.match(r"^(\d{4}-\d{2})-", entry_id)
        if m:
            group = m.group(1)
        else:
            group = entry_id[:7] if len(entry_id) >= 7 else entry_id

    elif key == "project-groupings":
        # BD-262. Title from the bold-pair `**GRP-NNN — <Title>**` line
        # (the ID-keyed-entry anchor; title byte-preserved after the
        # em-dash).
        for ln in body_lines:
            m = re.match(r"^\*\*GRP-\d+ — (.+?)\*\*", ln)
            if m:
                title = m.group(1).strip()
                break
        # Group: the `Kind:` field — the stream's classification axis
        # (plain `Field: value` form per the closed groupings grammar).
        # Kind encodes no execution order; groups render alphabetically.
        for ln in body_lines:
            m = re.match(r"^Kind:\s*(\S+)", ln)
            if m:
                group = m.group(1).strip()
                break
        if not group:
            # Display fallback only (a missing Kind is a validation
            # matter, not the regenerator's); deterministic group label.
            group = "(no kind)"
        # Member count for the pinned row grammar
        # `- GRP-NNN — <Title> (phases: N)`.
        mp_value = ""
        for ln in body_lines:
            m = re.match(r"^Member-phases:\s*(.*)$", ln)
            if m:
                mp_value = m.group(1)
                break
        member_counts[entry_id] = len(re.findall(r"phase-\d+", mp_value))

    if not title:
        title = entry_id  # fallback so the TOC is never blank

    entries.append((name, entry_id, group, title))

# ─── Group + sort entries deterministically ──────────────────
# Sort entries by (group, id) initially for deterministic emission;
# re-group below with stream-specific group ordering.

grouped = {}
group_order = []
for (filename, entry_id, group, title) in entries:
    if group not in grouped:
        grouped[group] = []
        group_order.append(group)
    grouped[group].append((filename, entry_id, title))

# Stream-specific group ordering.
def order_groups(key, group_order):
    if key in ("pack-backlog", "project-backlog"):
        # BD-203 A7 — RATIFIED status order (BD-203 entry + amendment E2):
        # actionable-first (Open → Unblocked → Deferred) then terminal
        # (Resolved → Deprecated → Cancelled). `Unblocked` is admitted as
        # a canonical lifecycle state per D2. Any unknown statuses follow
        # alphabetically.
        canonical = ["Open", "Unblocked", "Deferred", "Resolved",
                     "Deprecated", "Cancelled"]
        head = [g for g in canonical if g in group_order]
        tail = sorted(g for g in group_order if g not in canonical)
        return head + tail
    if key == "pack-changelog":
        # Major version descending: v11 > v10 > v9 > ... v1.
        def vkey(g):
            m = re.match(r"^v(\d+)$", g)
            return -int(m.group(1)) if m else 0
        return sorted(group_order, key=vkey)
    if key == "project-implementation-plan":
        # Phase ascending: Phase 0, Phase 1, ...
        def pkey(g):
            m = re.match(r"^Phase (\d+)$", g)
            return int(m.group(1)) if m else 999
        return sorted(group_order, key=pkey)
    if key == "project-changelog":
        # Year-month descending.
        return sorted(group_order, reverse=True)
    if key == "project-groupings":
        # Kind slugs alphabetical (BD-262; the Kind axis encodes no
        # execution order — alphabetical is pure presentation).
        return sorted(group_order)
    return sorted(group_order)

ordered_groups = order_groups(key, group_order)

# Within-group entry sort.
def entry_sort_key(key, entry_tuple):
    filename, entry_id, title = entry_tuple
    if key in ("pack-backlog", "project-backlog"):
        # By numeric ID ascending. BD-211: canonical IDs are
        # `[A-Z]+-NNN` with NO letter suffix; the captured group is the
        # numeric part. Prefix-agnostic `[A-Z]+` serves BD AND TD
        # (CROSS-SURFACE).
        m = re.match(r"^[A-Z]+-(\d+)$", entry_id)
        return int(m.group(1)) if m else 0
    if key == "pack-changelog":
        # BD-203 CHANGE 2 — per-release granularity: each major-version
        # group holds exactly one `vN` entry, so within-group sort is
        # a no-op. Stable key by major version descending.
        m = re.match(r"^v(\d+)$", entry_id)
        if m:
            return -int(m.group(1))
        return 0
    if key == "project-implementation-plan":
        # Within a phase group there's exactly one phase-N file under
        # the addendum #1 §6.4 spec (tasks inline). Stable ordering by id.
        return entry_id
    if key == "project-changelog":
        # Descending date (lex sort of inverted strings). Python's tuple
        # comparison is lexicographic; negating per-char ord values
        # inverts the ordering so newer dates sort first.
        return tuple(-ord(c) for c in filename)
    if key == "project-groupings":
        # IDs ascending by numeric part within each Kind group (BD-262).
        m = re.match(r"^GRP-(\d+)$", entry_id)
        return int(m.group(1)) if m else 0
    return entry_id

# ─── Emit the TOC ────────────────────────────────────────────
out = []
out.append(f"# Table of contents — {display}")
out.append("")
out.append(f"<!-- generated by scripts/lib/per-entry/toc-regenerate.sh — DO NOT EDIT BY HAND -->")
# NB: sidecar §5.1 names a regeneration-time stamp + generator-version
# stamp as a candidate trailer. Deliberately omitted: any time/version
# stamp would make `_toc.md` content non-deterministic across pack
# version-bumps and would break Check 33 (TOC-in-sync) byte-identical
# regeneration. The "DO NOT EDIT BY HAND" line above is the only
# generated marker; readers wanting provenance can grep the helper path.
out.append("")

if not ordered_groups:
    out.append("(empty — no entries)")
else:
    for group in ordered_groups:
        out.append(f"## {group}")
        out.append("")
        items = grouped[group]
        items.sort(key=lambda e: entry_sort_key(key, e))
        for (filename, entry_id, title) in items:
            if key == "project-groupings":
                # BD-262 pinned row grammar (documented in the shipped
                # stream contract's Write-authority section — the
                # client-side format SSOT the PM regenerates against).
                count = member_counts.get(entry_id, 0)
                out.append(f"- {entry_id} — {title} (phases: {count})")
            else:
                out.append(f"- [{entry_id}](./{filename}) — {title}")
        out.append("")

# Trim trailing blank lines, ensure single trailing newline.
while out and out[-1] == "":
    out.pop()
out.append("")  # final newline

with open(out_path, "w", encoding="utf-8", newline="") as f:
    f.write("\n".join(out))
PYEOF

    # Idempotency check: if existing _toc.md is byte-identical to the
    # regenerated one, leave the on-disk file untouched (no mtime churn).
    if [[ -f "$toc_path" ]] && cmp -s "$toc_tmp" "$toc_path"; then
        rm -f "$toc_tmp"
        trap - EXIT
        return 0
    fi

    mv "$toc_tmp" "$toc_path"
    trap - EXIT
    return 0
}
