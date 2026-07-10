"""validate_checks.session_state — Cluster H: the BD-252 session-state
snapshot family (BD-256 W9) + the BD-271 narration-twin content-parity guard
(Check 85).

This module owns Cluster H's 3 session-state-snapshot check bodies (Checks 77,
78, 79) plus the Check 85 narration-twin content-parity guard (BD-271) — the
committed, CLI-agnostic resumable session-state snapshot
(`pack-ops/session-state.json`) guards: structural well-formedness (77,
struct), boundary freshness (78, fresh), and the bespoke no-history
anti-accretion grammar (79, grammar). Checks 77/78/79 are co-located because
they all key on the single session-state surface
(`pack-ops/session-state.json`) and share the `_session_state_load()` seam +
the `_SESSION_STATE_*` schema/grammar constants.

Check 85 (`check_narration_twin_content_parity`) SHARES the
`_SESSION_STATE_NARRATION_PATTERNS` constant Check 79 consumes but is a
cross-substrate PARITY guard, not a snapshot check: it does NOT key on the
JSON snapshot and does NOT use `_session_state_load()`. It reads Twin A
(`core.py :: _SESSION_STATE_NARRATION_PATTERNS`) as TEXT — for extraction
symmetry with the client twin, which cannot be imported — and compares it
against the client gate's embedded Twin B
(`project-template/scripts/validate-docs.sh :: _SS_NARRATION_PATTERNS`). It
therefore shares the narration constant with Cluster H but NOT the snapshot
surface or the `_session_state_load()` seam. See
`maintenance-docs/v11-implementation/DESIGN-BD-243-CLIENT-GATE.md` §C.3
addendum (BD-271) for why this narrow DATA parity is distinct from the
whole-gate BEHAVIORAL parity §C.3 rejected as a maintenance trap.

Checks 77/78/79 bodies are MOVED VERBATIM from the facade
(`scripts/validate-pack.py`); Check 85 is authored directly in this module
(BD-271 — not a move). The facade re-exports every symbol here via
`from validate_checks.session_state import *`, so the registry assembled in the
facade (`_build_check_registry()`) keeps resolving each `check_*` name
(77/78/79/85). Single SSOT — no forked copy.

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
module top (Check 78's git-probe calls); `ast` and `re` are also imported
directly (Check 85's text-AST twin extraction + the bd/td token fold),
mirroring the established per-module convention (the spine `import *` does not
re-export stdlib names).
"""

import ast
import re
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


# ── Check 85 — narration-twin regex-CONTENT parity (BD-271) ────────────────
# DESIGN-BD271-check85 FINAL (authority). Twin A (pack):
# `_SESSION_STATE_NARRATION_PATTERNS` above. Twin B (client-shipped,
# READ-ONLY input): `_SS_NARRATION_PATTERNS` embedded in the
# `python3 - <<'PYEOF'` heredoc in
# `project-template/scripts/validate-docs.sh`.

# The two twin (repo-relative path, symbol) pairs. Resolved against
# REPO_ROOT (imported above) so a test can monkeypatch REPO_ROOT at a `/tmp`
# fixture tree (the Check-80 BITE-1 idiom).
_CHECK_85_TWIN_A = (
    "scripts/lib/validate_checks/core.py",
    "_SESSION_STATE_NARRATION_PATTERNS",
)
_CHECK_85_TWIN_B = (
    "project-template/scripts/validate-docs.sh",
    "_SS_NARRATION_PATTERNS",
)

# Token-boundary bd/td audience fold (FINAL §5) — applied to name AND source.
_CHECK_85_BD_TD_FOLD = re.compile(r"(?i)(?<![A-Za-z0-9])(bd|td)(?![A-Za-z0-9])")

# The measured sanctioned divergent set (EE-N2), sized EXACTLY to the
# measurement — patterns #1/#2 only (`bd-past-action`/`td-past-action` and
# `per-bd`/`per-td`). Keyed by the FOLDED (audience-neutral) name.
_CHECK_85_SANCTIONED_FOLDED_NAMES = frozenset({"XX-past-action", "per-XX"})

