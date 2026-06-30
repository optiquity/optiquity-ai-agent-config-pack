"""validate_checks.per_entry_sync — Cluster F: the per-entry tree
sync / integrity family (BD-256 W7).

This module owns Cluster F's 3 check bodies (Checks 32, 33, 34) plus their
intra-cluster helpers and constants — the no-pack-monolith inverted guard
(32′, BD-203), the per-entry `_toc.md` in-sync gate (33, BD-168), and the
cross-reference integrity gate (34, BD-168). The three are co-located because
they all walk the same per-entry STREAMS trees and share the filename /
supporting-file conventions: Check 32′ defines the filename-conformance helper
(`_list_unknown_files`) and the canonical-header / mode-marker constants
(`_CANON_HEADER_RE`, `_RULES_MODE_MARKERS`, `_stream_is_id_shaped`); Checks 33
and 34 reuse the same STREAMS walk and the leading-underscore supporting-file
skip; Check 34 adds the cross-reference grammar (`CROSS_REF_RE`,
`_VERSION_POINT_RE`) and its resolution helpers (`_resolves_to_defined_id`,
`_collect_defined_ids`, `_extract_references`).

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.per_entry_sync
import *`, so the registry assembled in the facade (`_build_check_registry()`)
keeps resolving each `check_*` name. Single SSOT — no forked copy.

Intra-cluster symbols moved with the bodies (read only by Cluster F checks):
the filename-conformance helper + constants (`_list_unknown_files`,
`_CANON_HEADER_RE`, `_RULES_MODE_MARKERS`, `_stream_is_id_shaped`), the
cross-reference grammar + resolvers (`CROSS_REF_RE`, `_VERSION_POINT_RE`,
`_resolves_to_defined_id`, `_collect_defined_ids`, `_extract_references`), and
the per-entry library path (`PER_ENTRY_LIB`) read only by Check 33's TOC
regenerator invocation. None of these is read by a check outside Cluster F
(verified by grep at the extraction wave — `PER_ENTRY_LIB` has its sole
source-consumer in `check_toc_in_sync`; the per-entry test's same-named bash
variable is a separate scope, not a Python monkeypatch), so no core promotion
is needed — they are Cluster-F-owned, not a >=2-module seam. `PER_ENTRY_LIB`
is derived from the `from .core import REPO_ROOT` binding (the single SSOT for
the repo root), mirroring its prior facade derivation.

The Check 32′ explanatory preamble (BD-203 inverted-guard rationale) moves with
the block verbatim to preserve intra-module order; the parallel `# Check 28
RETIRED` / `# Checks 29-31 moved to W4` breadcrumbs at the facade stay in the
facade (they describe other waves' moves, not Cluster F's content), as does the
`pack-chat-only moved to core (W1 seams)` breadcrumb that precedes the Cluster G
block below the extracted region.

Spine + seams: the spine symbols (`REPO_ROOT`, `fail`, `ok`, `failures`) and the
W1 `STREAMS` core seam are imported `from .core` — the single SSOT for the spine
+ W1 seams. (`failures` is imported for the V3 failures-identity invariant —
`core.failures is per_entry_sync.failures` — matching the W2–W6 module
convention; the Cluster F bodies append via `fail()`, never rebind `failures`.)
Standard-library `os`, `re`, `subprocess`, `tempfile`, and `Path` are imported
directly at module top, mirroring the established per-module convention (the
spine `import *` does not re-export stdlib names).
"""

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
    failures,
)

# The per-entry shell library path (read only by Check 33's TOC-regenerator
# invocation). Derived from the `from .core import REPO_ROOT` binding — the
# single SSOT for the repo root — mirroring its prior facade derivation.
PER_ENTRY_LIB = REPO_ROOT / "scripts" / "lib" / "per-entry"


