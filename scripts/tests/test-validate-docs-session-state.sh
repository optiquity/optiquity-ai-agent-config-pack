#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-docs-session-state.sh — behavioral coverage for
# the BD-253 client doc-gate session-state leg
# (project-template/scripts/validate-docs.sh: run_session_state,
# _SS_NARRATION_PATTERNS, _ss_iter_string_values, the struct + grammar checks
# over docs/project/pm-session-state.json).
#
# Closes the ~zero-coverage gap a review found: the pack twin
# (scripts/lib/validate_checks/core.py / session_state.py, Check 79) has
# scripts/tests/test-validate-pack-check-79.sh's T1-T11 behavioral suite;
# this CLIENT gate had NONE. The narration twins were just aligned to
# case-sensitive (BD-252 pack / BD-253 client; post-Commit CAUGHT /
# post-commit PERMITTED) — this test proves the client side actually
# enforces it.
#
# Harness (drives the REAL embedded Python, never re-implemented):
#   Group A  extracts the embedded python3 heredoc block VERBATIM from the
#            shipped validate-docs.sh into a scratch .py file, then execs it
#            in-process (catching the module's own sys.exit(main())) to
#            obtain the LIVE run_session_state / _SS_NARRATION_PATTERNS /
#            _SS_FILE symbols — no stub, no re-implementation. A shared
#            in-process harness (module-load + fixture builders + assertion
#            helpers) is written once and exec'd fresh by every later group.
#   Group F  ALSO stages the real shipped gate + allowlist into a scratch
#            client tree and runs `bash validate-docs.sh` end-to-end — the
#            same stage-the-real-gate idiom as
#            scripts/tests/test-validate-docs-target-coherence.sh — proving
#            the session-state leg is actually WIRED into main(), not merely
#            unit-callable.
#
# Drift screen (declare-verify-backing): Group A reads the LIVE
# _SS_NARRATION_PATTERNS axis-name set from the shipped file at run time
# (never hardcoded) and asserts it equals this test's own covered-axis set —
# a new/renamed axis lands here as a LOUD failure, never a silent gap.
#
# Portability note (macOS bash 3.2): every embedded python3 invocation below
# redirects stdout+stderr to a scratch file and reads it back via
# `out="$(cat "$file")"` afterward, rather than wrapping the heredoc directly
# in `out="$(python3 <<'PYEOF' ... PYEOF)"`. Stock bash 3.2 has a heredoc
# quote-parity parsing bug when a `<<'DELIM'` heredoc sits inside a `$(...)`
# command substitution and its body contains an ODD number of literal single
# quotes (e.g. an English contraction in a comment) — it misparses the
# substitution's own closing paren. Redirecting to a file sidesteps the bug
# entirely (the command substitution around `cat "$file"` never contains a
# heredoc).
#
# Coverage (honesty per declare-verify-backing / enumerate-encoding-surfaces):
#   COVERED — struct: absent-file lenient SKIP, invalid JSON, non-object
#     top-level, missing required key(s), boundary_commit format (bad chars /
#     too short / wrong type), checkpoint format (non-ISO-8601 / wrong type);
#     grammar: >1 date (+ off-field), >1 commit SHA (+ off-field), EVERY
#     _SS_NARRATION_PATTERNS axis (11, read LIVE) each on its own isolated
#     violating fixture, the post-commit case-sensitivity pair (capital-C
#     CAUGHT / lowercase PERMITTED), bare TD-tag PERMITTED (the strip),
#     td-past-action / per-td biting the ORIGINAL (pre-strip) value,
#     _ss_iter_string_values recursing into a nested list-of-list-of-dict,
#     the byte-cap ANTI-GROWTH backstop, a fully-clean PASS baseline, and
#     end-to-end CLI wiring (Group F: clean PASS + dirty FAIL).
#   NOT COVERED (documented, not silently claimed clean):
#     - The "cannot read (...)" OSError branch. A chmod-based unreadable-file
#       simulation is unreliable when the test runs as root or under some CI
#       container UIDs (permission checks bypassed) — SIZE + reliability
#       call; a follow-up could use a monkeypatched builtins.open if this
#       branch ever regresses.
#     - The shipped validate-docs.sh --self-test entry point carries NO
#       session-state leg of its own (its self-test only exercises the 4
#       operating-doc axes + the per-entry conformance leg) — informational;
#       adding one would mean editing validate-docs.sh, which is out of this
#       task's pack-only scope (the twin fix already landed there).
#
# Usage:    bash scripts/tests/test-validate-docs-session-state.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GATE="$PACK_ROOT/project-template/scripts/validate-docs.sh"
ALLOWLIST="$PACK_ROOT/project-template/scripts/.docs-gate-allowlist.txt"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-vdocs-sessionstate.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '%s\n' "$2" | sed 's/^/    /'
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

