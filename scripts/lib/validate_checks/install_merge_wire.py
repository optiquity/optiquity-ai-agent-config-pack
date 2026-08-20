"""validate_checks.install_merge_wire — Check 94: install-merge token-wire guard
(BD-285 F9).

This module owns the STATIC wire guard for the install-time 2-way trinity fold
(BD-285). An `init --trinity=merge` install records each folded trinity file as a
row in the PERSISTENT `<TARGET>/.pack-install-reconcile/dispositions.tsv`, and the
client `resolve-merge-conflicts` skill's Case 3 later LOCATES those rows to run the
zero-loss fold. The two ends of that wire must agree on ONE column-4 action token,
and the skill's Case-3 on-success step must KEEP the `.user-orig` recovery copy
(unlike Case 2, which removes ITS sidecar). Check 94 makes both invariants
un-regressable with two assertions in ONE registry entry.

  - Check 94 LEG 1 — the token wire BITES (records-style declare-verify-backing):
    the action token (column 4) that `scripts/init-project.sh` WRITES into a
    `class=="trinity"` `_cp_record` row MUST MATCH the token the
    `project-template/skills/resolve-merge-conflicts/SKILL.md` Case-3 Locate awk
    selector READS (`$2=="trinity" && $4=="<token>"`). Verified in BOTH directions:
    the writer must exist (init writes a trinity action token) AND the reader must
    exist (the Case-3 selector reads a token) AND they must be equal. A declared
    selector with NO matching writer — the absence-of-backing instance — FAILs, not
    only a both-exist mismatch. The literals are READ from both sources (never a
    hardcoded copy that could drift from the surfaces the guard protects).

  - Check 94 LEG 2 — the Case-3 KEEP-on-success backstop (SHOULD-3 / Δ2 / P3): the
    SKILL.md Case-3 `### On success` block MUST NOT contain an AFFIRMATIVE
    `.user-orig` removal verb (`rm` / `remove` / `delete` / `unlink` targeting
    `.user-orig`). This statically enforces that Case 3 KEEPS `.user-orig` — the
    sole purpose-built recovery copy (there is no pre-install backup). The block
    LEGITIMATELY says "does NOT remove `<file>.user-orig` on success" and "Leave the
    `.user-orig` sidecar in place" — both KEEP statements — so the guard flags a
    removal verb ONLY when it is NOT negated (a Case-2-style
    "remove the `.user-orig` sidecar" would BITE). The scan is scoped to the Case-3
    On-success region ONLY (not the whole file): Case 2 legitimately removes ITS
    own `.v10-customized` / `.v10-base` sidecars in its own on-success block.

Own-module per the FIRM own-module-per-new-check convention
(`scripts/lib/validate_checks/README.md` § "The FIRM CONVENTION"): the guard's
candidate surface (the two named wire endpoints — `scripts/init-project.sh` and the
client `resolve-merge-conflicts/SKILL.md`) and its module-private helpers
(`_git_ls_files()`, `_slice_section()`) share NOTHING with any existing cluster, so
it gets its OWN module rather than joining an unrelated cluster (the same rationale
as BD-276's `mktemp_portability.py` and BD-205's `no_leak.py`).

Scope (measure-then-bound, ci-check-runtime-compounding): the guard reads exactly
TWO git-TRACKED files (enumerated via `git ls-files -- <two paths>`, never a raw
filesystem walk), O(lines over those two files), ONE bounded subprocess,
SKIP-lenient off a git work tree OR when either wire surface is untracked/absent
(a fresh clone / pre-BD-285 HEAD is never a violation — the `init_sh.is_file()`
absent-file idiom). The validator is PACK-SIDE (it READS the client SKILL.md but
ships no client dependency — dependency-direction-placement).

Bodies + the module-private helpers live only here; the facade
(`scripts/validate-pack.py`) re-exports the check via
`from validate_checks.install_merge_wire import *`, so the registry assembled in
the facade (`_build_check_registry()`) keeps resolving `check_install_merge_wire`
(94). Single SSOT — no forked copy.

Spine: the spine symbols (`REPO_ROOT`, `fail`, `ok`) are imported `from .core` —
the single SSOT for the spine. `_git_ls_files()` resolves the git root via
`cwd=REPO_ROOT` (the module constant) and the file reads join `REPO_ROOT`, so a
per-check test can monkeypatch `install_merge_wire.REPO_ROOT` to a /tmp scratch
repo (the Check 63 / 92 technique). Standard-library `re`, `subprocess`, and
`pathlib.Path` are imported directly at module top. The module is definitions +
literals only (no load-time CALL), so it imports standalone with no `NameError`
(the MUST-3 load-time-order contract).

See `scripts/lib/validate_checks/README.md` and `backlog/BD-285.md`.
"""