# ── Check 32′: no pack monolith exists (BD-203, inverts BD-168 Check 32) ───
#
# BD-203 retires the old "mirror-in-sync" Check 32 and REPLACES it with an
# inverted guard. Under the no-mirror model a pack stream's per-entry tree
# (+ `_toc.md`) is the SOLE source of truth + readable form; there is NO
# regenerated monolithic mirror to be "in sync" with. The guard's job
# therefore inverts to: for each pack stream whose tree is present, assert
# the monolith file is ABSENT and the `_rules.md` + `_toc.md` supporting
# files are present. The check still SKIPs when the tree is absent
# (pre-conversion state), so it is vacuously satisfied today (tree absent)
# and PASSES by construction at the post-conversion end-state (tree present
# + monolith deleted). See ARCHITECTURE-BD-203-V3.md §4 (Check 32′).


def _list_unknown_files(stream_dir: Path, entry_regex: str,
                        known_supporting: set) -> list:
    """List basenames in `stream_dir` that are neither known supporting
    files (e.g. `_rules.md`, `_intro.md`, `_toc.md`) nor matching the
    entry regex. Used by Check 32 pre-check (b) — non-conforming
    filenames per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.4.
    (Post-BD-203 B8 there is no `_v8-resolved-archive.md` supporting
    file — the BD-001..019 entries are now normal per-entry files — so
    it is no longer a known-supporting basename; see the
    `known_supporting_for` set in `check_mirror_in_sync`.)
    """
    if not stream_dir.is_dir():
        return []
    pattern = re.compile(entry_regex)
    unknown = []
    for child in sorted(stream_dir.iterdir()):
        if not child.is_file():
            continue
        name = child.name
        if name in known_supporting:
            continue
        if pattern.match(name):
            continue
        unknown.append(name)
    return unknown


# BD-211: canonical per-entry line-2 header for ID-shaped streams —
# `**<ID>-NNN — <Title>**` where <ID> is BD or TD. NO letter suffix and
# NO pre-em-dash parenthetical qualifier (a parenthetical, if present, is
# TITLE TEXT after the em-dash). Used by the Check 32′ header guard.
_CANON_HEADER_RE = re.compile(r"^\*\*(?:BD|TD)-\d+ — .+\*\*$")

# BD-204 Mode-3 ops contract (ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md
# §4.2): per-stream required mode marker in `_rules.md`. Check 32′
# asserts marker/heading PRESENCE only — never prose-pinning
# (anti-fragility). Allowlist sized to exactly the two pack streams
# (measure-then-bound; project streams gain theirs at BD-206/207 and are
# NOT asserted here). Flat-file per-entry is the sole supported mode, so
# `pack-backlog` declares only the "Flat-file mode" marker.
_RULES_MODE_MARKERS = {
    "pack-backlog":   ("Flat-file mode",),
    "pack-changelog": ("Mode invariance",),
}


def _stream_is_id_shaped(entry_regex: str) -> bool:
    """Return True iff `entry_regex` is an `[A-Z]+-\\d+`-shaped ID stream
    (pack-backlog / project-backlog) vs a version-shaped stream
    (pack-changelog `^v\\d+\\.md$`). Derived from the SAME STREAMS
    `entry_regex` the filename loop consumes — the single source of
    stream-applicability for both the filename conformance check and the
    BD-211 canonical-header guard (enumerate-encoding-surfaces: no
    hard-coded "pack-backlog" in two places). The canonical ID streams
    anchor their filename regex on an uppercase letter run before the
    digit run; version streams anchor on a literal `v`.
    """
    return bool(re.match(r"^\^[A-Z]+-", entry_regex))