# Restricted `re`-flag namespace (FINAL §2) — the ONLY flag references the
# canonicalizer recognizes; built once from the real `re` module so the
# integer values are authoritative (never a hand-copied literal table).
_CHECK_85_RE_FLAG_MAP = {
    name: int(getattr(re, name))
    for name in (
        "A", "ASCII", "I", "IGNORECASE", "L", "LOCALE", "M", "MULTILINE",
        "S", "DOTALL", "U", "UNICODE", "X", "VERBOSE",
    )
}

# Directionality guard tokens (FINAL §5.2) — token-boundary BD/TD (not the
# lowercase bd/td the fold matches; these check the RAW, unfolded source).
_CHECK_85_BD_TOKEN_RE = re.compile(r"(?<![A-Za-z0-9])BD(?![A-Za-z0-9])")
_CHECK_85_TD_TOKEN_RE = re.compile(r"(?<![A-Za-z0-9])TD(?![A-Za-z0-9])")


class _Check85ExtractError(Exception):
    """Internal signal for `check_narration_twin_content_parity()`: any
    extraction / canonicalization failure that must FAIL LOUD. Raised by the
    private helpers below; caught by the check body and converted to a
    single `fail()` call there — the uniform mechanism that keeps `fail()`
    calls out of the pure helpers (PLAN §4/§9 note 2)."""


def _check_85_eval_flag_node(node):
    """Evaluate ONE flag AST node to an int against the restricted `re`-flag
    namespace (FINAL §2). Never `eval()`s source, imports the file, or calls
    `re.compile` — the restricted-namespace AST walk is the only sanctioned
    path. Raises `_Check85ExtractError` on any node shape it does not
    recognize."""
    if isinstance(node, ast.Attribute):
        if (
            isinstance(node.value, ast.Name)
            and node.value.id == "re"
            and node.attr in _CHECK_85_RE_FLAG_MAP
        ):
            return _CHECK_85_RE_FLAG_MAP[node.attr]
        raise _Check85ExtractError(
            f"unrecognized flag reference `{ast.dump(node)}` (not a known "
            f"`re.<FLAG>` attribute)"
        )
    if isinstance(node, ast.BinOp) and isinstance(node.op, ast.BitOr):
        return _check_85_eval_flag_node(node.left) | _check_85_eval_flag_node(
            node.right
        )
    if isinstance(node, ast.Constant) and isinstance(node.value, int):
        return node.value
    if isinstance(node, ast.Name) and node.id in _CHECK_85_RE_FLAG_MAP:
        return _CHECK_85_RE_FLAG_MAP[node.id]
    raise _Check85ExtractError(
        f"unrecognized flag construct `{ast.dump(node)}` — the restricted "
        f"flag evaluator only accepts `re.<FLAG>`, `<FLAG>|<FLAG>` (BitOr), "
        f"a bare int, or a from-import bare name"
    )


def _check_85_canon_flags(compile_call):
    """Canonicalize a `re.compile(...)` `Call` node's flags to a single
    INTEGER (FINAL §2 — the load-bearing fix; compare integers, NEVER
    attribute-name strings: `re.I == re.IGNORECASE == 2`). Collects every
    positional flag arg (`call.args[1:]`) plus the `flags=` keyword value (if
    any) and OR-s their canonicalized integer values. No flag nodes -> `0`
    (an EXPLICIT-AST no-flags pattern canonicalizes to `0`, never the
    implicit `re.UNICODE` a live `re.compile(...).flags` read would carry —
    see FINAL §1's rejected-alternative)."""
    nodes = list(compile_call.args[1:])
    for kw in compile_call.keywords:
        if kw.arg == "flags":
            nodes.append(kw.value)
    if not nodes:
        return 0
    acc = 0
    for node in nodes:
        acc |= _check_85_eval_flag_node(node)
    return acc


