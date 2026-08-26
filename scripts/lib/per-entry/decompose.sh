# scripts/lib/per-entry/decompose.sh — split a monolithic mirror file
# into a per-entry tree (BD-164).
#
# Public API:
#   per_entry_decompose <stream_key> <monolithic_path> <stream_dir>
#       Split the monolithic mirror at <monolithic_path> into per-entry
#       files under <stream_dir>/<id>.md. Adds the line-1 HTML-comment
#       back-pointer to each per-entry file (Addendum #2 §2). Idempotent:
#       running twice on the same input is a no-op the second time
#       (the output tree is byte-identical).
#
#   Optional env PE_DECOMPOSE_DROPPED=<absolute path> — dropped-content
#       capture sink. When set, the walker TRUNCATES the capture file at
#       decompose start (re-entry never double-appends), then appends
#       every line the walk ignores (pre-first-anchor preamble;
#       section-break line + following non-anchor lines; H1-break line +
#       following non-anchor lines) VERBATIM, in input order. Each
#       contiguous ignored block is preceded by exactly one delimiter
#       line `<!-- v10 monolith lines A–B -->` (A/B = 1-based inclusive
#       monolith line numbers of the block; en-dash). When unset:
#       ignored lines are discarded (legacy behavior; existing callers
#       unaffected).
#
# Architecture:
#   maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md
#     §3 (per-entry directory shape, 5 streams)
#
# Design constraints binding on this file (their source architecture docs
# were deleted at BD-210; the constraints themselves still hold):
#   - Layer 2 — the back-pointer is added by decompose.
#   - Signal-6 carve-out — these helpers live in scripts/lib/.
#   - The back-pointer is an HTML comment on line 1 ONLY.
#
# Implementation: bash dispatch + python3 for the markdown parsing
# (precedent: scripts/lib/tracker-mirror.sh). Python3 is a hard
# dependency of the pack already (validate-pack.py).
#
# Bash 3.2 + macOS BSD utility compatible.
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source sibling _lib.sh if not already loaded.
if ! type pe_die >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fi

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

