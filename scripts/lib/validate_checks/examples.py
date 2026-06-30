"""validate_checks.examples — Cluster K: the example/artifact-hygiene family (BD-256 W12).

This module owns Cluster K's 2 check bodies (Checks 63, 64) — the
deliverable-artifact backstop guards: the graphify-out/ never-tracked git-hygiene
gate (63, BD-225: a cheap O(1) `git ls-files graphify-out/` screen that FAILs loud
the moment the per-clone Graphify knowledge-graph build artifact is committed) and
the dangling-`.example` deliverable referential-integrity gate (64, BD-231: a
bounded matcher over the three-member MCP/config `.example` family that FAILs when
a deliverable doc cites a `.example` whose `project-template/` target is absent).
The two are co-located because both key on the deliverable/build-artifact surface
resolved through `REPO_ROOT`.

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.examples import *`,
so the registry assembled in the facade (`_build_check_registry()`) keeps
resolving each `check_*` name (63/64). Single SSOT — no forked copy.

Intra-cluster symbols moved with the bodies (read only by Cluster K checks):
the `_CHECK_64_EXAMPLE_FAMILY` / `_CHECK_64_REF_PATTERN` / `_CHECK_64_EXCLUDE_PREFIXES`
/ `_CHECK_64_INCLUDE_TREES` constants and the `_check_64_basename_for` helper —
all read only by Check 64 (verified by grep at the extraction wave: no check
outside Cluster K reads them), so no core promotion is needed — they are
Cluster-K-owned, not a >=2-module seam. They are underscore-prefixed and NOT
asserted by the tests' facade-re-export surface (the W12 tests only `hasattr` the
two `check_*` names), so they are deliberately OMITTED from `__all__` (a declared
`__all__` gates non-underscore names too, but these are underscore-prefixed and
`import *` skips them regardless — they stay module-internal). The W12 test sites
(`test-validate-pack-check-63.sh` / `-64.sh`) are reworked in the same commit:
each `mod.REPO_ROOT` save/patch/restore triple converts to the wave-invariant
`_patch_root(mod, root)` helper (form B), because Checks 63/64 now read
`examples.REPO_ROOT` and a facade-only patch would no longer bite.

Spine + seam: the spine symbols (`REPO_ROOT`, `fail`, `ok`, `failures`) are
imported `from .core` — the single SSOT for the spine + W1 seams. (`failures`
is imported for the V3 failures-identity invariant — `core.failures is
examples.failures` — matching the W2–W11 module convention; the Cluster K bodies
append via `fail()`, never rebind `failures`.) Standard-library `re` and
`subprocess` and `pathlib.Path` are imported directly at module top (Check 63 uses
`subprocess.run`; Check 64 uses `re.compile`/`re`-pattern scanning and a
`list[Path]` annotation), mirroring the established per-module convention (the
spine `import *` does not re-export stdlib names).

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import re
import subprocess
from pathlib import Path

from .core import (
    REPO_ROOT,
    fail,
    ok,
    failures,
)


def check_graphify_out_never_tracked() -> None:
    """Check 63 — graphify-out/ is never tracked (BD-225).

    BD-225 git-hygiene guard (design §5.2). `graphify-out/` is the Graphify
    knowledge-graph build artifact — a per-clone, regenerated directory that
    must NEVER be committed (it is gitignored by the `.gitignore` entry C1
    declares). This check is the CI enforcement that pairs with that
    `.gitignore` entry: it FAILs loud the moment any `graphify-out/` path is
    tracked, so a stray `git add` of the build artifact can never slip in.

    Measure-then-bound (ci-guard-measure-then-bound): the guard's matching
    logic — `git ls-files graphify-out/` — returns 0 rows at HEAD, so the
    legitimate tracked-graph-artifact set is EMPTY. There is nothing to
    allowlist; the guard runs CLEAN against current AND projected-post-C1
    state, and the allowlist is sized to exactly zero.

    O(1) cost (ci-check-runtime-compounding): a SINGLE `git ls-files
    graphify-out/` subprocess — NO tree scan, NO per-entry subprocess storm.
    The cost is ~0 regardless of the battery's per-invocation multiplier.
    Routes through `run_check`.

    Resolves the git root via `cwd=REPO_ROOT` (the module-level constant) so
    the per-check test can monkeypatch `mod.REPO_ROOT` to a /tmp repo (N-4 —
    mirrors the Check 62 test's technique).

    Lenient ONLY if `git` itself is unavailable (mirrors Check 62's
    lenient-skip); never swallows a real "tracked path found" failure.
    """
    print("\n── Check 63: graphify-out/ is never tracked (BD-225) ──")
    try:
        result = subprocess.run(
            ["git", "ls-files", "graphify-out/"],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        ok("git not available — skipping (lenient)")
        return
    if result.returncode != 0:
        ok("git ls-files unavailable (not a git work tree) — skipping (lenient)")
        return

    tracked = [line for line in result.stdout.splitlines() if line.strip()]
    if tracked:
        fail(
            f"graphify-out/ has {len(tracked)} tracked path(s): "
            f"{', '.join(tracked)}. graphify-out/ is the Graphify knowledge-graph "
            f"build artifact — a per-clone, regenerated directory that must NEVER "
            f"be committed. Remediation: `git rm -r --cached graphify-out/` and "
            f"confirm `.gitignore` carries `graphify-out/`."
        )
        return
    ok("Check 63 — graphify-out/ is not tracked (gitignored build artifact; "
       "0 tracked paths).")


# ── Check 64 (BD-231): dangling-.example deliverable referential-integrity gate.
# The MCP/config `.example` family the BD cares about. Each member is a
# `project-template/`-rooted dotfile-`.example` whose BASENAME is cited across
# the deliverable surface (README layout block + project-template/** +
# supporting-docs/**). The matcher is BOUNDED to exactly this family
# (ci-guard-measure-then-bound): a single compiled alternation over the three
# basenames, NOT an over-broad `\b\S+\.example\b` sweep that would re-classify
# unrelated `.example` cites. Closes the Check-43 leading-dot-dotfile blind spot
# (DESIGN-BD-231 §4.1: `_CHECK_40_BARE_REF_PATTERN` requires `[A-Za-z]` first,
# so a leading-dot `.mcp.json.example` token is NEVER matched by Check 43).
_CHECK_64_EXAMPLE_FAMILY = (
    ".mcp.json.example",
    ".agents/mcp_config.json.example",
    ".codex/config.toml.example",
)
# Match either the full relative path or the bare basename for each family
# member (docs cite both forms — e.g. `.mcp.json.example` and
# `.agents/mcp_config.json.example`).
_CHECK_64_REF_PATTERN = re.compile(
    r"(?:\.agents/mcp_config\.json\.example"
    r"|\.codex/config\.toml\.example"
    r"|\.mcp\.json\.example"
    r"|\bmcp_config\.json\.example"
    r"|\bconfig\.toml\.example)"
)
# EXCLUDE path-prefixes (DESIGN-BD-231 §4.3): history is immutable, pack-only
# surfaces are not client deliverables, and the fixture trees are synthetic.
# Relative-to-REPO_ROOT POSIX prefixes.
_CHECK_64_EXCLUDE_PREFIXES = (
    "changelog/",
    "backlog/",
    "pack-ops/",
    "maintenance-docs/",
    "test-fixtures/",
    "scripts/tests/fixtures/",
    ".git/",
)
# The deliverable surface walked (DESIGN-BD-231 §4.3 INCLUDE): pack-root
# README.md (its project-template/ layout block), project-template/**,
# supporting-docs/**. README is included as a single file (only its layout
# block cites the family); the two trees are walked recursively.
_CHECK_64_INCLUDE_TREES = ("project-template", "supporting-docs")


def _check_64_basename_for(token: str) -> str:
    """Map a matched ref token to the family member basename it denotes."""
    if token.endswith("mcp_config.json.example"):
        return ".agents/mcp_config.json.example"
    if token.endswith("config.toml.example"):
        return ".codex/config.toml.example"
    return ".mcp.json.example"


def check_dangling_example_deliverable_refs() -> None:
    """Check 64 — no dangling MCP/config `.example` reference in deliverable docs (BD-231).

    Referential-integrity gate (DESIGN-BD-231 §4). For the MCP/config
    `.example` family — `.mcp.json.example` (Claude), `.agents/mcp_config.json
    .example` (Antigravity), `.codex/config.toml.example` (Codex) — every cite
    on the DELIVERABLE surface (pack-root `README.md` layout block,
    `project-template/**`, `supporting-docs/**`) MUST resolve to an existing
    file under `project-template/`. A cite of a family member whose target file
    is ABSENT is a dangling reference -> FAIL with `file:line` + the dangling
    token + a restore-or-drop remediation.

    Why a NEW check, not Check 43 (DESIGN-BD-231 §4.1): Check 43's
    `_CHECK_40_BARE_REF_PATTERN` requires the first char to be `[A-Za-z]`, so a
    leading-dot dotfile like `.mcp.json.example` is NEVER matched, and
    `.example` is not in `_CHECK_40_FILE_EXTS`. Check 43's green status is
    therefore NOT evidence these refs resolve — it is blind to them. This check
    is the targeted matcher that closes that blind spot.

    measure-then-bound (ci-guard-measure-then-bound): the matcher is bounded to
    exactly the three-member MCP/config family (`_CHECK_64_REF_PATTERN`), NOT an
    over-broad `.example` sweep; the surface is bounded to the deliverable
    INCLUDE trees minus the EXCLUDE path-prefixes (history / pack-only /
    fixtures). Every KEEP cite auto-passes once its target exists — there is no
    basename allowlist that could silently admit a real dangling ref; the only
    bound is the EXCLUDE list.

    Cheap (ci-check-runtime-compounding): a single bounded walk over README +
    project-template/** + supporting-docs/** with ONE compiled-regex scan per
    line — no whole-tree scan, no per-entry subprocess. Routes through
    `run_check`.

    Resolves all paths via `REPO_ROOT` (the module-level constant) so the
    per-check test can monkeypatch `mod.REPO_ROOT` to a /tmp fixture root and
    exercise the dangling-ref FAIL path without touching the real tree.
    """
    print("\n── Check 64: no dangling MCP/config .example deliverable refs (BD-231) ──")

    # The legitimate target set: family members that actually exist under
    # project-template/. A cite resolves iff its basename is present here.
    present_targets = set()
    for rel in _CHECK_64_EXAMPLE_FAMILY:
        if (REPO_ROOT / "project-template" / rel).is_file():
            present_targets.add(rel)

    def _excluded(rel_posix: str) -> bool:
        return any(rel_posix.startswith(p) for p in _CHECK_64_EXCLUDE_PREFIXES)

    # Build the bounded deliverable file set.
    walked: list[Path] = []
    readme = REPO_ROOT / "README.md"
    if readme.is_file():
        walked.append(readme)
    for tree in _CHECK_64_INCLUDE_TREES:
        root = REPO_ROOT / tree
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            rel_posix = path.relative_to(REPO_ROOT).as_posix()
            if _excluded(rel_posix):
                continue
            walked.append(path)

    dangling = []          # (file:line, token, basename)
    refs_checked = 0
    for path in walked:
        rel_posix = path.relative_to(REPO_ROOT).as_posix()
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue       # binary / unreadable file — nothing to cite
        for lineno, line in enumerate(text.splitlines(), start=1):
            for m in _CHECK_64_REF_PATTERN.finditer(line):
                token = m.group(0)
                basename = _check_64_basename_for(token)
                refs_checked += 1
                if basename not in present_targets:
                    dangling.append((f"{rel_posix}:{lineno}", token, basename))

    if dangling:
        for loc, token, basename in dangling:
            fail(
                f"{loc} — dangling MCP/config .example reference `{token}`: "
                f"the cited deliverable template `project-template/{basename}` "
                f"does NOT exist. Remediation: restore "
                f"`project-template/{basename}` OR drop the cite. (BD-231 Check 64)"
            )
        return

    ok(
        f"Check 64 — {len(walked)} deliverable file(s) walked; {refs_checked} "
        f"MCP/config .example reference(s) checked; every cite resolves to an "
        f"existing project-template/ template ({len(present_targets)} family "
        f"target(s) present)."
    )


# ── __all__ — every Cluster-K-OWNED symbol the facade / the tests reach ─────
# `from validate_checks.examples import *` skips underscore names UNLESS they are
# listed here; and once `__all__` is declared it ALSO gates the non-underscore
# names — so the two `check_*` (resolved by bare name in the facade's
# `_build_check_registry()`) MUST be enumerated. The Cluster-K-exclusive
# `_CHECK_64_*` constants + `_check_64_basename_for` helper are underscore-prefixed
# AND not asserted by the W12 tests' facade-re-export surface (the tests only
# `hasattr` the two `check_*` names), so they are deliberately OMITTED — they stay
# module-internal (read only by Check 64 inside this module). The `from .core`
# spine (`REPO_ROOT`, `fail`, `ok`, `failures`) is NOT re-listed — those are
# core-owned (the facade re-exports them via `from validate_checks.core import *`);
# `__all__` enumerates only examples's OWN symbols.
__all__ = [
    # ── Cluster K check bodies (63, 64) ──
    "check_graphify_out_never_tracked",
    "check_dangling_example_deliverable_refs",
]