def _check_85_extract_twin(text, path_rel, symbol):
    """Extract an ORDERED list of `(name, source, flags_int)` from `text`
    (a twin's full module source, or Twin B's sliced heredoc body) by
    locating the `symbol = (...)` tuple assignment and AST-parsing each
    element as `(name_literal, re.compile(source_literal, *flags))`.

    Raises `_Check85ExtractError` naming `path_rel` + what could not be
    located on ANY parse / locate / shape failure (FINAL §7 — symmetric
    fail-loud for BOTH twins; never a silent skip on a present-but-
    unextractable twin)."""
    try:
        tree = ast.parse(text)
    except SyntaxError as exc:
        raise _Check85ExtractError(
            f"{path_rel} — could not ast.parse the extracted text for "
            f"`{symbol}`: {exc}"
        )

    assign = None
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and len(node.targets) == 1:
            tgt = node.targets[0]
            if isinstance(tgt, ast.Name) and tgt.id == symbol:
                assign = node
                break
    if assign is None:
        raise _Check85ExtractError(
            f"{path_rel} — could not locate the `{symbol} = (...)` "
            f"assignment"
        )
    if not isinstance(assign.value, ast.Tuple):
        raise _Check85ExtractError(
            f"{path_rel} — `{symbol}` is not a tuple literal (got "
            f"{type(assign.value).__name__})"
        )

    result = []
    for elt in assign.value.elts:
        if not isinstance(elt, ast.Tuple) or len(elt.elts) != 2:
            raise _Check85ExtractError(
                f"{path_rel} — `{symbol}` has an element that is not a "
                f"2-tuple `(name, re.compile(...))`: {ast.dump(elt)}"
            )
        name_node, call_node = elt.elts
        try:
            name = ast.literal_eval(name_node)
        except Exception as exc:
            raise _Check85ExtractError(
                f"{path_rel} — `{symbol}` element name is not a literal: "
                f"{exc}"
            )
        if (
            not isinstance(call_node, ast.Call)
            or not isinstance(call_node.func, ast.Attribute)
            or call_node.func.attr != "compile"
            or not isinstance(call_node.func.value, ast.Name)
            or call_node.func.value.id != "re"
        ):
            raise _Check85ExtractError(
                f"{path_rel} — `{symbol}` axis {name!r} value is not a "
                f"`re.compile(...)` call"
            )
        if not call_node.args:
            raise _Check85ExtractError(
                f"{path_rel} — `{symbol}` axis {name!r} `re.compile(...)` "
                f"call has no source argument"
            )
        try:
            source = ast.literal_eval(call_node.args[0])
        except Exception as exc:
            raise _Check85ExtractError(
                f"{path_rel} — `{symbol}` axis {name!r} regex source is "
                f"not a literal: {exc}"
            )
        try:
            flags_int = _check_85_canon_flags(call_node)
        except _Check85ExtractError as exc:
            raise _Check85ExtractError(
                f"{path_rel} — `{symbol}` axis {name!r}: {exc}"
            )
        result.append((name, source, flags_int))
    return result


def _check_85_slice_twin_b_heredoc(text, path_rel, symbol):
    """FINAL §8 — select the `python3 ... <<DELIM` heredoc whose BODY
    contains `symbol`'s assignment (never a naive first-heredoc match), strip
    the delimiter's surrounding quotes, and slice to the line that EQUALS
    the bare delimiter (never the quoted form; never slice to EOF).

    Raises `_Check85ExtractError` naming `path_rel` on any opener /
    selection / close-line failure."""
    lines = text.splitlines()
    opener_re = re.compile(r"\bpython3\b.*<<-?\s*(['\"]?)(\w+)\1\s*$")

    candidates = []
    for i, line in enumerate(lines):
        m = opener_re.search(line)
        if m:
            candidates.append((i, m.group(2)))
    if not candidates:
        raise _Check85ExtractError(
            f"{path_rel} — no `python3 ... <<DELIM` heredoc opener found"
        )

    selected = None
    for opener_idx, delim in candidates:
        close_idx = None
        for j in range(opener_idx + 1, len(lines)):
            if lines[j] == delim:
                close_idx = j
                break
        if close_idx is None:
            continue  # this heredoc never closes with a bare-delimiter line
        body = "\n".join(lines[opener_idx + 1 : close_idx])
        if symbol in body:
            selected = body
            break
    if selected is None:
        raise _Check85ExtractError(
            f"{path_rel} — no `python3` heredoc body (that closes with a "
            f"bare-delimiter line) contains the `{symbol}` assignment "
            f"(delimiter munged, assignment renamed, or the heredoc never "
            f"closes)"
        )
    return selected