per_entry_decompose() {
    local key="$1"
    local mono_path="$2"
    local stream_dir="$3"

    [[ -n "$key" ]] || pe_die "per_entry_decompose: stream key required"
    [[ -n "$mono_path" ]] || pe_die "per_entry_decompose: monolithic path required"
    [[ -n "$stream_dir" ]] || pe_die "per_entry_decompose: stream dir required"

    # Validate stream key.
    local entry_regex
    entry_regex=$(pe_entry_regex_for_stream "$key") || \
        pe_die "per_entry_decompose: unknown stream key: $key"

    [[ -f "$mono_path" ]] || pe_die "per_entry_decompose: monolithic input not found: $mono_path"
    [[ -d "$stream_dir" ]] || pe_die "per_entry_decompose: stream dir not found: $stream_dir"

    # Dispatch to the python helper for parsing + writing. The optional
    # PE_DECOMPOSE_DROPPED capture path passes through only when the
    # caller set it (empty = unset = legacy ignore semantics).
    PE_DECOMPOSE_KEY="$key" \
    PE_DECOMPOSE_MONO="$mono_path" \
    PE_DECOMPOSE_DIR="$stream_dir" \
    PE_DECOMPOSE_REGEX="$entry_regex" \
    PE_DECOMPOSE_DROPPED="${PE_DECOMPOSE_DROPPED:-}" \
        python3 - <<'PYEOF' || pe_die "per_entry_decompose: python parser failed"
import os
import re
import sys

try:
    key = os.environ["PE_DECOMPOSE_KEY"]
    mono_path = os.environ["PE_DECOMPOSE_MONO"]
    stream_dir = os.environ["PE_DECOMPOSE_DIR"]
    entry_regex = os.environ["PE_DECOMPOSE_REGEX"]
except KeyError as e:
    sys.stderr.write(f"per-entry decompose: missing env var {e.args[0]}\n")
    sys.exit(2)

# Optional dropped-content capture sink (empty = unset = legacy).
dropped_path = os.environ.get("PE_DECOMPOSE_DROPPED", "")

# ─── Read input ──────────────────────────────────────────────
with open(mono_path, "r", encoding="utf-8", newline="") as f:
    text = f.read()

# Normalize: ensure trailing newline so the last entry's tail is
# captured cleanly. (BD-203: decompose is the one-time monolith→tree
# CONVERSION verb; the per-entry tree + `_toc.md` is the SOLE source of
# truth after conversion — there is NO regenerated monolithic mirror.)
if not text.endswith("\n"):
    text += "\n"

# ─── Stream-specific entry-anchor patterns ───────────────────
#
# Per sidecar §3.1: the per-entry CONTENT is the byte-identical
# span from the entry anchor through the last narrative line of
# the entry (inclusive). The anchors:
#
#   pack-backlog                  **BD-NNN[suffix] — Title**
#                                  (BD-203: admits the suffix + a
#                                   parenthetical qualifier before the
#                                   em-dash)
#   pack-changelog                ## vN — <date>
#                                  (BD-203: the unit is one `vN.md` per
#                                   major release; the entry body is the
#                                   ENTIRE H2 block incl. nested `### vN.M`
#                                   / `### New/Updated` subsections)
#   project-backlog               **TD-NNN[suffix] — Title**
#   project-implementation-plan   ## Phase N — Title  (phase-N.md;
#                                  per Addendum #1 §6.4 BD-167 spec
#                                  decision: tasks-inline, no
#                                  per-task files)
#   project-changelog             ### YYYY-MM-DD — <suffix>
#                                  (the ` — <suffix>` is MANDATORY; the
#                                   id is the date + the ENTIRE suffix
#                                   slugified — see the stream branch
#                                   below)
#
# We anchor on the line that begins the entry; the entry continues
# until the next anchor line OR an `## ` H2 boundary that is NOT
# part of the entry (e.g., `## How to use this file`,
# `## Active — v11 Scope`, `## Resolved — v8 (March 2026)`,
# `## Deferred`).
#
# Every `id_extract` takes (line, lineno) — the monolith line number
# feeds the fail-loud guards' diagnostics.

# Set by the project-changelog branch only; drives the walk-loop
# bare-date fail-loud guard.
date_prefix_re = None

if key == "pack-backlog":
    # BD-211 — canonical backlog anchor: `**BD-NNN — <Title>**`. NO
    # letter suffix and NO pre-em-dash parenthetical qualifier (a
    # parenthetical, if present, is TITLE TEXT after the em-dash). The
    # captured ID is the `BD-\d+` group. The former suffix sub-entries
    # were folded into their base BD-167/BD-169 entries as in-body sections
    # and the BD-195 pre-em-dash parenthetical was normalized before any
    # re-decompose. See
    # maintenance-docs/v11-implementation/ARCHITECTURE-BD-211.md §3.2.
    anchor_re = re.compile(r"^\*\*(BD-\d+)\s+— ")
    id_extract = lambda line, lineno: anchor_re.match(line).group(1)
    # Section H2 boundaries that close an entry: any new `## ` heading.
    section_break_re = re.compile(r"^## ")
elif key == "pack-changelog":
    # BD-203 ENGINE CHANGE 2 — pack-changelog grouping-preservation: the
    # entry unit is one `vN.md` per major release, anchored on the
    # `## vN — <date>` H2. The body is the ENTIRE H2 block (any nested
    # `### vN.M` / `### New/Updated` subsections ride inside it,
    # preserved verbatim). This is the only granularity that preserves
    # all releases including v1–v7 (H2-only, no `### vN.M` child). See
    # ARCHITECTURE-BD-203-V3.md §2.3.
    anchor_re = re.compile(r"^## (v\d+)\b")
    id_extract = lambda line, lineno: re.match(r"^## (v\d+)\b", line).group(1)
    # Under per-release granularity the H2 IS the anchor; a nested
    # `### vN.M` does NOT close the entry (it is part of the H2 block).
    # An entry closes only at the next `## ` heading — which is always
    # another anchor here (every `## ` in the changelog is a `## vN`),
    # so section_break_re never fires on a non-anchor line. Kept for
    # parity with the other streams' close logic.
    section_break_re = re.compile(r"^## ")
elif key == "project-backlog":
    # BD-211 — canonical TD anchor: `**TD-NNN — <Title>**`, mirroring the
    # pack-backlog anchor (NO letter suffix, NO pre-em-dash parenthetical).
    # CROSS-SURFACE: serves the project stream; agrees with the already-
    # canonical project-template `_rules.md` (`^TD-\d+\.md$`).
    anchor_re = re.compile(r"^\*\*(TD-\d+)\s+— ")
    id_extract = lambda line, lineno: anchor_re.match(line).group(1)
    section_break_re = re.compile(r"^## ")
elif key == "project-implementation-plan":
    # phase-N.md per Addendum #1 §6.4 (tasks inline, no per-task files).
    anchor_re = re.compile(r"^## Phase (\d+) — ")
    id_extract = lambda line, lineno: "phase-" + re.match(r"^## Phase (\d+) — ", line).group(1)
    # Phase entries are bounded by the next `## Phase N+1 — ` OR a
    # different non-phase H2 (rare; treat any `## ` as boundary).
    section_break_re = re.compile(r"^## ")
elif key == "project-changelog":
    # Anchor: `### YYYY-MM-DD — <suffix>` — the ` — ` separator and a
    # non-empty suffix are MANDATORY (stream contract:
    # docs/project/changelog/_rules.md § Filename convention). The id
    # mirrors the ENTIRE heading suffix after the FIRST ` — `, slugified
    # (lowercase; runs of non-[a-z0-9] chars become `-`; edge dashes
    # trimmed) — a second ` — ` inside the suffix is not special-cased
    # (the em-dash slugifies to `-`). Filenames are unique by
    # construction; identical full headings are an authoring error
    # (duplicate-id guard in the walk loop). A `### YYYY-MM-DD`-prefixed
    # line that fails the full anchor shape is fail-loud (bare-date
    # guard in the walk loop), never silently glued in-span or dropped.
    anchor_re = re.compile(r"^### (\d{4}-\d{2}-\d{2}) — (.+)$")
    date_prefix_re = re.compile(r"^### \d{4}-\d{2}-\d{2}")
    def _slugify(s):
        return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
    def id_extract(line, lineno):
        m = anchor_re.match(line)
        slug = _slugify(m.group(2))
        if not slug:
            sys.stderr.write(
                f"per-entry decompose: monolith line {lineno}: "
                "bare-date/empty-slug heading; the stream contract "
                "requires a mandatory slug: " + line.rstrip("\n") + "\n")
            sys.exit(2)
        return m.group(1) + "-" + slug
    section_break_re = re.compile(r"^## ")
else:
    sys.stderr.write(f"per-entry decompose: unsupported stream key: {key}\n")
    sys.exit(2)

# ─── Walk the monolithic file ───────────────────────────────
#
# Algorithm (fence state is evaluated BEFORE any other line
# classification):
#   0. A line starting with ``` toggles fenced-code state; the toggle
#      line itself is routed by the PRE-toggle state's entry/ignore
#      disposition. While inside a fence NO line is an anchor, a
#      section break, or an H1 break.
#   1. Iterate lines (1-based line numbers), tracking the current
#      entry start (or None).
#   2. On anchor match: duplicate-id guard (fail-loud naming both
#      monolith lines, BEFORE any write); close prior entry (write to
#      disk); open new entry.
#   3. On a section break (`## ` non-anchor) OR an H1 break (`# `
#      non-anchor outside a fence, seen after the first anchor): close
#      prior entry; do not open a new one. The break line + following
#      non-anchor lines are ignore/capture-routed (appended verbatim to
#      the PE_DECOMPOSE_DROPPED capture when set; discarded when unset).
#   4. Pre-first-anchor preamble lines take the same ignore/capture
#      route.
#   5. EOF: close prior entry if open; flush any pending capture block.
#
# An entry's CONTENT is ALL lines from the anchor line through the
# line BEFORE the boundary (exclusive of the boundary line itself).
# Trailing blank lines and any `---` separator immediately AFTER the
# entry but BEFORE the next anchor are NOT part of the entry's
# byte-identical span — they are inter-entry connective tissue. (BD-203:
# for the PACK there is no regenerated monolithic mirror; the per-entry
# tree + `_toc.md` is the sole SSOT + readable form.)

lines = text.splitlines(keepends=True)

current_id = None
current_buf = []

# In pack-backlog the v8 H2 (`## Resolved — v8 (March 2026)`) introduces
# frozen-historical content that goes into `_v8-resolved-archive.md`,
# NOT per-entry files. The decompose helper does not write the v8
# archive (that is BD-167's BD-165 migrator responsibility per integration
# parent §9.7). For 19a our test fixtures avoid the v8 archive case;
# at production-time the migrator will pre-extract the v8 archive
# before invoking the decompose helper, leaving only the entries+preamble
# in the monolithic input.

def normalize_entry(buf):
    """Strip trailing blank lines + trailing '---' separator from an
    entry's captured span. The byte-identical content is the entry's
    body proper (per sidecar parent §3.1).
    """
    # Trim trailing blank lines.
    while buf and buf[-1].strip() == "":
        buf.pop()
    # Trim trailing `---` separator if present (these are inter-entry
    # connective tissue).
    if buf and buf[-1].rstrip() == "---":
        buf.pop()
        # And any trailing blank lines that preceded the separator.
        while buf and buf[-1].strip() == "":
            buf.pop()
    return buf

def write_entry(stream_dir, key, entry_id, body_lines):
    """Write one per-entry file with line-1 HTML-comment back-pointer
    + the entry body. Idempotent: byte-identical output for byte-
    identical input.
    """
    # Determine source/contract path forms (matches pe_backpointer_line).
    # Pack streams use leading slash + dir-suffix; project streams use
    # the project-relative path.
    suffix_map = {
        "pack-backlog": ("/backlog", "pack"),
        "pack-changelog": ("/changelog", "pack"),
        "project-backlog": ("docs/project/backlog", "project"),
        "project-implementation-plan": ("docs/project/implementation-plan", "project"),
        "project-changelog": ("docs/project/changelog", "project"),
    }
    suffix, side = suffix_map[key]
    if side == "pack":
        source_path = f"{suffix}/{entry_id}.md"
        contract_path = f"{suffix}/_rules.md"
    else:
        source_path = f"{suffix}/{entry_id}.md"
        contract_path = f"{suffix}/_rules.md"
    backpointer = f"<!-- per-entry source: {source_path}; contract: {contract_path} -->\n"

    out_path = os.path.join(stream_dir, f"{entry_id}.md")
    body = "".join(body_lines)
    # Ensure body ends with a single newline (the byte-identical span
    # extends to the entry's last narrative line; add one trailing \n
    # so the file is well-formed).
    if not body.endswith("\n"):
        body += "\n"
    content = backpointer + body

    # Atomic write via temp file in same dir.
    tmp_path = out_path + ".per-entry-tmp"
    with open(tmp_path, "w", encoding="utf-8", newline="") as f:
        f.write(content)
    os.replace(tmp_path, out_path)

written = 0
seen_ids = {}  # id -> monolith line number of its anchor (duplicate guard)
in_fence = False

# Dropped-content capture sink (PE_DECOMPOSE_DROPPED). Truncated at
# decompose start; each contiguous ignored block is written as one
# provenance delimiter line `<!-- v10 monolith lines A–B -->` followed
# by the block's lines verbatim.
capture = None
if dropped_path:
    capture = open(dropped_path, "w", encoding="utf-8", newline="")
drop_buf = []
drop_start = 0
drop_end = 0

def drop_line(line, lineno):
    """Route an ignored line to the capture sink (verbatim) when set."""
    global drop_start, drop_end
    if capture is None:
        return
    if not drop_buf:
        drop_start = lineno
    drop_buf.append(line)
    drop_end = lineno

def flush_dropped():
    """Write the pending contiguous ignored block (delimiter + lines)."""
    global drop_buf
    if capture is not None and drop_buf:
        capture.write(f"<!-- v10 monolith lines {drop_start}–{drop_end} -->\n")
        for dropped in drop_buf:
            capture.write(dropped)
    drop_buf = []

for lineno, line in enumerate(lines, start=1):
    # Fence state FIRST: inside a fence no line is an anchor, a section
    # break, or an H1 break. The toggle line itself is routed by the
    # PRE-toggle state's disposition (the opening fence line belongs to
    # whatever span it opens within).
    fence_toggle = line.startswith("```")
    if in_fence:
        is_anchor = False
        is_section_break = False
        is_h1_break = False
    else:
        is_anchor = bool(anchor_re.match(line))
        is_section_break = bool(section_break_re.match(line)) and not is_anchor
        # An H1 after the first anchor closes the current entry exactly
        # as a section break does (a pre-first-anchor H1 is preamble;
        # the close below is then a no-op and the line routes to the
        # same ignore/capture arm).
        is_h1_break = line.startswith("# ") and not is_anchor
        # Fail-loud bare-date guard (project-changelog only). Evaluated
        # independently of the strict anchor regex: a bare
        # `### YYYY-MM-DD` line matches neither the anchor nor the
        # section-break regex and would otherwise silently glue in-span
        # or fall to the ignore arm.
        if (date_prefix_re is not None and not is_anchor
                and date_prefix_re.match(line)):
            sys.stderr.write(
                f"per-entry decompose: monolith line {lineno}: "
                "bare-date/empty-slug heading; the stream contract "
                "requires a mandatory slug: " + line.rstrip("\n") + "\n")
            sys.exit(2)
    if fence_toggle:
        in_fence = not in_fence

    if is_anchor:
        new_id = id_extract(line, lineno)
        # Duplicate-id guard — fires BEFORE any write of either
        # colliding entry, so `written` counts files on disk and no
        # earlier file is silently overwritten.
        if new_id in seen_ids:
            sys.stderr.write(
                f"per-entry decompose: duplicate entry id '{new_id}' "
                f"(monolith lines {seen_ids[new_id]} and {lineno}): "
                "identical full headings; extend the newer heading\n")
            sys.exit(2)
        seen_ids[new_id] = lineno
        flush_dropped()
        # Close prior entry.
        if current_id is not None:
            body = normalize_entry(current_buf)
            if body:
                write_entry(stream_dir, key, current_id, body)
                written += 1
        # Open new entry.
        current_id = new_id
        current_buf = [line]
    elif is_section_break or is_h1_break:
        # Close prior entry (without opening a new one).
        if current_id is not None:
            body = normalize_entry(current_buf)
            if body:
                write_entry(stream_dir, key, current_id, body)
                written += 1
            current_id = None
            current_buf = []
        # The break line itself + any following non-anchor lines are
        # NOT entry content; ignore/capture until the next anchor.
        drop_line(line, lineno)
    elif current_id is not None:
        current_buf.append(line)
    else:
        # Pre-first-anchor preamble: ignore/capture. (BD-203: the
        # human-only orientation preamble lives in `_intro.md`; there
        # is no mirror to re-inject it into for the pack).
        drop_line(line, lineno)

# EOF: close any open entry + flush any pending capture block.
if current_id is not None:
    body = normalize_entry(current_buf)
    if body:
        write_entry(stream_dir, key, current_id, body)
        written += 1
flush_dropped()
if capture is not None:
    capture.close()

sys.stderr.write(f"per-entry decompose: wrote {written} entry file(s) to {stream_dir}\n")
PYEOF
}