def check_mirror_in_sync() -> None:
    """Check 32′ — no pack monolith exists (BD-203; inverts BD-168 Check 32).

    For each pack-side stream in STREAMS:

      - SKIP if the per-entry tree directory is absent (pre-conversion
        pack-self / pre-v11.0 client). Vacuously satisfied today.

      - Assert the monolith file (the stream's former `mirror_relative`)
        is ABSENT. Under the no-mirror model the tree is the SOLE SSOT;
        a monolith co-existing with a tree is the wrong-model state the
        check now forbids. FAIL if the monolith is present.

      - Assert `_rules.md` is present (the per-entry contract SSOT).

      - Assert `_rules.md` carries the stream's required mode marker(s)
        (BD-204 Mode-3 ops contract; `_RULES_MODE_MARKERS` — marker
        presence only, never prose-pinning).

      - Assert `_toc.md` is present (the no-mirror readable index).

      - Assert per-entry filenames conform to the stream's entry regex
        (a useful tree-integrity invariant); FAIL on non-conforming
        filenames.

    Never regenerates a mirror — under no-mirror there is nothing to
    regenerate or sync.
    """
    print("\n── Check 32′: no pack monolith exists (BD-203) ──")

    # The set of known supporting basenames a pack stream may carry.
    # Mirrors `pe_supporting_files_known_for_stream` in
    # `scripts/lib/per-entry/_lib.sh` (kept in lockstep).
    known_supporting_for = {
        "pack-backlog":   {"_rules.md", "_intro.md", "_toc.md"},
        "pack-changelog": {"_rules.md", "_intro.md", "_toc.md"},
    }

    for stream_key, stream_rel, mirror_rel, entry_regex in STREAMS:
        stream_dir = REPO_ROOT / stream_rel
        mirror_path = REPO_ROOT / mirror_rel

        if not stream_dir.is_dir():
            ok(
                f"{stream_rel}/ — not present (skipping; pre-conversion "
                f"pack-self or pre-v11.0 client)"
            )
            continue

        # Inverted assertion: the tree is present, so the monolith MUST
        # be absent (no-mirror SSOT).
        if mirror_path.is_file():
            fail(
                f"{mirror_rel} still present while {stream_rel}/ tree "
                f"exists — under the no-mirror model the per-entry tree "
                f"(+ _toc.md) is the SOLE source of truth; delete the "
                f"monolith ({mirror_rel}) so the tree is the only SSOT"
            )
            continue

        # _rules.md must exist (per-entry contract SSOT).
        rules_path = stream_dir / "_rules.md"
        if not rules_path.is_file():
            fail(
                f"{stream_rel}/_rules.md missing — required for the "
                f"per-entry contract (the sole rules SSOT)"
            )
            continue

        # BD-204 Mode-3 ops contract: required mode marker(s) in _rules.md
        # (marker presence only — see _RULES_MODE_MARKERS above). The
        # pack-backlog contract must carry the "Flat-file mode" heading
        # (flat-file per-entry is the sole supported mode); the
        # pack-changelog contract must carry the "Mode invariance" marker.
        required_markers = _RULES_MODE_MARKERS.get(stream_key, ())
        if required_markers:
            try:
                rules_text = rules_path.read_text(
                    encoding="utf-8", errors="replace")
            except OSError:
                rules_text = ""
            missing_markers = [m for m in required_markers
                               if m not in rules_text]
            if missing_markers:
                fail(
                    f"{stream_rel}/_rules.md missing required mode "
                    f"marker(s) {missing_markers} — the Mode-3 ops "
                    f"contract (BD-204) requires the mode-conditional "
                    f"sections; restore the marker heading(s)"
                )
                continue

        # _toc.md must exist (no-mirror readable index).
        toc_path = stream_dir / "_toc.md"
        if not toc_path.is_file():
            fail(
                f"{stream_rel}/_toc.md missing — required as the "
                f"no-mirror readable index (regenerate via "
                f"per_entry_regenerate_toc {stream_key} {stream_dir})"
            )
            continue

        # Filename conformance (tree-integrity invariant).
        known_supporting = known_supporting_for.get(stream_key, set())
        unknown = _list_unknown_files(stream_dir, entry_regex, known_supporting)
        if unknown:
            fail(
                f"{stream_rel}/: non-conforming filenames: "
                f"{unknown} — entry regex {entry_regex!r}; supporting "
                f"basenames {sorted(known_supporting)}"
            )
            continue

        # BD-211: canonical line-2 header guard. For each ID-shaped
        # stream (derived from the SAME entry_regex the filename loop
        # uses — version-shaped streams like pack-changelog are SKIPped
        # so the version grammar is never mis-asserted), the line-2 bold
        # header (BELOW the line-1 `<!-- per-entry source: ... -->`
        # back-pointer) MUST match `**<ID>-NNN — <Title>**` with NO
        # letter suffix and NO pre-em-dash parenthetical. This is the
        # tree-integrity invariant "the FILENAME is the ID, the HEADER
        # must match the ID-grammar".
        if _stream_is_id_shaped(entry_regex):
            bad_headers = []
            for child in sorted(stream_dir.iterdir()):
                if not child.is_file():
                    continue
                name = child.name
                if name in known_supporting:
                    continue
                if not re.compile(entry_regex).match(name):
                    continue
                try:
                    with open(child, "r", encoding="utf-8", newline="") as f:
                        lines = f.read().splitlines()
                except OSError:
                    continue
                # Line 2 is the bold header below the line-1 back-pointer.
                header = lines[1] if len(lines) >= 2 else ""
                if not _CANON_HEADER_RE.match(header):
                    bad_headers.append((name, header))
            if bad_headers:
                detail = "; ".join(
                    f"{n}: {h!r}" for n, h in bad_headers
                )
                fail(
                    f"{stream_rel}/: non-canonical line-2 header(s) "
                    f"(BD-211 — must be `**<ID>-NNN — <Title>**`, NO "
                    f"letter suffix, NO pre-em-dash parenthetical): "
                    f"{detail}"
                )
                continue

        ok(
            f"{stream_rel}/ — no monolith present; _rules.md + _toc.md "
            f"present; filenames conform (no-mirror SSOT)"
        )


# ── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ────

def check_toc_in_sync() -> None:
    """Check 33 — per-entry `_toc.md` is in-sync with per-entry tree (BD-168).

    Same SKIP behavior as Check 32 (no per-entry tree → SKIP per
    integration parent §10.5). Invokes the BD-164 TOC regenerator
    against the on-disk tree, snapshotting the on-disk `_toc.md`,
    asking the helper to regenerate in place, then comparing the
    post-helper `_toc.md` to the snapshot. Restore on either path so
    the working tree is unchanged.

    Failure mode: developer hand-edited `_toc.md`, OR forgot to invoke
    the TOC regenerator after editing the per-entry tree.

    Recovery: re-run the TOC regenerator and re-commit.
    """
    print("\n── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──")

    for stream_key, stream_rel, _mirror_rel, _entry_regex in STREAMS:
        stream_dir = REPO_ROOT / stream_rel

        if not stream_dir.is_dir():
            ok(
                f"{stream_rel}/ — not present (skipping; pre-v11.0 "
                f"client or pre-BD-102 dog-food pack-self per integration "
                f"parent §10.5)"
            )
            continue

        # If _rules.md absent the stream is malformed; Check 32
        # already FAILed with the same diagnostic — emit a brief skip
        # here so Check 33 doesn't double-fail on the same condition.
        if not (stream_dir / "_rules.md").is_file():
            ok(
                f"{stream_rel}/_toc.md — skipped (Check 32 already "
                f"reported missing _rules.md)"
            )
            continue

        toc_path = stream_dir / "_toc.md"

        # M2 (BD-168 retro fix): create the snap in the system tempdir
        # (`dir=None`), NOT under `stream_dir/`. Rationale: a SIGKILL
        # between mkstemp() and the finally-block cleanup would leave a
        # leftover `.per-entry-toc-snap.XXXXXX.md` inside `stream_dir/`,
        # which Check 32 pre-check (b) (`_list_unknown_files`) would
        # flag as a non-conforming filename on the next CI run. The
        # snap is read-only consumed (no atomic rename across
        # filesystems required), so cross-filesystem placement is fine.
        snap_fd, snap_path = tempfile.mkstemp(
            prefix=".per-entry-toc-snap.", suffix=".md",
            dir=None,
        )
        try:
            os.close(snap_fd)
            had_existing_toc = toc_path.is_file()
            if had_existing_toc:
                snap_data = toc_path.read_bytes()
                Path(snap_path).write_bytes(snap_data)
            else:
                snap_data = None

            quoted_args = " ".join(
                f"'{a}'" for a in [stream_key, str(stream_dir)]
            )
            script = (
                f". '{PER_ENTRY_LIB}/_lib.sh' && "
                f". '{PER_ENTRY_LIB}/toc-regenerate.sh' && "
                f"per_entry_regenerate_toc {quoted_args}"
            )
            # S5 (BD-168 retro fix): any audit-trail stderr the helper
            # emits (Addendum #2 §4.5 anchored on the migrator path) is
            # captured but INTENTIONALLY discarded on the success-with-
            # divergence path below — in CI the validator's FAIL
            # message IS the audit trail. Documented for future readers.
            result = subprocess.run(
                ["bash", "-c", script],
                capture_output=True,
                text=True,
                stdin=subprocess.DEVNULL,
            )
            if result.returncode != 0:
                # Restore on-disk (if any) before failing. Use
                # write_bytes() not replace() so the restore is
                # cross-filesystem safe (the snap may now live in the
                # system tempdir per M2 retro fix; `os.rename` would
                # raise EXDEV if /tmp is on a different FS).
                if had_existing_toc:
                    toc_path.write_bytes(snap_data)
                fail(
                    f"{stream_rel}/_toc.md: regenerator failed "
                    f"(rc={result.returncode}); stderr: "
                    f"{result.stderr.strip()}"
                )
                continue

            new_data = toc_path.read_bytes() if toc_path.is_file() else None
            if had_existing_toc and new_data == snap_data:
                # In sync — leave the file untouched.
                Path(snap_path).unlink()
                ok(
                    f"{stream_rel}/_toc.md byte-identical "
                    f"({len(new_data)} bytes)"
                )
            elif not had_existing_toc and new_data is not None:
                # The on-disk tree had no _toc.md but the regenerator
                # produced one — that itself is a divergence (TOC
                # missing from the committed tree).
                toc_path.unlink()  # restore tree to original (no TOC)
                fail(
                    f"{stream_rel}/_toc.md absent — run "
                    f"`bash -c '. scripts/lib/per-entry/_lib.sh && "
                    f". scripts/lib/per-entry/toc-regenerate.sh && "
                    f"per_entry_regenerate_toc {stream_key} "
                    f"{stream_dir}'` to materialize before committing "
                    f"(the helper is sourced-not-executed); "
                    f"restored tree to pre-check state"
                )
            else:
                # Divergence — restore the snapshot, FAIL. Use
                # write_bytes() not replace() for cross-filesystem
                # safety (snap now lives in system tempdir per M2).
                if had_existing_toc:
                    toc_path.write_bytes(snap_data)
                fail(
                    f"{stream_rel}/_toc.md is out of sync — re-run "
                    f"`bash -c '. scripts/lib/per-entry/_lib.sh && "
                    f". scripts/lib/per-entry/toc-regenerate.sh && "
                    f"per_entry_regenerate_toc {stream_key} "
                    f"{stream_dir}'` before committing (the helper is "
                    f"sourced-not-executed; the regenerator "
                    f"unconditionally overwrites the on-disk file); "
                    f"restored on-disk file to pre-check state"
                )
        finally:
            if Path(snap_path).exists():
                try:
                    Path(snap_path).unlink()
                except OSError:
                    pass


