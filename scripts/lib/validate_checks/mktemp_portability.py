"""validate_checks.mktemp_portability — Check 92: BSD-mktemp `-t` portability guard
(BD-276).

This module owns the standing regression guard for the systemic BSD-mktemp `-t`
portability class swept in BD-276. The non-portable form
`mktemp [-d] -t <prefix>XXXXXX` diverges between BSD and GNU: BSD (macOS) treats
the `-t` argument as a PREFIX and appends its OWN random suffix, leaving a literal
`XXXXXX` in the path; GNU expands the `XXXXXX`. The portable form is the full-path
template `mktemp [-d] "${TMPDIR:-/tmp}/<prefix>.XXXXXX"` (both BSD and GNU expand a
full-path template). BD-276 swept every real pack-side invocation to the portable
form; THIS guard makes the class un-regressable — that is what makes BD-276
"systemic" rather than a one-time cleanup. The guard covers a SECOND, distinct
non-portable class too: the GNU-only tmpdir-specifier flags — the long option
`--tmpdir` and its short synonym `-p DIR` — which BSD/macOS mktemp lacks and errors
out on.

  - Check 92 (`check_mktemp_t_portability`): FAILs on any REAL invocation
    (command position, non-comment) in a git-TRACKED pack-side shell script of
    EITHER non-portable class: (1) the `-t <prefix>X{3,}` literal-XXXXXX form —
    INCLUDING the bundled getopt clusters `-dt` / `-qt` / `-dqt` — and (2) the
    GNU-only tmpdir specifiers `--tmpdir` and its short synonym `-p DIR` (BSD lacks
    both and errors out). Comment/doc
    MENTIONS are NOT violations (the invocation-vs-mention discipline — the same
    split BD-276's measure step used): full-line and trailing shell comments are
    stripped before matching (quote-aware, so `${#var}` / `$#` are never mistaken
    for a comment marker), and `.md` docs are never scanned (a doc code block is
    never an executed invocation).

Own-module per the FIRM own-module-per-new-check convention
(`scripts/lib/validate_checks/README.md` § "The FIRM CONVENTION"): the guard's
candidate surface (git-tracked `*.sh` shell scripts) and its module-private
helpers (`_git_ls_sh_files()`, `_strip_shell_comment()`) share NOTHING with any
existing cluster, so it gets its OWN module rather than joining an unrelated
cluster (the same rationale as BD-222's `wired_test_fragility.py` and BD-224's
`pack_ops_hygiene.py`).

Scope (measure-then-bound, pack-side): the guard enumerates git-TRACKED `*.sh`
files and EXCLUDES the `project-template/` prefix. BD-276 is a pack-only sweep
(test infra + runtime libs); project-side shell scripts ship to clients and are
validated by the client's own CI, so a project-side mktemp guard is a project-side
concern, not this pack-side check's. The sole current project-side occurrence
(`project-template/agent-run.sh:347`) is intentionally left for a separate
project-side follow-up (surfaced in the BD-276 IMPL-REPORT boundary section), NOT
silently swept into this pack-only work.

Allowlist (measure-then-bound): EMPTY. The legitimate documentation MENTIONS are
already excluded by the invocation-vs-mention logic — `.md` docs are outside the
`*.sh` candidate set, and the two pack-side `.sh` portability COMMENTS
(`scripts/tests/test-marker-preserve-bd136.sh` and
`scripts/tests/test-validate-pack-check-91.sh`) are `#`-comment lines stripped
before matching — so no path-based exemption is needed (an empty allowlist has no
blind spot). The guard's own per-check test (`test-validate-pack-check-92.sh`)
never trips it either: the test assembles its scratch buggy-invocation strings at
runtime (interpolating the `X`-run) so the test file's literal bytes never carry a
`<prefix>X{3,}` token in command position.

All git-TRACKED-enumerated (`git ls-files '*.sh'`, never a raw filesystem walk —
`ci-guard-measure-then-bound`), O(lines over the small pack-side `.sh` set), one
bounded subprocess, SKIP-lenient off a git work tree — the
`ci-check-runtime-compounding` shape.

Bodies + the shared helpers live only here; the facade
(`scripts/validate-pack.py`) re-exports the check via
`from validate_checks.mktemp_portability import *`, so the registry assembled in
the facade (`_build_check_registry()`) keeps resolving `check_mktemp_t_portability`
(92). Single SSOT — no forked copy.

Spine: the spine symbols (`REPO_ROOT`, `fail`, `ok`) are imported `from .core` —
the single SSOT for the spine. `_git_ls_sh_files()` resolves the git root via
`cwd=REPO_ROOT` (the module constant), so a per-check test can monkeypatch
`mktemp_portability.REPO_ROOT` to a /tmp scratch repo (the Check 63 technique).
Standard-library `pathlib`, `re`, and `subprocess` are imported directly at module
top. The module is definitions + literals only (no load-time CALL), so it imports
standalone with no `NameError` (the MUST-3 load-time-order contract).

See `scripts/lib/validate_checks/README.md` and `backlog/BD-276.md`.
"""