if [[ ! -f "$GATE" ]]; then
    fail "gate script present" "missing: $GATE"
fi
if [[ ! -f "$ALLOWLIST" ]]; then
    fail "allowlist present" "missing: $ALLOWLIST"
fi
if [[ $fails -gt 0 ]]; then
    echo "=== Results: $passes passed, $fails failed ==="
    exit 1
fi

echo "== BD-253 client session-state gate: behavioral coverage =="

EMBEDDED_PY="$FIXTURE_BASE/embedded_validate_docs.py"
HARNESS_PY="$FIXTURE_BASE/session_state_harness.py"

# ─────────────────────────────────────────────────────────────────────────
# Group A: extraction sanity + shared harness + LIVE drift screen
# ─────────────────────────────────────────────────────────────────────────
echo
echo "== Group A: extraction + harness + drift screen =="

# A1 — extract the embedded python3 heredoc block VERBATIM from the shipped
# gate (the same "<<'PYEOF' ... PYEOF" heredoc validate-docs.sh feeds to
# python3) into a scratch .py file. Never re-typed / re-implemented.
A1_OUT="$FIXTURE_BASE/a1.out"
GATE_PATH="$GATE" OUT_PATH="$EMBEDDED_PY" python3 > "$A1_OUT" 2>&1 <<'PYEOF'
import os
import sys

GATE = os.environ["GATE_PATH"]
OUT = os.environ["OUT_PATH"]
text = open(GATE, encoding="utf-8").read()
START = "<<" + "'PYEOF'\n"
if text.count(START) != 1:
    print("FAIL_MARKER_COUNT", text.count(START))
    sys.exit(1)
body_start = text.index(START) + len(START)
body_end = text.rindex("\nPYEOF")
if body_end <= body_start:
    print("FAIL_MARKER_ORDER")
    sys.exit(1)
py_src = text[body_start:body_end]
needed = ("_SS_NARRATION_PATTERNS", "def run_session_state(",
          "_ss_iter_string_values", "_SS_REQUIRED_KEYS", "_SS_BYTE_CAP",
          "_SS_FILE")
missing = [n for n in needed if n not in py_src]
if missing:
    print("FAIL_MISSING_TEXT", missing)
    sys.exit(1)
with open(OUT, "w", encoding="utf-8") as fh:
    fh.write(py_src)
print("OK extracted %d bytes" % len(py_src))
PYEOF
a1_out="$(cat "$A1_OUT")"
if printf '%s' "$a1_out" | grep -q "^OK extracted"; then
    pass "Group A1: extraction lands on the real embedded block ($(printf '%s' "$a1_out" | sed -n 's/^OK extracted \([0-9]*\) bytes/\1 bytes/p'); required-symbol text present verbatim)"
else
    fail "Group A1: extraction from the shipped gate failed" "$a1_out"
fi

# A2 — the shared in-process harness every later group execs fresh: loads
# the extracted module (catching its own sys.exit(main())) and exposes
# run_session_state / NARRATION / SS_FILE plus fixture builders +
# assertion helpers used by every group below.
cat > "$HARNESS_PY" <<'HARNESSEOF'
import contextlib
import io
import json
import os
import shutil
import tempfile

EMBEDDED = os.environ["EMBEDDED_PATH"]


