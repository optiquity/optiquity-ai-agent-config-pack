"""validate_checks.fixtures — Cluster J: the fixture-cohesion family (BD-256 W11).

This module owns Cluster J's 2 check bodies (Checks 61, 62) — the test-fixture
backstop guards: the fixture-dependent-test LOCATION gate (61, BD-219: a test
that depends on a built `test-fixtures/<NAME>` fixture MUST live under
`scripts/tests/fixture-dependent/` so the CI partitioner pins it into the single
fixture-building shard) and the manifest STRUCTURAL well-formedness screen (62,
BD-228: a cheap row-count / row-name / 40-hex-SHA screen on
`test-fixtures/manifest.txt`, the always-run companion to the authoritative
`build.sh --verify` rebuild). The two are co-located because they both key on the
single fixture surface — the build.sh FIXTURE_NAMES set — and share the
`_load_fixture_names()` parser.

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.fixtures import *`,
so the registry assembled in the facade (`_build_check_registry()`) keeps
resolving each `check_*` name (61/62). Single SSOT — no forked copy.

Intra-cluster symbols moved with the bodies (read only by Cluster J checks):
the `_load_fixture_names()` helper (parses the `readonly FIXTURE_NAMES=( ... )`
array out of `test-fixtures/build.sh`; the H2 backstop signal source for Check 61
and the oracle for Check 62). Both checks call it; no check outside Cluster J
reads it (verified by grep at the extraction wave: the only consumers of
`_load_fixture_names` are Checks 61 and 62), so no core promotion is needed — it
is Cluster-J-owned, not a >=2-module seam. The W11 test sites
(`test-validate-pack-check-61.sh` / `-62.sh`) are reworked in the same commit:
each file's single `mod.REPO_ROOT` save/patch/restore triple converts to the
wave-invariant `_patch_root(mod, root)` helper (form B), because Checks 61/62
now read `fixtures.REPO_ROOT` and a facade-only patch would no longer bite.

Spine + seam: the spine symbols (`REPO_ROOT`, `fail`, `ok`, `failures`) are
imported `from .core` — the single SSOT for the spine + W1 seams. (`failures`
is imported for the V3 failures-identity invariant — `core.failures is
fixtures.failures` — matching the W2–W10 module convention; the Cluster J bodies
append via `fail()`, never rebind `failures`.) Standard-library `re` is imported
directly at module top (both checks use `re.search` / `re.findall` /
`re.compile` / `re.DOTALL`), mirroring the established per-module convention (the
spine `import *` does not re-export stdlib names).

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import re

from .core import (
    REPO_ROOT,
    fail,
    ok,
    failures,
)


# ── Check 61: fixture-dependent test location backstop (BD-219 redesign) ────
#
# The BD-219 dynamic-autoregen redesign uses LOCATION-based fixture cohesion:
# a test that depends on a BUILT fixture (test-fixtures/<name>/, a gitignored
# build artifact) MUST live under scripts/tests/fixture-dependent/, so the
# partitioner auto-pins it into the single shard that builds fixtures. A
# fixture-dependent test SAVED ELSEWHERE would land in a non-fixture shard and
# either redden CI (loud) or silently SKIP (effectiveness loss). This backstop
# converts "saved in the wrong dir" from a silent-SKIP / CI-RED surprise into a
# named, early, fix-recipe'd guard hit.
#
# Signal (H2 lower-bound, measure-then-bound): a KEEP test whose BODY references
# a built `test-fixtures/<NAME>` path where NAME is a build.sh FIXTURE_NAMES
# entry. False positives (a prose/comment mention that is NOT a real fixture
# dependency) are designed to ZERO on the current tree by rewording the two
# benign comment mentions (pack-help-test.sh, test-migrate-v10-to-v11-decompose.sh)
# so they do not name a FIXTURE_NAMES fixture verbatim — Check 61 needs NO
# exempt list. If a NEW non-fixture test legitimately must name a FIXTURE_NAMES
# path in prose, reword the mention (the cheap, drift-free fix) rather than
# widening this guard.


def _load_fixture_names():
    """Return the build.sh FIXTURE_NAMES set (the H2 backstop signal source).

    Single source: parse the `readonly FIXTURE_NAMES=( ... )` array in
    test-fixtures/build.sh. Returns an empty set if the file or array is absent
    (the caller treats an empty set as "no signal" → lenient SKIP).
    """
    build_sh = REPO_ROOT / "test-fixtures" / "build.sh"
    if not build_sh.is_file():
        return set()
    text = build_sh.read_text()
    m = re.search(r"readonly\s+FIXTURE_NAMES=\((.*?)\)", text, re.DOTALL)
    if not m:
        return set()
    return set(re.findall(r'"([^"]+)"', m.group(1)))


def check_fixture_dependent_location() -> None:
    """Check 61 — fixture-dependent tests live under fixture-dependent/ (BD-219).

    BD-219 dynamic-autoregen redesign backstop. Fixture cohesion is LOCATION-
    based: a test that depends on a built fixture MUST live under
    scripts/tests/fixture-dependent/ (the partitioner pins everything there into
    the single fixture-building shard). This guard catches a fixture-dependent
    test saved in the WRONG directory before it can ship as a silent-SKIP or a
    CI-RED surprise.

    For each KEEP test (disk glob − allowlist) whose BODY references a built
    `test-fixtures/<NAME>` path (NAME ∈ build.sh FIXTURE_NAMES) AND is NOT under
    scripts/tests/fixture-dependent/ → FAIL naming the file + the remediation
    "move it to scripts/tests/fixture-dependent/".

    False-positive bound (measure-then-bound): the only NON-fixture-dependent
    tests that name a FIXTURE_NAMES path do so in benign comments; those
    comments are reworded in the same commit so this guard has ZERO false
    positives and needs NO exempt list. The 5 genuinely-fixture-dependent tests
    live under fixture-dependent/ and so do NOT trigger the backstop.

    Cheap (ci-check-runtime-compounding): three dir globs + one small read +
    one regex per KEEP file (same cost class as Check 42); no subprocess, no
    real-tree scan. Routes through `run_check`.

    Lenient: if build.sh / FIXTURE_NAMES is absent (no signal) → SKIP.
    """
    print("\n── Check 61: fixture-dependent tests live under fixture-dependent/ (BD-219) ──")
    scripts_dir = REPO_ROOT / "scripts"
    tests_dir = scripts_dir / "tests"
    fxdep_dir = tests_dir / "fixture-dependent"
    allowlist_path = scripts_dir / "ci-test-wiring-allowlist.txt"

    fixture_names = _load_fixture_names()
    if not fixture_names:
        ok("test-fixtures/build.sh FIXTURE_NAMES absent — skipping (lenient)")
        return

    # Disk KEEP set — same three explicit non-recursive dirs as Check 42.
    disk_paths = set()
    for p in scripts_dir.glob("test*.sh"):
        disk_paths.add(f"scripts/{p.name}")
    if tests_dir.is_dir():
        for p in tests_dir.glob("*.sh"):
            disk_paths.add(f"scripts/tests/{p.name}")
    if fxdep_dir.is_dir():
        for p in fxdep_dir.glob("*.sh"):
            disk_paths.add(f"scripts/tests/fixture-dependent/{p.name}")
    if not disk_paths:
        ok("no scripts/test*.sh or scripts/tests/*.sh present — skipping (lenient)")
        return

    allowlist = set()
    if allowlist_path.is_file():
        for raw in allowlist_path.read_text().splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            allowlist.add(line.split()[0])
    keep = sorted(disk_paths - allowlist)

    # H2 signal: a body reference to test-fixtures/<NAME> for a FIXTURE_NAMES
    # NAME. Anchor the path so a bare `test-fixtures/manifest.txt` or
    # `test-fixtures/<non-FIXTURE_NAMES>/` does not match.
    names_alt = "|".join(re.escape(n) for n in sorted(fixture_names))
    signal = re.compile(r"test-fixtures/(?:" + names_alt + r")(?:[/\"' ]|$)")

    prefix = "scripts/tests/fixture-dependent/"
    misplaced = []
    for rel in keep:
        if rel.startswith(prefix):
            continue  # correctly placed — location is the cohesion signal
        try:
            body = (REPO_ROOT / rel).read_text()
        except OSError:
            continue
        if signal.search(body):
            misplaced.append(rel)

    if misplaced:
        for rel in misplaced:
            fail(
                f"{rel} — references a built fixture (test-fixtures/<FIXTURE_NAME>) "
                f"but is NOT under scripts/tests/fixture-dependent/. The BD-219 "
                f"CI partitioner uses LOCATION-based fixture cohesion: a "
                f"fixture-dependent test MUST live under "
                f"scripts/tests/fixture-dependent/ so it is pinned into the "
                f"single shard that builds fixtures. Remediation: move it to "
                f"scripts/tests/fixture-dependent/ (and fix its `../` repo-root "
                f"depth). If the reference is a benign prose/comment mention "
                f"(NOT a real fixture dependency), reword the comment so it does "
                f"not name a FIXTURE_NAMES fixture verbatim."
            )
        return

    ok(
        f"Check 61 — {len(keep)} KEEP test(s) scanned; every test that "
        f"references a built fixture lives under scripts/tests/fixture-dependent/"
        f" (location-based cohesion intact; zero misplaced fixture tests)."
    )


def check_manifest_structural() -> None:
    """Check 62 — test-fixtures/manifest.txt is structurally well-formed (BD-228).

    BD-228 push-time-manifest method backstop (design §3.2). A CHEAP structural
    well-formedness SCREEN on the committed manifest — NOT the authoritative
    SHA-correctness gate. The authoritative gate stays the existing CI
    `test-fixtures/build.sh --verify` step (DESIGN §3.1), which rebuilds the
    fixtures and compares each row's SHA against the freshly-built fixture HEAD.
    Check 62 only catches a truncated / garbled / wrong-row-count / wrong-name /
    non-hex manifest INSTANTLY in the always-run `validate` job, before the
    expensive rebuild runs.

    It deliberately does NOT assert SHA-CORRECTNESS (only that each SHA is a
    40-hex token), so a comment-only edit to a fixture input that legitimately
    leaves the manifest unchanged is never a false positive (DESIGN §3.2(ii)).

    Asserts (on test-fixtures/manifest.txt, skipping `#`/blank lines):
      (a) exactly len(FIXTURE_NAMES) data rows (== 7 on the current tree);
      (b) the row NAMES, as a SET, equal `_load_fixture_names()`
          (the build.sh FIXTURE_NAMES set — the single source of truth);
      (c) each row is `<name>  <sha>` and the SHA matches `^[0-9a-f]{40}$`.

    Cheap (ci-check-runtime-compounding): ONE small file read + a per-line
    regex over the 7-row manifest + reuse of the existing `_load_fixture_names()`
    helper. NO fixture rebuild, NO subprocess, NO subprocess-per-entry, NO
    whole-real-tree scan — negligible cost across the ~155-invocation battery.
    Routes through `run_check`.

    Lenient: if build.sh / FIXTURE_NAMES is absent (no signal source) → SKIP
    (mirrors the Check 61 lenient pattern; the names set is the screen's oracle).
    """
    print("\n── Check 62: test-fixtures/manifest.txt is structurally well-formed (BD-228) ──")
    manifest_path = REPO_ROOT / "test-fixtures" / "manifest.txt"
    expected_names = _load_fixture_names()
    if not expected_names:
        ok("test-fixtures/build.sh FIXTURE_NAMES absent — skipping (lenient)")
        return
    if not manifest_path.is_file():
        fail(
            "test-fixtures/manifest.txt is MISSING but build.sh FIXTURE_NAMES is "
            "present. The committed manifest is the only product of build.sh and "
            "MUST exist. Remediation: run `bash test-fixtures/build.sh --all "
            "--clean` (or `bash scripts/manifest-sync.sh`) and commit the result."
        )
        return

    sha_re = re.compile(r"^[0-9a-f]{40}$")
    seen_names = []
    for lineno, raw in enumerate(manifest_path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) != 2:
            fail(
                f"test-fixtures/manifest.txt line {lineno}: expected exactly two "
                f"whitespace-separated fields `<fixture-name>  <sha>`, got "
                f"{len(parts)}: {line!r}. The manifest is generated by build.sh; "
                f"do not hand-edit — run `bash scripts/manifest-sync.sh`."
            )
            continue
        name, sha = parts
        if not sha_re.match(sha):
            fail(
                f"test-fixtures/manifest.txt line {lineno}: SHA {sha!r} for "
                f"fixture {name!r} is not a 40-character lowercase hex git SHA "
                f"(^[0-9a-f]{{40}}$). Check 62 is a structural screen; "
                f"SHA-correctness is enforced by `build.sh --verify` in CI."
            )
        seen_names.append(name)

    expected_count = len(expected_names)
    if len(seen_names) != expected_count:
        fail(
            f"test-fixtures/manifest.txt has {len(seen_names)} data row(s); "
            f"expected exactly {expected_count} (one per build.sh FIXTURE_NAMES "
            f"entry). The manifest is generated by build.sh; do not hand-edit — "
            f"run `bash scripts/manifest-sync.sh`."
        )

    seen_set = set(seen_names)
    if seen_set != expected_names:
        missing = sorted(expected_names - seen_set)
        extra = sorted(seen_set - expected_names)
        fail(
            f"test-fixtures/manifest.txt row names do not match build.sh "
            f"FIXTURE_NAMES. missing={missing} extra={extra}. The manifest's "
            f"fixture names must be exactly the build.sh FIXTURE_NAMES set; run "
            f"`bash scripts/manifest-sync.sh` to regenerate."
        )

    if seen_set == expected_names and len(seen_names) == expected_count:
        ok(
            f"Check 62 — test-fixtures/manifest.txt structurally well-formed: "
            f"{expected_count} data row(s), names == build.sh FIXTURE_NAMES, "
            f"every SHA a 40-hex token (structural screen only; SHA-correctness "
            f"enforced by `build.sh --verify` in CI)."
        )


# ── __all__ — every Cluster-J-OWNED symbol the facade / the tests reach ─────
# `from validate_checks.fixtures import *` skips underscore names UNLESS they are
# listed here; and once `__all__` is declared it ALSO gates the non-underscore
# names — so the two `check_*` (resolved by bare name in the facade's
# `_build_check_registry()`) MUST be enumerated. The Cluster-J-exclusive helper
# `_load_fixture_names` is underscore-prefixed (so `import *` would skip it) but
# the W11 test (`test-validate-pack-check-61.sh` Group 0) asserts the facade
# re-exports it (`required = [..., '_load_fixture_names']`), so it is enumerated
# here to keep the facade's public surface byte-stable. The `from .core` spine
# (`REPO_ROOT`, `fail`, `ok`, `failures`) is NOT re-listed — those are core-owned
# (the facade re-exports them via `from validate_checks.core import *`); `__all__`
# enumerates only fixtures's OWN symbols.
__all__ = [
    # ── Cluster-J-exclusive helper (read by Checks 61 and 62) ──
    "_load_fixture_names",
    # ── Cluster J check bodies (61, 62) ──
    "check_fixture_dependent_location",
    "check_manifest_structural",
]