import pathlib
import re
import subprocess

from .core import (
    REPO_ROOT,
    fail,
    ok,
)

# Check 92 flags a real invocation of EITHER of TWO non-portable mktemp classes.
#
# CLASS 1 — the `-t <prefix>XXXXXX` literal-XXXXXX form. BSD (macOS) treats the
# `-t` argument as a PREFIX and appends its own random suffix, leaving a literal
# `XXXXXX` in the path. Matched in TWO steps so an `X`-run is caught wherever it
# sits in the argument (inside quotes, after a mid-token quoted variable, or bare):
#   1. `_MKTEMP_T_ARG_RE` captures a WORD-BOUNDARIED `mktemp` (`(?<![\w-])` — so
#      `foomktemp` / `x-mktemp` do NOT match) + any leading single-dash flag tokens
#      + the `-t` BEARER + the ARGUMENT WORD. The bearer is `-[a-zA-Z]*t` — a
#      SINGLE-dash cluster ending in `t`, so it catches the standalone `-t` AND the
#      BUNDLED getopt clusters `-dt` / `-qt` / `-dqt` (BSD honours them identically
#      — same literal-XXXXXX bug — but a bare `\s+-t\s+` would evade them). A
#      double-dash long option (`--tmpdir`) is NOT a `-t` bearer here (CLASS 2). The
#      arg word is a maximal run of quoted segments (`"..."` / `'...'`) and
#      non-word-boundary chars — spanning an embedded quoted variable
#      (`pack-contract-"$persona".XXXXXX`), a fully-quoted template
#      (`"cp-$fname.XXXXXX"`), and the bare form (`foo.XXXXXX`) alike — stopping only
#      at an unquoted shell word boundary (whitespace / `)` / `;` / `|` / `&` /
#      backtick).
#   2. `_XRUN_RE` then tests the captured argument for an `X`-run of >=3 (the
#      template placeholder). Splitting the two makes the X-run detectable even
#      INSIDE the quotes — a single trailing-`X{3,}` regex would be swallowed by
#      the greedy quoted-segment alternative.
#
# CLASS 2 — the GNU-only tmpdir-SPECIFIER flags: the long option `--tmpdir` /
# `--tmpdir=DIR` AND its short synonym `-p DIR`. BSD/macOS mktemp LACKS both and
# ERRORS OUT, so ANY real `mktemp … --tmpdir` / `mktemp … -p <dir>` invocation is
# non-portable regardless of a template. `_MKTEMP_TMPDIR_RE` / `_MKTEMP_P_RE` each
# match a word-boundaried `mktemp` followed (before a command terminator — the
# token run stops at `;` / `|` / `&`) by the respective flag TOKEN; NO `X`-run is
# required (the flag itself is the bug). The `-p` bearer `-[a-zA-Z]*p` is a
# SINGLE-dash cluster ending in `p` (`-p` / `-dp`), so it does NOT collide with the
# CLASS-1 `-[a-zA-Z]*t` bearer (a cluster ending in `t`) and does NOT match the
# double-dash `--tmpdir` (whose second `-` is never whitespace-preceded). The
# `[^\s;|&]+` token run means a portable `mktemp -d "$dir/x.XXXXXX"; mkdir -p …`
# does NOT trip `-p` (the `;` ends the mktemp command before the unrelated
# `mkdir -p`). A line matching more than one class yields ONE finding (the check
# body short-circuits on `flagged`).
#
# No class matches the portable full-path template
# (`mktemp [-d] "${TMPDIR:-/tmp}/foo.XXXXXX"` / `mktemp -d "$dir/foo.XXXXXX"`) — no
# `-t`, no `--tmpdir`, no `-p` flag — nor a bare `mktemp -d`, nor a BSD prefix-only
# `mktemp -t foo` with no X-run.
#
# Conservative over-flag (INTENTIONAL — F2): the matcher flags a `-t …XXXXXX` /
# `--tmpdir` / `-p` token even when it is STRING DATA on a non-comment line
# (`echo "… mktemp -t foo.XXXXXX"`, `eval "mktemp --tmpdir …"`). This is SAFE by
# design — it also catches the `eval` / dynamic-construction cases a stricter
# matcher would miss, and it does not change what a real invocation must look like.
# A legitimate MENTION that must be string data belongs in a `#`-comment (the guard
# strips comments before matching); there is no allowlist to grow.
_MKTEMP_T_ARG_RE = re.compile(
    r"(?<![\w-])mktemp(?:\s+-[a-zA-Z]+)*\s+-[a-zA-Z]*t\s+"
    r"(?P<arg>(?:\"[^\"]*\"|'[^']*'|[^\s\"'`);|&])+)"
)
_XRUN_RE = re.compile(r"X{3,}")
# CLASS 2 — GNU-only tmpdir specifiers (BSD errors out). Flag presence is the bug.
_MKTEMP_TMPDIR_RE = re.compile(r"(?<![\w-])mktemp\b(?:\s+[^\s;|&]+)*?\s+--tmpdir\b")
_MKTEMP_P_RE = re.compile(r"(?<![\w-])mktemp\b(?:\s+[^\s;|&]+)*?\s+-[a-zA-Z]*p\b")