import re
import subprocess
from pathlib import Path

from .core import (
    REPO_ROOT,
    fail,
    ok,
)

# The two named git-TRACKED wire endpoints (repo-relative). The pack-side installer
# writes the token; the client-shipped skill reads it. Both are read-only inputs to
# this pack-side validator.
_INIT_SCRIPT_REL = "scripts/init-project.sh"
_SKILL_REL = "project-template/skills/resolve-merge-conflicts/SKILL.md"

# ── LEG 1 regexes ───────────────────────────────────────────────────────────
# WRITER token: the action column (column 4) of a `class=="trinity"` `_cp_record`
# call in init-project.sh. The `customization-preserve` `_cp_record` positional
# contract is `_cp_record <disposition> <class> <rel> <action> <sidecar> <diff>
# <notes>`, so the 4th quoted argument of a trinity `_cp_record` is the action /
# wire token. The regex is intentionally SPECIFIC (class literal "trinity" in the
# 2nd slot) so it matches only the install-merge writer, never an unrelated
# `_cp_record` shape. Matching runs over comment-STRIPPED init text (full-line
# `#` comments dropped) so a commented-out example / commented-out real call is
# NOT counted as a live writer (strengthens the absence-of-backing detection).
_WRITER_RE = re.compile(
    r'_cp_record\s+"[^"]*"\s+"trinity"\s+"[^"]*"\s+"([^"]*)"'
)
# READER token: the Case-3 Locate awk selector `$2=="trinity" && $4=="<token>"`.
# Applied ONLY within the "Locate the install fold rows (Case 3)" section so the
# Case-2 `$2=="trinity" && $4=="sidecar"` selector is never picked up.
_SELECTOR_RE = re.compile(r'\$2=="trinity"\s*&&\s*\$4=="([^"]*)"')

# ── LEG 2 regexes ───────────────────────────────────────────────────────────
# A removal verb (rm / remove(s|d) / delet* / unlink) that TARGETS `.user-orig`
# within a bounded forward window (single-line after the On-success block is
# whitespace-collapsed). This alone would false-match the LEGITIMATE negated KEEP
# sentence "does NOT remove `<file>.user-orig`", so a match is a violation ONLY
# when the removal verb is NOT preceded (within `_NEG_LOOKBACK` chars) by a
# negation token — i.e. it is an AFFIRMATIVE removal instruction.
_REMOVAL_RE = re.compile(r"\b(rm|remove[sd]?|delet\w+|unlink)\b.{0,40}?\.user-orig", re.I)
_NEGATION_RE = re.compile(r"\b(not|never)\b|n't", re.I)
_NEG_LOOKBACK = 40


