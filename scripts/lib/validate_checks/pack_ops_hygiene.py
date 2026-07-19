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
  - Check 88 (`check_dashboard_approvals_spec_shell_sync`): the render-cache
    DUAL-fingerprint / three-way sync-guard (BD-224 OPTION-2 reconciled model;
    ARCHITECTURE-DASHBOARD-OPTION2-RECONCILED.md §4 + §6.1). Both the committed
    build-script `scripts/dashboard-build.py` AND the runtime render shell
    `pack-ops/dashboard-approvals/dashboard-shell.html` carry a provenance line
    stamping TWO fingerprints — `spec-sha` (= `git hash-object` of the tracked
    build-spec `pack-ops/DASHBOARD-SPEC-PACK.md`, the LOGIC contract) and
    `structure-sha` (a sha256 fold of the FORMAT contract, §4.2). Three arms:
    * SCRIPT-arm (ALWAYS-ON — the script is committed source, always tracked):
      the script's embedded `{spec-sha, structure-sha}` MUST equal the freshly
      re-derived live pair. A HARD "the spec/format contract changed but the
      script was not re-stamped/reviewed" guard, never SKIP-lenient (§4.1).
    * SHELL-arm (SKIP-lenient — the shell is untracked until the first render
      commits): when the shell is tracked, its embedded `{spec-sha,
      structure-sha}` MUST equal the same live pair.
    * PAIRING-arm (both tracked): `script.{spec,structure}-sha ==
      shell.{spec,structure}-sha` — one regenerated while the other went stale
      FAILs (F10 partial-pair). declare-verify-backing: a declared fingerprint
      whose spec/format contract cannot be hashed is an absence-of-backing FAIL.

