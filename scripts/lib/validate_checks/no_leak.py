"""validate_checks.no_leak — Check 93: public-launch no-leak GUARD (BD-205).

The pack is going PUBLIC. BD-205's Wave A + B scrubbed the target application's
literal product name tree-wide and its domain vocabulary from every client/public
surface. This module is the standing ENFORCEMENT BACKSTOP that makes that scrub
un-regressable — the same "systemic ⇒ un-regressable" contract Check 92 gives the
BD-276 mktemp sweep. It has TWO legs:

  - LEG 1 (literal product name, TREE-WIDE): FAILs if the target app's literal
    product name appears in the CONTENT of ANY git-TRACKED file. The candidate set
    is `git ls-files` (never a raw FS walk) and every file's BYTES are read with
    Python — NOT `git grep`: `pack-ops/dashboard-approvals/dashboard.html` carries a
    `.gitattributes` `-diff` marker (BD-224, the minified regenerated board), which
    makes git treat it as BINARY, so `git grep -I` SILENTLY SKIPS it (the F2 blind
    spot); and `git grep -E` drops `\bOT\b` on this platform. A plain Python bytes
    read has neither blind spot. Allowlist: EMPTY (goal: grep-zero, which the
    post-Wave-A/B tree satisfies).

  - LEG 2 (domain vocabulary + `OT` codename, CLIENT/PUBLIC surfaces only): FAILs
    on any domain-vocab / hyphenated-OT / word-boundary bare-`OT` match on a
    client/public surface — `project-template/`, `supporting-docs/`, `.github/`,
    and the repo-root public files `README.md` + the pack-root trinity
    (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`). INTERNAL surfaces (`backlog/`,
    `changelog/`, `maintenance-docs/`, `test-fixtures/`) are NOT scanned by leg 2
    (their internal `OT` shorthand + the `realistic-ot` / fake-OT fixture-name
    keeps are PERMANENT — this repo is the single work repo and goes public with
    its history intact, so there is no separate scrubbed copy and the
    internal-surface exemption is a settled decision, not pending cleanup; do not
    re-open it). Allowlist: EXACTLY ONE entry (below).

The literal product name is ASSEMBLED at import from two fragments
(`_LITERAL_NAME`), so this guard's OWN source never carries — and, once the repo
is public, never LEAKS — the contiguous token, and leg 1's tree-wide scan does not
self-match this module. The same discipline governs the per-check test
(`scripts/tests/test-validate-pack-check-93.sh`): it interpolates the literal at
runtime so its own tracked bytes never carry the contiguous token.

Own-module per the FIRM own-module-per-new-check convention
(`scripts/lib/validate_checks/README.md` § "The FIRM CONVENTION"): the guard's
candidate surface (every git-tracked file / the client-surface subset) and its
module-private helpers (`_git_ls_files()`, `_is_client_surface()`,
`_mask_leg2_allowlist()`) share NOTHING with any existing cluster, so it gets its
OWN module rather than joining an unrelated cluster (the same rationale as BD-276's
`mktemp_portability.py`).

Allowlist (measure-then-bound, ci-guard-measure-then-bound): sized EXACTLY to the
one legitimate keep. A tree-wide measure at HEAD ee43bad found leg-1 = 0 and
leg-2 = exactly 1 — the `x-brokerage-api` custom-skill ROW NAME at
`project-template/docs/pack/PLATFORM-SKILLS.md` (the vocab `brokerage` is a
sub-span of that reserved `x-`-prefixed row name). That row is the OI-S7 KEEP: the
row NAME is retained as the illustrative custom-skill example (BD-088
customization-preserve sidecar tests + the `x-` reserved-prefix contract depend on
it) while its DESCRIPTION cell was scrubbed of domain specifics. The allowlist is
keyed (path -> exempt literal token), NOT (path, line-number) — line numbers drift
(architect-doc-reality-reconciliation) — and it masks ONLY the literal
`x-brokerage-api` token on ONLY that one file: a REAL domain-vocab / bare-`OT` leak
elsewhere on that same file (or anywhere else on any client surface) still FAILs.
It is deliberately NOT a broad `brokerage` exemption (which would let a real leak
through).

All git-TRACKED-enumerated (`git ls-files`, never a raw FS walk —
ci-guard-measure-then-bound), SKIP-lenient off a git work tree. Cost
(ci-check-runtime-compounding): one `git ls-files` subprocess + a single read per
tracked file; the common file (no literal, non-client) takes ONE bytes read + ONE
`in` test and is NOT line-split; only a file that carries the literal OR is a
client surface is decoded + line-scanned; leg 2 is scoped to the client/public
subset, not the whole tree. No subprocess-per-file.

Bodies + the shared helpers live only here; the facade (`scripts/validate-pack.py`)
re-exports the check via `from validate_checks.no_leak import *`, so the registry
assembled in the facade (`_build_check_registry()`) keeps resolving
`check_no_target_app_leak` (93). Single SSOT — no forked copy.

Spine: the spine symbols (`REPO_ROOT`, `fail`, `ok`) are imported `from .core` —
the single SSOT for the spine. `_git_ls_files()` resolves the git root via
`cwd=REPO_ROOT` (the module constant), so a per-check test can monkeypatch
`no_leak.REPO_ROOT` to a /tmp scratch repo (the Check 63 technique). Standard-library
`pathlib`, `re`, and `subprocess` are imported directly at module top. The module
is definitions + literals only (no load-time CALL), so it imports standalone with
no `NameError` (the MUST-3 load-time-order contract).

See `scripts/lib/validate_checks/README.md` and `backlog/BD-205.md`.
"""

