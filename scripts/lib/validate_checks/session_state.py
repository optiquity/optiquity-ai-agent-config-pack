"""validate_checks.session_state — Cluster H: the BD-252 session-state
snapshot family (BD-256 W9).

This module owns Cluster H's 3 check bodies (Checks 77, 78, 79) — the committed,
CLI-agnostic resumable session-state snapshot (`pack-ops/session-state.json`)
guards: structural well-formedness (77, struct), boundary freshness (78, fresh),
and the bespoke no-history anti-accretion grammar (79, grammar). The three are
co-located because they all key on the single session-state surface
(`pack-ops/session-state.json`) and share the `_session_state_load()` seam +
the `_SESSION_STATE_*` schema/grammar constants.

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via
`from validate_checks.session_state import *`, so the registry assembled in the
facade (`_build_check_registry()`) keeps resolving each `check_*` name
(77/78/79). Single SSOT — no forked copy.

Intra-cluster helper moved with the bodies (read only by Cluster H checks):
`_session_state_iter_string_values` — the recursive string-value yielder Check 79
uses to scan all state values for SHAs / dates / narration.

Spine + seam: the spine symbols (`REPO_ROOT`, `fail`, `ok`, `warn`, `failures`)
and the W1 core seam (`_session_state_load()` + the `_SESSION_STATE_*` schema +
grammar constants — the 8th cross-MODULE seam, read by Checks 77/78/79 here and
by Check 81's active-BD trigger in cross_bd) are imported `from .core` — the
single SSOT for the spine + W1 seams. (`failures` is imported for the V3
failures-identity invariant — `core.failures is session_state.failures` —
matching the W2–W8 module convention; the Cluster H bodies append via `fail()`,
never rebind `failures`.) Standard-library `subprocess` is imported directly at
module top (Check 78's git-probe calls), mirroring the established per-module
convention (the spine `import *` does not re-export stdlib names).
"""

import subprocess

from .core import (
    REPO_ROOT,
    fail,
    ok,
    warn,
    failures,
    _session_state_load,
    _SESSION_STATE_FILE,
    _SESSION_STATE_REQUIRED_KEYS,
    _SESSION_STATE_SHA_KEY,
    _SESSION_STATE_DATE_KEY,
    _SESSION_STATE_SHA_RE,
    _SESSION_STATE_SHA_FULL_RE,
    _SESSION_STATE_DATE_RE,
    _SESSION_STATE_ISO_RE,
    _SESSION_STATE_BD_TAG_RE,
    _SESSION_STATE_NARRATION_PATTERNS,
    _SESSION_STATE_BYTE_CAP,
    _SESSION_STATE_FRESH_WARN_THRESHOLD,
)


def _session_state_iter_string_values(obj):
    """Yield every STRING value nested in a json.load-ed snapshot object.

    Recurses dicts (values only — keys are structure, not state) and lists.
    Used by C-grammar (79) to scan all state values for SHAs / dates /
    narration. Cheap — the snapshot is a small bounded object (byte cap).
    """
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from _session_state_iter_string_values(v)
    elif isinstance(obj, (list, tuple)):
        for v in obj:
            yield from _session_state_iter_string_values(v)


# `_session_state_load()` + the `_SESSION_STATE_*` constants are imported
# `from .core` above (the BD-256 W1 seam — read by Checks 77/78/79 below).