def check_narration_twin_content_parity() -> None:
    """Check 85 — narration-twin regex-CONTENT parity guard (BD-271).

    Enforces regex-CONTENT parity (source bytes + INTEGER-value flags,
    load-bearing) between the two session-state narration-pattern twins:
      - Twin A (pack): `_SESSION_STATE_NARRATION_PATTERNS` in
        `scripts/lib/validate_checks/core.py` (this package).
      - Twin B (client-shipped, READ-ONLY input): `_SS_NARRATION_PATTERNS`
        embedded in the `python3 - <<'PYEOF'` heredoc in
        `project-template/scripts/validate-docs.sh`.

    This is a NARROW DATA-parity guard on ONE co-maintained shared literal —
    NOT the whole-gate BEHAVIORAL parity
    `maintenance-docs/v11-implementation/DESIGN-BD-243-CLIENT-GATE.md` §C.3
    rejected as a maintenance trap (see the §C.3 addendum, BD-271). Check 70
    (`check_client_doc_gate_parity`) guards the client gate's STRUCTURE
    (presence/axes/wiring); Check 85 guards this ONE shared DATA literal's
    content. Neither compares whole-gate behavior.

    Algorithm (DESIGN-BD271-check85 FINAL §9): Twin-B-FILE-absent lenient
    SKIP -> extract Twin A (AST from `core.py` TEXT) -> extract Twin B
    (select + slice the `python3` heredoc containing the assignment) ->
    count-parity assert -> per-twin dict-build with duplicate-folded-name
    FAIL-loud -> fold-reach guard (only the measured `bd`/`td` axes may
    diverge) -> directionality guard (Twin A carries BD, Twin B carries TD
    on the sanctioned axes) -> bidirectional map compare on
    `(FOLD(source), flags_int)` -> clean pass.

    SKIP-lenient ONLY when the Twin B FILE is wholly absent (a fresh-clone /
    pre-install artifact). Twin A absent, or either twin present-but-
    unextractable, is a structural FAIL (never a silent skip).

    Cheap (ci-check-runtime-compounding): reads exactly TWO named files; two
    `ast.parse` calls; in-memory fold/int/set work. No subprocess, no `git`,
    no filesystem walk.
    """
    print("\n── Check 85: narration-twin regex-CONTENT parity (BD-271) ──")

    twin_a_path = REPO_ROOT / _CHECK_85_TWIN_A[0]
    twin_b_path = REPO_ROOT / _CHECK_85_TWIN_B[0]

    if not twin_b_path.is_file():
        ok(
            f"Check 85 — {_CHECK_85_TWIN_B[0]} absent — skipping (lenient; "
            f"the client doc gate is a pre-install / not-yet-shipped "
            f"artifact). When present, Check 85 asserts regex-CONTENT "
            f"parity (source + integer-value flags) between "
            f"`{_CHECK_85_TWIN_A[0]}::{_CHECK_85_TWIN_A[1]}` (pack) and "
            f"`{_CHECK_85_TWIN_B[0]}::{_CHECK_85_TWIN_B[1]}` (client)."
        )
        return

    try:
        a_text = twin_a_path.read_text()
    except OSError as exc:
        fail(
            f"Check 85 — could not read {_CHECK_85_TWIN_A[0]}: {exc}. This "
            f"is the check's OWN package (not a lenient-absent case)."
        )
        return

    try:
        twin_a = _check_85_extract_twin(
            a_text, _CHECK_85_TWIN_A[0], _CHECK_85_TWIN_A[1]
        )
    except _Check85ExtractError as exc:
        fail(f"Check 85 — Twin A extraction failed: {exc}")
        return

    try:
        b_text = twin_b_path.read_text()
    except OSError as exc:
        fail(f"Check 85 — could not read {_CHECK_85_TWIN_B[0]}: {exc}.")
        return

    try:
        b_body = _check_85_slice_twin_b_heredoc(
            b_text, _CHECK_85_TWIN_B[0], _CHECK_85_TWIN_B[1]
        )
        twin_b = _check_85_extract_twin(
            b_body, _CHECK_85_TWIN_B[0], _CHECK_85_TWIN_B[1]
        )
    except _Check85ExtractError as exc:
        fail(f"Check 85 — Twin B extraction failed: {exc}")
        return

    # ── Count parity (FINAL §6.1) ──
    if len(twin_a) != len(twin_b):
        fail(
            f"Check 85 — narration twins differ in pattern COUNT "
            f"(pack={len(twin_a)}, client={len(twin_b)}) — a pattern was "
            f"added/removed on one side only. pack="
            f"{_CHECK_85_TWIN_A[0]}::{_CHECK_85_TWIN_A[1]} client="
            f"{_CHECK_85_TWIN_B[0]}::{_CHECK_85_TWIN_B[1]}."
        )
        return

    def _fold(s):
        return _CHECK_85_BD_TD_FOLD.sub("XX", s)

    def _build_map(twin_list, twin_label):
        built = {}
        for name, source, flags_int in twin_list:
            key = _fold(name)
            if key in built:
                raise _Check85ExtractError(
                    f"narration twin {twin_label} has a DUPLICATE axis "
                    f"'{key}' — a duplicate collapses last-wins and can "
                    f"hide a wrong-body copy; each axis name must be "
                    f"unique."
                )
            built[key] = (name, source, _fold(source), flags_int)
        return built

    # ── Per-twin dict-build with duplicate-folded-name FAIL-loud (§6.2) ──
    try:
        map_a = _build_map(twin_a, "A (pack)")
        map_b = _build_map(twin_b, "B (client)")
    except _Check85ExtractError as exc:
        fail(f"Check 85 — {exc}")
        return

    any_fail = False

    # ── Fold-reach guard (§5.1) — a bd/td token is PERMITTED only on the
    # measured sanctioned axes; any other axis carrying one FAILs loud.
    for twin_list, twin_label in (
        (twin_a, "A (pack)"),
        (twin_b, "B (client)"),
    ):
        for name, source, _flags in twin_list:
            key = _fold(name)
            if key in _CHECK_85_SANCTIONED_FOLDED_NAMES:
                continue
            if _CHECK_85_BD_TD_FOLD.search(name) or _CHECK_85_BD_TD_FOLD.search(
                source
            ):
                any_fail = True
                fail(
                    f"Check 85 — narration axis '{name}' (twin "
                    f"{twin_label}) carries a bd/td token but is not in "
                    f"the sanctioned divergent set "
                    f"{sorted(_CHECK_85_SANCTIONED_FOLDED_NAMES)}; the fold "
                    f"would collapse it unguarded — extend the "
                    f"directionality guard or reconsider the fold."
                )
    if any_fail:
        return

    # ── Directionality guard (§5.2) — Twin A carries BD (not TD); Twin B
    # carries TD (not BD) on the sanctioned axes (catches a wrong-audience
    # copy the fold alone would collapse to 'XX-').
    for key in sorted(_CHECK_85_SANCTIONED_FOLDED_NAMES):
        a_entry = map_a.get(key)
        b_entry = map_b.get(key)
        if a_entry is None or b_entry is None:
            continue  # absence is caught by the bidirectional compare below
        a_name, a_source = a_entry[0], a_entry[1]
        b_name, b_source = b_entry[0], b_entry[1]
        if not (
            _CHECK_85_BD_TOKEN_RE.search(a_source)
            and not _CHECK_85_TD_TOKEN_RE.search(a_source)
        ):
            any_fail = True
            fail(
                f"Check 85 — directionality: pack twin axis '{a_name}' "
                f"(sanctioned axis '{key}') does not carry the expected "
                f"BD (not TD) vocabulary: {a_source!r}."
            )
        if not (
            _CHECK_85_TD_TOKEN_RE.search(b_source)
            and not _CHECK_85_BD_TOKEN_RE.search(b_source)
        ):
            any_fail = True
            fail(
                f"Check 85 — directionality: client twin axis '{b_name}' "
                f"(sanctioned axis '{key}') does not carry the expected TD "
                f"(not BD) vocabulary — likely a wrong-audience copy: "
                f"{b_source!r}."
            )
    if any_fail:
        return

    # ── Bidirectional map compare (§8) — FAIL on missing/extra axes and on
    # any shared axis whose (folded source, flags_int) differs.
    keys_a = set(map_a)
    keys_b = set(map_b)
    for key in sorted(keys_a - keys_b):
        any_fail = True
        fail(
            f"Check 85 — axis '{map_a[key][0]}' present in the pack twin "
            f"({_CHECK_85_TWIN_A[0]}) but MISSING in the client twin "
            f"({_CHECK_85_TWIN_B[0]}). Add/remove the pattern on both "
            f"sides in lock-step."
        )
    for key in sorted(keys_b - keys_a):
        any_fail = True
        fail(
            f"Check 85 — axis '{map_b[key][0]}' present in the client "
            f"twin ({_CHECK_85_TWIN_B[0]}) but MISSING in the pack twin "
            f"({_CHECK_85_TWIN_A[0]}). Add/remove the pattern on both "
            f"sides in lock-step."
        )
    for key in sorted(keys_a & keys_b):
        a_name, a_source, a_fold_source, a_flags = map_a[key]
        b_name, b_source, b_fold_source, b_flags = map_b[key]
        if (a_fold_source, a_flags) != (b_fold_source, b_flags):
            any_fail = True
            fail(
                f"Check 85 — narration-twin CONTENT drift on axis '{key}': "
                f"pack ({_CHECK_85_TWIN_A[0]}::{_CHECK_85_TWIN_A[1]}) axis "
                f"'{a_name}'=(source={a_source!r}, flags={a_flags}) client "
                f"({_CHECK_85_TWIN_B[0]}::{_CHECK_85_TWIN_B[1]}) axis "
                f"'{b_name}'=(source={b_source!r}, flags={b_flags}). The "
                f"twins must carry byte-identical regex source + "
                f"integer-equal flags (only the sanctioned bd<->td "
                f"vocabulary on "
                f"{sorted(_CHECK_85_SANCTIONED_FOLDED_NAMES)} may differ). "
                f"Align both twins in the same change."
            )

    if any_fail:
        return

    ok(
        f"Check 85 — {len(twin_a)} patterns per twin; folded-parity holds "
        f"(no missing/extra, no source/flag drift); fold-reach bounded to "
        f"{sorted(_CHECK_85_SANCTIONED_FOLDED_NAMES)}; directionality OK."
    )


