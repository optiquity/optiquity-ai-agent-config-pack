#!/usr/bin/env python3
# pack-internal: true  (invoked only by migrators; not a user-facing verb)
"""
merge-trinity.py — classifier-wrapped merge of v9.3 pack trinity templates
(CLAUDE.md, AGENTS.md, GEMINI.md) with the corresponding project trinity
files. Per V10-MIGRATION-FIX-DESIGN.md Part 3.2 (BD-059), trinity prose is
high-stakes: the script does NOT auto-merge intermixed prose. Instead it
classifies each file via the four-case three-way classifier, and on
real-merge-required it performs a structural splice that preserves two
project-owned regions (Active-skills line, `### Custom agents` sub-section)
while taking the rest of the v10 template. This script has NO live caller
at HEAD: the migrate-v9-to-v10.sh migrator that invoked it was sunset in
v11 (BD-121), and the v11 customization-preserve path
(scripts/lib/customization-preserve.sh) routes trinity `.md` files through
its text strategy rather than this structural splice. A migrator that does
invoke it is responsible for writing the project's pre-migration file as a
`<file>.<sidecar-suffix>` sidecar (the live v10→v11 migrator emits the
`v10-customized` suffix) so the developer can reconcile per Procedure 5-C
from INSTALL-PROCEDURES.md.

Per V10-DESIGN §6.6: the three files are processed atomically. Either all
three merged outputs are written, or none are. A B6 pre-check validates
that each v9 project file has exactly one `**Active skills:**` line before
any output is written.

Usage:
    merge-trinity.py [--base-dir BASE_DIR] <v10-template-dir> <v9-project-dir> <output-dir>

Arguments:
    --base-dir BASE_DIR  Directory containing v9.3 baseline copies of
                         CLAUDE.md / AGENTS.md / GEMINI.md. Required for
                         classifier dispatch. Files inside may be missing
                         (the classifier's auxiliary cases handle absence).
                         If omitted, the script falls back to legacy
                         splice-only behaviour for backward compatibility.
    <v10-template-dir>   Directory containing v10 pack trinity templates.
    <v9-project-dir>     Project directory containing the project's
                         current trinity files.
    <output-dir>         Directory the merged outputs are written to.
                         Created if it does not exist.

Stdout (one line per trinity file, tab-separated):
    <file>\\t<classifier-token>\\t<notes>

The classifier-token is one of: unchanged-pack, pack-update-applied,
merged-with-customization, real-merge-required, new-file-in-pack,
project-only-file, project-shadows-new-pack, removed-by-pack-clean,
removed-by-pack-customized, removed-everywhere, project-deleted-pack-kept.

Exit codes:
    0 — success (merged outputs written; dispositions on stdout)
    1 — argument error or pre-check failure (no outputs written)
"""

import re
import sys
from pathlib import Path

ACTIVE_SKILLS_RE = re.compile(r"^\*\*Active skills:\*\*\s*")
CUSTOM_AGENTS_HEADING = "### Custom agents"

TRINITY_FILES = ("CLAUDE.md", "AGENTS.md", "GEMINI.md")


# ── Three-way classifier (Python mirror of scripts/lib/three-way.sh) ──

def classify(base_path, ours_path, theirs_path):
    """Return one of the 12 classifier tokens (str)."""
    has_base = bool(base_path) and Path(base_path).is_file()
    has_ours = bool(ours_path) and Path(ours_path).is_file()
    has_theirs = bool(theirs_path) and Path(theirs_path).is_file()

    def read_bytes(p):
        return Path(p).read_bytes()

    if has_base and has_ours and has_theirs:
        b = read_bytes(base_path)
        o = read_bytes(ours_path)
        t = read_bytes(theirs_path)
        if b == o and b == t:
            return "unchanged-pack"
        if b == o and b != t:
            return "pack-update-applied"
        if b != o and b == t:
            return "merged-with-customization"
        return "real-merge-required"

    if not has_base and not has_ours and has_theirs:
        return "new-file-in-pack"
    if not has_base and has_ours and not has_theirs:
        return "project-only-file"
    if not has_base and has_ours and has_theirs:
        return "project-shadows-new-pack"
    if has_base and not has_theirs:
        if not has_ours:
            return "removed-everywhere"
        if read_bytes(base_path) == read_bytes(ours_path):
            return "removed-by-pack-clean"
        return "removed-by-pack-customized"
    if has_base and not has_ours and has_theirs:
        return "project-deleted-pack-kept"
    return "no-inputs"


