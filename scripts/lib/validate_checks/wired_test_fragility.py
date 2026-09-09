"""validate_checks.wired_test_fragility — Check 83: wired-test CI-environment
fragility guard (BD-222).

This module owns ONE genuinely-isolated check body (Check 83,
`check_wired_test_ci_fragility`) — the standing anti-drift guard that statically
scans every CI-WIRED test script for the CI-environment-fragile bug classes
that took a sharded CI run red, so the class cannot silently recur:

  (a) a HARDCODED absolute dev/home path (`/Users/…`, `/home/…`, `/opt/homebrew/`,
      `/private/var/folders/`, `/var/folders/`, a quoted `"$HOME/…"` literal) that
      exists on the dev machine but not on the CI runner;
  (b) a direct un-shimmed live-`gh` call (a CI-wired test that invokes real `gh`
      without a fake-`gh`-on-PATH shim, so it passes only because the dev box's
      `gh` is authenticated and fails on CI's unauthenticated runner);
  (c) the `grep -c … || echo 0` "double-zero" failure-masking idiom.
  (d) a SHELL-ACTIVE construct (a backtick or a `$(`) inside an UNQUOTED heredoc
      body — the BD-294 class. An unquoted heredoc delimiter (`<<EOF`, not
      `<<'EOF'`) makes the WHOLE body shell-expanded, so a backtick in what reads
      as inert payload — a Python comment, a prose sentence, a markdown snippet —
      is a command substitution the shell EXECUTES. Two ways it bites, and the
      severity is why leg (d) scans the payload legs (a)/(c) already scan:
        • PARSE-ABORT: if the backticked text is not valid shell, bash ABORTS the
          whole command. The bash version decides whether that is fatal — bash 5
          (the Ubuntu CI runner) returns non-zero so the test group FAILs, while
          bash 3.2 (macOS) substitutes empty and continues with status 0. A dev
          box therefore goes GREEN on the very defect that takes CI RED.
        • SILENT INJECTION: if the backticked text IS a runnable command, its
          stdout is spliced into the payload with no error at all, on every
          platform.
      Both are invisible to `bash -n`, which does not parse a heredoc body.
      The fix is a QUOTED delimiter (`<<'EOF'`) with values passed through the
      ENVIRONMENT and read via `os.environ` — the idiom already used by
      `test-install-map.sh`, `test-validate-pack-check-16.sh` and this check's
      own `test-validate-pack-check-83.sh`.

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
iff a direct `gh`-exec token survives strip AND no fake-`gh` shim is installed);
leg (d) scans ONLY the two SHELL-EXPANDED payload shapes — an UNQUOTED heredoc
body and a DOUBLE-quoted `python3 -c "…"` body. The inert forms (a
quoted-delimiter heredoc, a single-quoted `-c '…'`) are not scanned at all.
Covering BOTH shapes is evidence-driven, not symmetry-for-its-own-sake: the
BD-294 census found a SECOND live instance of the class in the `-c "…"` shape
(`test-validate-pack-check-92.sh` was executing a backticked `!= 89` out of a
Python comment on every run), which a heredoc-only guard would have missed.

Leg (d) measure-then-bound (`ci-guard-measure-then-bound`), measured over the
143-file candidate set at the BD-294 hotfix: 102 unquoted heredocs / 525 quoted
plus 84 double-quoted `-c` bodies / 29 single-quoted; 6 shell-active hits —
5 DEFECT (4 `test-validate-pack-check-19.sh` backticks that took CI red, and
1 `test-validate-pack-check-92.sh` backtick pair in the `-c "…"` shape; both
files fixed in the same change by converting every payload region to a quoted
delimiter + `os.environ`) and 1 KEEP
(`test-trinity-template-obeyable.sh`, a `read … <<EOF` wrapping `$(awk …)` where
the substitution IS the payload and a quoted delimiter would defeat the point).
The KEEP is exempted by an INLINE PRAGMA on the heredoc's OPENING line
(`ci-fragility: allow-shell-active-heredoc`) rather than by a path:line entry in
`ci-fragility-allowlist.txt`, for three reasons: (1) a line number DRIFTS and the
pack forbids line-number cross-references; (2) the existing file-level allowlist
`continue`s the WHOLE file, which would blind that file to legs (a)/(b)/(c) too —
a real blind spot; (3) the pragma travels WITH the code and documents itself at
the site. Exemption count is therefore exactly 1, and it is greppable:
`git grep -n "allow-shell-active-heredoc"`.

Leg (d) does NOT flag a bare `$VAR` / `${VAR}` interpolation. Measured basis:
interpolating `$REPO_ROOT` / `$VALIDATE` is the REASON ~all 102 unquoted heredocs
are unquoted, so banning it would ban the construct rather than bound it, and
"intended vs accidental interpolation" is not mechanically decidable. The
severity split is the justification: a bare `$VAR` can only interpolate an
unintended VALUE, whereas a backtick / `$(` EXECUTES A COMMAND and can abort the
parse. Leg (d) bounds the executable class.

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

# ── Leg (d) — shell-active construct inside an UNQUOTED heredoc (BD-294). ─────
# LEG_D_OPEN matches a heredoc REDIRECTION OPERATOR and captures whether the
# delimiter is quoted. Groups: 1 = `-` for the tab-stripping `<<-` form,
# 2 = a backslash-escaped delimiter (`<<\EOF`, quoted), 3 = the quote char
# (`'`/`"`, quoted) or empty (UNQUOTED — the scanned case), 4 = the delimiter.
#   `(?<!<)` + `(?!<)` exclude the `<<<` here-string AND the 7-char `<<<<<<<`
#   diff3 conflict marker. That exclusion is LOAD-BEARING, not defensive: the
#   census's first parser matched `<< your` out of the literal string
#   "<<<<<<< your customization" in test-customization-preserve.sh and then
#   swallowed 1136 lines of ordinary shell as a "heredoc body".
LEG_D_OPEN = re.compile(
    r"(?<!<)<<(-?)(?!<)\s*(\\?)(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\3")

# The shell-active constructs. A backtick or a `$(` inside an EXPANDED heredoc
# body is a command substitution the shell runs. `(?<!\\)` honours an escaped
# literal (`\`` / `\$(`), which is already inert.
LEG_D_ACTIVE = re.compile(r"(?<!\\)`|(?<!\\)\$\(")

# The inline opt-out, placed on the heredoc's OPENING line. Sized to the
# measured KEEP set (exactly 1 occurrence in the tree at landing).
LEG_D_PRAGMA = re.compile(r"ci-fragility:\s*allow-shell-active-heredoc")

# The SECOND shell-expanded payload shape: `python3 -c "…"`. A double-quoted
# shell string is expanded exactly like an unquoted heredoc body, so a backtick
# in it is equally a command substitution. This sub-leg is NOT hypothetical: the
# BD-294 census found a REAL second instance of the class here
# (`test-validate-pack-check-92.sh`, a backticked `!= 89` inside a Python comment
# that the shell was executing on every run — "!=: command not found" on stderr,
# exit 0, silently splicing empty into the payload). A SINGLE-quoted `-c '…'`
# body is inert and is not matched.
LEG_D_DASHC = re.compile(r"(?:python3?|python)\s+-c\s+\"")


def _dashc_active_hits(text):
    """Yield (lineno, snippet) for every shell-active construct inside a
    DOUBLE-quoted `python3 -c "…"` body (leg (d), second shape).

    The body extent is walked CHARACTER-wise honouring backslash escapes (the
    bodies routinely carry `\\"` inner quotes), not by a line heuristic — a
    line-based scan mis-tracks multi-line bodies and both over- and
    under-reports. An unterminated body means the parse lost sync: it is
    SKIPPED (lenient), never reported.
    """
    pos = 0
    n = len(text)
    while True:
        m = LEG_D_DASHC.search(text, pos)
        if not m:
            return
        start = m.end()               # first char INSIDE the quoted body
        i, closed = start, False
        while i < n:
            c = text[i]
            if c == "\\":             # escape consumes the next char
                i += 2
                continue
            if c == '"':
                closed = True
                break
            i += 1
        if not closed:
            return                    # lost sync — stop scanning this file
        open_line = text.count("\n", 0, m.start()) + 1
        if not LEG_D_PRAGMA.search(text[m.start():start]):
            for mm in LEG_D_ACTIVE.finditer(text[start:i]):
                lineno = text.count("\n", 0, start + mm.start()) + 1
                yield (lineno, open_line)
        pos = i + 1


def _unquoted_heredoc_active_hits(lines):
    """Yield (body_lineno, body_text, open_lineno) for every shell-active
    construct inside an UNQUOTED heredoc body (leg (d)).

    Bodies of QUOTED-delimiter heredocs are inert and are skipped wholesale.
    An opening line carrying the LEG_D_PRAGMA exempts that one heredoc.

    Heredoc bodies are NOT shell commands, so a nested `<<` inside a body is
    data, never a new operator — the body is consumed without re-scanning for
    operators. An UNTERMINATED heredoc means the parse has lost sync; it yields
    NOTHING (lenient) rather than emitting hits the parser cannot stand behind.
    """
    i, n = 0, len(lines)
    while i < n:
        opens = []
        for m in LEG_D_OPEN.finditer(lines[i]):
            dash, backslash, quote, delim = m.groups()
            opens.append((delim, bool(backslash or quote), dash == "-", i + 1,
                          bool(LEG_D_PRAGMA.search(lines[i]))))
        i += 1
        for delim, quoted, dashed, open_ln, pragma in opens:
            body, closed = [], False
            while i < n:
                # A `<<-` terminator may be indented with TABS only.
                probe = lines[i].lstrip("\t") if dashed else lines[i]
                if probe == delim:
                    closed, i = True, i + 1
                    break
                body.append((i + 1, lines[i]))
                i += 1
            if quoted or pragma or not closed:
                continue
            for ln, text in body:
                if LEG_D_ACTIVE.search(text):
                    yield (ln, text, open_ln)


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

    Statically scan every CI-WIRED test script for four CI-environment-fragile
    bug classes — (a) hardcoded dev/home paths, (b) direct un-shimmed live-`gh`
    calls, (c) the `grep -c … || echo 0` double-zero idiom, (d) a shell-active
    construct (backtick / `$(`) inside an UNQUOTED heredoc body — so the CI-red
    class is caught at validate-pack/PR time, before push.

    Candidate set = the CI-wired set = raw three-glob (scripts/test*.sh +
    scripts/tests/*.sh + scripts/tests/fixture-dependent/*.sh) MINUS
    scripts/ci-test-wiring-allowlist.txt (Check-42 mirror). An optional
    scripts/ci-fragility-allowlist.txt exempts a legitimate hit (absent = empty
    set; no file at landing). SKIP-lenient if no test*.sh on disk.

    Leg (d) is the BD-294 class and the reason this guard must exist at all: the
    defect is INVISIBLE to a macOS dev box. bash 3.2 substitutes empty and exits
    0 on an unparseable command substitution, while bash 5 (the CI runner) aborts
    the command and reds the group — and `bash -n` sees neither, because a
    heredoc body is not parsed until expansion. Leg (d)'s exemption is an inline
    pragma on the heredoc's opening line, NOT a path:line allowlist entry.

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

        # ── Leg (d): scan ONLY UNQUOTED heredoc bodies (a quoted-delimiter body
        # is inert). Report per-line, naming the heredoc that opened the body.
        for ln, text, open_ln in _unquoted_heredoc_active_hits(lines):
            problems = True
            fail(
                f"{rel}:{ln} — leg (d) SHELL-ACTIVE construct (backtick or `$(`) "
                f"inside the UNQUOTED heredoc opened at line {open_ln}. The "
                f"unquoted delimiter makes the whole body shell-expanded, so this "
                f"is a command substitution the shell EXECUTES — not inert text. "
                f"On bash 5 (the CI runner) an unparseable substitution ABORTS the "
                f"command and reds the group; on bash 3.2 (macOS) it substitutes "
                f"empty and exits 0, so the dev box goes green on the very defect "
                f"that reds CI. `bash -n` cannot see it either (a heredoc body is "
                f"not parsed until expansion). Fix: quote the delimiter "
                f"(`<<'EOF'`) and pass values through the ENVIRONMENT, reading "
                f"them with os.environ (see test-validate-pack-check-16.sh). If "
                f"the substitution IS the intended payload, mark the opening line "
                f"`# ci-fragility: allow-shell-active-heredoc`. "
                f"Offending line: {text.strip()[:80]}"
            )

        # ── Leg (d), second shape: a DOUBLE-quoted `python3 -c "…"` body is
        # shell-expanded exactly like an unquoted heredoc body.
        for ln, open_ln in _dashc_active_hits(text):
            problems = True
            fail(
                f"{rel}:{ln} — leg (d) SHELL-ACTIVE construct (backtick or `$(`) "
                f"inside the DOUBLE-quoted `python3 -c \"…\"` body opened at line "
                f"{open_ln}. A double-quoted shell string is expanded just like "
                f"an unquoted heredoc, so this is a command substitution the "
                f"shell EXECUTES — it runs on every invocation and splices its "
                f"output (or empty, plus a 'command not found' on stderr) into "
                f"the payload. Fix: use a QUOTED heredoc (`python3 - <<'EOF'`) "
                f"and pass values through the ENVIRONMENT, reading them with "
                f"os.environ (see test-validate-pack-check-16.sh)."
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
            f"(c), 0 shell-active constructs in a shell-expanded payload — "
            f"unquoted heredoc or double-quoted `python3 -c` body (d). (Scan set "
            f"= raw three-glob − ci-test-wiring-allowlist.txt; the "
            f"unauthenticated CI `tests` runner is the transitive-`gh` backstop; "
            f"(d) is the macOS-invisible bash-3.2-vs-5 class.)"
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
    "LEG_D_OPEN",
    "LEG_D_ACTIVE",
    "LEG_D_PRAGMA",
    "LEG_D_DASHC",
    # ── The check body (Check 83, resolved by bare name in _build_check_registry) ──
    "check_wired_test_ci_fragility",
]