def check_session_state_struct() -> None:
    """Check 77 — session-state snapshot structural well-formedness (BD-252).

    Parses `pack-ops/session-state.json` (`json.load`) and asserts the required
    P1-P9 key set (sized EXACTLY to the seed schema — measure-then-bound), plus
    that the two structural fields are well-typed: `boundary_commit` matches
    `^[0-9a-f]{7,40}$` and `checkpoint` is ISO-8601. Well-formedness so
    `/pack-startup` reads it deterministically and C-fresh / C-grammar can rely
    on the fields.

    SKIP-lenient when the snapshot is ABSENT (fresh clone / pre-feature HEAD —
    the seed ships in a LATER commit; until then this leg SKIPs, never fails).

    Cheap (ci-check-runtime-compounding): one small read + one json parse; no
    subprocess, no whole-tree scan.
    """
    print(
        "\n── Check 77: session-state snapshot structural well-formedness "
        "(BD-252) ──"
    )

    loaded = _session_state_load()
    if loaded is None:
        ok(
            f"{_SESSION_STATE_FILE} absent — skipping (lenient; the resumable "
            f"session-state snapshot is a live-state artifact, absent on a "
            f"fresh clone / pre-feature HEAD). When present, Check 77 asserts "
            f"the required P1-P9 key set + `boundary_commit` is 7-40 hex + "
            f"`checkpoint` is ISO-8601."
        )
        return

    if loaded[0] == "PARSE_ERROR":
        fail(
            f"{_SESSION_STATE_FILE} — INVALID JSON (could not parse): "
            f"{loaded[2]}. The snapshot must be valid JSON so /pack-startup "
            f"reads it deterministically. Fix the JSON syntax."
        )
        return

    data, _raw = loaded
    any_fail = False

    if not isinstance(data, dict):
        fail(
            f"{_SESSION_STATE_FILE} — top-level JSON must be an OBJECT "
            f"(got {type(data).__name__}). The snapshot is a keyed "
            f"current-frontier object (P1-P9)."
        )
        return

    # Required-key set (sized EXACTLY to P1-P9 — measure-then-bound).
    present = set(data.keys())
    required = set(_SESSION_STATE_REQUIRED_KEYS)
    missing = sorted(required - present)
    if missing:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — missing required key(s): {missing}. The "
            f"snapshot must carry the full P1-P9 frontier set "
            f"{list(_SESSION_STATE_REQUIRED_KEYS)}."
        )

    # `boundary_commit` (P7) — present + 7-40 hex.
    bc = data.get(_SESSION_STATE_SHA_KEY)
    if _SESSION_STATE_SHA_KEY in present:
        if not isinstance(bc, str) or not _SESSION_STATE_SHA_FULL_RE.match(bc):
            any_fail = True
            fail(
                f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_SHA_KEY}` must be a "
                f"7-40-char lowercase-hex commit SHA (got {bc!r}). It is the "
                f"single durable-boundary reference C-fresh resolves."
            )

    # `checkpoint` (P8) — present + ISO-8601.
    cp = data.get(_SESSION_STATE_DATE_KEY)
    if _SESSION_STATE_DATE_KEY in present:
        if not isinstance(cp, str) or not _SESSION_STATE_ISO_RE.match(cp):
            any_fail = True
            fail(
                f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_DATE_KEY}` must be an "
                f"ISO-8601 timestamp (e.g. `2026-06-29T00:00:00Z`); got {cp!r}. "
                f"It is the single freshness anchor."
            )

    if not any_fail:
        ok(
            f"Check 77 — {_SESSION_STATE_FILE}: valid JSON; required P1-P9 keys "
            f"present ({len(required)} keys); `{_SESSION_STATE_SHA_KEY}` is "
            f"7-40 hex; `{_SESSION_STATE_DATE_KEY}` is ISO-8601."
        )