# ── Splice helpers ──

def find_active_skills_block(lines):
    """Return (start_idx, end_idx) of the Active skills block, or None.

    Multi-line placeholder blocks (`**Active skills:** [...]` spanning
    several lines) are detected by scanning forward until a line containing
    `]` is found. Single-line populated content has end_idx == start_idx + 1.
    """
    matches = [i for i, ln in enumerate(lines) if ACTIVE_SKILLS_RE.match(ln)]
    if len(matches) != 1:
        return None
    start = matches[0]
    start_line = lines[start]
    prefix_end = ACTIVE_SKILLS_RE.match(start_line).end()
    content = start_line[prefix_end:].lstrip()
    if content.startswith("["):
        end = start + 1
        while end < len(lines):
            if "]" in lines[end]:
                end += 1
                break
            if not lines[end].strip():
                break
            end += 1
        if "]" in start_line[prefix_end:]:
            end = start + 1
    else:
        end = start + 1
    return (start, end)


def is_active_skills_placeholder(line):
    """True if the line's content after `**Active skills:**` starts with `[`."""
    m = ACTIVE_SKILLS_RE.match(line)
    if not m:
        return False
    return line[m.end():].lstrip().startswith("[")


def find_custom_agents_region(lines):
    """Return (start_idx, end_idx) of the `### Custom agents` region, or None.

    Region extends from the heading to the next `## ` H2 (or EOF).
    """
    start = None
    for i, ln in enumerate(lines):
        if ln.rstrip("\n") == CUSTOM_AGENTS_HEADING:
            start = i
            break
    if start is None:
        return None
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if lines[j].startswith("## "):
            end = j
            break
    return (start, end)


def splice_with_project_regions(v10_lines, v9_lines):
    """Splice v10 template with project-owned regions from v9 file.

    Preserves: (1) Active-skills line content if populated (not placeholder),
    (2) `### Custom agents` sub-section content if present in v9.

    Caller must have run the B6 pre-check on v9_lines (exactly one
    Active-skills line).
    """
    v10_as = find_active_skills_block(v10_lines)
    if v10_as is None:
        raise ValueError(
            "v10 template does not contain exactly one `**Active skills:**` line"
        )
    v10_ca = find_custom_agents_region(v10_lines)
    if v10_ca is None:
        raise ValueError(
            "v10 template does not contain a `### Custom agents` sub-section"
        )

    v9_as = find_active_skills_block(v9_lines)
    assert v9_as is not None, "pre-check should have caught this"
    v9_as_line = v9_lines[v9_as[0]]
    if is_active_skills_placeholder(v9_as_line):
        as_replacement = v10_lines[v10_as[0]:v10_as[1]]
    else:
        as_replacement = v9_lines[v9_as[0]:v9_as[1]]

    v9_ca = find_custom_agents_region(v9_lines)
    if v9_ca is None:
        ca_replacement = v10_lines[v10_ca[0]:v10_ca[1]]
    else:
        ca_replacement = v9_lines[v9_ca[0]:v9_ca[1]]

    as_start, as_end = v10_as
    ca_start, ca_end = v10_ca
    if as_end > ca_start:
        raise ValueError(
            "v10 template has Active-skills block after `### Custom agents` — "
            "unexpected ordering; cannot merge safely"
        )

    return (
        v10_lines[:as_start]
        + as_replacement
        + v10_lines[as_end:ca_start]
        + ca_replacement
        + v10_lines[ca_end:]
    )


def precheck_active_skills(v9_lines, filename):
    """Return None if pre-check passes, or a diagnostic string on failure."""
    matches = [i for i, ln in enumerate(v9_lines) if ACTIVE_SKILLS_RE.match(ln)]
    count = len(matches)
    if count == 1:
        return None
    if count == 0:
        return (
            f"{filename}: no `**Active skills:**` line found "
            f"(expected exactly one — pattern `^\\*\\*Active skills:\\*\\*`)"
        )
    return (
        f"{filename}: found {count} `**Active skills:**` lines at line(s) "
        f"{', '.join(str(i + 1) for i in matches)} (expected exactly one)"
    )


