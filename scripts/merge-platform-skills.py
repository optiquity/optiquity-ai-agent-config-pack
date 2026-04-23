#!/usr/bin/env python3
"""
merge-platform-skills.py — merge a v10 pack PLATFORM-SKILLS.md template
with a v9.3 (or later) project PLATFORM-SKILLS.md, preserving the
project-owned `## Custom agents` and `## Custom skills` sections.

Per V10-DESIGN §6.6:

- The project-owned region begins at the first `## Custom agents` or
  `## Custom skills` heading, whichever comes first, and extends to EOF.
- Everything above is pack-owned.
- On v9.3 project files (no custom headings), the v10 pack template is
  used verbatim — the pack's placeholder custom sections carry through.

Usage:
    merge-platform-skills.py <v10-template> <v9-project-file> [<output-file>]

If <output-file> is omitted, the merged output is written to stdout.
"""

import re
import sys
from pathlib import Path

CUSTOM_HEADING_RE = re.compile(r"^## Custom (agents|skills)\s*$")


def find_first_custom_heading(lines: list[str]) -> int | None:
    """Return index of first `## Custom agents` / `## Custom skills` line, or None."""
    for i, line in enumerate(lines):
        if CUSTOM_HEADING_RE.match(line.rstrip("\n")):
            return i
    return None


def merge(v10_template: str, v9_project: str) -> str:
    v10_lines = v10_template.splitlines(keepends=True)
    v9_lines = v9_project.splitlines(keepends=True)

    v10_custom_idx = find_first_custom_heading(v10_lines)
    if v10_custom_idx is None:
        raise ValueError(
            "v10 template does not contain a `## Custom agents` or "
            "`## Custom skills` heading — cannot identify pack region boundary"
        )

    v9_custom_idx = find_first_custom_heading(v9_lines)
    if v9_custom_idx is None:
        # v9.3 has no custom sections — use v10 template verbatim.
        return "".join(v10_lines)

    pack_region = v10_lines[:v10_custom_idx]
    project_region = v9_lines[v9_custom_idx:]
    return "".join(pack_region) + "".join(project_region)


def main() -> int:
    argv = sys.argv[1:]
    if len(argv) < 2 or len(argv) > 3:
        print(
            "usage: merge-platform-skills.py <v10-template> <v9-project-file> "
            "[<output-file>]",
            file=sys.stderr,
        )
        return 1

    v10_path = Path(argv[0])
    v9_path = Path(argv[1])
    out_path = Path(argv[2]) if len(argv) == 3 else None

    if not v10_path.is_file():
        print(f"error: v10 template not found: {v10_path}", file=sys.stderr)
        return 1
    if not v9_path.is_file():
        print(f"error: v9 project file not found: {v9_path}", file=sys.stderr)
        return 1

    try:
        merged = merge(v10_path.read_text(), v9_path.read_text())
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    if out_path:
        out_path.write_text(merged)
    else:
        sys.stdout.write(merged)
    return 0


if __name__ == "__main__":
    sys.exit(main())