def _load_module():
    """exec the extracted embedded-python source in a fresh namespace,
    catching the module's own trailing sys.exit(main()) (it runs main()
    against a throwaway empty ROOT_DIR, a clean no-op) so every name defined
    ABOVE that trailing call (run_session_state, _SS_NARRATION_PATTERNS,
    _SS_FILE, ...) survives in the namespace dict."""
    scratch_root = tempfile.mkdtemp(prefix="vdocs-ss-embedroot-")
    os.environ["ROOT_DIR"] = scratch_root
    os.environ["ALLOWLIST"] = "/nonexistent-allowlist.txt"
    os.environ["GATE_MODE"] = "scan"
    os.environ["ARG_FILE"] = ""
    ns = {"__name__": "validate_docs_embedded"}
    src = open(EMBEDDED, encoding="utf-8").read()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            exec(compile(src, EMBEDDED, "exec"), ns)
    except SystemExit:
        pass
    finally:
        shutil.rmtree(scratch_root, ignore_errors=True)
    return ns


_NS = _load_module()
run_session_state = _NS["run_session_state"]
NARRATION = _NS["_SS_NARRATION_PATTERNS"]
SS_FILE = _NS["_SS_FILE"]


def clean_snapshot():
    """A fully conforming pm-session-state.json body: 1 date only in
    checkpoint, 1 SHA only in boundary_commit, bare TD-tags (PERMITTED), no
    narration, well under the byte cap."""
    return {
        "schema": "pm-session-state/1",
        "boundary_commit": "abc1234",
        "checkpoint": "2026-07-02T00:00:00Z",
        "active": [],
        "in_flight_agents": [],
        "queue": ["TD-1", "TD-2"],
        "parallelization": "serial",
        "wave": None,
        "pending_decisions": [],
        "cycle_position": None,
    }


def build_tree(data=None, raw=None, include=True):
    """A scratch client-tree root carrying (or, if include=False, lacking)
    docs/project/pm-session-state.json at the real SS_FILE relative path."""
    d = tempfile.mkdtemp(prefix="vdocs-ss-fixture-")
    if include:
        p = os.path.join(d, SS_FILE)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        if raw is not None:
            with open(p, "wb") as fh:
                fh.write(raw)
        else:
            payload = data if data is not None else clean_snapshot()
            with open(p, "w", encoding="utf-8") as fh:
                fh.write(json.dumps(payload, indent=2) + "\n")
    return d


def run_in_tree(**kwargs):
    """Build a scratch tree, run the REAL run_session_state against it,
    clean up, return the fails list."""
    root = build_tree(**kwargs)
    try:
        return run_session_state(root)
    finally:
        shutil.rmtree(root, ignore_errors=True)


def check_hit(bucket, label, fails, substr):
    if not any(substr in f for f in fails):
        bucket.append("%s: expected a fail containing %r, got %r"
                       % (label, substr, fails))


def check_clean(bucket, label, fails):
    if fails:
        bucket.append("%s: expected 0 fails, got %r" % (label, fails))


def check_count(bucket, label, fails, n):
    if len(fails) != n:
        bucket.append("%s: expected exactly %d fail(s), got %d: %r"
                       % (label, n, len(fails), fails))
HARNESSEOF

# A2 verification run: the harness loads cleanly + the live drift screen.
A2_OUT="$FIXTURE_BASE/a2.out"
EMBEDDED_PATH="$EMBEDDED_PY" HARNESS_PATH="$HARNESS_PY" python3 > "$A2_OUT" 2>&1 <<'PYEOF'
import os
import sys

exec(compile(open(os.environ["HARNESS_PATH"], encoding="utf-8").read(),
             os.environ["HARNESS_PATH"], "exec"))

failures = []

for _name in ("run_session_state", "NARRATION", "SS_FILE", "clean_snapshot",
              "build_tree", "run_in_tree", "check_hit", "check_clean",
              "check_count"):
    if _name not in dir():
        failures.append("harness did not expose expected name: %r" % _name)

if SS_FILE != "docs/project/pm-session-state.json":
    failures.append("SS_FILE unexpected: %r" % (SS_FILE,))

