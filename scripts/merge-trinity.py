#!/usr/bin/env python3
"""
merge-trinity.py — merge v10 pack trinity templates (CLAUDE.md, AGENTS.md,
GEMINI.md) with the corresponding v9.3 project trinity files, preserving
two project-owned regions per file:

  1. `**Active skills:**` line content (if populated, not the pack placeholder).
  2. `### Custom agents` sub-section (if present in the v9 project file).

Everything else in each merged output comes from that file's own v10
template — structure, level of detail, and wording differ per file and
those differences are preserved per the pack's trinity convention.

Per V10-DESIGN §6.6: the three files are processed atomically. Either
all three merged outputs are written, or none are. A B6 pre-check
validates that each v9 project file has exactly one `**Active skills:**`
line before any output is written.

Usage:
    merge-trinity.py <v10-template-dir> <v9-project-dir> <output-dir>

Both template and project directories must contain CLAUDE.md, AGENTS.md,
and GEMINI.md. The output directory will be created if it does not exist.
"""

import re
import sys
from pathlib import Path

ACTIVE_SKILLS_RE = re.compile(r"^\*\*Active skills:\*\*\s*")
CUSTOM_AGENTS_HEADING = "### Custom agents"

TRINITY_FILES = ("CLAUDE.md", "AGENTS.md", "GEMINI.md")


def find_active_skills_block(lines: list[str]) -> tuple[int, int] | None:
    """Return (start_idx, end_idx exclusive) of the Active skills block.

    Multi-line placeholder blocks (`**Active skills:** [...]` spanning
    several lines) are detected by scanning forward until a line
    containing `]` is found. Single-line populated content has an
    end_idx of start_idx + 1.

    Returns None if the count of Active-skills lines is not exactly 1.
    """
    matches = [i for i, ln in enumerate(lines) if ACTIVE_SKILLS_RE.match(ln)]
    if len(matches) != 1:
        return None
    start = matches[0]
    start_line = lines[start]
    prefix_end = ACTIVE_SKILLS_RE.match(start_line).end()
    content = start_line[prefix_end:].lstrip()
    if content.startswith("["):
        # Multi-line placeholder — scan forward to the closing `]`.
        end = start + 1
        while end < len(lines):
            if "]" in lines[end]:
                end += 1
                break
            if not lines[end].strip():
                # Safety: blank line terminates; shouldn't normally hit.
                break
            end += 1
        # Edge case: placeholder fits on the start line (`[something]`).
        if "]" in start_line[prefix_end:]:
            end = start + 1
    else:
        # Single-line populated value.
        end = start + 1
    return (start, end)


def is_active_skills_placeholder(line: str) -> bool:
    """True if the line's content after `**Active skills:**` starts with `[`."""
    m = ACTIVE_SKILLS_RE.match(line)
    if not m:
        return False
    return line[m.end():].lstrip().startswith("[")


def find_custom_agents_region(lines: list[str]) -> tuple[int, int] | None:
    """Return (start_idx, end_idx exclusive) of the `### Custom agents`
    region. Region extends from the heading to the next `## ` H2 (or EOF).

    Returns None if no `### Custom agents` heading is present.
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


def merge_one_file(v10_lines: list[str], v9_lines: list[str]) -> list[str]:
    """Splice two regions from v9 project file into v10 template lines.

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

    # Active-skills replacement: if v9 has populated content, use it; else
    # keep v10's block. (v9_as guaranteed non-None by caller's pre-check.)
    v9_as = find_active_skills_block(v9_lines)
    assert v9_as is not None, "pre-check should have caught this"
    v9_as_line = v9_lines[v9_as[0]]
    if is_active_skills_placeholder(v9_as_line):
        as_replacement = v10_lines[v10_as[0]:v10_as[1]]
    else:
        as_replacement = v9_lines[v9_as[0]:v9_as[1]]

    # Custom-agents replacement: if v9 has the sub-section, use it; else
    # keep v10's sub-section.
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


def precheck_active_skills(v9_lines: list[str], filename: str) -> str | None:
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


def main() -> int:
    argv = sys.argv[1:]
    if len(argv) != 3:
        print(
            "usage: merge-trinity.py <v10-template-dir> <v9-project-dir> <output-dir>",
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

    # Read all six files upfront.
    v10_files: dict[str, list[str]] = {}
    v9_files: dict[str, list[str]] = {}
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

    # Compute all three merged outputs before writing any.
    merged: dict[str, str] = {}
    for name in TRINITY_FILES:
        try:
            merged_lines = merge_one_file(v10_files[name], v9_files[name])
        except ValueError as e:
            print(f"error: merging {name}: {e}", file=sys.stderr)
            return 1
        merged[name] = "".join(merged_lines)

    # Write all three atomically (from caller's perspective; Python writes
    # file-by-file, but all merges have already succeeded above).
    out_dir.mkdir(parents=True, exist_ok=True)
    for name in TRINITY_FILES:
        (out_dir / name).write_text(merged[name])
    return 0


if __name__ == "__main__":
    sys.exit(main())
