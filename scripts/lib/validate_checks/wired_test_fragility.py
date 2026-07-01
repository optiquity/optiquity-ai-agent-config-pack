"""validate_checks.wired_test_fragility — Check 83: wired-test CI-environment
fragility guard (BD-222).

This module owns ONE genuinely-isolated check body (Check 83,
`check_wired_test_ci_fragility`) — the standing anti-drift guard that statically
scans every CI-WIRED test script for the three CI-environment-fragile bug classes
that took BD-219's first sharded CI run red, so the class cannot silently recur:

  (a) a HARDCODED absolute dev/home path (`/Users/…`, `/home/…`, `/opt/homebrew/`,
      `/private/var/folders/`, `/var/folders/`, a quoted `"$HOME/…"` literal) that
      exists on the dev machine but not on the CI runner;
  (b) a direct un-shimmed live-`gh` call (a CI-wired test that invokes real `gh`
      without a fake-`gh`-on-PATH shim, so it passes only because the dev box's
      `gh` is authenticated and fails on CI's unauthenticated runner);
  (c) the `grep -c … || echo 0` "double-zero" failure-masking idiom.

The guard is a NEW genuinely-isolated check per the FIRM own-module-per-new-check
convention (`scripts/lib/validate_checks/README.md` § "The FIRM CONVENTION"):
Check 83 shares NO module-level symbol with any existing cluster (its candidate
set — the CI-wired `.sh` set — differs from every cluster's set), so it gets its
OWN module rather than joining `singletons.py`. It is the first post-split realized
consumer of that convention (see
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md` § 8).

Candidate/scan set = the CI-WIRED set = the raw inline three-glob
(`scripts/test*.sh` + `scripts/tests/*.sh` + `scripts/tests/fixture-dependent/*.sh`)
MINUS `scripts/ci-test-wiring-allowlist.txt`. This is a FAITHFUL mirror of Check 42
(`singletons.py::check_ci_workflow_wires_per_check_tests`): enumerate the raw
three-glob into `disk_paths`, then subtract the allowlist
(`candidate = disk_paths - allowlist`) using Check 42's exact inline parser. The
subtraction is load-bearing: the guard's scan set == the CI matrix's wired set, so
it NEVER flags a test that does not run in CI (the sole allowlist member,
`tracker-bd204-lossless-roundtrip-test.sh`, is the manual-only live-GH oracle — its
un-shimmed `gh` is CORRECT because it never runs in CI). The `parse_wired_tests()`
partitioner in `scripts/lib/ci-shard-plan.py` is NOT imported (hyphenated filename →
not module-importable; importing the CI partitioner into a leaf check inverts
dependency direction). The inline mirror reproduces its
`sorted(found - load_allowlist())` result. Git-tracked-equivalent by construction
(globs enumerate on-disk `.sh`, all tracked); SKIP-lenient if no `test*.sh` exists.

Leg-specific scan scope: legs (a) and (c) scan ALL lines (a hardcoded path or a
`grep -c…||echo 0` idiom is a bug even inside a heredoc/comment — BD-219's path was
in a heredoc that looked like a comment); leg (b) strips comments+strings FIRST
(the measured comment false-positives) and its verdict is per-FILE (a file FAILs
iff a direct `gh`-exec token survives strip AND no fake-`gh` shim is installed).

An OPTIONAL second allowlist `scripts/ci-fragility-allowlist.txt` is supported
(absent = empty exemption set, per the `load_allowlist()` missing-file precedent),
but NO file is shipped at landing — the fragility KEEP set is empty (census 0/0/0
over the candidate set). It is a SEPARATE allowlist from the CI-wiring
`ci-test-wiring-allowlist.txt` used for candidate enumeration; do not conflate them.

Cheapness (ci-check-runtime-compounding): glob + in-process read-once regex over
the small wired set; module-load-compiled patterns; NO subprocess-per-file; routed
through `run_check(..., budget_s=W)` (the standard per-check WARN budget) in the
facade's registry.

Spine + seam: the spine symbols (`REPO_ROOT`, `fail`, `ok`) are imported
`from .core` — the single SSOT for the spine. Standard-library `re` is imported
directly at module top (the leg patterns use `re.compile`), mirroring the
established per-module convention (the spine `import *` does not re-export stdlib
names).

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import re

from .core import (
    REPO_ROOT,
    fail,
    ok,
)


# ── The three module-load-compiled detection legs (literals only — no load-time
# CALL, so the module imports standalone with no NameError, the core.py-style
# "definitions + literals only" property). Carried VERBATIM from
# DESIGN-BD222-RECONCILED.md §3.3 (the final CORRECTED leg logic). ────────────

# Leg (a) — hardcoded dev/home path (WIDENED per AR-5). Scanned on ALL lines.
LEG_A = re.compile(r'(?<![\w-])/(?:Users|home)/[A-Za-z0-9._$%{}()-]+'
                   r'|(?<![\w-])/opt/homebrew/'
                   r'|(?<![\w-])/private/var/folders/'
                   r'|(?<![\w-])/var/folders/')
HOME_ABS = re.compile(r'"\$\{?HOME\}?/')                  # quoted "$HOME/<path>"

# Leg (b) — direct un-shimmed live-`gh` (CORRECTED shim per AR-1; strip-first per
# AR-3). Leg (b) FAILs a file iff any STRIPPED line matches GH_EXEC AND no line
# matches SHIM. It is the ONLY leg that strips comments+strings first.
GH_EXEC = re.compile(r'(?:^|[;&|`(]|\$\(|&&|\|\||\bthen\b|\bdo\b|\belse\b)\s*gh\s+'
                     r'(?:label|issue|repo|auth|pr|api|run|workflow|release|search|gist|secret|variable|cache)\b')
SHIM = re.compile(r'(?:cat|printf|tee|echo)\b[^\n]*>\s*["\']?\S*?/gh["\']?'
                  r'|chmod\s+\+x\s+["\']?\S*?/gh\b'
                  r'|^\s*gh\s*\(\)\s*\{'
                  r'|function\s+gh\b')

# Leg (c) — double-zero `grep -c|--count … || echo|printf 0` (EXTENDED per AR-6).
# Scanned on ALL lines (a literal is a bug even in a heredoc).
LEG_C = re.compile(r'grep\s+(?:-c[A-Za-z]*|--count)\b.*\|\|\s*(?:echo|printf)\s+["\']?0\b')


def _strip_comments_strings(line):
    """Blank out a shell line's comment tail + quoted-string CONTENTS (leg (b)
    ONLY; the AR-3 comment-handling basis).

    Walk the line left-to-right: outside a quote, stop at the first UNQUOTED `#`
    (a comment); inside a quote, blank the CONTENTS but preserve the quote chars.
    This suppresses the measured comment false-positives (a `gh …` inside a
    comment or a string literal) while preserving a real `gh` after an in-string
    `#` (`echo "issue #42" ; gh label create x` → the trailing `gh` survives).
    The one UNHANDLED case is heredoc bodies — handled NOT here but by the
    assembled-fragment fixture discipline in test-83.
    """
    out = []
    quote = None
    for ch in line:
        if quote is not None:
            if ch == quote:
                quote = None
                out.append(ch)
            else:
                out.append(' ')
        else:
            if ch == '#':
                break
            if ch == '"' or ch == "'":
                quote = ch
                out.append(ch)
            else:
                out.append(ch)
    return ''.join(out)


def check_wired_test_ci_fragility():
    """Check 83 — wired-test CI-environment fragility guard (BD-222).

    Statically scan every CI-WIRED test script for three CI-environment-fragile
    bug classes — (a) hardcoded dev/home paths, (b) direct un-shimmed live-`gh`
    calls, (c) the `grep -c … || echo 0` double-zero idiom — so the BD-219 CI-red
    class is caught at validate-pack/PR time, before push.

    Candidate set = the CI-wired set = raw three-glob (scripts/test*.sh +
    scripts/tests/*.sh + scripts/tests/fixture-dependent/*.sh) MINUS
    scripts/ci-test-wiring-allowlist.txt (Check-42 mirror). An optional
    scripts/ci-fragility-allowlist.txt exempts a legitimate hit (absent = empty
    set; no file at landing). SKIP-lenient if no test*.sh on disk.

    Cheap (ci-check-runtime-compounding): three dir globs + one small allowlist
    parse + a read-once regex pass over the small wired set; no subprocess.

    LOCAL-PASS-IS-INSUFFICIENT (the BD-219 clean-room lesson): a wired test can
    pass on an authenticated dev box yet fail on the unauthenticated CI runner —
    this static guard is the PR-time direct-case backstop; the unauthenticated CI
    `tests` runner is the enforcement gate for the transitive library-`gh` case.
    """
    print("\n── Check 83: wired-test CI-environment fragility guard (BD-222) ──")

    scripts_dir = REPO_ROOT / "scripts"
    tests_dir = scripts_dir / "tests"
    fxdep_dir = tests_dir / "fixture-dependent"
    wiring_allowlist_path = scripts_dir / "ci-test-wiring-allowlist.txt"
    fragility_allowlist_path = scripts_dir / "ci-fragility-allowlist.txt"

    # ── Enumerate the raw disk test-script set (repo-relative paths) over the
    # SAME three explicit non-recursive dirs as Check 42 /
    # ci-shard-plan.py parse_wired_tests(). scripts/tests/fixtures/ (inert data)
    # is never reached (no recursion).
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

    # ── Subtract the CI-WIRING allowlist (the load-bearing scan-set fix — the
    # FAITHFUL Check-42 mirror: candidate = disk_paths - allowlist). One
    # repo-relative path per line; `#` comments + blanks ignored; an inline
    # `# reason` after the path is dropped (first whitespace token only). The
    # subtraction removes exactly the manual-only live-GH oracle
    # (tracker-bd204-lossless-roundtrip-test.sh, the sole member at landing) so
    # the guard's scan set == the CI matrix's wired set and it never flags a test
    # that does not run in CI.
    wiring_allowlist = set()
    if wiring_allowlist_path.is_file():
        for raw in wiring_allowlist_path.read_text().splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            wiring_allowlist.add(line.split()[0])
    candidate = disk_paths - wiring_allowlist

    # ── Load the OPTIONAL second (fragility) allowlist — a distinct file from the
    # CI-wiring allowlist above. Absent = empty exemption set (no file at
    # landing; the fragility KEEP set is empty). Same parse idiom.
    fragility_allowlist = set()
    if fragility_allowlist_path.is_file():
        for raw in fragility_allowlist_path.read_text().splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            fragility_allowlist.add(line.split()[0])

    problems = False
    for rel in sorted(candidate):
        if rel in fragility_allowlist:
            continue
        try:
            text = (REPO_ROOT / rel).read_text(errors="replace")
        except OSError:
            continue
        lines = text.splitlines()

        # ── Legs (a) + (c): scan ALL lines (a literal is a bug even in a
        # heredoc/comment). Report per-line.
        for idx, ln in enumerate(lines, start=1):
            if LEG_A.search(ln) or HOME_ABS.search(ln):
                problems = True
                fail(
                    f"{rel}:{idx} — leg (a) HARDCODED dev/home path in a CI-wired "
                    f"test. A path like /Users/… /home/… /opt/homebrew/ "
                    f"/private/var/folders/ /var/folders/ or a quoted \"$HOME/…\" "
                    f"exists on the dev box but not on the CI runner (BD-219). "
                    f"Use a repo-relative path derived at runtime "
                    f"(e.g. \"$(cd \"$(dirname \"${{BASH_SOURCE[0]}}\")/../..\" && pwd)\")."
                )
            if LEG_C.search(ln):
                problems = True
                fail(
                    f"{rel}:{idx} — leg (c) DOUBLE-ZERO failure-masking idiom "
                    f"(`grep -c|--count … || echo|printf 0`) in a CI-wired test. "
                    f"The `|| echo 0` swallows grep's non-match/error status, "
                    f"masking a real failure (BD-219). Capture the count and "
                    f"branch on grep's own exit status instead."
                )

        # ── Leg (b): strip comments+strings FIRST, then decide per-FILE (FAIL iff
        # a direct gh-exec token survives strip AND no fake-gh shim is installed).
        stripped = [_strip_comments_strings(ln) for ln in lines]
        direct_gh = any(GH_EXEC.search(s) for s in stripped)
        shimmed = any(SHIM.search(ln) for ln in lines)
        if direct_gh and not shimmed:
            problems = True
            fail(
                f"{rel} — leg (b) direct un-shimmed live-`gh` call in a CI-wired "
                f"test. It invokes real `gh` without a fake-`gh`-on-PATH shim, so "
                f"it passes only on an authenticated dev box and fails on the "
                f"unauthenticated CI runner (BD-219). Install a fake-`gh` shim on "
                f"PATH (see scripts/tests/tracker-bd129-gh-repo-test.sh), or — if "
                f"it is a genuine manual-only live-GH oracle — add it to "
                f"scripts/ci-test-wiring-allowlist.txt (so it never wires into CI)."
            )

    if not problems:
        ok(
            f"Check 83 — no CI-environment-fragile idiom in the "
            f"{len(candidate)} CI-wired test script(s): 0 hardcoded dev/home "
            f"paths (a), 0 un-shimmed live-`gh` files (b), 0 double-zero idioms "
            f"(c). (Scan set = raw three-glob − ci-test-wiring-allowlist.txt; "
            f"the unauthenticated CI `tests` runner is the transitive-`gh` "
            f"backstop.)"
        )


# ── __all__ — every wired_test_fragility-OWNED symbol the facade / the tests
# reach. `from validate_checks.wired_test_fragility import *` skips underscore
# names UNLESS listed here; and once `__all__` is declared it ALSO gates the
# non-underscore names — so the check body (resolved by bare name in the facade's
# `_build_check_registry()`) MUST be enumerated. The leg patterns LEG_A / HOME_ABS
# / GH_EXEC / SHIM / LEG_C are non-underscore module symbols the wired test-83
# imports for a targeted regex-behavior negative control, so they are enumerated
# to keep the module's `import *` surface stable. The `from .core` spine
# (`REPO_ROOT`, `fail`, `ok`) is NOT re-listed — those are core-owned (the facade
# re-exports them via `from validate_checks.core import *`); `__all__` enumerates
# only this module's OWN symbols.
__all__ = [
    # ── Leg patterns (imported by the wired test-83 regex-behavior controls) ──
    "LEG_A",
    "HOME_ABS",
    "GH_EXEC",
    "SHIM",
    "LEG_C",
    # ── The check body (Check 83, resolved by bare name in _build_check_registry) ──
    "check_wired_test_ci_fragility",
]