live_names = sorted(n for n, _ in NARRATION)
COVERED_AXES = sorted([
    "td-past-action", "per-td", "carry-over", "user-locked", "incident",
    "commit-n", "override-n", "post-commit", "pre-date", "lessons-marker",
    "update-marker",
])
if live_names != COVERED_AXES:
    failures.append(
        "DRIFT: live _SS_NARRATION_PATTERNS axis names %r != this test's "
        "covered-axis set %r (extra-live=%r extra-test=%r), a new or "
        "renamed axis needs a fixture added to this test"
        % (live_names, COVERED_AXES,
           sorted(set(live_names) - set(COVERED_AXES)),
           sorted(set(COVERED_AXES) - set(live_names))))

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK axes=%s" % ",".join(live_names))
PYEOF
a2_out="$(cat "$A2_OUT")"
if printf '%s' "$a2_out" | grep -q "^OK axes="; then
    pass "Group A2: shared harness loads (module exec + fixture/assert helpers exposed) + LIVE axis-name DRIFT SCREEN matches this test's covered set (${a2_out##*axes=})"
else
    fail "Group A2: harness load / drift-screen check failed" "$a2_out"
fi

# ─────────────────────────────────────────────────────────────────────────
# Group B: struct checks (absent / invalid-JSON / non-object / missing-key /
# boundary_commit format / checkpoint format / clean-PASS baseline)
# ─────────────────────────────────────────────────────────────────────────
echo
echo "== Group B: struct checks =="

B_OUT="$FIXTURE_BASE/b.out"
EMBEDDED_PATH="$EMBEDDED_PY" HARNESS_PATH="$HARNESS_PY" python3 > "$B_OUT" 2>&1 <<'PYEOF'
import os
import sys

exec(compile(open(os.environ["HARNESS_PATH"], encoding="utf-8").read(),
             os.environ["HARNESS_PATH"], "exec"))

failures = []

# T-absent: no snapshot file at all -> lenient SKIP (runtime-authored;
# absent at every fresh install).
check_clean(failures, "T-absent (no snapshot file -> lenient SKIP)",
            run_in_tree(include=False))

# T-invalid-json: unparseable JSON.
fails = run_in_tree(raw=b"{not valid json\n")
check_hit(failures, "T-invalid-json", fails, "INVALID JSON")
check_count(failures, "T-invalid-json isolated", fails, 1)

# T-not-object: valid JSON but the top-level value is not an object.
fails = run_in_tree(raw=b"[1, 2, 3]\n")
check_hit(failures, "T-not-object", fails, "top-level JSON must be an OBJECT")
check_count(failures, "T-not-object isolated", fails, 1)

# T-missing-key: a required key absent (schema-required-set enforcement).
d = clean_snapshot()
del d["wave"]
fails = run_in_tree(data=d)
check_hit(failures, "T-missing-key (wave)", fails,
           "missing required key(s)")
check_hit(failures, "T-missing-key (wave) names the key", fails, "'wave'")
check_count(failures, "T-missing-key isolated", fails, 1)

# T-bad-sha-chars: boundary_commit has non-hex characters.
d = clean_snapshot()
d["boundary_commit"] = "ZZZZZZZ"
fails = run_in_tree(data=d)
check_hit(failures, "T-bad-sha-chars", fails, "must be a 7-40-char")
check_count(failures, "T-bad-sha-chars isolated", fails, 1)

# T-bad-sha-tooshort: boundary_commit shorter than the 7-char floor.
d = clean_snapshot()
d["boundary_commit"] = "abc12"
fails = run_in_tree(data=d)
check_hit(failures, "T-bad-sha-tooshort", fails, "must be a 7-40-char")
check_count(failures, "T-bad-sha-tooshort isolated", fails, 1)

# T-bad-sha-type: boundary_commit is not even a string.
d = clean_snapshot()
d["boundary_commit"] = 12345
fails = run_in_tree(data=d)
check_hit(failures, "T-bad-sha-type", fails, "must be a 7-40-char")
check_count(failures, "T-bad-sha-type isolated", fails, 1)

# T-bad-date-format: checkpoint is a string but not ISO-8601.
d = clean_snapshot()
d["checkpoint"] = "07/02/2026"
fails = run_in_tree(data=d)
check_hit(failures, "T-bad-date-format", fails, "must be an ISO-8601")
check_count(failures, "T-bad-date-format isolated", fails, 1)