The three form a connected component per the FIRM own-module-per-new-check
convention (`scripts/lib/validate_checks/README.md` § "The FIRM CONVENTION"):
they share their module-private `_git_ls_files()` helper — Check 88 additionally
uses the module-private `_git_hash_object()` helper (spec-sha) plus the
module-private `_structure_sha()` fold + `_extract_fp()` provenance parser
(structure-sha) — with EACH OTHER, and NOTHING with any existing cluster (they do
NOT read `_load_fixture_names` / any Cluster-J symbol; their candidate surfaces —
scripts/dashboard-build.py + pack-ops/dashboard-approvals/ +
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
helper (a single bounded `git ls-files` subprocess) plus, for Check 88, three
`git hash-object` subprocesses (spec + the two per-entry `_rules.md` that seed the
`structure-sha` fold, via `_git_hash_object()` / `_structure_sha()`) + one
`pack-ops/session-state.json` read + an O(1) `from .core import
_SESSION_STATE_REQUIRED_KEYS`, so they are O(one dir) / O(1) and SKIP-lenient off a
git work tree — the `ci-guard-measure-then-bound` / `ci-check-runtime-compounding`
shape. `_structure_sha()` reproduces `scripts/dashboard-build.py`'s
`compute_structure_sha()` byte-fold EXACTLY (declare-verify-backing: the guard
recomputes the REAL live fold, not a proxy), so the script's / shell's stamped
`structure-sha` is verified against the true format contract.

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

import hashlib
import json
import pathlib
import re
import subprocess

from .core import (
    REPO_ROOT,
    _SESSION_STATE_REQUIRED_KEYS,
    fail,
    failures,
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


# ── Module-private git-hash + structure-fold helpers (read by Check 88) ─────
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


# Check 88 render-cache surfaces (BD-224 OPTION-2 reconciled model). The committed
# build-script AND the runtime render shell each stamp a DUAL fingerprint
# `{spec-sha, structure-sha}` in a provenance line; the guard re-derives both live
# and asserts three-way equality (script-arm always-on; shell-arm SKIP-lenient;
# pairing-arm when both tracked).
_CHECK_88_SCRIPT = "scripts/dashboard-build.py"
_CHECK_88_SHELL = "pack-ops/dashboard-approvals/dashboard-shell.html"
_CHECK_88_SPEC = "pack-ops/DASHBOARD-SPEC-PACK.md"
# structure-sha fold inputs (ARCHITECTURE-DASHBOARD-OPTION2-RECONCILED.md §4.2 —
# the FORMAT contract): the two per-entry `_rules.md` git-blob ids + the
# session-state `schema` token + `repr(_SESSION_STATE_REQUIRED_KEYS)`.
_CHECK_88_BACKLOG_RULES = "backlog/_rules.md"
_CHECK_88_CHANGELOG_RULES = "changelog/_rules.md"
_CHECK_88_SESSION_STATE = "pack-ops/session-state.json"
# Provenance extraction — exact-length hex so the 40-hex spec-sha and 64-hex
# structure-sha never bleed into one another (`\b` anchors the tail). "spec-sha:"
# is NOT a substring of "structure-sha:", so the spec regex never false-matches
# the structure token on the shared provenance line.
_CHECK_88_SPEC_SHA_RE = re.compile(r"spec-sha:\s*([0-9a-f]{40})\b")
_CHECK_88_STRUCT_SHA_RE = re.compile(r"structure-sha:\s*([0-9a-f]{64})\b")


def _extract_fp(text):
    """Return the declared `(spec_sha, structure_sha)` from a provenance line —
    each the hex string or None when the token is absent."""
    sm = _CHECK_88_SPEC_SHA_RE.search(text)
    stm = _CHECK_88_STRUCT_SHA_RE.search(text)
    return (sm.group(1) if sm else None, stm.group(1) if stm else None)


def _structure_sha():
    """Recompute the live `structure-sha` — the FORMAT-contract fingerprint —
    reproducing `scripts/dashboard-build.py`'s `compute_structure_sha()` byte-fold
    EXACTLY (declare-verify-backing: the guard recomputes the REAL fold, not a
    proxy). Byte-serialization (must match the script's pin byte-for-byte):

        structure_sha = sha256("".join(part + "\\n" for part in [
            git_blob_sha1(backlog/_rules.md),      # 40-hex (== `git hash-object`)
            git_blob_sha1(changelog/_rules.md),    # 40-hex
            <session-state "schema" token value>,  # e.g. pack-session-state/1
            repr(_SESSION_STATE_REQUIRED_KEYS),    # the tuple VALUE, from .core
        ]))

    Returns `(available, sha)`: `available` is False when git is absent OR any fold
    input is absent/unhashable/unparseable (⇒ the caller treats a stamped file's
    declared structure-sha as an absence-of-backing FAIL); `sha` is the 64-hex
    sha256 else None. O(1): two `git hash-object` + one JSON read + one O(1) import
    of the tuple — no tree walk, no ast (the tuple imports directly from `.core`,
    the same SSOT the script ast-extracts from `core.py`)."""
    ok1, rules_backlog = _git_hash_object(_CHECK_88_BACKLOG_RULES)
    ok2, rules_changelog = _git_hash_object(_CHECK_88_CHANGELOG_RULES)
    if not ok1 or not rules_backlog or not ok2 or not rules_changelog:
        return (False, None)
    ss_path = pathlib.Path(REPO_ROOT) / _CHECK_88_SESSION_STATE
    try:
        obj = json.loads(ss_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return (False, None)
    schema = obj.get("schema")
    if not schema:
        return (False, None)
    parts = [
        rules_backlog,
        rules_changelog,
        schema,
        repr(_SESSION_STATE_REQUIRED_KEYS),
    ]
    payload = "".join(part + "\n" for part in parts)
    return (True, hashlib.sha256(payload.encode("utf-8")).hexdigest())


def _verify_stamped_fingerprints(
    relpath, label, spec_available, live_spec_sha, struct_available, live_struct_sha
):
    """Verify one TRACKED stamped file's declared `{spec-sha, structure-sha}`
    against the freshly re-derived live pair. Appends a `fail()` per shortfall
    (missing token / absence-of-backing / mismatch) and returns the DECLARED
    `(spec_sha, structure_sha)` tuple when BOTH tokens are present (for the pairing
    arm), else None. A tracked-but-unreadable file is a lenient skip of THIS arm
    (no fail)."""
    fs_path = pathlib.Path(REPO_ROOT) / relpath
    try:
        text = fs_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        ok(f"{relpath} ({label}) is tracked but unreadable on disk — skipping this arm (lenient)")
        return None

    declared_spec, declared_struct = _extract_fp(text)
    if not declared_spec:
        fail(
            f"{relpath} ({label}) is git-TRACKED but carries no `spec-sha: <40-hex>` "
            f"provenance comment, so its build-spec fingerprint cannot be verified. "
            f"Remediation: re-stamp the provenance line with the current "
            f"`git hash-object` of pack-ops/DASHBOARD-SPEC-PACK.md."
        )
    if not declared_struct:
        fail(
            f"{relpath} ({label}) is git-TRACKED but carries no `structure-sha: "
            f"<64-hex>` provenance comment, so its format-contract fingerprint "
            f"cannot be verified. Remediation: re-stamp the provenance line with the "
            f"current structure-sha fold (the two per-entry `_rules.md` blob ids + "
            f"the session-state schema token + the required-keys tuple)."
        )

    if declared_spec:
        if not spec_available or not live_spec_sha:
            fail(
                f"{relpath} ({label}) declares a spec-sha ({declared_spec}) but its "
                f"backing build-spec pack-ops/DASHBOARD-SPEC-PACK.md cannot be hashed "
                f"(absent / unreadable) — the declared fingerprint has no "
                f"load-bearing backing. Remediation: restore the build-spec, or "
                f"re-stamp against the current spec."
            )
        elif declared_spec != live_spec_sha:
            fail(
                f"{relpath} ({label}) is stale: embedded spec-sha ({declared_spec}) "
                f"!= git hash-object of the tracked build-spec "
                f"pack-ops/DASHBOARD-SPEC-PACK.md ({live_spec_sha}) — spec-sha "
                f"mismatch. The build-spec changed without a re-stamp/re-render, so "
                f"the tracked {label} no longer matches the spec. Remediation: "
                f"re-stamp/re-render so it re-embeds the current spec-sha."
            )

    if declared_struct:
        if not struct_available or not live_struct_sha:
            fail(
                f"{relpath} ({label}) declares a structure-sha ({declared_struct}) "
                f"but the live format-contract fold cannot be computed (a "
                f"`_rules.md` / session-state input is absent / unparseable) — the "
                f"declared fingerprint has no load-bearing backing. Remediation: "
                f"restore the format-contract inputs, or re-stamp against the "
                f"current fold."
            )
        elif declared_struct != live_struct_sha:
            fail(
                f"{relpath} ({label}) is stale: embedded structure-sha "
                f"({declared_struct}) != the live format-contract fold "
                f"({live_struct_sha}) — structure-sha mismatch. A per-entry "
                f"`_rules.md`, the session-state schema token, or the required-keys "
                f"tuple changed without a re-stamp/re-render. Remediation: "
                f"re-stamp/re-render so it re-embeds the current structure-sha."
            )

    if declared_spec and declared_struct:
        return (declared_spec, declared_struct)
    return None


def check_dashboard_approvals_spec_shell_sync() -> None:
    """Check 88 — build-script + render shell {spec-sha, structure-sha} match the
    live spec + format contract (BD-224 OPTION-2 reconciled).

    BD-224 render-cache DUAL-fingerprint sync-guard
    (ARCHITECTURE-DASHBOARD-OPTION2-RECONCILED.md §4 + §6.1). The committed
    build-script `scripts/dashboard-build.py` AND the runtime render shell
    `pack-ops/dashboard-approvals/dashboard-shell.html` each stamp a provenance
    line with TWO fingerprints: `spec-sha` (= `git hash-object` of the tracked
    build-spec pack-ops/DASHBOARD-SPEC-PACK.md — the LOGIC contract) and
    `structure-sha` (a sha256 fold of the FORMAT contract — the two per-entry
    `_rules.md` blob ids + the session-state schema token + the required-keys
    tuple, §4.2). This guard re-derives BOTH fingerprints FRESH and asserts
    three-way equality:

      * SCRIPT-arm (ALWAYS-ON): the script is committed source (always tracked), so
        this arm is a HARD guard — the script's `{spec-sha, structure-sha}` MUST
        equal the live pair. It catches "the spec or format contract changed but
        the committed script was not re-stamped/reviewed" (§4.1), never SKIPs.
      * SHELL-arm (SKIP-lenient): the shell is untracked until the first render
        commits; when tracked, its `{spec-sha, structure-sha}` MUST equal the live
        pair.
      * PAIRING-arm (both tracked): `script.{spec,structure}-sha ==
        shell.{spec,structure}-sha` — one regenerated while the other went stale
        FAILs (F10 partial-pair).

    declare-verify-backing: each stamped file DECLARES a `{spec-sha, structure-sha}`
    pair; this guard VERIFIES both against the LOAD-BEARING SSOTs (the real
    `git hash-object` of the spec + the real recomputed structure fold), not a
    necessary-but-insufficient property. It ALSO catches absence-of-backing (a
    declared fingerprint whose spec/format contract cannot be hashed) — a declared
    mapping with no backing FAILs, not only the drift case.

    measure-then-bound (ci-guard-measure-then-bound): enumeration is git-TRACKED
    (`git ls-files` for the script + the shell), never a raw FS walk. At HEAD the
    shell is absent (shell-arm SKIPs) while the committed script is tracked
    (script-arm runs); the guard runs clean against current AND the projected
    present-shell state.

    O(1) cost (ci-check-runtime-compounding): two `git ls-files` + ≤2 stamped-file
    reads + three `git hash-object` (spec + two `_rules.md`) + one JSON read + one
    O(1) import of the required-keys tuple — no tree scan, no per-entry subprocess.
    Routes through `run_check`.

    Lenient: git absent / not a git work tree ⇒ SKIP the whole check; neither the
    script nor the shell tracked ⇒ SKIP (fresh state, not a violation); a tracked
    stamped file that is unreadable ⇒ SKIP that arm. FAIL only when a TRACKED
    stamped file declares a fingerprint that does not match (or whose backing
    cannot be hashed), or the script/shell pair diverges.
    """
    print(
        "\n── Check 88: scripts/dashboard-build.py + dashboard-shell.html "
        "{spec-sha, structure-sha} match DASHBOARD-SPEC-PACK.md + the live format "
        "contract (BD-224) ──"
    )
    # git-availability gate (one probe; both arms + the fold need a git work tree).
    available, script_tracked = _git_ls_files(_CHECK_88_SCRIPT)
    if not available:
        ok("git ls-files unavailable (git absent / not a git work tree) — skipping (lenient)")
        return
    _, shell_tracked = _git_ls_files(_CHECK_88_SHELL)

    script_present = _CHECK_88_SCRIPT in set(script_tracked)
    shell_present = _CHECK_88_SHELL in set(shell_tracked)
    if not script_present and not shell_present:
        ok(
            "neither the committed build-script scripts/dashboard-build.py nor the "
            "render shell pack-ops/dashboard-approvals/dashboard-shell.html is "
            "tracked (fresh state) — skipping (lenient)"
        )
        return

    # Live fingerprints, re-derived ONCE and shared by every arm.
    spec_available, live_spec_sha = _git_hash_object(_CHECK_88_SPEC)
    struct_available, live_struct_sha = _structure_sha()

    pre = len(failures)
    script_fp = None
    shell_fp = None

    # ── SCRIPT-arm (always-on: the committed source is always tracked) ──
    if script_present:
        script_fp = _verify_stamped_fingerprints(
            _CHECK_88_SCRIPT, "committed build-script",
            spec_available, live_spec_sha, struct_available, live_struct_sha,
        )

    # ── SHELL-arm (SKIP-lenient: the shell is untracked until the first render) ──
    if shell_present:
        shell_fp = _verify_stamped_fingerprints(
            _CHECK_88_SHELL, "render shell",
            spec_available, live_spec_sha, struct_available, live_struct_sha,
        )

    # ── PAIRING-arm (both tracked): the script + shell fingerprints must agree ──
    if script_fp and shell_fp and script_fp != shell_fp:
        fail(
            f"pack-ops/dashboard-approvals/dashboard-shell.html {{spec-sha, "
            f"structure-sha}} = {shell_fp} != scripts/dashboard-build.py {script_fp} "
            f"— the committed build-script and the render shell carry a DIVERGENT "
            f"fingerprint pair (one was regenerated while the other went stale). "
            f"Remediation: re-render via /pack-dashboard so the shell re-embeds the "
            f"same {{spec-sha, structure-sha}} as the committed script."
        )

    if len(failures) == pre:
        scope = []
        if script_present:
            scope.append("script-arm")
        if shell_present:
            scope.append("shell-arm")
        if script_present and shell_present:
            scope.append("pairing-arm")
        ok(
            "Check 88 — {spec-sha, structure-sha} in sync ("
            + ", ".join(scope)
            + f"): spec-sha {live_spec_sha}, structure-sha {live_struct_sha}."
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