# ── Check 34: cross-reference integrity (BD-168) ───────────────────────────

# Per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §11.2, the reference
# regex matches BD-NNN, TD-NNN, vN.M (with optional `-suffix`),
# `phase-N`, and `phase-N.M`. Conservative — false positives in code
# blocks / quoted text are tolerated per §11.2.
# BD-211: the cross-ref TOKEN for BD/TD is canonical `BD-NNN` / `TD-NNN`
# — NO letter suffix (the former suffix sub-entries were folded into
# their base entries; no suffix ID exists). CROSS-SURFACE: the `TD-\d+`
# token serves the project stream. The version token after `vMAJOR.MINOR`
# carries EITHER an optional `.PATCH` segment OR a bounded release-state
# qualifier `-(?:alpha|beta|RC\d+|GA)` (alpha/beta lowercase, RC numbered,
# GA uppercase) — never both, because a PATCH is NEVER qualified. Old
# two-level `vN.M` still tokenizes (both the patch and the qualifier are
# optional).
CROSS_REF_RE = re.compile(
    r"\b("
    r"BD-\d+"
    r"|TD-\d+"
    r"|phase-\d+(?:\.\d+)?"
    r"|v\d+\.\d+(?:\.\d+|(?:-(?:alpha|beta|RC\d+|GA))?)"
    r")\b"
)