# ── __all__ — every Cluster-H-OWNED symbol the facade / the tests reach ─────
# `from validate_checks.session_state import *` skips underscore names UNLESS
# they are listed here; and once `__all__` is declared it ALSO gates the
# non-underscore names — so the four `check_*` (resolved by bare name in the
# facade's `_build_check_registry()`) MUST be enumerated. The Cluster-H-exclusive
# helper `_session_state_iter_string_values` is enumerated so the facade
# re-exports it (it is reached by test-validate-pack-check-79.sh's grammar
# legs). The `from .core` seams (`_session_state_load`, `_SESSION_STATE_*`) are
# NOT re-listed — they are core-owned (the facade re-exports them via
# `from validate_checks.core import *`); `__all__` enumerates only session_state's
# OWN symbols. The `_CHECK_85_*` constants + `_check_85_canon_flags` are
# enumerated so test-validate-pack-check-85.sh reaches them by name via the
# facade (FINAL §11 surface 2).
__all__ = [
    # ── Cluster-H-exclusive helper (read by Check 79) ──
    "_session_state_iter_string_values",
    # ── Cluster H check bodies (77, 78, 79) ──
    "check_session_state_struct",
    "check_session_state_fresh",
    "check_session_state_grammar",
    # ── Cluster H parity guard (85, BD-271) ──
    "check_narration_twin_content_parity",
    "_check_85_canon_flags",
    "_CHECK_85_TWIN_A",
    "_CHECK_85_TWIN_B",
    "_CHECK_85_SANCTIONED_FOLDED_NAMES",
    "_CHECK_85_BD_TD_FOLD",
]