# T-bad-date-type: checkpoint is not a string at all.
d = clean_snapshot()
d["checkpoint"] = None
fails = run_in_tree(data=d)
check_hit(failures, "T-bad-date-type", fails, "must be an ISO-8601")
check_count(failures, "T-bad-date-type isolated", fails, 1)

# T-clean-pass: a fully conforming snapshot -> 0 fails (the PASS baseline
# every other test in this file leans on for isolation asserts).
check_clean(failures, "T-clean-pass (well-formed snapshot)",
            run_in_tree(data=clean_snapshot()))

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
PYEOF
b_out="$(cat "$B_OUT")"
if printf '%s' "$b_out" | grep -q "^OK$"; then
    pass "Group B: struct checks (absent-SKIP / invalid-JSON / non-object / missing-key / bad boundary_commit[chars,too-short,type] / bad checkpoint[format,type] / clean-PASS baseline)"
else
    fail "Group B: struct checks failed" "$b_out"
fi

# ─────────────────────────────────────────────────────────────────────────
# Group C: grammar — anti-accretion bounds (>1 date / >1 SHA + off-field)
# ─────────────────────────────────────────────────────────────────────────
echo
echo "== Group C: anti-accretion bounds (date / SHA count + off-field) =="

C_OUT="$FIXTURE_BASE/c.out"
EMBEDDED_PATH="$EMBEDDED_PY" HARNESS_PATH="$HARNESS_PY" python3 > "$C_OUT" 2>&1 <<'PYEOF'
import os
import sys

exec(compile(open(os.environ["HARNESS_PATH"], encoding="utf-8").read(),
             os.environ["HARNESS_PATH"], "exec"))

failures = []

# T-date-2nd: a second date, outside checkpoint -> both the >1-date count
# FAIL and the off-field FAIL fire (exactly 2 fails, nothing else).
d = clean_snapshot()
d["active"] = ["something happened on 2026-07-01"]
fails = run_in_tree(data=d)
check_hit(failures, "T-date-2nd (count)", fails, "date(s)")
check_hit(failures, "T-date-2nd (off-field)", fails,
           "a date appears OUTSIDE")
check_count(failures, "T-date-2nd exactly 2 fails (count + off-field)",
            fails, 2)

# T-sha-2nd: a second commit SHA (7-40 lowercase hex), outside
# boundary_commit -> both the >1-SHA count FAIL and the off-field FAIL fire.
d = clean_snapshot()
d["active"] = ["fixed at deadbee1"]
fails = run_in_tree(data=d)
check_hit(failures, "T-sha-2nd (count)", fails, "commit SHA(s)")
check_hit(failures, "T-sha-2nd (off-field)", fails,
           "a commit SHA appears OUTSIDE")
check_count(failures, "T-sha-2nd exactly 2 fails (count + off-field)",
            fails, 2)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
PYEOF
c_out="$(cat "$C_OUT")"
if printf '%s' "$c_out" | grep -q "^OK$"; then
    pass "Group C: anti-accretion bounds (a 2nd date fires count+off-field; a 2nd/off-field commit SHA fires count+off-field)"
else
    fail "Group C: anti-accretion bounds failed" "$c_out"
fi

# ─────────────────────────────────────────────────────────────────────────
# Group D: the narration guard — EVERY _SS_NARRATION_PATTERNS axis (read
# live in Group A) on its own isolated violating fixture, the post-commit
# case-sensitivity pair, bare-TD-tag PERMITTED (the strip), and
# _ss_iter_string_values recursing into a nested list-of-list-of-dict.
# ─────────────────────────────────────────────────────────────────────────
echo
echo "== Group D: the narration guard (every axis + case-sensitivity + strip + recursion) =="

D_OUT="$FIXTURE_BASE/d.out"
EMBEDDED_PATH="$EMBEDDED_PY" HARNESS_PATH="$HARNESS_PY" python3 > "$D_OUT" 2>&1 <<'PYEOF'
import os
import sys

exec(compile(open(os.environ["HARNESS_PATH"], encoding="utf-8").read(),
             os.environ["HARNESS_PATH"], "exec"))

failures = []