# Pack-side scope (measure-then-bound): project-side shell scripts are the client's
# CI concern, not this pack-only guard's. The sole current project-side occurrence
# (project-template/agent-run.sh:347) is surfaced for a separate project-side
# follow-up, not swept into BD-276's pack-only work.
_MKTEMP_EXCLUDE_PREFIXES = ("project-template/",)


def _git_ls_sh_files():
    """Return `(available, sh_paths)` for `git ls-files '*.sh'`.

    `available` is False when the `git` binary is absent OR the tree is not a git
    work tree (both ⇒ the caller SKIPs lenient — a fresh clone / non-git checkout
    is never a violation). `available` is True otherwise, with `sh_paths` the list
    of git-TRACKED repo-relative `*.sh` paths (recursive; git pathspec `*.sh`
    matches across directories). Resolves the git root via `cwd=REPO_ROOT` (the
    module constant) so a per-check test can monkeypatch
    `mktemp_portability.REPO_ROOT` to a /tmp scratch repo (the Check 63 technique).
    ONE bounded subprocess; O(tracked `.sh` files); never a whole-tree scan, never
    a subprocess-per-entry.
    """
    try:
        result = subprocess.run(
            ["git", "ls-files", "*.sh"],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        return (False, [])
    if result.returncode != 0:
        return (False, [])
    return (True, [line for line in result.stdout.splitlines() if line.strip()])


def _strip_shell_comment(line):
    """Return `line` with any shell comment removed (quote-aware).

    A comment begins at the first `#` that is at line start or preceded by
    whitespace AND is outside single/double quotes — so a trailing `  # ...` note
    is stripped, a full-line `# ...` comment collapses to its indentation, and a
    `#` that is part of `${#var}` / `$#` / `${var#pat}` (preceded by `{` / `$` /
    a word char, never whitespace) is NEVER mistaken for a comment marker (no
    false-negative on a real invocation that follows such a construct). The quote
    tracker is single-line (mktemp invocations are single-line); it does NOT skip a
    match that merely sits inside `"$(...)"` — command substitution is not a
    comment — so the very common `foo="$(mktemp ...)"` real-invocation form is kept.
    """
    in_squote = False
    in_dquote = False
    for i, c in enumerate(line):
        if c == "'" and not in_dquote:
            in_squote = not in_squote
        elif c == '"' and not in_squote:
            in_dquote = not in_dquote
        elif c == "#" and not in_squote and not in_dquote:
            prev = line[i - 1] if i > 0 else " "
            if i == 0 or prev in " \t":
                return line[:i]
    return line


def check_mktemp_t_portability() -> None:
    """Check 92 — no non-portable `mktemp -t <prefix>XXXXXX` / `--tmpdir` / `-p` invocation (BD-276).

    The regression guard for the non-portable mktemp classes swept in BD-276. FAILs
    on any REAL invocation (command position, non-comment) in a git-TRACKED pack-side
    shell script of EITHER class: (1) the `-t <prefix>X{3,}` literal-XXXXXX form —
    including the bundled getopt clusters `-dt` / `-qt` / `-dqt` — where BSD treats
    the `-t` argument as a PREFIX and appends its own random suffix, leaving a literal
    `XXXXXX` in the path on macOS; and (2) the GNU-only tmpdir specifiers — the long
    option `--tmpdir` and its short synonym `-p DIR` — which BSD/macOS mktemp lacks
    and errors out on. The portable fix for class 1 is the full-path template
    `mktemp [-d] "${TMPDIR:-/tmp}/<prefix>.XXXXXX"`; for class 2, build the dir into
    that same full-path template instead of `--tmpdir` / `-p`.

    invocation-vs-mention (the same split the BD-276 measure step used): comment/doc
    MENTIONS are NOT violations. Full-line and trailing shell comments are stripped
    before matching via `_strip_shell_comment` (quote-aware, so `${#var}` / `$#` are
    never mistaken for a comment marker), and `.md` docs are never scanned (a doc
    code block is never an executed invocation). So the pack-side portability
    COMMENTS in `scripts/tests/test-marker-preserve-bd136.sh` and
    `scripts/tests/test-validate-pack-check-91.sh` are spared, as are every `.md`
    doc that names the buggy form.

    measure-then-bound (ci-guard-measure-then-bound): enumeration is git-TRACKED
    (`git ls-files '*.sh'`), never a raw FS walk; the candidate set EXCLUDES the
    `project-template/` prefix (pack-side scope — project-side is the client CI's
    concern); the allowlist is EMPTY (the legitimate mentions are already excluded
    by the invocation-vs-mention logic, so there is no blind spot). The STRIP set
    (real invocations) is empty post-sweep, so the guard runs clean at HEAD.

    O(lines) cost (ci-check-runtime-compounding): one `git ls-files '*.sh'`
    subprocess + a read-once regex pass over the small pack-side `.sh` set; no
    subprocess-per-file, no whole-tree scan. Routes through `run_check`.

    Lenient: git absent / not a git work tree ⇒ SKIP. A `.sh` file that is tracked
    but unreadable on disk is skipped (not a violation).
    """
    print("\n── Check 92: no non-portable `mktemp -t <prefix>XXXXXX` / `--tmpdir` / `-p` invocation (BD-276) ──")
    available, sh_files = _git_ls_sh_files()
    if not available:
        ok("git ls-files unavailable (git absent / not a git work tree) — skipping (lenient)")
        return

    violations = []
    for relpath in sh_files:
        if relpath.startswith(_MKTEMP_EXCLUDE_PREFIXES):
            continue
        fs_path = pathlib.Path(REPO_ROOT) / relpath
        try:
            text = fs_path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue  # tracked but unreadable — not a violation
        for lineno, raw in enumerate(text.splitlines(), 1):
            code = _strip_shell_comment(raw)
            flagged = False
            # CLASS 1 — `-t <prefix>XXXXXX` (incl. bundled -dt/-qt/-dqt).
            for m in _MKTEMP_T_ARG_RE.finditer(code):
                if _XRUN_RE.search(m.group("arg")):
                    flagged = True
                    break
            # CLASS 2 — GNU-only tmpdir specifiers `--tmpdir` / `-p` (no X-run
            # required). `flagged` short-circuits so a line matching >1 class
            # yields exactly ONE finding (no double-count).
            if not flagged and _MKTEMP_TMPDIR_RE.search(code):
                flagged = True
            if not flagged and _MKTEMP_P_RE.search(code):
                flagged = True
            if flagged:
                violations.append((relpath, lineno, raw.strip()))

    if violations:
        detail = "; ".join(f"{p}:{ln} ({src})" for p, ln, src in violations[:20])
        more = "" if len(violations) <= 20 else f" (+{len(violations) - 20} more)"
        fail(
            f"{len(violations)} non-portable mktemp invocation(s) found in "
            f"git-tracked pack-side shell scripts: {detail}{more}. Non-portable "
            f"classes: (1) `mktemp [-d] -t <prefix>XXXXXX` (incl. bundled `-dt` / "
            f"`-qt` / `-dqt`) — the BSD `-t` form treats the argument as a prefix "
            f"and appends its own random suffix, leaving a literal XXXXXX in the "
            f"temp path on macOS; (2) `mktemp … --tmpdir` / `mktemp … -p <dir>` — "
            f"GNU-only tmpdir specifiers, BSD/macOS lacks them and errors out. "
            f"Remediation (BD-276): rewrite each to the portable full-path template "
            f"`mktemp [-d] \"${{TMPDIR:-/tmp}}/<prefix>.XXXXXX\"` (preserve `-d` iff "
            f"present; fold any `--tmpdir` / `-p` directory into the template path — "
            f"both BSD and GNU expand a trailing-XXXXXX full-path template)."
        )
        return

    ok(
        "Check 92 — no non-portable `mktemp -t <prefix>XXXXXX` (incl. bundled "
        "`-dt`/`-qt`/`-dqt`) or GNU-only `--tmpdir` / `-p` invocation in "
        "git-tracked pack-side shell scripts (the BD-276 portability classes stay "
        "swept; comment/doc mentions are correctly spared)."
    )


# ── __all__ — the check body the facade's _build_check_registry() resolves ──────
# `from validate_checks.mktemp_portability import *` skips underscore names UNLESS
# they are listed here; once `__all__` is declared it ALSO gates the non-underscore
# names — so the `check_*` (resolved by bare name in the facade's
# `_build_check_registry()`) MUST be enumerated. The module-private helpers
# (`_git_ls_sh_files` / `_strip_shell_comment`) + constants (`_MKTEMP_T_ARG_RE` /
# `_XRUN_RE` / `_MKTEMP_TMPDIR_RE` / `_MKTEMP_P_RE` / `_MKTEMP_EXCLUDE_PREFIXES`) are underscore-prefixed and NOT asserted by any test's
# facade-re-export surface (the test only `hasattr`s the `check_*`), so they stay
# module-internal and are OMITTED from `__all__` (`import *` skips underscore names
# regardless).
__all__ = [
    "check_mktemp_t_portability",
]
