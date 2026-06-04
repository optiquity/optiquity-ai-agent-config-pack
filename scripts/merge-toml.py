#!/usr/bin/env python3
# pack-internal: true  (invoked only by migrators; not a user-facing verb)
"""
merge-toml.py — three-way TOML key-merge per V10-MIGRATION-FIX-DESIGN.md
Part 3.7 (BD-059). Invoked by scripts/lib/customization-preserve.sh
(structured-config dispatch) for the TOML allowlist (e.g.
`.codex/config.toml`, `.codex/requirements.toml`) when the four-case
classifier returns real-merge-required.

Algorithm mirrors merge-json.py — recursive merge over the union of keys
in BASE, OURS, THEIRS, with set-difference logic for arrays — applied at
the TOML table level. The OT case (project intentionally removed
[model_providers.ollama] / [model_providers.lmstudio]) is the canonical
test: section absent in OURS, present in BASE, present in THEIRS;
set-difference correctly drops the section unless pack edited it (which
would surface as a reconciliation warning).

Requires Python 3.11+ for `tomllib` (read) and the third-party `tomli_w`
package for write. If `tomli_w` is unavailable, the script falls back to
a minimal builtin TOML serializer that handles the subset of TOML the
pack ships in K2/K3 (tables, sub-tables, scalars, simple arrays).

Usage:
    merge-toml.py BASE OURS THEIRS [--output PATH]

If --output is not given, the merged TOML is written to stdout.

Exit codes:
    0  merged cleanly (no warnings)
    1  argument or parse error (no output written)
    2  merged with reconciliation warnings (output still written; warnings
       to stderr)
"""

import argparse
import sys
from pathlib import Path
from typing import Any

try:
    import tomllib
except ModuleNotFoundError:
    print("error: Python 3.11+ required (tomllib not available)", file=sys.stderr)
    sys.exit(1)

try:
    import tomli_w  # type: ignore
    _HAS_TOMLI_W = True
except ModuleNotFoundError:
    _HAS_TOMLI_W = False


_MISSING = object()


def load_toml(path: str | None) -> Any:
    """Return parsed TOML, or _MISSING if path is empty/missing."""
    if not path:
        return _MISSING
    p = Path(path)
    if not p.is_file():
        return _MISSING
    text = p.read_text()
    if not text.strip():
        return _MISSING
    return tomllib.loads(text)


def is_present(v: Any) -> bool:
    return v is not _MISSING


def is_dict(v: Any) -> bool:
    return is_present(v) and isinstance(v, dict)


def is_list(v: Any) -> bool:
    return is_present(v) and isinstance(v, list)


# ── Merge logic (mirrors merge-json.py) ──

def merge_dict(base: Any, ours: Any, theirs: Any, path: str, warnings: list) -> dict:
    base_d = base if is_dict(base) else {}
    ours_d = ours if is_dict(ours) else {}
    theirs_d = theirs if is_dict(theirs) else {}

    all_keys: set[str] = set()
    all_keys |= set(base_d.keys())
    all_keys |= set(ours_d.keys())
    all_keys |= set(theirs_d.keys())

    merged: dict[str, Any] = {}

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

        if in_base and in_ours and in_theirs:
            sub = merge_value(b, o, t, sub_path, warnings)
            if sub is not _MISSING:
                merged[key] = sub
        elif in_base and not in_ours and in_theirs:
            if b == t:
                pass  # honor project removal
            else:
                warnings.append(
                    f"{sub_path}: project removed; pack edited "
                    f"(kept project removal — reconcile manually)"
                )
        elif in_base and in_ours and not in_theirs:
            if b == o:
                pass  # honor pack removal
            else:
                warnings.append(
                    f"{sub_path}: pack removed; project edited "
                    f"(kept project edit — reconcile manually)"
                )
                merged[key] = o
        elif in_base and not in_ours and not in_theirs:
            pass
        elif not in_base and in_ours and in_theirs:
            if o == t:
                merged[key] = t
            else:
                warnings.append(
                    f"{sub_path}: both added with different values "
                    f"(kept project value — reconcile manually)"
                )
                merged[key] = o
        elif not in_base and in_ours and not in_theirs:
            merged[key] = o
        elif not in_base and not in_ours and in_theirs:
            merged[key] = t

    return merged