# One hand-authored violating fixture per LIVE axis name (Group A's drift
# screen guarantees this dict's key set == the live _SS_NARRATION_PATTERNS
# name set, a new/renamed axis fails THERE, not silently here). Each
# fixture is verified isolated (matches its OWN axis only) via the
# exactly-1-fail assert below.
AXIS_FIXTURES = {
    "td-past-action": "TD-9 deleted the file",
    "per-td": "queued per TD-9 as agreed",
    "carry-over": "carried from the prior session",
    "user-locked": "session param is User-locked now",
    "incident": "there was an incident today",
    "commit-n": "see Commit 3 for details",
    "override-n": "Override 2 applied",
    "post-commit": "ran the post-Commit hook manually",
    "pre-date": "pre-2026 baseline noted",
    "lessons-marker": "LESSONS learned here",
    "update-marker": "UPDATE-3 applied",
}

for name, fixture in AXIS_FIXTURES.items():
    d = clean_snapshot()
    d["notes"] = fixture
    fails = run_in_tree(data=d)
    check_hit(failures, "axis '%s' CAUGHT" % name, fails,
               "narration pattern '%s'" % name)
    check_count(failures, "axis '%s' isolated (exactly 1 fail)" % name,
                fails, 1)

# The direct subject of the just-landed BD-252/BD-253 parity work: the
# post-commit pattern is CASE-SENSITIVE. Capital-C is caught above
# (AXIS_FIXTURES["post-commit"]); the legitimate lowercase git-hook term is
# PERMITTED.
d = clean_snapshot()
d["notes"] = "wired the post-commit hook"
check_clean(failures, "post-commit lowercase PERMITTED (case-sensitivity)",
            run_in_tree(data=d))

# Bare TD-tags are PERMITTED (the strip), legitimate current-state content,
# not narration.
d = clean_snapshot()
d["active"] = ["TD-42"]
check_clean(failures, "bare TD-tag PERMITTED (the strip)", run_in_tree(data=d))

# _ss_iter_string_values must recurse into a nested list-of-list-of-dict,
# the reviewer-named independent control-flow surface. A narration string
# buried two levels deep must still be reached.
d = clean_snapshot()
d["pending_decisions"] = [["nested", {"deep": "carried from something buried"}]]
fails = run_in_tree(data=d)
check_hit(failures,
           "_ss_iter_string_values recursion (list-of-list-of-dict)",
           fails, "narration pattern 'carry-over'")
check_count(failures, "nested-recursion isolated", fails, 1)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
PYEOF
d_out="$(cat "$D_OUT")"
if printf '%s' "$d_out" | grep -q "^OK$"; then
    pass "Group D: every narration axis CAUGHT + isolated (11/11, live-driven) + post-commit case-sensitivity (capital-C caught / lowercase permitted) + bare-TD-tag permitted (the strip) + _ss_iter_string_values nested recursion"
else
    fail "Group D: narration guard checks failed" "$d_out"
fi

# ─────────────────────────────────────────────────────────────────────────
# Group E: the byte-cap ANTI-GROWTH backstop
# ─────────────────────────────────────────────────────────────────────────
echo
echo "== Group E: byte-cap ANTI-GROWTH backstop =="

E_OUT="$FIXTURE_BASE/e.out"
EMBEDDED_PATH="$EMBEDDED_PY" HARNESS_PATH="$HARNESS_PY" python3 > "$E_OUT" 2>&1 <<'PYEOF'
import os
import sys

exec(compile(open(os.environ["HARNESS_PATH"], encoding="utf-8").read(),
             os.environ["HARNESS_PATH"], "exec"))

failures = []

# Padding with a repeated non-hex, non-digit character so ONLY the byte cap
# fires (no incidental date/SHA/narration hit from the padding itself).
d = clean_snapshot()
d["notes"] = "z" * 4200
fails = run_in_tree(data=d)
check_hit(failures, "T-byte-cap (ANTI-GROWTH backstop)", fails,
           "ANTI-GROWTH")
check_count(failures,
            "T-byte-cap isolated (exactly 1 fail; no unrelated "
            "date/SHA/narration noise from the padding)", fails, 1)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
