"""validate_checks.pack_ops_hygiene — Checks 86, 87, 88: pack-ops runtime-surface
git-tracked-state hygiene guards (BD-224).

This module owns the three BD-224 /pack-dashboard git-hygiene guards — cheap
git-TRACKED-state screens over the pack-ops runtime surface introduced by BD-224:

  - Check 86 (`check_dashboard_approvals_file_cap`): caps the git-TRACKED
    `pack-ops/dashboard-approvals/` set at EXACTLY {dashboard.html,
    dashboard-url.txt, dashboard-shell.html} (all-three-or-none first-commit
    atomicity — design §11.2 Check A / F12).
  - Check 87 (`check_session_config_not_committed`): asserts the per-clone
    runtime `pack-ops/session-config.json` (gitignored) is never git-TRACKED
    (design §11.2 Check B).
  - Check 88 (`check_dashboard_approvals_spec_shell_sync`): when the tracked shell
    `pack-ops/dashboard-approvals/dashboard-shell.html` exists, asserts its
    embedded `spec-sha` HTML comment matches `git hash-object` of the tracked
    build-spec `pack-ops/DASHBOARD-SPEC-PACK.md` — a declare-verify-backing
    sync-guard that fails loud on a committed stale shell (render-cache;
    architecture §9).

The three form a connected component per the FIRM own-module-per-new-check
convention (`scripts/lib/validate_checks/README.md` § "The FIRM CONVENTION"):
they share their module-private `_git_ls_files()` helper — Check 88 additionally
uses the module-private `_git_hash_object()` helper — with EACH OTHER, and NOTHING
with any existing cluster (they do NOT read `_load_fixture_names` / any Cluster-J
symbol; their candidate surfaces — pack-ops/dashboard-approvals/ +
pack-ops/session-config.json + pack-ops/DASHBOARD-SPEC-PACK.md — differ from every
cluster's set). So the cluster gets its OWN module rather than joining
`fixtures.py` or `singletons.py`. This is the second post-split realized consumer
of that convention (after BD-222's `wired_test_fragility.py`; see
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md` § 8). It also
satisfies PLAN-BD224.md R7's ONLY load-bearing constraint — keep the guards OUT of
`boundary_refs.py` so a future boundary-refs edit never shares a file with them —
because a NEW module is disjoint from `boundary_refs.py` too.

All three key on git-TRACKED paths (never a raw filesystem walk —
`ci-guard-measure-then-bound`) via the shared module-private `_git_ls_files()`
helper (a single bounded `git ls-files` subprocess) plus, for Check 88, a single
`git hash-object` subprocess (`_git_hash_object()`), so they are O(one dir) / O(1)
and SKIP-lenient off a git work tree — the `ci-guard-measure-then-bound` /
`ci-check-runtime-compounding` shape.

Bodies + the shared helpers live only here; the facade
(`scripts/validate-pack.py`) re-exports the three `check_*` via
`from validate_checks.pack_ops_hygiene import *`, so the registry assembled in the
facade (`_build_check_registry()`) keeps resolving each `check_*` name (86/87/88).
Single SSOT — no forked copy.

Spine + seam: the spine symbols (`REPO_ROOT`, `fail`, `ok`) are imported
`from .core` — the single SSOT for the spine. `_git_ls_files()` and
`_git_hash_object()` resolve the git root via `cwd=REPO_ROOT` (the module
constant), so a per-check test can monkeypatch `pack_ops_hygiene.REPO_ROOT` to a
/tmp scratch repo (the Check 63 technique). Standard-library `subprocess`, `re`,
and `pathlib` are imported directly at module top (mirroring the established
per-module convention — the spine `import *` does not re-export stdlib names). The
module is definitions + literals only (no load-time CALL), so it imports
standalone with no `NameError` (the MUST-3 load-time-order contract).

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import pathlib
import re
import subprocess

from .core import (
    REPO_ROOT,
    fail,
    ok,
)


# ── Shared module-private helper (read by Checks 86, 87, and 88) ────────────
def _git_ls_files(pathspec):
    """Return `(available, tracked_paths)` for `git ls-files <pathspec>`.

    `available` is False when the `git` binary is absent OR the tree is not a git
    work tree (both ⇒ the caller SKIPs lenient — a fresh clone / non-git checkout
    is never a violation). `available` is True otherwise, with `tracked_paths` the
    list of git-TRACKED repo-relative paths matching the pathspec (possibly
    empty). Resolves the git root via `cwd=REPO_ROOT` (the module constant) so a
    per-check test can monkeypatch `pack_ops_hygiene.REPO_ROOT` to a /tmp scratch
    repo (the Check 63 technique). ONE bounded subprocess; O(files under the
    pathspec); never a whole-tree scan, never a subprocess-per-entry.
    """
    try:
        result = subprocess.run(
            ["git", "ls-files", pathspec],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        return (False, [])
    if result.returncode != 0:
        return (False, [])
    return (True, [line for line in result.stdout.splitlines() if line.strip()])


# Check 86: the approvals dir is capped at EXACTLY these three tracked files. The
# legitimate set is sized to precisely three (measure-then-bound; at HEAD the dir
# is absent, so the tracked set is empty and the guard SKIPs). An EXTRA tracked
# file (registry creep) FAILs; a MISSING file (any strict subset of the trio
# tracked) FAILs — the missing-file teeth ENFORCE the all-three-or-none
# first-commit atomicity (F12: the first approvals-dir commit MUST stage ALL THREE
# files; any lone / partial tracked subset trips the cap).
_CHECK_86_APPROVALS_DIR = "pack-ops/dashboard-approvals"
_CHECK_86_EXPECTED = (
    "pack-ops/dashboard-approvals/dashboard.html",
    "pack-ops/dashboard-approvals/dashboard-url.txt",
    "pack-ops/dashboard-approvals/dashboard-shell.html",
)


def check_dashboard_approvals_file_cap() -> None:
    """Check 86 — pack-ops/dashboard-approvals/ holds exactly three files (BD-224).

    BD-224 /pack-dashboard guard (design §11.2 Check A). The approvals dir is a
    three-file surface — `dashboard.html` (the rendered dashboard), `dashboard-url.
    txt` (the published URL), and `dashboard-shell.html` (the spec-derived, reused
    render shell). This guard caps the git-TRACKED set at EXACTLY those three names
    so neither registry creep (an extra tracked file) nor a half-written first
    commit (only a strict subset tracked) can slip in.

    all-three-or-none first-commit atomicity (design §11.2 F12): the missing-file
    teeth mean the FIRST approvals-dir commit must stage ALL THREE files together —
    any strict subset (e.g. a lone tracked `dashboard.html`) FAILs the cap. The
    natural first-run flow (regenerate shell -> render HTML -> publish -> obtain
    URL -> write `dashboard-url.txt`) leaves a transient partial WORKING-tree
    state, but this guard reads git-TRACKED files, and nothing is committed until
    all three files exist — so the transient state is never a tracked state and
    never trips.

    measure-then-bound (ci-guard-measure-then-bound): the legitimate set is sized
    to EXACTLY the three names — no allowlist beyond them. Enumeration is
    git-TRACKED (`git ls-files pack-ops/dashboard-approvals/`), never a raw FS
    walk. At HEAD the dir is absent (0 tracked) so the guard SKIPs; it runs clean
    against current AND projected three-file state.

    O(one dir) cost (ci-check-runtime-compounding): one `git ls-files` prefix
    subprocess, O(files in the one dir), no subprocess-per-entry, no whole-tree
    scan. Routes through `run_check`.

    Lenient: git absent / not a git work tree ⇒ SKIP; the dir absent / untracked
    (empty tracked set) ⇒ SKIP (fresh runtime state, not a violation).
    """
    print("\n── Check 86: pack-ops/dashboard-approvals/ holds exactly three files (BD-224) ──")
    available, tracked = _git_ls_files(_CHECK_86_APPROVALS_DIR + "/")
    if not available:
        ok("git ls-files unavailable (git absent / not a git work tree) — skipping (lenient)")
        return

    tracked_set = set(tracked)
    if not tracked_set:
        ok(
            "pack-ops/dashboard-approvals/ has no tracked files (dir absent / "
            "fresh runtime state) — skipping (lenient)"
        )
        return

    expected = set(_CHECK_86_EXPECTED)
    extra = sorted(tracked_set - expected)
    missing = sorted(expected - tracked_set)
    if extra or missing:
        fail(
            f"pack-ops/dashboard-approvals/ must hold EXACTLY the three approval "
            f"files {{dashboard.html, dashboard-url.txt, dashboard-shell.html}} as "
            f"its git-TRACKED set. extra={extra} missing={missing}. An extra "
            f"tracked file is registry creep; a missing file breaks the "
            f"all-three-or-none first-commit atomicity (the first approvals-dir "
            f"commit MUST stage ALL THREE files together — design §11.2 F12). "
            f"Remediation: `git rm --cached` any extra path; stage the missing "
            f"member so the tracked set is exactly the three approval files."
        )
        return

    ok(
        "Check 86 — pack-ops/dashboard-approvals/ holds exactly "
        "{dashboard.html, dashboard-url.txt, dashboard-shell.html} (three-file "
        "cap intact; all-three-or-none atomicity satisfied)."
    )


# Check 87: the per-clone runtime session-config must never be committed. A single
# `git ls-files pack-ops/session-config.json` must be empty. This verifies the
# LOAD-BEARING reality (actually not tracked), not merely that `.gitignore` carries
# a line (declare-verify-backing).
_CHECK_87_SESSION_CONFIG = "pack-ops/session-config.json"


def check_session_config_not_committed() -> None:
    """Check 87 — pack-ops/session-config.json is never committed (BD-224).

    BD-224 git-hygiene guard (design §11.2 Check B). `pack-ops/session-config.json`
    is a per-clone runtime file (gitignored) that must NEVER leak into the repo.
    This guard FAILs loud the moment the config is git-TRACKED, so a stray
    `git add` of a per-clone-state file can never slip in.

    declare-verify-backing: the guard checks the LOAD-BEARING reality — that the
    file is actually NOT tracked — not merely that `.gitignore` carries an
    exclusion line (a necessary-but-insufficient property). A `.gitignore` line
    that is silently overridden by an earlier `git add -f` would still leak the
    file; this guard catches that.

    O(1) cost (ci-check-runtime-compounding): a single `git ls-files
    pack-ops/session-config.json` subprocess — no tree scan, no per-entry
    subprocess. Passes on an empty result. Routes through `run_check`.

    Lenient: git absent / not a git work tree ⇒ SKIP.
    """
    print("\n── Check 87: pack-ops/session-config.json is never committed (BD-224) ──")
    available, tracked = _git_ls_files(_CHECK_87_SESSION_CONFIG)
    if not available:
        ok("git ls-files unavailable (git absent / not a git work tree) — skipping (lenient)")
        return

    if tracked:
        fail(
            f"pack-ops/session-config.json is git-TRACKED ({len(tracked)} "
            f"path(s): {', '.join(tracked)}) but is a per-clone runtime file that "
            f"must NEVER be committed. Remediation: `git rm --cached "
            f"pack-ops/session-config.json` and confirm `.gitignore` excludes it."
        )
        return

    ok(
        "Check 87 — pack-ops/session-config.json is not tracked (per-clone "
        "runtime file; gitignored)."
    )


# ── Module-private git-hash helper (read by Check 88) ───────────────────────
def _git_hash_object(relpath):
    """Return `(available, sha)` for `git hash-object <relpath>` run at REPO_ROOT.

    `available` is False when the `git` binary is absent OR the target path cannot
    be hashed (absent / unreadable); `sha` is the stripped hex object id on success
    else None. Resolves the git root via `cwd=REPO_ROOT` (the module constant) —
    the SAME monkeypatch seam as `_git_ls_files()`, so a per-check test can point
    `pack_ops_hygiene.REPO_ROOT` at a /tmp scratch repo. ONE bounded subprocess;
    O(1) on a single file; never a whole-tree scan, never a subprocess-per-entry.
    """
    try:
        result = subprocess.run(
            ["git", "hash-object", relpath],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        return (False, None)
    if result.returncode != 0:
        return (False, None)
    sha = result.stdout.strip()
    return (True, sha or None)


# Check 88: the tracked render shell embeds a `spec-sha: <hex>` provenance comment
# = `git hash-object` of the build-spec at the moment the shell was generated
# (architecture §3/§4). This guard VERIFIES that declared fingerprint against the
# LOAD-BEARING spec (declare-verify-backing): when the shell is tracked, its
# embedded spec-sha MUST equal `git hash-object pack-ops/DASHBOARD-SPEC-PACK.md`.
# A mismatch means the spec changed without a re-render (a committed stale shell);
# an unhashable spec means a declared fingerprint with NO backing — both FAIL loud
# (fail-loud-delete-old-source). At HEAD the dir/shell is absent so the guard
# SKIPs (measure-then-bound; runs clean against the projected present-shell state).
_CHECK_88_SHELL = "pack-ops/dashboard-approvals/dashboard-shell.html"
_CHECK_88_SPEC = "pack-ops/DASHBOARD-SPEC-PACK.md"
_CHECK_88_SPEC_SHA_RE = re.compile(r"spec-sha:\s*([0-9a-f]{40,64})")


def check_dashboard_approvals_spec_shell_sync() -> None:
    """Check 88 — dashboard-shell.html spec-sha matches DASHBOARD-SPEC-PACK.md (BD-224).

    BD-224 render-cache sync-guard (architecture §9). The committed render shell
    `pack-ops/dashboard-approvals/dashboard-shell.html` carries an embedded
    `spec-sha: <hex>` HTML comment = `git hash-object` of the build-spec at
    generation time (architecture §3). This guard is the fail-loud complement to
    the §4 render-time self-heal: when the shell is git-TRACKED, its declared
    spec-sha MUST equal `git hash-object` of the tracked build-spec
    `pack-ops/DASHBOARD-SPEC-PACK.md`; otherwise the spec changed without a
    re-render and the committed shell is stale.

    declare-verify-backing: the shell DECLARES a spec-sha; this guard VERIFIES it
    against the LOAD-BEARING spec (the real `git hash-object`), not a
    necessary-but-insufficient property. It ALSO catches the absence-of-backing
    instance (a shell that declares a spec-sha whose spec cannot be hashed) — a
    declared mapping with no backing FAILs, not only the drift case.

    measure-then-bound (ci-guard-measure-then-bound): enumeration is git-TRACKED
    (`git ls-files` for the shell), never a raw FS walk. At HEAD the dir/shell is
    absent (0 tracked) so the guard SKIPs; it runs clean against current AND the
    projected present-shell state.

    O(1) cost (ci-check-runtime-compounding): one `git ls-files` (shell tracked?)
    + one shell read + one `git hash-object` (the spec) — no tree scan, no
    per-entry subprocess. Routes through `run_check`.

    Lenient: git absent / not a git work tree ⇒ SKIP; the shell absent / untracked
    ⇒ SKIP (fresh runtime state, not a violation). FAIL only when a TRACKED shell
    declares a spec-sha that does not match (or whose spec cannot be hashed).
    """
    print("\n── Check 88: pack-ops/dashboard-approvals/dashboard-shell.html spec-sha matches DASHBOARD-SPEC-PACK.md (BD-224) ──")
    available, tracked = _git_ls_files(_CHECK_88_SHELL)
    if not available:
        ok("git ls-files unavailable (git absent / not a git work tree) — skipping (lenient)")
        return

    if _CHECK_88_SHELL not in set(tracked):
        ok(
            "pack-ops/dashboard-approvals/dashboard-shell.html is not tracked "
            "(dir/shell absent / fresh runtime state) — skipping (lenient)"
        )
        return

    shell_fs_path = pathlib.Path(REPO_ROOT) / _CHECK_88_SHELL
    try:
        shell_text = shell_fs_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        ok(
            "pack-ops/dashboard-approvals/dashboard-shell.html is tracked but "
            "unreadable on disk — skipping (lenient)"
        )
        return

    match = _CHECK_88_SPEC_SHA_RE.search(shell_text)
    if not match:
        fail(
            "pack-ops/dashboard-approvals/dashboard-shell.html is git-TRACKED but "
            "carries no `spec-sha: <hex>` provenance comment, so its build-spec "
            "fingerprint cannot be verified. Remediation: re-render via "
            "/pack-dashboard so the shell re-embeds the current `git hash-object` "
            "of pack-ops/DASHBOARD-SPEC-PACK.md."
        )
        return
    declared = match.group(1)

    hashed_available, spec_sha = _git_hash_object(_CHECK_88_SPEC)
    if not hashed_available or not spec_sha:
        fail(
            f"pack-ops/dashboard-approvals/dashboard-shell.html declares a "
            f"spec-sha ({declared}) but its backing build-spec "
            f"pack-ops/DASHBOARD-SPEC-PACK.md cannot be hashed (absent / "
            f"unreadable) — the declared fingerprint has no load-bearing backing. "
            f"Remediation: restore the build-spec, or re-render the shell against "
            f"the current spec."
        )
        return

    if declared != spec_sha:
        fail(
            f"pack-ops/dashboard-approvals/dashboard-shell.html is stale: its "
            f"embedded spec-sha ({declared}) != git hash-object of the tracked "
            f"build-spec pack-ops/DASHBOARD-SPEC-PACK.md ({spec_sha}) — spec-sha "
            f"mismatch. The build-spec changed without a re-render, so the "
            f"committed shell no longer matches the spec. Remediation: re-render "
            f"via /pack-dashboard to regenerate the shell and re-embed the current "
            f"spec-sha."
        )
        return

    ok(
        "Check 88 — pack-ops/dashboard-approvals/dashboard-shell.html spec-sha "
        f"matches git hash-object of pack-ops/DASHBOARD-SPEC-PACK.md ({spec_sha}); "
        "shell/spec in sync."
    )


# ── __all__ — the three check bodies the facade's _build_check_registry() resolves ─
# `from validate_checks.pack_ops_hygiene import *` skips underscore names UNLESS
# they are listed here; and once `__all__` is declared it ALSO gates the
# non-underscore names — so the three `check_*` (resolved by bare name in the
# facade's `_build_check_registry()`) MUST be enumerated. The module-private
# `_git_ls_files` / `_git_hash_object` helpers + the `_CHECK_86_*` / `_CHECK_87_*`
# / `_CHECK_88_*` constants are underscore-prefixed and NOT asserted by any test's
# facade-re-export surface (the tests only `hasattr` the three `check_*`), so —
# like examples.py's `_CHECK_64_*` privates — they stay module-internal and are
# OMITTED from `__all__` (`import *` skips underscore names regardless).
__all__ = [
    "check_dashboard_approvals_file_cap",
    "check_session_config_not_committed",
    "check_dashboard_approvals_spec_shell_sync",
]