import pathlib
import re
import subprocess

from .core import (
    REPO_ROOT,
    fail,
    ok,
)

# ── Leg 1: the target application's literal product name, TREE-WIDE ──────────────
# Assembled from two fragments so this module's OWN source never carries the
# contiguous token (leg 1 scans every git-tracked file, THIS module included, and
# the repo is going public — the contiguous literal must not appear in tracked
# source). `_LITERAL_NAME_BYTES` drives the cheap first-pass bytes `in` test; the
# str form drives the line-number pass only when the bytes test already hit.
_LITERAL_NAME = "Optiquity" + "Trader"
_LITERAL_NAME_BYTES = _LITERAL_NAME.encode("utf-8")

# ── Leg 2: domain vocabulary + `OT` codename, CLIENT/PUBLIC surfaces only ────────
# The client/public surface set (the pack goes public — these ship or are visible
# to clients). Prefixes match by `str.startswith`; the four repo-root files match
# by exact relpath. INTERNAL surfaces (backlog/ changelog/ maintenance-docs/
# test-fixtures/) are deliberately OUT of this set — their internal `OT` shorthand
# + fixture-name keeps are PERMANENT. This repo is the single work repo and goes
# public with its history intact; there is no separate scrubbed public copy, so
# the internal-surface exemption is settled by decision, not pending cleanup.
_CLIENT_PREFIXES = ("project-template/", "supporting-docs/", ".github/")
_CLIENT_ROOT_FILES = frozenset({"README.md", "CLAUDE.md", "AGENTS.md", "GEMINI.md"})

# Domain vocab is case-INSENSITIVE (the vocabulary can appear in any casing). The
# `OT`-codename patterns are case-SENSITIVE (the uppercase codename), matching the
# measure-then-bound sweep: a case-insensitive `OT` would match a lowercase `ot`
# substring class the scrub never targeted.
_LEG2_VOCAB_RE = re.compile(
    r"broker|brokerage|algorithmic trading|trading prototype|QuoteService|"
    r"TradingStrategy|StreamingQuoteProvider|BrokerCapabilit|Schwab|E\*Trade|"
    r"Public\.com|paper trading",
    re.IGNORECASE,
)
# Hyphenated-`OT` forms — the `(?![\w-])` bare-OT lookahead below deliberately does
# NOT fire on these (the `-` blocks it), so they get their own alternation.
_LEG2_HYPHEN_OT_RE = re.compile(r"OT-derived|real[- ]OT|FROM-OT")
# Word-boundary bare `OT` (the standalone codename): not preceded/followed by a
# word char or hyphen — so `NOT` / `PROTOCOL` / `ROOT` / `OT-derived` do NOT match.
_LEG2_BARE_OT_RE = re.compile(r"(?<![\w-])OT(?![\w-])")

