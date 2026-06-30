"""validate_checks.migrator_docs — Cluster L: the migrator/removed-doc family (BD-256 W13).

This module owns Cluster L's 2 check bodies (Checks 48, 49) — the doc/migrator
hygiene guards: the JC-5 soft-advisory removed-doc guard (48, BD-195 C6 / BD-203
A12: a WARN-only scan of the `/backlog/` + `/changelog/` per-entry trees that
surfaces accurate-history citations to docs REMOVED from the repo, NEVER failing
the gate) and the migrator field/body-faithfulness deep guard (49, BD-204 §4.2/
§4.6: a PACK_VALIDATE_DEEP=1-gated whole-tree verification that FAILs a lossy/
corrupting forward→reverse tracker migration or a body-limit/title breach, driving
the SINGLE-SOURCED batch codec via the `_CHECK_49_SEAM_SCRIPT` bash seam).

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.migrator_docs import
*`, so the registry assembled in the facade (`_build_check_registry()`) keeps
resolving each check by bare name — Check 48 by its `check_removed_doc_advisory`
name, and Check 49 through its named-lambda entry
`lambda: check_migrator_field_faithfulness(REPO_ROOT / "backlog")` with the DEEP
faithfulness per-check WARN budget (`RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S`). The
lambda closes over the facade's `import *`-bound `check_migrator_field_faithfulness`
+ the core-seam `REPO_ROOT`, so the registry tuple still builds and dispatches
post-move. Single SSOT — no forked copy.

Intra-cluster symbols moved with the bodies (read only by Cluster L checks):
the `_REMOVED_DOC_BASENAMES` / `_REMOVED_DOC_SCAN_DIRS` frozen sets (Check 48),
the `_CHECK_49_SEAM_SCRIPT` bash seam, the `_check_49_read_frames` /
`_check_49_stream_key_for_tree` / `_check_49_first_control_byte` /
`_check_49_first_diff` helpers, and the `_CHECK_49_DISALLOWED_CONTROL` /
`_CHECK_49_TITLE_MAX_CODEPOINTS` / `_CHECK_49_ENTRY_HEADER_RE` constants (Check 49)
— all read only by Cluster L (verified by grep at the extraction wave: no check
outside Cluster L reads them), so no core promotion is needed — they are
Cluster-L-owned, not a >=2-module seam. They are underscore-prefixed; the five
that the W13 tests reach on the facade re-export surface — `_REMOVED_DOC_BASENAMES`
/ `_REMOVED_DOC_SCAN_DIRS` (the removed-doc-advisory test) and `_CHECK_49_SEAM_SCRIPT`
/ `_CHECK_49_DISALLOWED_CONTROL` / `_CHECK_49_TITLE_MAX_CODEPOINTS` (the check-49
test's Group-0 `hasattr`) — are enumerated in `__all__` (a declared `__all__`
gates non-underscore names too AND must list any underscore name `import *` should
re-export). The remaining `_CHECK_49_ENTRY_HEADER_RE` / `_check_49_read_frames` /
`_check_49_stream_key_for_tree` / `_check_49_first_control_byte` /
`_check_49_first_diff` are read only by Check 49 inside this module and not asserted
by any test, so they are deliberately OMITTED — they stay module-internal. The W13
test sites (`test-validate-pack-check-removed-doc-advisory.sh`)
are reworked in the same commit: the `mod.REPO_ROOT` reassign converts to the
wave-invariant `_patch_root(mod, root)` helper (form B) and the
`mod._REMOVED_DOC_SCAN_DIRS` reassign to `_patch_attr(mod, name, value)` (form B),
because Check 48 now reads `migrator_docs.REPO_ROOT` /
`migrator_docs._REMOVED_DOC_SCAN_DIRS` and a facade-only patch would no longer bite.

Spine + seam: the spine symbols (`REPO_ROOT`, `fail`, `ok`, `warn`, `failures`)
and the cross-module seam `STREAMS` are imported `from .core` — the single SSOT
for the spine + W1 seams. (`STREAMS` is a W1 seam — read by Cluster F Checks
32/33/34 AND Check 49's `_check_49_stream_key_for_tree` — so it lives in core and
is imported here, never forked.) (`failures` is imported for the V3 failures-
identity invariant — `core.failures is migrator_docs.failures` — matching the
W2–W12 module convention; the Cluster L bodies append via `fail()`, never rebind
`failures`.) Standard-library `json`, `os`, `re`, `subprocess`, `tempfile` and
`pathlib.Path` are imported directly at module top (Check 48 uses `re.compile`/
`re.escape`; Check 49 uses `os.environ`, `tempfile.TemporaryDirectory`,
`subprocess.run`/`subprocess.DEVNULL`, `json.loads`, and `Path` byte reads),
mirroring the established per-module convention (the spine `import *` does not
re-export stdlib names).

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import json
import os
import re
import subprocess
import tempfile
from pathlib import Path

from .core import (
    REPO_ROOT,
    STREAMS,
    fail,
    ok,
    warn,
    failures,
)


# ── Check 48 (BD-195 C6): JC-5 soft-advisory removed-doc guard ─────────────
# Frozen measure-then-bound set (PLAN-BD-195-REMEDIATION.md §2.3 Step-1):
# basenames of docs REMOVED from the repo that are still cited (as accurate
# v8/v9 + process history). Each was verified ABSENT from the tree at design
# time (`find . -name <name>` → 0). The guard WARNs (never fail()s) on each
# occurrence so the accurate-history citations surface without breaking CI
# (JC-5: NO hand-correction).
#
# BD-203 A12: the accurate-history citations relocate from the two deleted
# monoliths INTO the per-entry trees, so the scan is REPOINTED to walk the
# `/backlog/` + `/changelog/` per-entry directories (every `*.md` entry +
# supporting file). SKIP-on-absent is preserved (the trees are absent
# pre-conversion), so Check 48 reports 0 hits cleanly at the pre-conversion
# state. No full-repo walk — scoped to the two tree dirs.
_REMOVED_DOC_BASENAMES = (
    "GEMINI-CLI-ANALYSIS.md",
    "ANDROID-ANALYSIS.md",
    "V10-PREDESIGN.md",
    "ARCHITECTURE-BD-185.md",
    "PLAN-BD-185.md",
)
_REMOVED_DOC_SCAN_DIRS = (
    "changelog",
    "backlog",
)


def check_removed_doc_advisory() -> None:
    """Check 48 — JC-5 soft-advisory removed-doc guard (BD-195 C6).

    SOFT-ADVISORY ONLY: WARNs (never fail()s; never changes the exit
    code) when a citation in a scanned file resolves to a doc REMOVED
    from the repo. Covers the K3.12 + K3.13 accurate-history citations
    WITHOUT hand-correcting them (JC-5: leave accurate v8/v9 + process
    history intact).

    BD-203 A12: the citations relocated from the two deleted monoliths
    INTO the per-entry trees, so the scan walks every `*.md` file under
    the `/backlog/` + `/changelog/` directories (`_REMOVED_DOC_SCAN_DIRS`)
    instead of the monolith files. SKIP-on-absent is preserved (a tree
    absent at this HEAD is not an advisory condition).

    Measure-then-bound (PLAN-BD-195-REMEDIATION.md §2.3): the bounded
    set of removed-doc basenames is frozen in `_REMOVED_DOC_BASENAMES`
    (each verified ABSENT from the tree at design time). Every hit is a
    warning; NONE is a STRIP / gate failure.

    The token boundary `(?<![\\w.-])` / `(?![\\w-])` ensures
    `ARCHITECTURE-BD-185.md` does NOT match the LIVE
    `ARCHITECTURE-BD-185-V2.md` (and likewise `PLAN-BD-185.md` vs
    `PLAN-BD-185-V2.md`) while still matching path-form citations such
    as `supporting-docs/GEMINI-CLI-ANALYSIS.md` and
    `maintenance-docs/V10-PREDESIGN.md`.
    """
    print("\n── Check 48: JC-5 soft-advisory removed-doc guard (BD-195) ──")

    # Compile the basename alternation ONCE. Leading guard rejects a
    # preceding word char, `.`, or `-` so a longer live basename that
    # merely ends with a removed name is not matched (but a `/` path
    # separator IS allowed — path-form citations are still removed-doc
    # references); trailing guard rejects a following word char or `-`
    # so `ARCHITECTURE-BD-185.md` does not match inside the live
    # `ARCHITECTURE-BD-185-V2.md`.
    alternation = "|".join(re.escape(name) for name in _REMOVED_DOC_BASENAMES)
    pattern = re.compile(r"(?<![\w.-])(?:" + alternation + r")(?![\w-])")

    total_hits = 0
    dirs_scanned = 0
    for stream_rel in _REMOVED_DOC_SCAN_DIRS:
        stream_dir = REPO_ROOT / stream_rel
        if not stream_dir.is_dir():
            # Lenient: a tree absent at this HEAD is not an advisory
            # condition (nothing to scan).
            continue
        dirs_scanned += 1
        for entry in sorted(stream_dir.glob("*.md")):
            rel = entry.relative_to(REPO_ROOT)
            try:
                text = entry.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                # Read failure is surfaced by other checks; the
                # soft-advisory simply skips an unreadable file.
                continue
            for line_no, line in enumerate(text.splitlines(), start=1):
                for m in pattern.finditer(line):
                    total_hits += 1
                    warn(
                        f"{rel}:{line_no} cites `{m.group(0)}` — a removed doc "
                        f"(JC-5 accurate-history citation; advisory only, NOT a "
                        f"gate failure, NOT hand-corrected)"
                    )

    # Always an OK summary line — the advisory NEVER fails the gate.
    ok(
        f"Check 48 — soft-advisory removed-doc scan: {total_hits} "
        f"removed-doc citation(s) WARNed across {dirs_scanned} per-entry "
        f"tree dir(s); advisory only (exit code unaffected)"
    )


# ── Check 49: migrator field/body faithfulness (BD-204 §4.2/§4.6) ──────────
#
# The deep CI guard that fails a LOSSY or CORRUPTING forward→reverse tracker
# migration (the C-2 19-field-drop hazard) OR a body-limit/title breach — the
# exact gap that shipped green in the dead `pack-extra-fields` carrier. It
# drives the SINGLE-SOURCED batch codec (Option B; design §4.6 (S)), NOT a
# reproduced codec (OQ-4 — see the §4.5 single-source check below) and NOT the
# per-entry real functions (Option A = measured 142 s, rejected).
#
# Three mandatory runtime constraints (`ci-check-runtime-compounding`, §4.6):
#   (P) ENV-GATE — the FIRST statement early-returns a SKIP unless
#       PACK_VALIDATE_DEEP=1, BEFORE any tree read, so the 151× general battery
#       path pays ~0 (the prior C-4.6 ran the heavy scan in the 151× main()).
#   (T) TARGET-TREE SCOPING — the check validates the CALLER's `tree_dir`, with
#       NO `tree_dir or REPO_ROOT/"backlog"` fallback (that `or` was the exact
#       C-4.6 bug: a 3-entry fixture paid the full real-211 cost).
#   (S) SEAM = the SHARED BATCH CODEC — ONE python3 over all entries via the
#       real `_tmf_gz64_encode_batch` / `_tmr_decode_body_blob_batch` /
#       `_tmf_neutralize_autolinks_batch` / `tmf_compose_issue_body_batch`
#       (measured 0.05 s), so the guard shares the production codec and cannot
#       FALSE-PASS a lossy codec change.
#
# The BYTE LEG is the §4.6.2 TWO-ASSERTION contract (NOT the forbidden
# `decode(encode(raw_body)) == raw_body` tautology):
#   (a) CODEC-LOSSLESS  decode(encode(raw_body)) == raw_body — the shared batch
#       codec round-trips the captured bytes; AND
#   (b) PARSE-FAITHFUL  PRE_PARSE_ORIGINAL_body == raw_body — the parser's
#       captured span equals the entry FILE's lines 2..EOF read BYTE-SAFELY
#       (a direct byte read of the file after the first `\n`, NEVER awk/a
#       text-normalizing read). THIS IS THE C-2 CATCH: if the parser strips/
#       normalizes ANY byte (a CR, a NUL, a field line, a prose block) leg (b)
#       FAILs. (Belt-and-suspenders with R-BODY-6, which scans the same raw
#       file bytes for a control byte.)
#
# Plus, per design §4.4/§3.3c/§3.3e:
#   - R-BODY-6 control-char leg: scan the entry FILE bytes (pre-parse, not a
#     decoded string) for NUL / CR / disallowed-C0-other-than-tab/LF.
#   - SIZE leg: the REAL composed Issue body length (via the shared batch
#     composer/codec) < provider_body_limit − SAFETY_MARGIN.
#   - TITLE leg: the ID-prefixed bold-header title ≤ 256 CODEPOINTS (R-TITLE-1).

# The bash seam that sources the migrator libs ONCE and drives the shared batch
# functions in ONE process each (Option B; design §4.6 (S)). It materializes
# the parse JSON + the framed decode + the framed composed-body into a temp
# dir, and prints `body_limit<TAB>margin` on stdout for the size leg. The
# guard's Python side reads the FILE bytes directly for the PRE-PARSE ORIGINAL
# (leg b) + R-BODY-6, so this seam carries only the codec/composer work.
_CHECK_49_SEAM_SCRIPT = r'''
set -u
LIB="$1"; TREE_KEY="$2"; TREE_DIR="$3"; OUTDIR="$4"
. "$LIB/per-entry/_lib.sh"
. "$LIB/tracker-errors.sh"
. "$LIB/tracker-config.sh" 2>/dev/null || true
. "$LIB/tracker-provider.sh"
. "$LIB/tracker-provider-gh.sh"
. "$LIB/tracker-migrate-forward.sh"
. "$LIB/tracker-migrate-reverse.sh"

# 1. Parse the TARGET tree → entries JSON (the SAME real parser the migration
#    uses; raw_body is the round-trip truth).
tmf_parse_backlog_tree "$TREE_KEY" "$TREE_DIR" > "$OUTDIR/tree.json" || exit 11

# 2. Frame every raw_body (length-prefixed _TMF_BATCH protocol; arbitrary
#    bytes safe), then drive the SHARED BATCH codec encode→decode in ONE
#    python3 each (Option B; no per-entry storm, no reproduction).
python3 - "$OUTDIR/tree.json" > "$OUTDIR/raw.frame" <<'PY'
import sys, json
d = json.load(open(sys.argv[1]))
recs = [e["raw_body"].encode("utf-8") for e in d]
w = sys.stdout.buffer
w.write(("%d\n" % len(recs)).encode("ascii"))
for r in recs:
    w.write(("%d\n" % len(r)).encode("ascii")); w.write(r)
PY
_tmf_gz64_encode_batch     < "$OUTDIR/raw.frame" > "$OUTDIR/enc.frame" || exit 12
_tmr_decode_body_blob_batch < "$OUTDIR/enc.frame" > "$OUTDIR/dec.frame" || exit 13

# 3. Drive the SHARED BATCH composer over all entries (the REAL composer's
#    assembly: markers + neutralized H2 + gz64 blob) for the SIZE leg — its
#    output frame carries the real composed-body length per entry.
python3 - "$OUTDIR/tree.json" <<'PY' | tmf_compose_issue_body_batch > "$OUTDIR/composed.frame" || exit 14
import sys, json
d = json.load(open(sys.argv[1]))
w = sys.stdout.buffer
w.write(("%d\n" % len(d)).encode("ascii"))
for e in d:
    for key in ("pack_id", "description", "context", "resolution",
                "file_symbol", "raw_body"):
        b = (e.get(key) or "").encode("utf-8")
        w.write(("%d\n" % len(b)).encode("ascii")); w.write(b)
PY

# 4. The ACTIVE provider's body limit + the migrator's safety margin (the SAME
#    measurement the forward composer's §3.3c overflow gate uses).
BODY_LIMIT="$(printf '%s' "$(provider_capabilities 2>/dev/null)" | jq -r '.body.limit // empty' 2>/dev/null)"
MARGIN="${TMF_SIZE_SAFETY_MARGIN:-2048}"
printf '%s\t%s\n' "$BODY_LIMIT" "$MARGIN"
'''


def _check_49_read_frames(path):
    """Read a _TMF_BATCH length-prefixed framed stream → list[bytes]."""
    data = Path(path).read_bytes()
    i = data.index(b"\n")
    n = int(data[:i])
    pos = i + 1
    out = []
    for _ in range(n):
        j = data.index(b"\n", pos)
        length = int(data[pos:j])
        pos = j + 1
        out.append(data[pos:pos + length])
        pos += length
    return out


def _check_49_stream_key_for_tree(tree_path) -> str:
    """Resolve the per-entry STREAM KEY for a target tree (BD-204 C-4.6 F-3).

    The key only labels the stream for the seam's `pe_list_entry_files`
    entry-regex; the codec/byte work is key-agnostic. DERIVE it from the
    target tree's directory name against the `STREAMS` table (the SSOT for
    `stream_key ↔ stream_dir_relative`) — never hardcode — so a changelog-
    stream caller (`pack-changelog`) or a relocated tree resolves correctly.
    Defaults to `pack-backlog` (both §3.LF.5 deep homes target `/backlog/`)
    when no `STREAMS` row matches the tree's basename.
    """
    name = Path(tree_path).name
    for stream_key, stream_dir_relative, _mirror, _regex in STREAMS:
        if name == Path(stream_dir_relative).name:
            return stream_key
    return "pack-backlog"


# Disallowed control bytes (R-BODY-6): NUL, CR, and any C0 control char OTHER
# than tab (0x09) and LF (0x0A). DEL (0x7f) is included.
_CHECK_49_DISALLOWED_CONTROL = (
    set(range(0x00, 0x20)) - {0x09, 0x0A}
) | {0x7F}

# R-TITLE-1: the stored ID-prefixed title must be ≤ 256 CODEPOINTS.
_CHECK_49_TITLE_MAX_CODEPOINTS = 256
# The per-entry bold-header grammar (mirrors `_tmf_parse_backlog_file`'s
# ENTRY_HEADER) — group 1 = pack-id, group 2 = title text.
_CHECK_49_ENTRY_HEADER_RE = re.compile(
    r"^\*\*((?:BD|TD)-\d{3})\s*[—-]\s*(.+?)\*\*\s*$"
)


def check_migrator_field_faithfulness(tree_dir) -> None:
    """Check 49 — migrator field/body faithfulness (BD-204 §4.2/§4.6).

    `tree_dir` = the CALLER's target per-entry tree (a `Path`). DEEP-GATED:
    runs the heavy whole-tree verification ONLY under PACK_VALIDATE_DEEP=1
    (§4.6 (P)); the default path is a ~0 ms SKIP. There is NO
    `tree_dir or REPO_ROOT/"backlog"` fallback (§4.6 (T) — that `or` was the
    C-4.6 bug).
    """
    # (P) ENV-GATE — the FIRST statement, BEFORE any tree read. The 151×
    # general battery path early-returns here paying ~0.
    if os.environ.get("PACK_VALIDATE_DEEP") != "1":
        ok("SKIP: field-faithfulness deep check (set PACK_VALIDATE_DEEP=1)")
        return

    print("\n── Check 49: migrator field/body faithfulness (BD-204, DEEP) ──")
    tree_path = Path(tree_dir)
    if not tree_path.is_dir():
        fail(f"Check 49 — target tree {tree_path} is not a directory")
        return

    lib_dir = REPO_ROOT / "scripts" / "lib"
    # Stream key: DERIVE from `tree_dir` rather than hardcode (BD-204 C-4.6
    # review F-3). The key only labels the stream for `pe_list_entry_files`'s
    # entry-regex; the byte work is key-agnostic. Match the target tree's
    # directory name against the STREAMS table (the SSOT for stream_key ↔
    # stream_dir) so a future changelog-stream caller (or a relocated tree)
    # resolves the correct key instead of mis-labelling everything
    # `pack-backlog`. Default to `pack-backlog` for the `/backlog/` deep homes
    # (both §3.LF.5 deep homes today) when no STREAMS row matches.
    tree_key = _check_49_stream_key_for_tree(tree_path)

    with tempfile.TemporaryDirectory(prefix="vp-check49-") as outdir:
        # (S) SEAM = the SHARED BATCH CODEC — ONE bash invocation sourcing the
        # libs once and driving the real batch functions in one python3 each.
        result = subprocess.run(
            ["bash", "-c", _CHECK_49_SEAM_SCRIPT, "_",
             str(lib_dir), tree_key, str(tree_path), outdir],
            capture_output=True, text=True, stdin=subprocess.DEVNULL,
        )
        if result.returncode != 0:
            fail(
                f"Check 49 — shared batch-codec seam failed "
                f"(rc={result.returncode}); stderr: {result.stderr.strip()}"
            )
            return

        try:
            entries = json.loads((Path(outdir) / "tree.json").read_text())
            decoded = _check_49_read_frames(Path(outdir) / "dec.frame")
            composed = _check_49_read_frames(Path(outdir) / "composed.frame")
        except Exception as exc:  # noqa: BLE001 — surface any seam-output defect
            fail(f"Check 49 — could not read seam output: {exc}")
            return

        last = result.stdout.strip().splitlines()[-1] if result.stdout.strip() else ""
        body_limit_raw, _, margin_raw = last.partition("\t")
        body_limit = int(body_limit_raw) if body_limit_raw.isdigit() else None
        margin = int(margin_raw) if margin_raw.strip().isdigit() else 2048

        n = len(entries)
        if not (len(decoded) == n and len(composed) == n):
            fail(
                f"Check 49 — seam record-count mismatch: {n} entries, "
                f"{len(decoded)} decoded, {len(composed)} composed"
            )
            return

        any_fail = False
        for idx, entry in enumerate(entries):
            pid = entry.get("pack_id", f"<entry-{idx}>")
            raw_body = (entry.get("raw_body") or "").encode("utf-8")

            # (a) CODEC-LOSSLESS — decode(encode(raw_body)) == raw_body.
            if decoded[idx] != raw_body:
                any_fail = True
                fail(
                    f"Check 49 — {pid}: codec round-trip is LOSSY "
                    f"(decode(encode(raw_body)) != raw_body): "
                    f"{_check_49_first_diff(raw_body, decoded[idx])}"
                )

            # (b) PARSE-FAITHFUL — PRE_PARSE_ORIGINAL_body == raw_body.
            # PRE_PARSE_ORIGINAL = the FILE's lines 2..EOF read BYTE-SAFELY
            # (a direct byte read after the first `\n`; NEVER awk). The C-2
            # catch: a parser-stripped/normalized byte makes this differ.
            entry_file = tree_path / f"{pid}.md"
            pre_parse_original = None
            if entry_file.is_file():
                file_bytes = entry_file.read_bytes()
                nl = file_bytes.find(b"\n")
                pre_parse_original = file_bytes[nl + 1:] if nl >= 0 else b""
                if pre_parse_original != raw_body:
                    any_fail = True
                    fail(
                        f"Check 49 — {pid}: PARSE-FAITHFUL leg FAILED "
                        f"(PRE_PARSE_ORIGINAL != raw_body — the C-2 catch; a "
                        f"parse step stripped/normalized a byte): "
                        f"{_check_49_first_diff(pre_parse_original, raw_body)}"
                    )

                # R-BODY-6 control-char leg — scan the RAW FILE bytes (pre-parse,
                # not a decoded string) for a disallowed control byte.
                bad = _check_49_first_control_byte(pre_parse_original)
                if bad is not None:
                    any_fail = True
                    off, byte = bad
                    fail(
                        f"Check 49 — {pid}: R-BODY-6 disallowed control byte "
                        f"0x{byte:02x} at body offset {off} (raw-file scan; "
                        f"NUL/CR/C0-other-than-tab-LF/DEL forbidden)"
                    )

            # SIZE leg — the REAL composed Issue body length (shared batch
            # composer) < provider_body_limit − SAFETY_MARGIN.
            if body_limit is not None:
                composed_bytes = len(composed[idx])
                budget = body_limit - margin
                if composed_bytes > budget:
                    any_fail = True
                    fail(
                        f"Check 49 — {pid}: composed Issue body "
                        f"{composed_bytes} bytes exceeds provider body limit "
                        f"{body_limit} − margin {margin} = {budget}"
                    )

            # TITLE leg — the ID-prefixed bold-header title ≤ 256 codepoints
            # (R-TITLE-1; CODEPOINT count, not byte count). The stored title
            # is `<ID>: <title>`.
            title = entry.get("title", "")
            if title:
                stored_title = f"{pid}: {title}"
                if len(stored_title) > _CHECK_49_TITLE_MAX_CODEPOINTS:
                    any_fail = True
                    fail(
                        f"Check 49 — {pid}: stored title {len(stored_title)} "
                        f"codepoints exceeds R-TITLE-1 limit "
                        f"{_CHECK_49_TITLE_MAX_CODEPOINTS}"
                    )

        if not any_fail:
            limit_note = (
                f"size leg vs provider body limit {body_limit} − margin {margin}"
                if body_limit is not None
                else "size leg SKIPPED (provider declares no body limit)"
            )
            ok(
                f"Check 49 — {n} entries byte-faithful (codec-lossless + "
                f"parse-faithful), control-char-clean, title ≤ "
                f"{_CHECK_49_TITLE_MAX_CODEPOINTS} codepoints, {limit_note}"
            )


def _check_49_first_control_byte(data: bytes):
    """Return (offset, byte) of the first disallowed control byte, or None."""
    for off, byte in enumerate(data):
        if byte in _CHECK_49_DISALLOWED_CONTROL:
            return (off, byte)
    return None


def _check_49_first_diff(a: bytes, b: bytes) -> str:
    """A short unified-style description of the first differing byte (§4.2)."""
    minlen = min(len(a), len(b))
    for i in range(minlen):
        if a[i] != b[i]:
            return (
                f"first differ at byte {i}: "
                f"{a[max(0, i - 8):i + 8]!r} vs {b[max(0, i - 8):i + 8]!r}"
            )
    return f"lengths differ: {len(a)} vs {len(b)} bytes"


# ── __all__ — every Cluster-L-OWNED symbol the facade / the tests reach ─────
# `from validate_checks.migrator_docs import *` skips underscore names UNLESS
# they are listed here; and once `__all__` is declared it ALSO gates the
# non-underscore names — so `check_removed_doc_advisory` (resolved by bare name
# in the facade's `_build_check_registry()`) and `check_migrator_field_faithfulness`
# (resolved by the registry's named-lambda) MUST be enumerated. The `__all__` set
# is the UNION of registry-referenced `check_*` + the underscore-prefixed
# TESTED-PRIVATE symbols the W13 tests reach on the facade re-export surface
# (SHOULD-5). Those tested privates are: `_REMOVED_DOC_BASENAMES` /
# `_REMOVED_DOC_SCAN_DIRS` (removed-doc-advisory Group-0 `hasattr` + the
# `_REMOVED_DOC_SCAN_DIRS` patch site) AND `_CHECK_49_SEAM_SCRIPT` /
# `_CHECK_49_DISALLOWED_CONTROL` / `_CHECK_49_TITLE_MAX_CODEPOINTS`
# (test-validate-pack-check-49 Group-0 `hasattr` on the facade) — all enumerated.
# The remaining Cluster-L-exclusive underscore symbols (`_check_49_read_frames`,
# `_check_49_stream_key_for_tree`, `_CHECK_49_ENTRY_HEADER_RE`,
# `_check_49_first_control_byte`, `_check_49_first_diff`) are read only by Check 49
# inside this module AND not asserted by any test's facade-re-export surface, so
# they are deliberately OMITTED — they stay module-internal. The `from .core` spine
# (`REPO_ROOT`, `STREAMS`, `fail`, `ok`, `warn`, `failures`) is NOT re-listed —
# those are core-owned (the facade re-exports them via `from validate_checks.core
# import *`); `__all__` enumerates only migrator_docs's OWN symbols.
__all__ = [
    # ── Cluster L check bodies (48, 49) ──
    "check_removed_doc_advisory",
    "check_migrator_field_faithfulness",
    # ── Cluster-L-owned tested privates the W13 tests reach / patch ──
    "_REMOVED_DOC_BASENAMES",
    "_REMOVED_DOC_SCAN_DIRS",
    "_CHECK_49_SEAM_SCRIPT",
    "_CHECK_49_DISALLOWED_CONTROL",
    "_CHECK_49_TITLE_MAX_CODEPOINTS",
]