def merge_list(base: Any, ours: Any, theirs: Any, path: str, warnings: list) -> list:
    base_l = base if is_list(base) else []
    ours_l = ours if is_list(ours) else []
    theirs_l = theirs if is_list(theirs) else []

    def key(item: Any) -> str:
        if isinstance(item, (str, int, float, bool)) or item is None:
            return repr(item)
        return repr(item)

    base_set = {key(x): x for x in base_l}
    ours_set = {key(x): x for x in ours_l}
    theirs_set = {key(x): x for x in theirs_l}

    removed_by_project = set(base_set) - set(ours_set)
    added_by_project = set(ours_set) - set(base_set)
    added_by_pack = set(theirs_set) - set(base_set)
    removed_by_pack = set(base_set) - set(theirs_set)

    for k in (removed_by_project & added_by_pack):
        warnings.append(
            f"{path}[]: project removed value; pack added matching value "
            f"(kept pack value — reconcile manually)"
        )
    for k in (added_by_project & removed_by_pack):
        warnings.append(
            f"{path}[]: pack removed value; project added matching value "
            f"(kept project value — reconcile manually)"
        )

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

    if base == ours and base == theirs:
        return theirs
    if base == ours and base != theirs:
        return theirs
    if base != ours and base == theirs:
        return ours
    if ours == theirs:
        return ours
    warnings.append(
        f"{path}: scalar conflict — base={base!r}, ours={ours!r}, theirs={theirs!r} "
        f"(kept ours — reconcile manually)"
    )
    return ours


# ── TOML write fallback (used when tomli_w is not installed) ──

def _toml_format_scalar(v: Any) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        # Always use double-quoted basic string with simple escaping.
        escaped = v.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        return f'"{escaped}"'
    if v is None:
        # TOML has no null; skip via caller.
        return '""'
    raise ValueError(f"unsupported scalar type for fallback TOML writer: {type(v).__name__}")


def _toml_format_array(arr: list) -> str:
    if not arr:
        return "[]"
    if all(isinstance(x, (str, int, float, bool)) or x is None for x in arr):
        items = ", ".join(_toml_format_scalar(x) for x in arr)
        return f"[{items}]"
    # Inline array of tables / nested arrays — emit minimal representation.
    parts = []
    for x in arr:
        if isinstance(x, dict):
            inner = ", ".join(f"{k} = {_toml_format_scalar(v) if not isinstance(v, list) else _toml_format_array(v)}" for k, v in x.items())
            parts.append("{ " + inner + " }")
        elif isinstance(x, list):
            parts.append(_toml_format_array(x))
        else:
            parts.append(_toml_format_scalar(x))
    return "[" + ", ".join(parts) + "]"


def _toml_dump_fallback(data: dict, prefix: str = "") -> str:
    """Minimal TOML serializer for dict-of-dicts (with scalar/array leaves).

    Sufficient for K2/K3 (.codex/config.toml, .codex/requirements.toml) which
    use top-level scalars + tables-of-scalars and a few simple arrays.
    """
    lines: list[str] = []
    # Emit scalars and arrays first at this level
    for k, v in data.items():
        if isinstance(v, dict):
            continue
        if isinstance(v, list):
            lines.append(f"{k} = {_toml_format_array(v)}")
        else:
            lines.append(f"{k} = {_toml_format_scalar(v)}")
    # Then sub-tables
    for k, v in data.items():
        if isinstance(v, dict):
            section_name = f"{prefix}{k}" if not prefix else f"{prefix}.{k}"
            lines.append("")
            lines.append(f"[{section_name}]")
            lines.append(_toml_dump_fallback(v, section_name))
    return "\n".join(line for line in lines if line is not None)


def dump_toml(data: dict) -> str:
    if _HAS_TOMLI_W:
        return tomli_w.dumps(data)
    out = _toml_dump_fallback(data)
    if not out.endswith("\n"):
        out += "\n"
    return out


# ── Main ──

def main() -> int:
    ap = argparse.ArgumentParser(description="Three-way TOML key-merge.")
    ap.add_argument("base", help="v9.3 pack baseline file (or empty string)")
    ap.add_argument("ours", help="project file pre-migration")
    ap.add_argument("theirs", help="v10 pack template file")
    ap.add_argument("--output", help="write merged TOML to PATH (default: stdout)")
    args = ap.parse_args()

    try:
        base = load_toml(args.base) if args.base else _MISSING
        ours = load_toml(args.ours)
        theirs = load_toml(args.theirs)
    except tomllib.TOMLDecodeError as e:
        print(f"error: TOML parse failed: {e}", file=sys.stderr)
        return 1

    if not is_present(ours):
        print("error: ours file is missing or empty", file=sys.stderr)
        return 1
    if not is_present(theirs):
        print("error: theirs file is missing or empty", file=sys.stderr)
        return 1

    warnings: list[str] = []
    merged = merge_value(base, ours, theirs, "", warnings)
    if not isinstance(merged, dict):
        print(f"error: merged result is not a TOML table at top level: {type(merged).__name__}", file=sys.stderr)
        return 1

    output = dump_toml(merged)

    if args.output:
        Path(args.output).write_text(output)
    else:
        sys.stdout.write(output)

    for w in warnings:
        print(f"warning: {w}", file=sys.stderr)

    return 2 if warnings else 0


if __name__ == "__main__":
    sys.exit(main())