# Allowlist (measure-then-bound): EXACTLY ONE entry, keyed path -> exempt literal
# token(s). The `x-brokerage-api` custom-skill ROW NAME at PLATFORM-SKILLS.md is the
# OI-S7 keep (see the module docstring). Masking ONLY that literal token on ONLY
# that file exempts the keep while leaving every other domain-vocab / bare-`OT`
# match on that same file (and every other client surface) live — NOT a broad
# `brokerage` exemption.
_LEG2_ALLOWLIST = {
    "project-template/docs/pack/PLATFORM-SKILLS.md": ("x-brokerage-api",),
}


def _git_ls_files():
    """Return `(available, paths)` for `git ls-files` (all tracked files).

    `available` is False when the `git` binary is absent OR the tree is not a git
    work tree (both ⇒ the caller SKIPs lenient — a fresh clone / non-git checkout
    is never a violation). `available` is True otherwise, with `paths` the list of
    git-TRACKED repo-relative paths. Resolves the git root via `cwd=REPO_ROOT` (the
    module constant) so a per-check test can monkeypatch `no_leak.REPO_ROOT` to a
    /tmp scratch repo (the Check 63 technique). ONE bounded subprocess; never a
    whole-tree FS walk, never a subprocess-per-entry.
    """
    try:
        result = subprocess.run(
            ["git", "ls-files"],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        return (False, [])
    if result.returncode != 0:
        return (False, [])
    return (True, [line for line in result.stdout.splitlines() if line.strip()])


def _is_client_surface(relpath):
    """True iff `relpath` is a client/public surface scanned by leg 2."""
    return relpath.startswith(_CLIENT_PREFIXES) or relpath in _CLIENT_ROOT_FILES


def _mask_leg2_allowlist(relpath, line):
    """Return `line` with this file's allowlisted literal tokens removed.

    Masking (rather than skipping the whole line) keeps leg 2 live for any OTHER
    domain-vocab / bare-`OT` match on the same line/file — only the exact exempt
    token is neutralised. Non-allowlisted files are returned unchanged.
    """
    exempt = _LEG2_ALLOWLIST.get(relpath)
    if not exempt:
        return line
    for token in exempt:
        line = line.replace(token, "")
    return line


def check_no_target_app_leak() -> None:
    """Check 93 — no target-app name/domain-vocab leak on public surfaces (BD-205).

    The public-launch no-leak GUARD. LEG 1 (tree-wide): FAILs if the target app's
    literal product name appears in ANY git-tracked file's content. LEG 2
    (client/public surfaces only): FAILs on any domain-vocab / hyphenated-OT /
    word-boundary bare-`OT` match on `project-template/`, `supporting-docs/`,
    `.github/`, or the repo-root `README.md` + pack-root trinity — EXCEPT the one
    allowlisted `x-brokerage-api` row-name keep (OI-S7).

    measure-then-bound (ci-guard-measure-then-bound): enumeration is git-TRACKED
    (`git ls-files`), never a raw FS walk; leg 1's allowlist is EMPTY (post-Wave-A/B
    the tree is grep-zero); leg 2's allowlist is sized EXACTLY to the one legitimate
    keep (path->token mask). The guard BITES the ABSENCE-of-scrub case (a
    re-introduced leak), proven by the per-check test.

    Cost (ci-check-runtime-compounding): one `git ls-files` subprocess + one read
    per tracked file; a non-client file with no literal is NOT line-split (one
    bytes `in` test); leg 2 is scoped to the client/public subset. No
    subprocess-per-file, no whole-tree FS walk.

    Lenient: git absent / not a git work tree ⇒ SKIP. A tracked file unreadable on
    disk is skipped (not a violation).
    """
    print("\n── Check 93: no target-app name/domain-vocab leak on public surfaces (BD-205) ──")
    available, files = _git_ls_files()
    if not available:
        ok("git ls-files unavailable (git absent / not a git work tree) — skipping (lenient)")
        return

    leg1_violations = []   # (relpath, lineno)
    leg2_violations = []   # (relpath, lineno, categories)

    for relpath in files:
        fs_path = pathlib.Path(REPO_ROOT) / relpath
        try:
            data = fs_path.read_bytes()
        except OSError:
            continue  # tracked but unreadable — not a violation

        client = _is_client_surface(relpath)
        has_literal = _LITERAL_NAME_BYTES in data

        # Fast path: a non-client file with no literal needs no line-level work.
        if not has_literal and not client:
            continue

        text = data.decode("utf-8", errors="replace")
        for lineno, raw in enumerate(text.splitlines(), 1):
            # LEG 1 — literal product name (tree-wide). Reported by location only;
            # the offending content (the sensitive literal) is NOT echoed.
            if has_literal and _LITERAL_NAME in raw:
                leg1_violations.append((relpath, lineno))
            # LEG 2 — domain vocab + `OT` codename (client/public surfaces only).
            if client:
                scan = _mask_leg2_allowlist(relpath, raw)
                cats = []
                if _LEG2_VOCAB_RE.search(scan):
                    cats.append("domain-vocab")
                if _LEG2_HYPHEN_OT_RE.search(scan):
                    cats.append("hyphenated-OT")
                if _LEG2_BARE_OT_RE.search(scan):
                    cats.append("bare-OT")
                if cats:
                    leg2_violations.append((relpath, lineno, ",".join(cats)))

    if leg1_violations or leg2_violations:
        if leg1_violations:
            l1 = "; ".join(f"{p}:{ln}" for p, ln in leg1_violations[:20])
            more1 = "" if len(leg1_violations) <= 20 else f" (+{len(leg1_violations) - 20} more)"
            fail(
                f"LEG 1 — {len(leg1_violations)} occurrence(s) of the target app's "
                f"literal product name in git-tracked content (location shown; the "
                f"literal is not echoed): {l1}{more1}. The pack is going PUBLIC — the "
                f"literal name must appear in ZERO tracked files (BD-205 Wave A). "
                f"Remove it from each location listed."
            )
        if leg2_violations:
            l2 = "; ".join(f"{p}:{ln} ({c})" for p, ln, c in leg2_violations[:20])
            more2 = "" if len(leg2_violations) <= 20 else f" (+{len(leg2_violations) - 20} more)"
            fail(
                f"LEG 2 — {len(leg2_violations)} target-domain-vocabulary / `OT`-codename "
                f"leak(s) on client/public surfaces: {l2}{more2}. These surfaces ship or "
                f"are visible to clients when the pack is public (BD-205 Wave B); scrub "
                f"the domain vocabulary / bare-`OT` codename. If an occurrence is a "
                f"legitimate keep, add its exact (path -> token) to the leg-2 allowlist "
                f"in scripts/lib/validate_checks/no_leak.py (never a broad exemption)."
            )
        return

    ok(
        "Check 93 — no target-app literal-name leak in any git-tracked file (leg 1, "
        "tree-wide) and no domain-vocabulary / `OT`-codename leak on client/public "
        "surfaces (leg 2, project-template/ + supporting-docs/ + .github/ + repo-root "
        "README + pack-root trinity), except the one allowlisted `x-brokerage-api` "
        "row-name keep (OI-S7). The BD-205 public-launch scrub stays enforced."
    )


# ── __all__ — the check body the facade's _build_check_registry() resolves ──────
# `from validate_checks.no_leak import *` skips underscore names UNLESS listed here;
# once `__all__` is declared it ALSO gates non-underscore names — so the `check_*`
# (resolved by bare name in the facade's `_build_check_registry()`) MUST be
# enumerated. The module-private helpers (`_git_ls_files` / `_is_client_surface` /
# `_mask_leg2_allowlist`) + constants are underscore-prefixed and NOT asserted by
# any test's facade-re-export surface (the test only `hasattr`s the `check_*`), so
# they stay module-internal and are OMITTED (`import *` skips underscore names
# regardless).
__all__ = [
    "check_no_target_app_leak",
]