# BD-203 FLAG-b (measure-then-bound): under per-release changelog
# granularity (CHANGE 2) the pack-changelog defined-ID set is the set of
# MAJOR versions (`v11`, `v10`, … — one `vN.md` per `## vN` release). A
# point-release reference `vN.M` (e.g. `v11.0`, `v9.3`) lives INSIDE its
# major release file's body (the H2 block carries the nested `### vN.M`
# subsections verbatim — ARCHITECTURE-BD-203-V3.md §2.3). So a `vN.M`
# reference RESOLVES iff its MAJOR `vN` entry is defined. This mapping is
# sized EXACTLY to the per-release granularity decision (resolve `vN.M`
# to `vN`); it does NOT widen the allowlist to admit unclassified hits —
# a `vN.M` whose major `vN` is undefined still FAILs.
_VERSION_POINT_RE = re.compile(
    r"^v(\d+)\.\d+(?:\.\d+|(?:-(?:alpha|beta|RC\d+|GA))?)$")


def _resolves_to_defined_id(ref: str, defined_all: set,
                            loaded_prefixes: set,
                            highest_defined_major: int = None) -> bool:
    """True iff `ref` resolves to a defined entry ID OR is an out-of-scope
    cross-stream reference per the Check 34 documented contract.

    Resolution paths:
      - Direct hit in the loaded defined-ID set.
      - (BD-203 FLAG-b) a `vN.M` point-release reference whose MAJOR
        `vN` entry is defined (the point release lives inside the major
        `vN.md` release file under per-release granularity). Sized
        EXACTLY to the granularity mapping — a `vN.M` whose major is
        undefined still FAILs.
      - (BD-203 D1, measure-then-bound forward-ref tolerance) a `vN.M`
        point-release reference whose MAJOR `vN` is GREATER than the
        highest defined changelog major is a genuine FORWARD reference
        (a version that does not exist YET — e.g. "required before
        tagging v12.0" when the highest released major is v11). This is
        sized EXACTLY to `major > highest-defined-major`, NOT a token
        allowlist: a `vN.M` whose major is `<=` the highest defined but
        undefined (an in-range gap / typo) still FAILs. When no
        changelog major is loaded (`highest_defined_major is None`) this
        path does not fire.
      - (Cross-stream tolerance, §10.6 — the check's documented
        contract) a reference whose ID-prefix belongs to a stream that
        is NOT loaded is out of scope for this validation. A pack-side
        run loads only the pack streams (pack-backlog ↔ pack-changelog),
        so a `TD-` reference (project-backlog) is tolerated — the
        project tree is not present to validate against. This makes the
        implementation honor the docstring's "cross-stream references
        are tolerated" clause (previously asserted but not enforced).
    """
    if ref in defined_all:
        return True
    m = _VERSION_POINT_RE.match(ref)
    if m and f"v{m.group(1)}" in defined_all:
        return True
    # BD-203 D1 — measure-then-bound forward-ref tolerance: a `vN.M`
    # whose MAJOR `vN` exceeds the highest defined changelog major is a
    # forward reference to a version that does not exist yet (not a
    # dangling entry-ref). Sized to `major > highest-defined` — an
    # in-range-but-undefined major (a gap/typo) still FAILs.
    if (m and highest_defined_major is not None
            and int(m.group(1)) > highest_defined_major):
        return True
    # Cross-stream tolerance: if the ref's prefix is not among the
    # loaded streams' prefixes, it targets an unloaded stream (§10.6).
    if "TD-" not in loaded_prefixes and ref.startswith("TD-"):
        return True
    return False


