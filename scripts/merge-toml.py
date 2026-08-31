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

Whole-line comment BLOCKS survive the merge; inline comments and comments
inside an array-of-tables do not. See the "Comment preservation" section
below for the exact scope and for why the merge would otherwise drop every
comment in the file.

Usage:
    merge-toml.py BASE OURS THEIRS [--output PATH]
    merge-toml.py "" OURS THEIRS --pack-authored-base PACK --pack-source REL

If --output is not given, the merged TOML is written to stdout.

DERIVED BASE (--pack-authored-base / --pack-source)

Same contract as `merge-json.py`: `--update` has no recorded BASE for a
structured file, and a BASE-less three-way cannot tell a stale PACK value from
a CLIENT edit, so every diverged pack key freezes. These two flags let the
common ancestor be DERIVED per key from the pack's own object history
(`scripts/lib/pack_provenance_keys.py`). Used ONLY when the positional BASE is
empty; a derivation that finds nothing leaves BASE absent, i.e. exactly
today's behaviour.

Exit codes:
    0  merged cleanly (no warnings)
    1  argument or parse error (no output written)
    2  merged with reconciliation warnings (output still written; warnings
       to stderr)
"""

import argparse
import re
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
from pack_provenance_keys import (  # noqa: E402
    derive_base, emit_removal_notices, historical_docs,
)

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


# ── Comment preservation ──
#
# The loss is a PARSE-time loss, not a writer bug. `tomllib.loads()` returns a
# plain dict and TOML comments are discarded there, before any writer runs;
# both `tomli_w.dumps` and `_toml_dump_fallback` are downstream of an already
# comment-free structure, so neither can restore what the parser dropped.
# Measured on `project-template/.codex/requirements.toml` through the
# `real-merge-required` arm: 6 comment lines in OURS, 6 in THEIRS, 0 in the
# merged output.
#
# The repair re-attaches comments to the SERIALIZED text — the one layer both
# writers converge on — so behaviour does not depend on whether the optional
# `tomli_w` happens to be installed. Comments are harvested from the source
# texts and keyed by the construct they precede; a block is re-emitted only
# when its construct SURVIVED the merge, so a key the merge legitimately
# dropped never leaves an orphan comment behind. OURS wins over THEIRS when
# both annotate the same construct: the client's own note is the one a client
# would miss.
#
# SCOPE — whole-line comment BLOCKS only. PRESERVED:
#   * the file header;
#   * the block directly above a `[table]` header or a `key =` line;
#   * a block at end-of-file, which annotates no construct and is re-emitted
#     verbatim at the end (two pack-shipped files end with one).
#
# NOT preserved:
#   * a TRAILING INLINE comment (`key = true  # why`) — telling an inline `#`
#     from a `#` inside a quoted value needs a real TOML tokenizer, and
#     mis-splitting one would corrupt the value. No pack-shipped TOML uses
#     inline comments (measured: zero across `.codex/config.toml`,
#     `.codex/config.toml.example`, `.codex/requirements.toml`).
#   * a comment INSIDE an array-of-tables (`[[items]]`) — the writers flatten
#     `[[items]]` to an inline `items = [{...}]` array, so no `items.name`
#     construct line survives for the block to key against. No pack-shipped
#     TOML uses an array-of-tables (measured: zero across the same three
#     files).
#
# Neither case arises in a file the pack ships today, and both are recorded
# here rather than left for a reader to rediscover from the code. The list is
# the set MEASURED so far, not a proof of exhaustiveness: this is a line-shape
# reader, not a TOML tokenizer, so a construct whose shape it cannot key is
# always possible. What IS bounded is the blast radius — only comment
# INSERTION is keyed, output lines are copied verbatim, so the worst case is
# a lost comment, never a changed value.


# A table header is a WHOLE line — `[name]` / `[[name]]`, optionally followed
# by a comment — whose NAME is a TOML key path (dotted bare or quoted keys).
# Both halves of that shape are load-bearing. Treating any line that merely
# BEGINS with `[` as a header also captures a continuation line of a
# multi-line array (`  [1, 2],`), and requiring only that it end with `]`
# still captures the last element of one (`  [3, 4]`). Either way the section
# becomes `1, 2`, every later comment in the table is keyed under a table that
# does not exist, and — since the merged output writes the array on one line
# and keys the same comments under the real table — no block ever matches and
# the comments are silently dropped.
_TOML_KEY = r"""(?:[A-Za-z0-9_-]+|"[^"]*"|'[^']*')"""
_TOML_KEYPATH = rf"{_TOML_KEY}(?:\s*\.\s*{_TOML_KEY})*"
_TABLE_HEADER_RE = re.compile(rf"^\[\s*({_TOML_KEYPATH})\s*\]\s*(?:#.*)?$")
_ARRAY_TABLE_RE = re.compile(rf"^\[\[\s*({_TOML_KEYPATH})\s*\]\]\s*(?:#.*)?$")


def _construct_path(stripped: str, section: str) -> tuple:
    """Return `(comment key, new section or None)` for a TOML construct line."""
    m = _ARRAY_TABLE_RE.match(stripped)
    if m:
        return m.group(1), m.group(1)
    m = _TABLE_HEADER_RE.match(stripped)
    if m:
        return m.group(1), m.group(1)
    if stripped.startswith("["):
        # Bracketed but not a well-formed header: an array continuation line.
        # It names no construct, and it must not move the section.
        return None, None
    if "=" in stripped:
        key = stripped.split("=", 1)[0].strip()
        return (f"{section}.{key}" if section else key), None
    return None, None