def check_session_state_fresh() -> None:
    """Check 78 — session-state snapshot boundary freshness (BD-252).

    Reads `boundary_commit` and asserts it (a) resolves to a real commit
    (`git cat-file -e <sha>^{commit}`) AND (b) is an ancestor-of-or-equal-to
    HEAD (`git merge-base --is-ancestor <sha> HEAD`). When the boundary lags
    HEAD by more than the advisory threshold
    (`git rev-list --count <sha>..HEAD` > _SESSION_STATE_FRESH_WARN_THRESHOLD)
    the check ADVISORY-WARNs (NOT a fail — GATE DECISION 2).

    N2 (expected, not a failure): C-fresh advisory-WARNs as HEAD advances past a
    committed seed — the seed lags by the count of commits authored since it was
    written. That is the overwrite-on-every-change contract surfacing, not a
    defect; the WARN never changes the exit code.

    SKIP-lenient when the snapshot is ABSENT, when `boundary_commit` is absent /
    malformed (Check 77 owns that hard failure — C-fresh does not double-fail),
    or when git is unavailable / not a work tree (the Check 69 lenient idiom).

    Cheap (ci-check-runtime-compounding): one small read + 1-3 tiny git calls;
    no whole-tree scan.
    """
    print("\n── Check 78: session-state snapshot boundary freshness (BD-252) ──")

    loaded = _session_state_load()
    if loaded is None:
        ok(
            f"{_SESSION_STATE_FILE} absent — skipping (lenient; live-state "
            f"artifact absent on a fresh clone / pre-feature HEAD). When "
            f"present, Check 78 asserts `boundary_commit` resolves + is "
            f"ancestor-of-HEAD; advisory-WARN if it lags HEAD by "
            f">{_SESSION_STATE_FRESH_WARN_THRESHOLD} commit(s)."
        )
        return

    if loaded[0] == "PARSE_ERROR":
        ok(
            f"{_SESSION_STATE_FILE} unparseable — skipping freshness (lenient; "
            f"Check 77 owns the JSON-parse failure)."
        )
        return

    data, _raw = loaded
    sha = data.get(_SESSION_STATE_SHA_KEY) if isinstance(data, dict) else None
    if not isinstance(sha, str) or not _SESSION_STATE_SHA_FULL_RE.match(sha):
        ok(
            f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_SHA_KEY}` absent / "
            f"malformed; skipping freshness (lenient; Check 77 owns that "
            f"structural failure)."
        )
        return

    def _git(args):
        try:
            return subprocess.run(
                ["git", *args], capture_output=True, text=True, cwd=REPO_ROOT,
            )
        except FileNotFoundError:
            return None

    # Git availability / work-tree probe (lenient SKIP — Check 69 idiom).
    probe = _git(["rev-parse", "--is-inside-work-tree"])
    if probe is None or probe.returncode != 0:
        ok(
            f"git unavailable / not a git work tree — skipping freshness "
            f"(lenient; never hard-fail a non-git environment)."
        )
        return

    # (a) boundary resolves to a real commit.
    exists = _git(["cat-file", "-e", f"{sha}^{{commit}}"])
    if exists is None or exists.returncode != 0:
        fail(
            f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_SHA_KEY}` {sha!r} does "
            f"NOT resolve to a commit in this repo. The boundary must be a real "
            f"reachable commit. Re-author the snapshot at the current boundary "
            f"(the last landed commit SHA)."
        )
        return

    # (b) boundary is ancestor-of-or-equal-to HEAD.
    ancestor = _git(["merge-base", "--is-ancestor", sha, "HEAD"])
    if ancestor is None or ancestor.returncode != 0:
        fail(
            f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_SHA_KEY}` {sha!r} is NOT "
            f"an ancestor of HEAD. The boundary must be a commit reachable from "
            f"HEAD (the durable frontier the snapshot was built against). "
            f"Re-author the snapshot at the current boundary."
        )
        return

    # Advisory freshness: how far behind HEAD (advisory WARN only — never fail).
    behind = _git(["rev-list", "--count", f"{sha}..HEAD"])
    n_behind = 0
    if behind is not None and behind.returncode == 0:
        n_behind = int(behind.stdout.strip() or "0")
    if n_behind > _SESSION_STATE_FRESH_WARN_THRESHOLD:
        warn(
            f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_SHA_KEY}` {sha} lags "
            f"HEAD by {n_behind} commit(s) (> advisory threshold "
            f"{_SESSION_STATE_FRESH_WARN_THRESHOLD}). ADVISORY ONLY — this is "
            f"the overwrite-on-every-state-change contract surfacing (the seed "
            f"goes stale as HEAD advances; Pack Chat overwrites it on the next "
            f"transition). NOT a gate failure."
        )
    else:
        ok(
            f"Check 78 — {_SESSION_STATE_FILE}: `{_SESSION_STATE_SHA_KEY}` "
            f"{sha} resolves + is ancestor-of-HEAD ({n_behind} commit(s) "
            f"behind; <= advisory threshold "
            f"{_SESSION_STATE_FRESH_WARN_THRESHOLD})."
        )