def _collect_defined_ids(stream_key: str, stream_dir: Path,
                         entry_regex: str) -> set:
    """Collect all defined entry IDs for a stream from per-entry filenames.

    For each file in `stream_dir` matching `entry_regex`, emit the ID
    (filename minus `.md`). Per integration parent §10.3 — the
    filename IS the ID.
    """
    if not stream_dir.is_dir():
        return set()
    pattern = re.compile(entry_regex)
    defined = set()
    for child in stream_dir.iterdir():
        if not child.is_file():
            continue
        if not pattern.match(child.name):
            continue
        defined.add(child.name[:-3])  # strip .md
    return defined


def _extract_references(text: str) -> list:
    """Extract (ref, line_no) pairs from `text` matching CROSS_REF_RE.

    Note: post-BD-203 B8 there is no `_v8-resolved-archive.md` SKIP — the
    BD-001..019 entries are now normal per-entry files, so no v8-archive
    supporting file is emitted. The caller's walk loop in
    `check_cross_reference_integrity` skips leading-underscore supporting
    files generically (`startswith("_")`), which covers any such file
    without a special case. (An earlier draft also carried a defensive
    in-text `skip_v8_archive` parameter that suppressed references after
    any line matching `^## Resolved — v\\d+\\b`; that parameter was
    removed per BD-168 retro fix N2 because the file-level skip is
    sufficient and the in-text version risked false negatives in
    per-entry pack-changelog files that might legitimately carry a
    `## Resolved — v11.0` H2 in their bodies.)
    """
    refs = []
    for line_no, line in enumerate(text.splitlines(), start=1):
        for match in CROSS_REF_RE.finditer(line):
            refs.append((match.group(1), line_no))
    return refs


