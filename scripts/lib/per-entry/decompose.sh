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
# Architecture:
#   maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md
#     §3 (per-entry directory shape, 5 streams)
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md
#     §4.2 (Layer 2 — back-pointer add by decompose)
#     §13.3 (signal-6 carve-out — helpers in scripts/lib/)
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md
#     §2 (back-pointer is HTML-comment line-1 ONLY)
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

    # Dispatch to the python helper for parsing + writing.
    PE_DECOMPOSE_KEY="$key" \
    PE_DECOMPOSE_MONO="$mono_path" \
    PE_DECOMPOSE_DIR="$stream_dir" \
    PE_DECOMPOSE_REGEX="$entry_regex" \
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

# ─── Read input ──────────────────────────────────────────────
with open(mono_path, "r", encoding="utf-8", newline="") as f:
    text = f.read()

# Normalize: ensure trailing newline so the last entry's tail is
# captured cleanly. Round-trip preserves trailing-newline behavior
# because mirror generator emits the same shape.
if not text.endswith("\n"):
    text += "\n"

# ─── Stream-specific entry-anchor patterns ───────────────────
#
# Per sidecar §3.1: the per-entry CONTENT is the byte-identical
# span from the entry anchor through the last narrative line of
# the entry (inclusive). The anchors:
#
#   pack-backlog                  **BD-NNN — Title**
#   pack-changelog                ## vN — <date>  AND ### vN.M ...
#                                  (the unit is the H3 vN.M block;
#                                  H2 vN is grouping handled by
#                                  mirror generator at emit time)
#   project-backlog               **TD-NNN — Title**
#   project-implementation-plan   ## Phase N — Title  (phase-N.md;
#                                  per Addendum #1 §6.4 BD-167 spec
#                                  decision: tasks-inline, no
#                                  per-task files)
#   project-changelog             ### YYYY-MM-DD — Phase N — Title
#                                 OR ### YYYY-MM-DD — <slug>
#
# We anchor on the line that begins the entry; the entry continues
# until the next anchor line OR an `## ` H2 boundary that is NOT
# part of the entry (e.g., `## How to use this file`,
# `## Active — v11 Scope`, `## Resolved — v8 (March 2026)`,
# `## Deferred`).

if key == "pack-backlog":
    anchor_re = re.compile(r"^\*\*(BD-\d+) — ")
    id_extract = lambda line: re.match(r"^\*\*(BD-\d+) — ", line).group(1)
    # Section H2 boundaries that close an entry: any new `## ` heading.
    section_break_re = re.compile(r"^## ")
elif key == "pack-changelog":
    # Each H3 `### vN.M` is one entry; the file is sliced at H3 boundaries.
    # The H2 `## vN — <date>` is regrouped by the mirror generator.
    # Suffix shape harmonized with _lib.sh:77 + toc-regenerate.sh:85 — the
    # canonical pack-changelog convention per sidecar §3.2 line 302 is
    # `v10.0-post-release` (lowercase, leading-hyphen, [a-z0-9-]).
    anchor_re = re.compile(r"^### (v\d+\.\d+(?:-[a-z0-9-]+)?)\b")
    id_extract = lambda line: re.match(r"^### (v\d+\.\d+(?:-[a-z0-9-]+)?)\b", line).group(1)
    # The H2 `## vN — <date>` line ends an entry only by introducing
    # the next H2; the next entry-anchor (next `### vN.M`) ends it
    # within the same H2. Either signals close.
    section_break_re = re.compile(r"^## ")
elif key == "project-backlog":
    anchor_re = re.compile(r"^\*\*(TD-\d+) — ")
    id_extract = lambda line: re.match(r"^\*\*(TD-\d+) — ", line).group(1)
    section_break_re = re.compile(r"^## ")
elif key == "project-implementation-plan":
    # phase-N.md per Addendum #1 §6.4 (tasks inline, no per-task files).
    anchor_re = re.compile(r"^## Phase (\d+) — ")
    id_extract = lambda line: "phase-" + re.match(r"^## Phase (\d+) — ", line).group(1)
    # Phase entries are bounded by the next `## Phase N+1 — ` OR a
    # different non-phase H2 (rare; treat any `## ` as boundary).
    section_break_re = re.compile(r"^## ")
elif key == "project-changelog":
    anchor_re = re.compile(r"^### (\d{4}-\d{2}-\d{2})(?: — Phase (\d+))?(?: — (.+?))?$")
    def id_extract(line):
        m = anchor_re.match(line)
        date = m.group(1)
        phase = m.group(2)
        slug = m.group(3) or ""
        if phase:
            return f"{date}-phase-{phase}"
        # Slug-form: best-effort slugification — lowercase, spaces→dashes,
        # strip non-[a-z0-9-] chars.
        s = re.sub(r"[^a-z0-9-]+", "-", slug.lower()).strip("-")
        if not s:
            return date
        return f"{date}-{s}"
    section_break_re = re.compile(r"^## ")
else:
    sys.stderr.write(f"per-entry decompose: unsupported stream key: {key}\n")
    sys.exit(2)

# ─── Walk the monolithic file ───────────────────────────────
#
# Algorithm:
#   1. Iterate lines, tracking the current entry start (or None).
#   2. On anchor match: close prior entry (write to disk); open new entry.
#   3. On section-break that is NOT an anchor: close prior entry; do
#      not open a new one (lines until next anchor are ignored — they
#      belong to the mirror preamble or trailing _v8-resolved-archive
#      block, which the mirror generator re-injects from supporting
#      files).
#   4. EOF: close prior entry if open.
#
# An entry's CONTENT is ALL lines from the anchor line through the
# line BEFORE the boundary (exclusive of the boundary line itself).
# Trailing blank lines and any `---` separator immediately AFTER the
# entry but BEFORE the next anchor are NOT part of the entry's
# byte-identical span — they are inter-entry connective tissue
# re-emitted by the mirror generator.

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
for line in lines:
    is_anchor = bool(anchor_re.match(line))
    is_section_break = bool(section_break_re.match(line)) and not is_anchor

    if is_anchor:
        # Close prior entry.
        if current_id is not None:
            body = normalize_entry(current_buf)
            if body:
                write_entry(stream_dir, key, current_id, body)
                written += 1
        # Open new entry.
        current_id = id_extract(line)
        current_buf = [line]
    elif is_section_break:
        # Close prior entry (without opening a new one).
        if current_id is not None:
            body = normalize_entry(current_buf)
            if body:
                write_entry(stream_dir, key, current_id, body)
                written += 1
            current_id = None
            current_buf = []
        # The section-break line itself + any following non-anchor
        # lines are NOT entry content; ignore until the next anchor.
    elif current_id is not None:
        current_buf.append(line)
    # else: pre-first-anchor preamble; ignore (handled by mirror
    # generator from `_intro.md`).

# EOF: close any open entry.
if current_id is not None:
    body = normalize_entry(current_buf)
    if body:
        write_entry(stream_dir, key, current_id, body)
        written += 1

sys.stderr.write(f"per-entry decompose: wrote {written} entry file(s) to {stream_dir}\n")
PYEOF
}