def harvest_comments(text: str) -> tuple:
    """Split a TOML source into `(header, {construct path: block}, trailer)`."""
    header: list[str] = []
    by_path: dict[str, list[str]] = {}
    pending: list[str] = []
    section = ""
    seen_construct = False
    for raw in text.splitlines():
        s = raw.strip()
        if not s:
            # Inside the file header a blank line is part of the block; once a
            # construct has been seen, a blank line DETACHES the pending block
            # so it is not misread as annotating the next construct.
            if not seen_construct:
                if pending:
                    pending.append("")
            else:
                pending = []
            continue
        if s.startswith("#"):
            pending.append(raw.rstrip())
            continue
        path, sect = _construct_path(s, section)
        if sect is not None:
            section = sect
        if not seen_construct:
            seen_construct = True
            header = list(pending)
            while header and not header[-1]:
                header.pop()
        elif pending and path:
            by_path[path] = [ln for ln in pending if ln]
        pending = []
    # Whatever is still pending at end-of-input precedes no construct, so it
    # is a TRAILING block. Two pack-shipped files end with one, and dropping
    # it here is what silently deleted them on every update.
    if not seen_construct:
        # No construct at all: the file is entirely header, not trailer, or
        # the block would migrate from the top of the file to the bottom.
        header = [ln for ln in pending if ln]
        pending = []
    return header, by_path, [ln for ln in pending if ln]


def reattach_comments(output: str, ours_text: str, theirs_text: str) -> str:
    """Re-emit harvested comments around the constructs that survived the merge."""
    o_header, o_paths, o_trailer = harvest_comments(ours_text)
    t_header, t_paths, t_trailer = harvest_comments(theirs_text)
    header = o_header or t_header
    trailer = o_trailer or t_trailer

    out_lines = output.splitlines()
    # The fallback writer opens with a blank line before its first table; drop
    # leading blanks so the header lands at the top of the file.
    while out_lines and not out_lines[0].strip():
        out_lines.pop(0)

    result: list[str] = []
    if header:
        result.extend(header)
        result.append("")

    section = ""
    used: set[str] = set()
    for raw in out_lines:
        s = raw.strip()
        if s and not s.startswith("#"):
            path, sect = _construct_path(s, section)
            if sect is not None:
                section = sect
            if path and path not in used:
                block = o_paths.get(path) or t_paths.get(path)
                if block:
                    used.add(path)
                    if result and result[-1].strip():
                        result.append("")
                    result.extend(block)
        result.append(raw)

    # A trailing block annotates no construct, so it cannot be orphaned by a
    # dropped key: it is re-emitted verbatim at the end.
    if trailer:
        if result and result[-1].strip():
            result.append("")
        result.extend(trailer)

    text = "\n".join(result)
    if not text.endswith("\n"):
        text += "\n"
    return text


# ── Main ──

def main() -> int:
    ap = argparse.ArgumentParser(description="Three-way TOML key-merge.")
    ap.add_argument("base", help="v9.3 pack baseline file (or empty string)")
    ap.add_argument("ours", help="project file pre-migration")
    ap.add_argument("theirs", help="v10 pack template file")
    ap.add_argument("--output", help="write merged TOML to PATH (default: stdout)")
    ap.add_argument("--pack-authored-base", metavar="PACK_ROOT",
                    help="derive BASE from this pack clone's object history "
                         "(only when the positional BASE is empty)")
    ap.add_argument("--pack-source", metavar="RELPATH",
                    help="pack-relative SOURCE path of OURS, the key the "
                         "history walk is indexed by")
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

    # DERIVED BASE — see the module docstring. Strictly a fallback: an explicit
    # BASE is never overridden, so the migrator's three-way keeps the ancestor
    # it recorded. A failed or empty derivation leaves BASE absent, which is
    # the pre-existing behaviour rather than an error.
    #
    # Broad `except` for the same reason as merge-json.py: the derivation is an
    # ACCELERATOR, so a failure inside it must cost the ancestor and nothing
    # else. Raising would exit 1, and the structured strategy reads a non-0/2
    # rc as "merge errored" — sidecar the client's file and copy THEIRS over
    # it. Degrading to the empty base is stale, never destructive.
    if not is_present(base) and args.pack_authored_base and args.pack_source:
        try:
            docs = historical_docs(args.pack_authored_base, args.pack_source,
                                   tomllib.loads)
            derived = derive_base(ours, docs)
        except Exception:  # noqa: BLE001 — see above
            derived = None
        if derived is not None:
            base = derived

    warnings: list[str] = []
    merged = merge_value(base, ours, theirs, "", warnings)
    if not isinstance(merged, dict):
        print(f"error: merged result is not a TOML table at top level: {type(merged).__name__}", file=sys.stderr)
        return 1

    # Re-attach the comments the tomllib parse dropped. Sources are re-read as
    # TEXT because the parsed dicts no longer carry them.
    ours_text = Path(args.ours).read_text() if Path(args.ours).is_file() else ""
    theirs_text = Path(args.theirs).read_text() if Path(args.theirs).is_file() else ""
    output = reattach_comments(dump_toml(merged), ours_text, theirs_text)

    if args.output:
        Path(args.output).write_text(output)
    else:
        sys.stdout.write(output)

    for w in warnings:
        print(f"warning: {w}", file=sys.stderr)
    # Disclosure, not a verdict: a value the client holds can be dropped at
    # rc 0 when the pack has retired it. See the DERIVED BASE note above.
    emit_removal_notices(ours, merged, sys.stderr)

    return 2 if warnings else 0


if __name__ == "__main__":
    sys.exit(main())