def check_cross_reference_integrity() -> None:
    """Check 34 — cross-reference integrity (BD-168).

    Pseudo-code sketches the behavioral contract; planner refines exact
    implementation (per Addendum #1 §9.2 disclaimer).

    For each pack-side stream with a per-entry tree present:

      - Collect defined IDs: the filename of every entry file that
        matches the stream's entry regex (filename minus `.md` IS the
        ID per integration parent §10.3).

      - Walk every per-entry file in the stream; extract references
        matching CROSS_REF_RE (`BD-NNN`, `TD-NNN`, `vN.M`,
        `phase-N[.M]`); for each reference, FAIL with the offending
        file + line number + ref if the ref is not in the union of
        defined IDs across all loaded streams.

      - Supporting files (leading-underscore basenames such as
        `_toc.md`) are not walked. (Post-BD-203 B8 there is no
        `_v8-resolved-archive.md` archive file — the BD-001..019 entries
        are now normal per-entry files — so the former §11.3 archive SKIP
        is dead; the generic leading-underscore guard covers any such
        supporting file.)

    Cross-stream references are tolerated (a pack BD referencing a
    project TD is out of scope for pack-side validation per §10.6).
    Cross-stream references within the LOADED set (pack-backlog ↔
    pack-changelog) ARE validated since both streams are loaded.

    SKIP gracefully when no per-entry tree exists (per integration
    parent §10.5).
    """
    print("\n── Check 34: cross-reference integrity (BD-168) ──")

    # Build the union of defined IDs across loaded streams.
    defined_by_stream = {}
    any_stream_present = False
    for stream_key, stream_rel, _mirror_rel, entry_regex in STREAMS:
        stream_dir = REPO_ROOT / stream_rel
        if not stream_dir.is_dir():
            continue
        any_stream_present = True
        defined_by_stream[stream_key] = _collect_defined_ids(
            stream_key, stream_dir, entry_regex
        )

    if not any_stream_present:
        ok(
            "no per-entry trees present (skipping; pre-v11.0 client or "
            "pre-BD-102 dog-food pack-self per integration parent §10.5)"
        )
        return

    defined_all = set()
    for ids in defined_by_stream.values():
        defined_all |= ids

    # BD-203 D1 — compute the highest defined changelog MAJOR once (the
    # pack-changelog defined IDs are `vN`; parse the integer N from each
    # `^v\d+$` member). Used by `_resolves_to_defined_id` to tolerate a
    # genuine `vN.M` FORWARD reference (major > highest-defined). `None`
    # when no changelog major is loaded (the forward-ref path then does
    # not fire). Sized to the forward-ref category, never a token list.
    _major_re = re.compile(r"^v(\d+)$")
    _defined_majors = [
        int(mm.group(1)) for did in defined_all
        for mm in (_major_re.match(did),) if mm
    ]
    highest_defined_major = max(_defined_majors) if _defined_majors else None

    # The ID-prefixes of the LOADED streams (for cross-stream tolerance,
    # §10.6). A reference whose prefix is not loaded targets an unloaded
    # stream and is out of scope. Map each loaded stream key to its
    # reference-token prefix.
    _stream_prefix = {
        "pack-backlog": "BD-",
        "pack-changelog": "v",
        "project-backlog": "TD-",
        "project-implementation-plan": "phase-",
        "project-changelog": "",
    }
    loaded_prefixes = {
        _stream_prefix[k] for k in defined_by_stream
        if k in _stream_prefix
    }

    # BD-203 B8: the former `_v8-resolved-archive.md` SKIP is DEAD — the
    # 19 BD-001..019 entries are now normal `BD-00N.md` per-entry files
    # (pre-normalize Commit 1), so no v8-archive supporting file is
    # emitted. Any leading-underscore supporting file is already skipped
    # by the `startswith("_")` guard below; no special-case basename set
    # is needed.

    any_dangling = False
    total_files = 0
    total_refs = 0

    for stream_key, stream_rel, _mirror_rel, entry_regex in STREAMS:
        stream_dir = REPO_ROOT / stream_rel
        if not stream_dir.is_dir():
            continue

        pattern = re.compile(entry_regex)
        # Walk per-entry files (NOT supporting files like _toc.md /
        # _rules.md / _intro.md — those are not entry content).
        for child in sorted(stream_dir.iterdir()):
            if not child.is_file():
                continue
            if child.name.startswith("_"):
                # Other supporting files (e.g., _toc.md) — not entry
                # content; out of scope per integration parent §10.3
                # ("Walk every per-entry file").
                continue
            if not pattern.match(child.name):
                # Non-conforming files are reported by Check 32; skip
                # here to avoid double-reporting.
                continue

            total_files += 1
            try:
                text = child.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                fail(
                    f"{child.relative_to(REPO_ROOT)}: unable to read for "
                    f"cross-reference scan"
                )
                any_dangling = True
                continue

            refs = _extract_references(text)
            total_refs += len(refs)
            seen_ids_this_file = set()
            for ref, line_no in refs:
                if _resolves_to_defined_id(
                    ref, defined_all, loaded_prefixes,
                    highest_defined_major,
                ):
                    continue
                # Self-reference (a file referencing its own ID) is
                # always defined — the ID lives in the filename.
                self_id = child.name[:-3]
                if ref == self_id:
                    continue
                # Track distinct dangling refs per file for clearer
                # output (don't flood with one FAIL per repeat).
                key = (ref, line_no)
                if key in seen_ids_this_file:
                    continue
                seen_ids_this_file.add(key)
                fail(
                    f"{child.relative_to(REPO_ROOT)}:{line_no} references "
                    f"{ref} — no matching entry file found in the loaded "
                    f"per-entry streams (defined-IDs scope: pack-backlog + "
                    f"pack-changelog per integration parent §10.6); fix "
                    f"the reference or restore the missing entry"
                )
                any_dangling = True

    if not any_dangling:
        # Suppress the per-stream OK line if no streams had files;
        # the any_stream_present guard above already SKIPed cleanly.
        if total_files > 0:
            ok(
                f"cross-reference integrity: {total_refs} reference(s) "
                f"across {total_files} per-entry file(s); all resolved "
                f"to defined IDs (or self-reference; leading-underscore "
                f"supporting files are not walked)"
            )


__all__ = [
    "PER_ENTRY_LIB",
    "_list_unknown_files",
    "_CANON_HEADER_RE",
    "_RULES_MODE_MARKERS",
    "_stream_is_id_shaped",
    "check_mirror_in_sync",
    "check_toc_in_sync",
    "CROSS_REF_RE",
    "_VERSION_POINT_RE",
    "_resolves_to_defined_id",
    "_collect_defined_ids",
    "_extract_references",
    "check_cross_reference_integrity",
]
