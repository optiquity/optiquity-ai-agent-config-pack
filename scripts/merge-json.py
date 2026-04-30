#!/usr/bin/env python3
"""
merge-json.py — three-way JSON key-merge per V10-MIGRATION-FIX-DESIGN.md
Part 3.7 (BD-059). Used by migrate-v9-to-v10.sh for K1 (`.claude/settings.json`)
and K4 (`.mcp.json.example`) when the four-case classifier returns
real-merge-required.

Algorithm:

- BASE  = v9.3 pack baseline
- OURS  = project file pre-migration
- THEIRS = v10 pack template

Recursive merge over the union of keys present in any of the three:

- Scalar leaves (str/int/float/bool/null):
    - base == ours      → take theirs (pack update accepted)
    - base != ours      → take ours   (project edit wins)
    - all three differ but ours == theirs → take ours (no real conflict)
    - all three differ AND ours != theirs → conflict; default to ours,
      emit reconciliation warning to stderr
- Object branches: recurse.
- List leaves: union with set-difference logic
    result = (THEIRS minus base-to-ours-removals) plus project-added items
    Conflicts (project removed AND pack added same item) emit warnings.
- Project-only keys (not in BASE/THEIRS): kept as project addendum.
- Pack-new keys (not in BASE/OURS): added.
- Project removed but pack didn't change: honor project removal.
- Pack removed but project edited: honor project edit; warn.
- Project removed AND pack edited: warn; honor project removal (default).

Usage:
    merge-json.py BASE OURS THEIRS [--output PATH]

If --output is not given, the merged JSON is written to stdout.
A trailing newline is emitted.

Exit codes:
    0  merged cleanly (no warnings)
    1  argument or parse error (no output written)
    2  merged with reconciliation warnings (output still written; warnings
       to stderr)
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def load_json(path: str | None) -> Any:
    """Return parsed JSON, or `_MISSING` if path is empty/missing."""
    if not path:
        return _MISSING
    p = Path(path)
    if not p.is_file():
        return _MISSING
    text = p.read_text()
    return json.loads(text) if text.strip() else _MISSING


_MISSING = object()  # sentinel for "input not provided / file absent"


def is_present(v: Any) -> bool:
    return v is not _MISSING


def is_dict(v: Any) -> bool:
    return is_present(v) and isinstance(v, dict)


def is_list(v: Any) -> bool:
    return is_present(v) and isinstance(v, list)


def merge_dict(base: Any, ours: Any, theirs: Any, path: str, warnings: list) -> dict:
    """Recursive object merge. Returns merged dict. Appends to warnings."""
    base_d = base if is_dict(base) else {}
    ours_d = ours if is_dict(ours) else {}
    theirs_d = theirs if is_dict(theirs) else {}

    all_keys: set[str] = set()
    all_keys |= set(base_d.keys())
    all_keys |= set(ours_d.keys())
    all_keys |= set(theirs_d.keys())

    merged: dict[str, Any] = {}

    # Preserve key order: theirs (pack v10 schema), then ours (project additions).
    ordered: list[str] = []
    seen: set[str] = set()
    for k in theirs_d.keys():
        if k in all_keys and k not in seen:
            ordered.append(k); seen.add(k)
    for k in ours_d.keys():
        if k in all_keys and k not in seen:
            ordered.append(k); seen.add(k)
    for k in base_d.keys():
        if k in all_keys and k not in seen:
            ordered.append(k); seen.add(k)

    for key in ordered:
        sub_path = f"{path}.{key}" if path else key

        in_base = key in base_d
        in_ours = key in ours_d
        in_theirs = key in theirs_d

        b = base_d.get(key, _MISSING)
        o = ours_d.get(key, _MISSING)
        t = theirs_d.get(key, _MISSING)

        # All three present
        if in_base and in_ours and in_theirs:
            sub = merge_value(b, o, t, sub_path, warnings)
            if sub is not _MISSING:
                merged[key] = sub
        # Project removed; pack still ships
        elif in_base and not in_ours and in_theirs:
            if b == t:
                # Pack didn't change; honor project removal silently.
                pass
            else:
                warnings.append(
                    f"{sub_path}: project removed; pack edited "
                    f"(kept project removal — reconcile manually)"
                )
        # Pack removed; project still has it
        elif in_base and in_ours and not in_theirs:
            if b == o:
                # Project didn't edit; honor pack removal.
                pass
            else:
                warnings.append(
                    f"{sub_path}: pack removed; project edited "
                    f"(kept project edit — reconcile manually)"
                )
                merged[key] = o
        # Both removed
        elif in_base and not in_ours and not in_theirs:
            pass
        # Both added (not in base)
        elif not in_base and in_ours and in_theirs:
            if o == t:
                merged[key] = t
            else:
                warnings.append(
                    f"{sub_path}: both added with different values "
                    f"(kept project value — reconcile manually)"
                )
                merged[key] = o
        # Project-only addition
        elif not in_base and in_ours and not in_theirs:
            merged[key] = o
        # Pack-only addition (new in v10)
        elif not in_base and not in_ours and in_theirs:
            merged[key] = t
        # Impossible combinations are silently ignored

    return merged


def merge_list(base: Any, ours: Any, theirs: Any, path: str, warnings: list) -> list:
    """Three-way list merge using set-difference logic.

    Lists are treated as multisets of comparable items (typically strings).
    The result preserves item order from THEIRS, appends project-only
    additions afterward.
    """
    base_l = base if is_list(base) else []
    ours_l = ours if is_list(ours) else []
    theirs_l = theirs if is_list(theirs) else []

    # Use string serialization for membership comparison so dicts/lists are
    # equality-checkable without TypeError.
    def key(item: Any) -> str:
        if isinstance(item, (str, int, float, bool)) or item is None:
            return repr(item)
        return json.dumps(item, sort_keys=True)

    base_set = {key(x): x for x in base_l}
    ours_set = {key(x): x for x in ours_l}
    theirs_set = {key(x): x for x in theirs_l}

    removed_by_project = set(base_set) - set(ours_set)
    added_by_project = set(ours_set) - set(base_set)
    removed_by_pack = set(base_set) - set(theirs_set)
    added_by_pack = set(theirs_set) - set(base_set)

    # Conflict: project removed AND pack added the same item (key).
    overlap_remove_add = removed_by_project & added_by_pack
    for k in overlap_remove_add:
        warnings.append(
            f"{path}[]: project removed {ours_set.get(k, base_set[k])!r}; "
            f"pack added matching value (kept pack value — reconcile manually)"
        )
    overlap_add_remove = added_by_project & removed_by_pack
    for k in overlap_add_remove:
        warnings.append(
            f"{path}[]: pack removed {ours_set[k]!r}; "
            f"project added matching value (kept project value — reconcile manually)"
        )

    # Build result. Order: THEIRS items minus project-removed, plus project-added.
    result: list[Any] = []
    seen_keys: set[str] = set()
    for item in theirs_l:
        k = key(item)
        if k in removed_by_project and k not in added_by_pack:
            continue
        if k not in seen_keys:
            result.append(item)
            seen_keys.add(k)
    for item in ours_l:
        k = key(item)
        if k in added_by_project and k not in seen_keys:
            result.append(item)
            seen_keys.add(k)

    return result


def merge_value(base: Any, ours: Any, theirs: Any, path: str, warnings: list) -> Any:
    """Type-dispatched merge: dict / list / scalar."""
    # Type mismatch → conflict; prefer theirs (pack schema), warn.
    types_present = []
    for v in (base, ours, theirs):
        if is_present(v):
            types_present.append(type(v).__name__)
    if len(set(types_present)) > 1:
        warnings.append(
            f"{path}: type mismatch across base/ours/theirs ({types_present}); "
            f"kept theirs (pack v10 schema) — reconcile manually"
        )
        return theirs if is_present(theirs) else (ours if is_present(ours) else base)

    if is_dict(theirs) or is_dict(ours) or is_dict(base):
        return merge_dict(base, ours, theirs, path, warnings)
    if is_list(theirs) or is_list(ours) or is_list(base):
        return merge_list(base, ours, theirs, path, warnings)

    # Scalar: pure four-case logic.
    if base == ours and base == theirs:
        return theirs
    if base == ours and base != theirs:
        return theirs
    if base != ours and base == theirs:
        return ours
    # All three differ.
    if ours == theirs:
        return ours
    warnings.append(
        f"{path}: scalar conflict — base={base!r}, ours={ours!r}, theirs={theirs!r} "
        f"(kept ours — reconcile manually)"
    )
    return ours


def main() -> int:
    ap = argparse.ArgumentParser(description="Three-way JSON key-merge.")
    ap.add_argument("base", help="v9.3 pack baseline file (or empty string)")
    ap.add_argument("ours", help="project file pre-migration")
    ap.add_argument("theirs", help="v10 pack template file")
    ap.add_argument("--output", help="write merged JSON to PATH (default: stdout)")
    args = ap.parse_args()

    try:
        base = load_json(args.base) if args.base else _MISSING
        ours = load_json(args.ours)
        theirs = load_json(args.theirs)
    except json.JSONDecodeError as e:
        print(f"error: JSON parse failed: {e}", file=sys.stderr)
        return 1

    if not is_present(ours):
        print("error: ours file is missing or empty", file=sys.stderr)
        return 1
    if not is_present(theirs):
        print("error: theirs file is missing or empty", file=sys.stderr)
        return 1

    warnings: list[str] = []
    merged = merge_value(base, ours, theirs, "", warnings)

    output = json.dumps(merged, indent=2) + "\n"
    if args.output:
        Path(args.output).write_text(output)
    else:
        sys.stdout.write(output)

    for w in warnings:
        print(f"warning: {w}", file=sys.stderr)

    return 2 if warnings else 0


if __name__ == "__main__":
    sys.exit(main())