# ── Main ──

def main():
    argv = sys.argv[1:]
    base_dir = None
    if argv and argv[0] == "--base-dir":
        if len(argv) < 2:
            print("error: --base-dir requires a directory argument", file=sys.stderr)
            return 1
        base_dir = Path(argv[1])
        argv = argv[2:]

    if len(argv) != 3:
        print(
            "usage: merge-trinity.py [--base-dir BASE_DIR] "
            "<v10-template-dir> <v9-project-dir> <output-dir>",
            file=sys.stderr,
        )
        return 1

    v10_dir = Path(argv[0])
    v9_dir = Path(argv[1])
    out_dir = Path(argv[2])

    for d, label in ((v10_dir, "v10-template-dir"), (v9_dir, "v9-project-dir")):
        if not d.is_dir():
            print(f"error: {label} not found: {d}", file=sys.stderr)
            return 1

    # Read all six files upfront (base optional per file).
    v10_files = {}
    v9_files = {}
    base_paths = {}
    for name in TRINITY_FILES:
        v10_path = v10_dir / name
        v9_path = v9_dir / name
        if not v10_path.is_file():
            print(f"error: missing v10 template file: {v10_path}", file=sys.stderr)
            return 1
        if not v9_path.is_file():
            print(f"error: missing v9 project file: {v9_path}", file=sys.stderr)
            return 1
        v10_files[name] = v10_path.read_text().splitlines(keepends=True)
        v9_files[name] = v9_path.read_text().splitlines(keepends=True)
        base_paths[name] = (base_dir / name) if base_dir else None

    # B6 pre-check: every v9 file must have exactly one Active-skills line.
    failures = []
    for name in TRINITY_FILES:
        diagnostic = precheck_active_skills(v9_files[name], str(v9_dir / name))
        if diagnostic:
            failures.append(diagnostic)
    if failures:
        print(
            "error: Active-skills pre-check failed (no output written):",
            file=sys.stderr,
        )
        for f in failures:
            print(f"  {f}", file=sys.stderr)
        return 1

    # Classify each file. Compute merged outputs in memory before any write.
    merged = {}
    classifications = {}
    for name in TRINITY_FILES:
        base = base_paths[name]
        if base and not base.is_file():
            base = None  # baseline absent — auxiliary case
        v10 = v10_dir / name
        v9 = v9_dir / name

        token = classify(str(base) if base else "", str(v9), str(v10))
        classifications[name] = token

        # Decide what content to write to OUTPUT_DIR per disposition.
        if token in ("unchanged-pack", "pack-update-applied", "new-file-in-pack"):
            # Take pack v10 verbatim.
            merged[name] = "".join(v10_files[name])
        elif token == "merged-with-customization":
            # Pack didn't change v9.3 → v10. Keep the project file as-is.
            merged[name] = "".join(v9_files[name])
        elif token in ("real-merge-required", "project-shadows-new-pack"):
            # Splice: v10 template + project's Active-skills line +
            # project's Custom-agents sub-section. Caller writes a
            # .v9-customized sidecar of the full v9 file separately.
            try:
                spliced = splice_with_project_regions(
                    v10_files[name], v9_files[name]
                )
            except ValueError as e:
                print(f"error: splice failed for {name}: {e}", file=sys.stderr)
                return 1
            merged[name] = "".join(spliced)
        else:
            # Auxiliary cases unlikely for trinity (project-only,
            # removed-everywhere, etc.). Default safe action: take v10.
            merged[name] = "".join(v10_files[name])

    # All merges succeeded — write outputs atomically (file-by-file but all
    # decisions already made).
    out_dir.mkdir(parents=True, exist_ok=True)
    for name in TRINITY_FILES:
        (out_dir / name).write_text(merged[name])

    # Print per-file dispositions on stdout for the caller.
    for name in TRINITY_FILES:
        token = classifications[name]
        notes = "-"
        if token in ("real-merge-required", "project-shadows-new-pack"):
            notes = "spliced project Active-skills + Custom-agents into v10 template"
        print(f"{name}\t{token}\t{notes}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
