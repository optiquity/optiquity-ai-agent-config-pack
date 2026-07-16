"""validate_checks.pack_ops_hygiene — Checks 86, 87: pack-ops runtime-surface
git-tracked-state hygiene guards (BD-224).

This module owns the two BD-224 /pack-dashboard git-hygiene guards — cheap
git-TRACKED-state screens over the pack-ops runtime surface introduced by BD-224:

  - Check 86 (`check_dashboard_approvals_two_file_cap`): caps the git-TRACKED
    `pack-ops/dashboard-approvals/` set at EXACTLY {dashboard.html,
    dashboard-url.txt} (both-or-neither first-commit atomicity — design §11.2
    Check A / F12).
  - Check 87 (`check_session_config_not_committed`): asserts the per-clone
    runtime `pack-ops/session-config.json` (gitignored) is never git-TRACKED
    (design §11.2 Check B).

The two form a NEW 2-check connected component per the FIRM
own-module-per-new-check convention (`scripts/lib/validate_checks/README.md`
§ "The FIRM CONVENTION"): they share EXACTLY one module-level non-`core` symbol —
their own module-private `_git_ls_files()` helper — with EACH OTHER, and NOTHING
with any existing cluster (they do NOT read `_load_fixture_names` / any Cluster-J
symbol; their candidate surfaces — pack-ops/dashboard-approvals/ +
pack-ops/session-config.json — differ from every cluster's set). So the cluster
gets its OWN module rather than joining `fixtures.py` or `singletons.py`. This is
the second post-split realized consumer of that convention (after BD-222's
`wired_test_fragility.py`; see
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md` § 8). It also
satisfies PLAN-BD224.md R7's ONLY load-bearing constraint — keep the guards OUT of
`boundary_refs.py` so a future boundary-refs edit never shares a file with them —
because a NEW module is disjoint from `boundary_refs.py` too.

Both key on git-TRACKED paths (never a raw filesystem walk —
`ci-guard-measure-then-bound`) via the shared module-private `_git_ls_files()`
helper (a single bounded `git ls-files` subprocess), so they are O(one dir) / O(1)
and SKIP-lenient off a git work tree — the `ci-guard-measure-then-bound` /
`ci-check-runtime-compounding` shape.

Bodies + the shared helper live only here; the facade
(`scripts/validate-pack.py`) re-exports the two `check_*` via
`from validate_checks.pack_ops_hygiene import *`, so the registry assembled in the
facade (`_build_check_registry()`) keeps resolving each `check_*` name (86/87).
Single SSOT — no forked copy.

Spine + seam: the spine symbols (`REPO_ROOT`, `fail`, `ok`) are imported
`from .core` — the single SSOT for the spine. `_git_ls_files()` resolves the git
root via `cwd=REPO_ROOT` (the module constant), so a per-check test can
monkeypatch `pack_ops_hygiene.REPO_ROOT` to a /tmp scratch repo (the Check 63
technique). Standard-library `subprocess` is imported directly at module top
(mirroring the established per-module convention — the spine `import *` does not
re-export stdlib names). The module is definitions + literals only (no load-time
CALL), so it imports standalone with no `NameError` (the MUST-3 load-time-order
contract).

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import subprocess

from .core import (
    REPO_ROOT,
    fail,
    ok,
)


# ── Shared module-private helper (read by Checks 86 and 87) ─────────────────
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


# Check 86: the approvals dir is capped at EXACTLY these two tracked files. The
# legitimate set is sized to precisely two (measure-then-bound; at HEAD the dir is
# absent, so the tracked set is empty and the guard SKIPs). An EXTRA tracked file
# (registry creep) FAILs; a MISSING file (only one of the pair tracked) FAILs —
# the missing-file teeth ENFORCE the both-or-neither first-commit atomicity (F12:
# the first approvals-dir commit MUST stage BOTH files; a lone tracked file trips
# the cap).
_CHECK_86_APPROVALS_DIR = "pack-ops/dashboard-approvals"
_CHECK_86_EXPECTED = (
    "pack-ops/dashboard-approvals/dashboard.html",
    "pack-ops/dashboard-approvals/dashboard-url.txt",
)


def check_dashboard_approvals_two_file_cap() -> None:
    """Check 86 — pack-ops/dashboard-approvals/ holds exactly two files (BD-224).

    BD-224 /pack-dashboard guard (design §11.2 Check A). The approvals dir is a
    two-file surface — `dashboard.html` (the rendered dashboard) + `dashboard-url.
    txt` (the published URL). This guard caps the git-TRACKED set at EXACTLY those
    two names so neither registry creep (an extra tracked file) nor a half-written
    first commit (only one of the pair tracked) can slip in.

    both-or-neither first-commit atomicity (design §11.2 F12): the missing-file
    teeth mean the FIRST approvals-dir commit must stage BOTH files together — a
    lone tracked `dashboard.html` (or lone `dashboard-url.txt`) FAILs the cap. The
    natural first-run flow (render HTML -> publish -> obtain URL -> write
    `dashboard-url.txt`) leaves a transient single-file WORKING-tree state, but
    this guard reads git-TRACKED files, and nothing is committed until both files
    exist — so the transient state is never a tracked state and never trips.

    measure-then-bound (ci-guard-measure-then-bound): the legitimate set is sized
    to EXACTLY the two names — no allowlist beyond them. Enumeration is
    git-TRACKED (`git ls-files pack-ops/dashboard-approvals/`), never a raw FS
    walk. At HEAD the dir is absent (0 tracked) so the guard SKIPs; it runs clean
    against current AND projected two-file state.

    O(one dir) cost (ci-check-runtime-compounding): one `git ls-files` prefix
    subprocess, O(files in the one dir), no subprocess-per-entry, no whole-tree
    scan. Routes through `run_check`.

    Lenient: git absent / not a git work tree ⇒ SKIP; the dir absent / untracked
    (empty tracked set) ⇒ SKIP (fresh runtime state, not a violation).
    """
    print("\n── Check 86: pack-ops/dashboard-approvals/ holds exactly two files (BD-224) ──")
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
            f"pack-ops/dashboard-approvals/ must hold EXACTLY the two approval "
            f"files {{dashboard.html, dashboard-url.txt}} as its git-TRACKED set. "
            f"extra={extra} missing={missing}. An extra tracked file is registry "
            f"creep; a missing file breaks the both-or-neither first-commit "
            f"atomicity (the first approvals-dir commit MUST stage BOTH files "
            f"together — design §11.2 F12). Remediation: `git rm --cached` any "
            f"extra path; stage the missing member so the tracked set is exactly "
            f"the two approval files."
        )
        return

    ok(
        "Check 86 — pack-ops/dashboard-approvals/ holds exactly "
        "{dashboard.html, dashboard-url.txt} (two-file cap intact; both-or-"
        "neither atomicity satisfied)."
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


# ── __all__ — the two check bodies the facade's _build_check_registry() resolves ─
# `from validate_checks.pack_ops_hygiene import *` skips underscore names UNLESS
# they are listed here; and once `__all__` is declared it ALSO gates the
# non-underscore names — so the two `check_*` (resolved by bare name in the
# facade's `_build_check_registry()`) MUST be enumerated. The shared
# `_git_ls_files` helper + the `_CHECK_86_*` / `_CHECK_87_*` constants are
# underscore-prefixed and NOT asserted by any test's facade-re-export surface (the
# tests only `hasattr` the two `check_*`), so — like examples.py's `_CHECK_64_*`
# privates — they stay module-internal and are OMITTED from `__all__` (`import *`
# skips underscore names regardless).
__all__ = [
    "check_dashboard_approvals_two_file_cap",
    "check_session_config_not_committed",
]