def _git_ls_files():
    """Return `(available, tracked_set)` for `git ls-files -- <the two wire paths>`.

    `available` is False when the `git` binary is absent OR the tree is not a git
    work tree (both ⇒ the caller SKIPs lenient — a fresh clone / non-git checkout is
    never a violation). `available` is True otherwise, with `tracked_set` the subset
    of the two wire paths that are git-TRACKED. Resolves the git root via
    `cwd=REPO_ROOT` (the module constant) so a per-check test can monkeypatch
    `install_merge_wire.REPO_ROOT` to a /tmp scratch repo (the Check 63 / 92
    technique). ONE bounded subprocess, scoped to the two named paths (never a
    whole-tree scan, never a subprocess-per-entry) — the
    ci-check-runtime-compounding shape.
    """
    try:
        result = subprocess.run(
            ["git", "ls-files", "--", _INIT_SCRIPT_REL, _SKILL_REL],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        return (False, set())
    if result.returncode != 0:
        return (False, set())
    return (True, {line for line in result.stdout.splitlines() if line.strip()})


def _slice_section(lines, start_pred, end_pred):
    """Return the lines AFTER the first `start_pred` line up to (excluding) the next
    `end_pred` line; `None` if no start line is found.

    Both predicates take a single line string. The start line itself is EXCLUDED
    from the returned slice (so the section HEADING is not scanned), and iteration
    begins after it (so the start line's own shape never re-triggers `end_pred`).
    If no `end_pred` line follows, the slice runs to the end of `lines`.
    """
    start = None
    for i, ln in enumerate(lines):
        if start_pred(ln):
            start = i
            break
    if start is None:
        return None
    out = []
    for ln in lines[start + 1:]:
        if end_pred(ln):
            break
        out.append(ln)
    return out


def check_install_merge_wire() -> None:
    """Check 94 — install-merge token-wire guard + Case-3 KEEP-on-success backstop (BD-285 F9).

    LEG 1 (declare-verify-backing): the column-4 action token `scripts/init-project.sh`
    WRITES into a `class=="trinity"` `_cp_record` row MUST equal the token the
    `resolve-merge-conflicts` SKILL.md Case-3 Locate selector READS
    (`$2=="trinity" && $4=="<token>"`). Verified BOTH directions — the writer must
    exist, the reader must exist, and the two must match — so a declared selector
    with no matching writer (absence-of-backing) FAILs, not only a both-exist
    mismatch. Literals are read from both sources (never hardcoded).

    LEG 2 (SHOULD-3 / Δ2 / P3): the SKILL.md Case-3 `### On success` block MUST NOT
    contain an AFFIRMATIVE `.user-orig` removal verb, statically enforcing that
    Case 3 KEEPS `.user-orig` (the sole purpose-built recovery copy). The
    LEGITIMATE negated KEEP sentence ("does NOT remove `<file>.user-orig`") is
    spared; a Case-2-style affirmative "remove the `.user-orig` sidecar" BITEs. The
    scan is scoped to the Case-3 On-success region only.

    measure-then-bound (ci-guard-measure-then-bound): enumeration is git-TRACKED
    (`git ls-files -- <two paths>`), never a raw FS walk; the candidate set is the
    two named wire endpoints; there is no allowlist (the negated KEEP sentence is
    excluded by the negation-aware match, so there is no blind spot). O(lines over
    two files); one `git ls-files` subprocess; routes through `run_check`.

    Lenient: git absent / not a git work tree ⇒ SKIP; either wire surface untracked
    or unreadable ⇒ SKIP (a fresh clone / pre-BD-285 HEAD is never a violation).
    """
    print("\n── Check 94: install-merge token-wire guard + Case-3 KEEP-on-success backstop (BD-285 F9) ──")
    available, tracked = _git_ls_files()
    if not available:
        ok("git ls-files unavailable (git absent / not a git work tree) — skipping (lenient)")
        return
    if _INIT_SCRIPT_REL not in tracked or _SKILL_REL not in tracked:
        ok(
            "install-merge wire surfaces not both git-tracked "
            f"({_INIT_SCRIPT_REL} / {_SKILL_REL}) — skipping (lenient)"
        )
        return

    try:
        init_text = (Path(REPO_ROOT) / _INIT_SCRIPT_REL).read_text(
            encoding="utf-8", errors="replace")
        skill_text = (Path(REPO_ROOT) / _SKILL_REL).read_text(
            encoding="utf-8", errors="replace")
    except OSError as exc:
        ok(f"install-merge wire surface unreadable ({exc}) — skipping (lenient)")
        return

    failed = False
    skill_lines = skill_text.splitlines()

    # ── LEG 1 — the token wire BITES (both directions) ───────────────────────
    # Writer: comment-strip init text so a commented-out `_cp_record` is not
    # counted as a live writer (strengthens absence-of-backing detection).
    init_code = "\n".join(
        ln for ln in init_text.splitlines() if not ln.lstrip().startswith("#")
    )
    write_tokens = set(_WRITER_RE.findall(init_code))

    locate3 = _slice_section(
        skill_lines,
        lambda ln: ln.startswith("## ") and "Locate the install fold rows" in ln,
        lambda ln: ln.startswith("## "),
    )
    read_tokens = set()
    if locate3 is not None:
        read_tokens = set(_SELECTOR_RE.findall("\n".join(locate3)))

    # Direction A — init must WRITE a trinity action/wire token.
    if not write_tokens:
        fail(
            "Check 94 LEG 1 — no `class==\"trinity\"` `_cp_record` action (column-4) "
            f"token found in {_INIT_SCRIPT_REL}: the install-merge writer is absent, "
            "so the resolve-merge-conflicts Case-3 selector has no backing writer "
            "(declare-verify-backing)."
        )
        failed = True
    # Direction B — the skill Case-3 Locate selector must READ a token.
    if locate3 is None:
        fail(
            "Check 94 LEG 1 — the '## Locate the install fold rows (Case 3)' section "
            f"is absent from {_SKILL_REL}: cannot verify the Case-3 selector token "
            "(the install-merge reader surface is missing)."
        )
        failed = True
    elif not read_tokens:
        fail(
            "Check 94 LEG 1 — no `$2==\"trinity\" && $4==\"<token>\"` selector found in "
            f"the Case-3 Locate section of {_SKILL_REL}: the install-merge reader is "
            "absent."
        )
        failed = True
    elif len(read_tokens) > 1:
        fail(
            "Check 94 LEG 1 — the Case-3 Locate section of "
            f"{_SKILL_REL} declares multiple distinct trinity selector tokens "
            f"{sorted(read_tokens)}; exactly one wire token is required."
        )
        failed = True
    # Match — the reader token must be BACKED by an init writer (the wire BITES).
    if write_tokens and read_tokens and len(read_tokens) == 1:
        read_token = next(iter(read_tokens))
        if read_token not in write_tokens:
            fail(
                "Check 94 LEG 1 — install-merge token WIRE BROKEN: the "
                f"resolve-merge-conflicts Case-3 selector reads action `{read_token}` "
                f"($4) but {_INIT_SCRIPT_REL} writes trinity action token(s) "
                f"{sorted(write_tokens)} — the selector has no matching writer "
                "(declare-verify-backing)."
            )
            failed = True

    # ── LEG 2 — the Case-3 On-success block KEEPS `.user-orig` (SHOULD-3) ─────
    case3 = _slice_section(
        skill_lines,
        lambda ln: ln.startswith("## Case 3"),
        lambda ln: ln.startswith("## "),
    )
    onsucc = None
    if case3 is not None:
        onsucc = _slice_section(
            case3,
            lambda ln: ln.startswith("### On success"),
            lambda ln: ln.startswith("## ") or ln.startswith("### "),
        )
    if case3 is None or onsucc is None:
        fail(
            "Check 94 LEG 2 — the Case-3 '### On success' block is absent from "
            f"{_SKILL_REL}: cannot verify the KEEP-`.user-orig`-on-success invariant "
            "(the backstop surface is missing)."
        )
        failed = True
    else:
        joined = " ".join(" ".join(onsucc).split())  # whitespace-collapse the block
        for m in _REMOVAL_RE.finditer(joined):
            verb_start = m.start(1)
            preceding = joined[max(0, verb_start - _NEG_LOOKBACK):verb_start]
            if not _NEGATION_RE.search(preceding):
                fail(
                    "Check 94 LEG 2 — the Case-3 '### On success' block in "
                    f"{_SKILL_REL} contains an AFFIRMATIVE `.user-orig` removal "
                    f"(`{m.group(0).strip()}`): Case 3 MUST KEEP `.user-orig` on "
                    "success (UNLIKE Case 2) — it is the sole purpose-built recovery "
                    "copy (there is no pre-install backup)."
                )
                failed = True
                break

    if not failed:
        wire = next(iter(read_tokens))
        ok(
            "Check 94 — install-merge token wire intact (init-project.sh writes + "
            f"resolve-merge-conflicts Case-3 selects action `{wire}`) and the Case-3 "
            "On-success block KEEPS `.user-orig` (no affirmative removal verb)."
        )


# ── __all__ — the check body the facade's _build_check_registry() resolves ──────
# `from validate_checks.install_merge_wire import *` skips underscore names UNLESS
# they are listed here; once `__all__` is declared it ALSO gates the non-underscore
# names — so the `check_*` (resolved by bare name in the facade's
# `_build_check_registry()`) MUST be enumerated. The module-private helpers
# (`_git_ls_files` / `_slice_section`) + constants (`_WRITER_RE` / `_SELECTOR_RE` /
# `_REMOVAL_RE` / `_NEGATION_RE` / `_NEG_LOOKBACK` / `_INIT_SCRIPT_REL` /
# `_SKILL_REL`) are underscore-prefixed and NOT asserted by any test's facade-
# re-export surface (the test only `hasattr`s the `check_*`), so they stay
# module-internal and are OMITTED from `__all__` (`import *` skips underscore names
# regardless).
__all__ = [
    "check_install_merge_wire",
]