def check_session_state_grammar() -> None:
    """Check 79 — session-state snapshot no-history grammar (BD-252).

    The bespoke anti-accretion grammar (DESIGN-RECONCILED §4). It PERMITS the
    snapshot's legitimate STATE — bare `BD-\\d+` tags (any number), exactly one
    date (only in `checkpoint`), exactly one SHA (only in `boundary_commit`) —
    and FORBIDS ACCRETION: a 2nd date, a 2nd SHA, any off-field SHA, the
    narration set (history shapes), and serialized size over the byte cap.

    Detector ORDERING (N3): the DECISIVE accretion detectors are the date / SHA
    / narration bounds; the byte cap is an anti-growth BACKSTOP (the structural
    teeth against append-growth that a token-count alone would miss) — it is
    checked LAST, after the precise bounds.

    SKIP-lenient when the snapshot is ABSENT or unparseable (Check 77 owns the
    parse failure).

    Cheap (ci-check-runtime-compounding): one small read + regex scans over a
    byte-capped object; no subprocess, no whole-tree scan.
    """
    print(
        "\n── Check 79: session-state snapshot no-history grammar (BD-252) ──"
    )

    loaded = _session_state_load()
    if loaded is None:
        ok(
            f"{_SESSION_STATE_FILE} absent — skipping (lenient; live-state "
            f"artifact absent on a fresh clone / pre-feature HEAD). When "
            f"present, Check 79 PERMITS bare BD-tags + 1 date (checkpoint) + 1 "
            f"SHA (boundary_commit) and FORBIDS accretion (2nd date/SHA, "
            f"off-field SHA, narration, size > {_SESSION_STATE_BYTE_CAP} B)."
        )
        return

    if loaded[0] == "PARSE_ERROR":
        ok(
            f"{_SESSION_STATE_FILE} unparseable — skipping grammar (lenient; "
            f"Check 77 owns the JSON-parse failure)."
        )
        return

    data, raw = loaded
    any_fail = False

    # Per-key string-value collection so date/SHA single-occurrence asserts can
    # key off the FIELD (JSON's keyed structure makes "only in `checkpoint` /
    # `boundary_commit`" exact — an advantage over a flat markdown scan).
    if isinstance(data, dict):
        sha_field_values = list(_session_state_iter_string_values(
            data.get(_SESSION_STATE_SHA_KEY)))
        date_field_values = list(_session_state_iter_string_values(
            data.get(_SESSION_STATE_DATE_KEY)))
    else:
        sha_field_values = []
        date_field_values = []
    all_values = list(_session_state_iter_string_values(data))

    # ── DECISIVE detector 1: dates. Exactly <=1 date, only in `checkpoint`.
    total_dates = 0
    off_field_dates = 0
    for v in all_values:
        hits = _SESSION_STATE_DATE_RE.findall(v)
        total_dates += len(hits)
    in_field_dates = sum(
        len(_SESSION_STATE_DATE_RE.findall(v)) for v in date_field_values)
    off_field_dates = total_dates - in_field_dates
    if total_dates > 1:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — ACCRETION: found {total_dates} date(s) "
            f"(20YY-MM-DD); the snapshot PERMITS exactly ONE, only in "
            f"`{_SESSION_STATE_DATE_KEY}`. A 2nd dated note = a history stack. "
            f"Overwrite the frontier; move history to BD/changelog/commit."
        )
    if off_field_dates > 0:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — ACCRETION: a date appears OUTSIDE "
            f"`{_SESSION_STATE_DATE_KEY}` ({off_field_dates} off-field). The "
            f"single checkpoint date must live ONLY in "
            f"`{_SESSION_STATE_DATE_KEY}`."
        )

    # ── DECISIVE detector 2: SHAs. Exactly <=1 SHA, only in `boundary_commit`.
    total_shas = 0
    for v in all_values:
        total_shas += len(_SESSION_STATE_SHA_RE.findall(v))
    in_field_shas = sum(
        len(_SESSION_STATE_SHA_RE.findall(v)) for v in sha_field_values)
    off_field_shas = total_shas - in_field_shas
    if total_shas > 1:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — ACCRETION: found {total_shas} commit "
            f"SHA(s) (7-40 hex); the snapshot PERMITS exactly ONE, only in "
            f"`{_SESSION_STATE_SHA_KEY}`. Multiple stacked SHAs = the carry-"
            f"over's failure. Keep only the boundary SHA."
        )
    if off_field_shas > 0:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — ACCRETION: a commit SHA appears OUTSIDE "
            f"`{_SESSION_STATE_SHA_KEY}` ({off_field_shas} off-field). The "
            f"single boundary SHA must live ONLY in `{_SESSION_STATE_SHA_KEY}`."
        )

    # ── DECISIVE detector 3: narration. ZERO history shapes. Bare BD-tags are
    # PERMITTED — strip them FIRST so a `bd-past-action` verb is the only thing
    # that fires on a BD-bearing value (a legal `"BD-219"` never trips).
    for v in all_values:
        stripped = _SESSION_STATE_BD_TAG_RE.sub("BD", v)
        for name, pat in _SESSION_STATE_NARRATION_PATTERNS:
            # bd-past-action and per-bd must scan the ORIGINAL value (they need
            # the BD-\d+); the strip protects bare BD-tags from every other
            # pattern.
            scan_target = v if name in ("bd-past-action", "per-bd") else stripped
            if pat.search(scan_target):
                any_fail = True
                fail(
                    f"{_SESSION_STATE_FILE} — ACCRETION: history/narration "
                    f"pattern `{name}` matched value {v[:80]!r}. The snapshot "
                    f"is current STATE only (bare BD-tags OK); history "
                    f"(lessons, carry notes, past-action narration) goes to "
                    f"BD/changelog/commit/handoff, never the snapshot."
                )
                break

    # ── BACKSTOP detector (N3): serialized byte size <= cap. Checked LAST — the
    # decisive detectors above catch the SHAPE of accretion; the cap catches its
    # GROWTH (a snapshot that grows over time is accreting).
    size = len(raw)
    if size > _SESSION_STATE_BYTE_CAP:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — ANTI-GROWTH BACKSTOP: {size} bytes "
            f"exceeds the {_SESSION_STATE_BYTE_CAP}-byte cap. A true current-"
            f"frontier snapshot is small + bounded; growth over time is "
            f"accretion. Overwrite the frontier; move history out."
        )

    if not any_fail:
        ok(
            f"Check 79 — {_SESSION_STATE_FILE}: no-history grammar OK "
            f"(<=1 date in `{_SESSION_STATE_DATE_KEY}`, <=1 SHA in "
            f"`{_SESSION_STATE_SHA_KEY}`, bare BD-tags permitted, zero "
            f"narration, {size} B <= {_SESSION_STATE_BYTE_CAP} B cap)."
        )


# ── __all__ — every Cluster-H-OWNED symbol the facade / the tests reach ─────
# `from validate_checks.session_state import *` skips underscore names UNLESS
# they are listed here; and once `__all__` is declared it ALSO gates the
# non-underscore names — so the three `check_*` (resolved by bare name in the
# facade's `_build_check_registry()`) MUST be enumerated. The Cluster-H-exclusive
# helper `_session_state_iter_string_values` is enumerated so the facade
# re-exports it (it is reached by test-validate-pack-check-79.sh's grammar
# legs). The `from .core` seams (`_session_state_load`, `_SESSION_STATE_*`) are
# NOT re-listed — they are core-owned (the facade re-exports them via
# `from validate_checks.core import *`); `__all__` enumerates only session_state's
# OWN symbols.
__all__ = [
    # ── Cluster-H-exclusive helper (read by Check 79) ──
    "_session_state_iter_string_values",
    # ── Cluster H check bodies (77, 78, 79) ──
    "check_session_state_struct",
    "check_session_state_fresh",
    "check_session_state_grammar",
]