PYEOF
e_out="$(cat "$E_OUT")"
if printf '%s' "$e_out" | grep -q "^OK$"; then
    pass "Group E: byte-cap ANTI-GROWTH backstop fires in isolation on an over-cap, otherwise-clean snapshot"
else
    fail "Group E: byte-cap check failed" "$e_out"
fi

# ─────────────────────────────────────────────────────────────────────────
# Group F: end-to-end CLI wiring proof — stage the REAL shipped gate +
# allowlist into a scratch client tree and run it via `bash validate-docs.sh`
# (no args -> full scan), mirroring
# scripts/tests/test-validate-docs-target-coherence.sh's stage-the-real-gate
# idiom. Proves run_session_state is actually FOLDED into main()'s aggregate
# scan/exit-code, not merely unit-callable via the Group A/B/C/D/E harness.
# ─────────────────────────────────────────────────────────────────────────
echo
echo "== Group F: end-to-end CLI wiring (bash validate-docs.sh, staged client tree) =="

stage_tree() {
    local root="$1"
    mkdir -p "$root/scripts" "$root/docs/project"
    cp "$GATE" "$root/scripts/validate-docs.sh"
    cp "$ALLOWLIST" "$root/scripts/.docs-gate-allowlist.txt"
    chmod +x "$root/scripts/validate-docs.sh"
}
run_gate() { bash "$1/scripts/validate-docs.sh" > "$2" 2>&1; }

# F1 — a clean, well-formed pm-session-state.json -> overall PASS.
R="$FIXTURE_BASE/e2e-clean"
stage_tree "$R"
cat > "$R/docs/project/pm-session-state.json" <<'JSONEOF'
{
  "schema": "pm-session-state/1",
  "boundary_commit": "abc1234",
  "checkpoint": "2026-07-02T00:00:00Z",
  "active": [],
  "in_flight_agents": [],
  "queue": ["TD-1", "TD-2"],
  "parallelization": "serial",
  "wave": null,
  "pending_decisions": [],
  "cycle_position": null
}
JSONEOF
F1_OUT="$FIXTURE_BASE/f1.out"
run_gate "$R" "$F1_OUT"
rc=$?
f1_out="$(cat "$F1_OUT")"
if [[ $rc -eq 0 ]] && printf '%s\n' "$f1_out" | grep -q "^\[validate-docs\] PASS"; then
    pass "Group F1: end-to-end bash validate-docs.sh PASSes on a clean pm-session-state.json (full CLI wiring, exit 0)"
else
    fail "Group F1: expected an end-to-end PASS (exit 0) on the clean snapshot (rc=$rc)" "$f1_out"
fi

# F2 — a carry-over narration violation -> overall FAIL, with the
# [session-state] family line + the narration message present in the real
# CLI output (proves main() folds run_session_state's fails into the
# aggregate list and non-zero exit, not just that the function is callable).
R="$FIXTURE_BASE/e2e-dirty"
stage_tree "$R"
cat > "$R/docs/project/pm-session-state.json" <<'JSONEOF'
{
  "schema": "pm-session-state/1",
  "boundary_commit": "abc1234",
  "checkpoint": "2026-07-02T00:00:00Z",
  "active": [],
  "in_flight_agents": [],
  "queue": ["TD-1"],
  "parallelization": "serial",
  "wave": null,
  "pending_decisions": [],
  "cycle_position": null,
  "notes": "carried from the prior session"
}
JSONEOF
F2_OUT="$FIXTURE_BASE/f2.out"
run_gate "$R" "$F2_OUT"
rc=$?
f2_out="$(cat "$F2_OUT")"
if [[ $rc -ne 0 ]] \
    && printf '%s\n' "$f2_out" | grep -qF "[session-state]" \
    && printf '%s\n' "$f2_out" | grep -qF "narration pattern 'carry-over'"; then
    pass "Group F2: end-to-end bash validate-docs.sh FAILs (non-zero exit) on a carry-over-narration pm-session-state.json, with the [session-state] family line + the narration message in the real CLI output"
else
    fail "Group F2: expected an end-to-end FAIL naming the session-state carry-over narration (rc=$rc)" "$f2_out"
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
