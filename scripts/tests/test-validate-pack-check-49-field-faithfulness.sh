#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-49-field-faithfulness.sh —
# BD-204 C-4.6 per-check test for Check 49 (migrator field/body
# faithfulness, DEEP-gated) + Check 50 (OQ-4 single-source codec guard)
# + the §4.7 run_check runtime-budget guard.
#
# This per-check test is the FIRST of the TWO deep homes (SHOULD-1): it
# sets PACK_VALIDATE_DEEP=1 AND points the check at the REAL
# `REPO_ROOT/backlog` (≥211 entries) for the POSITIVE leg — a test that
# sets the env but points at a 3-entry fixture is green-but-toothless
# (REJECT). The synthetic NEGATIVE legs build small scratch trees and
# pass them as the check's `tree_dir` (proving §4.6 (T) target-tree
# scoping: a fixture pays only fixture cost), exercising:
#   (i)   byte-leg (b) NUL/CR TEETH — a parser-stripped CR/NUL makes the
#         byte-safe PRE_PARSE_ORIGINAL != the parser's raw_body → leg (b)
#         FAILS (the catch the prior tautology PASSED). R-BODY-6 fires too.
#   (ii)  over-limit composed body FAILS the SIZE leg (real composer).
#   (iii) over-length title FAILS the TITLE leg (R-TITLE-1 codepoints).
#   (iv)  a control-byte body FAILS the R-BODY-6 raw-file scan.
#   (v)   §4.5 OQ-4 SINGLE-SOURCE TEETH — a reintroduced reproduced codec
#         in validate-pack.py FAILS Check 50.
#   (vi)  the §4.7 RUNTIME-BUDGET total-run guard hard-FAILS on a synthetic
#         slow check.
#
# Usage: bash scripts/tests/test-validate-pack-check-49-field-faithfulness.sh
#
# macOS bash 3.2 / BSD-utils compatible.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: module import + Check 49/50 symbols registered
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: module import + Check 49/50 symbol registration ===\n"

python3 - "$REPO_ROOT" "$VALIDATE" <<'PY' > /tmp/vp-check49-import.out 2>&1
import sys, importlib.util
repo_root, validate = sys.argv[1], sys.argv[2]
sys.path.insert(0, repo_root + "/scripts")
spec = importlib.util.spec_from_file_location("vp", validate)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    "check_migrator_field_faithfulness",
    "check_validate_pack_no_reproduced_codec",
    "run_check",
    "_CHECK_49_SEAM_SCRIPT",
    "_CHECK_49_DISALLOWED_CONTROL",
    "_CHECK_49_TITLE_MAX_CODEPOINTS",
    "_CHECK_50_FORBIDDEN_CODEC_TOKENS",
    "RUN_CHECK_TOTAL_GENERAL_BUDGET_S",
    "RUN_CHECK_TOTAL_DEEP_BUDGET_S",
    "_check_timings",
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print("FAIL_MISSING " + " ".join(missing)); sys.exit(1)
print("OK")
PY
if grep -q "^OK$" /tmp/vp-check49-import.out; then
    t_pass "validate-pack.py imports + Check 49/50 symbols registered"
else
    t_fail "import or Check 49/50 symbol registration failed" \
        "$(cat /tmp/vp-check49-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: POSITIVE — deep run on the REAL >=211 tree PASSES
#          (SHOULD-1: the deep check MUST execute the real tree here).
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: deep run on the REAL backlog tree (>=211) PASSES ===\n"

PACK_VALIDATE_DEEP=1 python3 "$VALIDATE" > /tmp/vp-check49-deep.out 2>&1
deep_rc=$?
if grep -qE "Check 49 — [0-9]+ entries byte-faithful" /tmp/vp-check49-deep.out \
        && [[ "$deep_rc" -eq 0 ]]; then
    # Confirm the real tree (>=211) actually executed, not a SKIP. Extract the
    # ENTRY count (the integer immediately before " entries"), not the "49".
    n_entries=$(grep -oE "[0-9]+ entries byte-faithful" /tmp/vp-check49-deep.out \
        | grep -oE "^[0-9]+" | head -1)
    if [[ -n "$n_entries" && "$n_entries" -ge 211 ]]; then
        t_pass "deep Check 49 PASSES on the real tree ($n_entries entries; both byte-leg assertions green)"
    else
        t_fail "deep Check 49 ran but entry count <211 (toothless)" \
            "n_entries=$n_entries"
    fi
else
    t_fail "deep Check 49 did not pass on the real tree" \
        "rc=$deep_rc; tail: $(tail -25 /tmp/vp-check49-deep.out)"
fi

# Confirm the GENERAL (deep UNSET) path is a ~0 ms SKIP before any tree scan.
python3 "$VALIDATE" > /tmp/vp-check49-general.out 2>&1
if grep -q "SKIP: field-faithfulness deep check" /tmp/vp-check49-general.out; then
    t_pass "general path (PACK_VALIDATE_DEEP unset) is a SKIP early-return"
else
    t_fail "general path did not SKIP the deep check" \
        "$(grep -i 'field-faithfulness' /tmp/vp-check49-general.out | head -3)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 2: NEGATIVE legs on synthetic scratch trees (target-tree
#          scoping — the check validates the CALLER's small fixture).
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: synthetic NEGATIVE legs (byte-leg-b / size / title / R-BODY-6) ===\n"

python3 - "$REPO_ROOT" "$VALIDATE" <<'PY'
import sys, os, io, tempfile, shutil, pathlib, contextlib, importlib.util
repo_root, validate = sys.argv[1], sys.argv[2]
sys.path.insert(0, repo_root + "/scripts")
spec = importlib.util.spec_from_file_location("vp", validate)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

BACKPOINTER = "<!-- per-entry source: /backlog/{pid}.md; contract: /backlog/_rules.md -->\n"

def write_entry(tree, pid, body_bytes):
    """Write a per-entry file: line 1 = the canonical back-pointer (stripped
    by the parser's pe_strip_backpointer_stdin), then `body_bytes` verbatim.
    So the FILE's lines 2..EOF (the byte-safe PRE_PARSE_ORIGINAL) == body_bytes.
    """
    p = pathlib.Path(tree) / (pid + ".md")
    with open(p, "wb") as fh:
        fh.write(BACKPOINTER.format(pid=pid).encode("utf-8"))
        fh.write(body_bytes)

def run_check_on_tree(tree, env_margin=None):
    """Run check_migrator_field_faithfulness(tree) under PACK_VALIDATE_DEEP=1;
    return (n_failures, captured_stdout)."""
    saved_failures = list(mod.failures)
    mod.failures.clear()
    saved_deep = os.environ.get("PACK_VALIDATE_DEEP")
    saved_margin = os.environ.get("TMF_SIZE_SAFETY_MARGIN")
    os.environ["PACK_VALIDATE_DEEP"] = "1"
    if env_margin is not None:
        os.environ["TMF_SIZE_SAFETY_MARGIN"] = str(env_margin)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_migrator_field_faithfulness(pathlib.Path(tree))
        n = len(mod.failures)
        cap = buf.getvalue()
    finally:
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        if saved_deep is None:
            os.environ.pop("PACK_VALIDATE_DEEP", None)
        else:
            os.environ["PACK_VALIDATE_DEEP"] = saved_deep
        if env_margin is not None:
            if saved_margin is None:
                os.environ.pop("TMF_SIZE_SAFETY_MARGIN", None)
            else:
                os.environ["TMF_SIZE_SAFETY_MARGIN"] = saved_margin
    return (n, cap)

failures = []

# Baseline sanity: a CLEAN synthetic tree PASSES (proves the negatives below
# fail BECAUSE of the injected hazard, not a fixture-shape artifact).
clean = tempfile.mkdtemp(prefix="vp-check49-clean-")
try:
    write_entry(clean, "BD-900", b"**BD-900 \xe2\x80\x94 Clean fixture**\nStatus: Open\nA clean body.\n")
    n, cap = run_check_on_tree(clean)
    if n != 0:
        failures.append(f"baseline clean tree expected PASS, got {n} failures: {cap}")
finally:
    shutil.rmtree(clean, ignore_errors=True)

# (i) NUL/CR byte-leg-(b) TEETH — a CR in the body. The parser splits-on-lines
#     and re-joins with \n (dropping the \r); the byte-safe PRE_PARSE_ORIGINAL
#     keeps it → leg (b) FAILS. R-BODY-6 ALSO fires on the CR. This is the
#     catch the bare-== raw_body tautology PASSED.
cr = tempfile.mkdtemp(prefix="vp-check49-cr-")
try:
    write_entry(cr, "BD-900", b"**BD-900 \xe2\x80\x94 CR fixture**\nStatus: Open\nline with a CR\rhere\n")
    n, cap = run_check_on_tree(cr)
    if n < 1:
        failures.append(f"(i) CR byte-leg-(b) expected FAIL, got {n}: {cap}")
    else:
        if "PARSE-FAITHFUL leg FAILED" not in cap:
            failures.append(f"(i) CR: expected PARSE-FAITHFUL (leg b) failure, got: {cap}")
        if "R-BODY-6 disallowed control byte 0x0d" not in cap:
            failures.append(f"(i) CR: expected R-BODY-6 0x0d fire (belt+suspenders), got: {cap}")
finally:
    shutil.rmtree(cr, ignore_errors=True)

# (iv) NUL control-byte R-BODY-6 TEETH — a NUL in the body fires R-BODY-6
#      (and leg (b), since the line-split drops the NUL-bearing structure).
nul = tempfile.mkdtemp(prefix="vp-check49-nul-")
try:
    write_entry(nul, "BD-903", b"**BD-903 \xe2\x80\x94 NUL fixture**\nStatus: Open\nbody with a NUL\x00byte\n")
    n, cap = run_check_on_tree(nul)
    if n < 1:
        failures.append(f"(iv) NUL R-BODY-6 expected FAIL, got {n}: {cap}")
    elif "R-BODY-6 disallowed control byte 0x00" not in cap:
        failures.append(f"(iv) NUL: expected R-BODY-6 0x00 fire, got: {cap}")
finally:
    shutil.rmtree(nul, ignore_errors=True)

# (ii) SIZE leg TEETH — force the budget to 0 via the TMF_SIZE_SAFETY_MARGIN
#      test seam (margin = the provider body limit → budget = 0), so any
#      non-empty REAL composed body exceeds. The size leg measures the
#      ACTUAL composed body (markers + neutralized H2 + gz64 blob) via the
#      shared batch composer — not a reproduction.
size = tempfile.mkdtemp(prefix="vp-check49-size-")
try:
    write_entry(size, "BD-901", b"**BD-901 \xe2\x80\x94 Size fixture**\nStatus: Open\nA normal body that composes to a non-empty Issue body.\n")
    n, cap = run_check_on_tree(size, env_margin=65536)
    if n < 1:
        failures.append(f"(ii) size leg expected FAIL (budget=0), got {n}: {cap}")
    elif "exceeds provider body limit" not in cap:
        failures.append(f"(ii) size: expected size-budget failure message, got: {cap}")
finally:
    shutil.rmtree(size, ignore_errors=True)

# (iii) TITLE leg TEETH — a bold-header title > 256 codepoints fails R-TITLE-1.
title = tempfile.mkdtemp(prefix="vp-check49-title-")
try:
    long_title = "T" * 300
    body = ("**BD-902 — " + long_title + "**\nStatus: Open\nbody.\n").encode("utf-8")
    write_entry(title, "BD-902", body)
    n, cap = run_check_on_tree(title)
    if n < 1:
        failures.append(f"(iii) title leg expected FAIL, got {n}: {cap}")
    elif "exceeds R-TITLE-1 limit" not in cap:
        failures.append(f"(iii) title: expected R-TITLE-1 failure message, got: {cap}")
finally:
    shutil.rmtree(title, ignore_errors=True)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
PY
case $? in
    0) t_pass "synthetic NEGATIVE legs (i CR / iv NUL / ii size / iii title) each FAIL their leg" ;;
    *) t_fail "synthetic NEGATIVE legs failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: §4.5 OQ-4 SINGLE-SOURCE TEETH — a reproduced codec FAILS Check 50.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: §4.5 single-source TEETH — reproduced codec FAILS Check 50 ===\n"

python3 - "$REPO_ROOT" "$VALIDATE" <<'PY'
import sys, io, tempfile, os, pathlib, contextlib, importlib.util
repo_root, validate = sys.argv[1], sys.argv[2]
sys.path.insert(0, repo_root + "/scripts")

# Build a COPY of validate-pack.py with a reproduced codec injected OUTSIDE
# the seam (a bare, unquoted gzip/base64 transform) — the exact OQ-4
# violation that got C-4.6 #2 reverted. Check 50 scans `__file__`, so the
# copy's own path is scanned.
src = pathlib.Path(validate).read_text()
injection = (
    "\n\ndef _injected_reproduced_codec(data):\n"
    "    buf = gzip.compress(data)\n"
    "    return base64.b64encode(buf)\n"
)
# Inject just before the `# ── Main ──` banner so it is module-level Python,
# outside the seam string and outside any comment.
marker = "# ── Main ──"
idx = src.index(marker)
dirty = src[:idx] + injection + "\n" + src[idx:]

tmp = tempfile.NamedTemporaryFile(prefix="vp-check50-dirty-", suffix=".py",
                                  delete=False, mode="w")
tmp.write(dirty); tmp.close()
try:
    spec = importlib.util.spec_from_file_location("vp_dirty", tmp.name)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.failures.clear()
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        mod.check_validate_pack_no_reproduced_codec()
    cap = buf.getvalue()
    n = len(mod.failures)
    ok = True
    if n < 1:
        print("FAIL: reproduced codec expected Check 50 FAIL, got 0:", cap); ok = False
    elif "reproduces the gz64/" not in cap:
        print("FAIL: Check 50 message did not name the reproduced codec:", cap); ok = False

    # Reverse direction: the REAL (clean) validate-pack.py PASSES Check 50.
    spec2 = importlib.util.spec_from_file_location("vp_clean", validate)
    mod2 = importlib.util.module_from_spec(spec2)
    spec2.loader.exec_module(mod2)
    mod2.failures.clear()
    buf2 = io.StringIO()
    with contextlib.redirect_stdout(buf2):
        mod2.check_validate_pack_no_reproduced_codec()
    if len(mod2.failures) != 0:
        print("FAIL: clean validate-pack.py expected Check 50 PASS, got",
              len(mod2.failures), ":", buf2.getvalue()); ok = False

    print("OK" if ok else "NOT_OK")
    sys.exit(0 if ok else 1)
finally:
    os.unlink(tmp.name)
PY
case $? in
    0) t_pass "§4.5 single-source: reproduced codec FAILS Check 50; clean source PASSES" ;;
    *) t_fail "§4.5 single-source teeth failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3b: §4.5 SELF-QUOTING-COMMENT EVASION TEETH (review F-1) — a
#           FULLY FUNCTIONAL reproduced codec whose every line SELF-QUOTES
#           its own forbidden token in a trailing comment MUST FAIL Check 50.
#           The prior per-line escape (`f'"{token}"' in line`) excused the
#           whole line on the quoted copy alone, letting this evade. The
#           per-occurrence strip (Check 50's _check_50_strip_quoted_spans)
#           removes the quoted comment span and flags the bare executable call.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3b: §4.5 self-quoting-comment EVASION FAILS Check 50 (review F-1) ===\n"

python3 - "$REPO_ROOT" "$VALIDATE" <<'PY'
import sys, io, tempfile, os, pathlib, contextlib, importlib.util
repo_root, validate = sys.argv[1], sys.argv[2]
sys.path.insert(0, repo_root + "/scripts")

# Build a COPY of validate-pack.py with a FULLY FUNCTIONAL reproduced gz64/
# base64 codec injected OUTSIDE the seam, where EVERY codec line self-quotes
# its own forbidden token in a trailing comment — the exact reviewer exploit
# (review F-1). A per-line quote escape sees a quoted token on every line and
# excuses all of them; the per-occurrence strip must keep the bare executable
# call in the residual and FAIL.
src = pathlib.Path(validate).read_text()
injection = (
    "\n\n"
    "import gzip  # \"import gzip\"\n"
    "import base64  # \"import base64\"\n"
    "def _evasion_reproduced_gz64(raw):\n"
    "    z = gzip.compress(raw)  # \"gzip.compress\"\n"
    "    return base64.b64encode(z)  # \"base64.b64encode\"\n"
    "def _evasion_reproduced_ungz64(blob):\n"
    "    z = base64.b64decode(blob)  # \"base64.b64decode\"\n"
    "    return gzip.decompress(z)  # \"gzip.decompress\"\n"
)
marker = "# ── Main ──"
idx = src.index(marker)
dirty = src[:idx] + injection + "\n" + src[idx:]

tmp = tempfile.NamedTemporaryFile(prefix="vp-check50-evasion-", suffix=".py",
                                  delete=False, mode="w")
tmp.write(dirty); tmp.close()
try:
    # Prove the injected codec is REAL (round-trips) — not a dead string.
    spec = importlib.util.spec_from_file_location("vp_evasion", tmp.name)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    sample = b"hello\x00\r world \xe2\x80\x94"
    rt = mod._evasion_reproduced_ungz64(mod._evasion_reproduced_gz64(sample))
    ok = True
    if rt != sample:
        print("FAIL: injected codec did not round-trip (not a real exploit):", rt); ok = False

    mod.failures.clear()
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        mod.check_validate_pack_no_reproduced_codec()
    cap = buf.getvalue()
    n = len(mod.failures)
    if n < 1:
        print("FAIL: self-quoting reproduced codec EVADED Check 50 (expected FAIL), got 0:", cap)
        ok = False
    elif "reproduces the gz64/" not in cap:
        print("FAIL: Check 50 fired but message did not name the reproduced codec:", cap)
        ok = False

    # Reverse direction: the REAL (clean) validate-pack.py still PASSES — its
    # denylist literals (bare `"gzip.compress"`) have no unquoted occurrence.
    spec2 = importlib.util.spec_from_file_location("vp_clean2", validate)
    mod2 = importlib.util.module_from_spec(spec2)
    spec2.loader.exec_module(mod2)
    mod2.failures.clear()
    buf2 = io.StringIO()
    with contextlib.redirect_stdout(buf2):
        mod2.check_validate_pack_no_reproduced_codec()
    if len(mod2.failures) != 0:
        print("FAIL: clean validate-pack.py expected Check 50 PASS (no false-FAIL), got",
              len(mod2.failures), ":", buf2.getvalue()); ok = False

    print("OK" if ok else "NOT_OK")
    sys.exit(0 if ok else 1)
finally:
    os.unlink(tmp.name)
PY
case $? in
    0) t_pass "§4.5 self-quoting evasion: a self-quoting reproduced codec FAILS Check 50; clean source still PASSES" ;;
    *) t_fail "§4.5 self-quoting-comment evasion teeth failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: §4.7 RUNTIME-BUDGET total-run guard — a synthetic slow check
#          trips the hard-FAIL (general path).
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: §4.7 runtime-budget total-run hard-FAIL on a slow check ===\n"

python3 - "$REPO_ROOT" "$VALIDATE" <<'PY'
import sys, io, contextlib, importlib.util
repo_root, validate = sys.argv[1], sys.argv[2]
sys.path.insert(0, repo_root + "/scripts")
spec = importlib.util.spec_from_file_location("vp_rt", validate)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# (a) run_check WARNs on a per-check budget overrun WITHOUT failing the gate.
#     Drive time.monotonic so the wrapped fn APPEARS to take >2 s instantly.
class FakeClock:
    def __init__(self, seq):
        self.seq = list(seq); self.i = 0
    def __call__(self):
        v = self.seq[min(self.i, len(self.seq) - 1)]; self.i += 1
        return v

mod._check_timings.clear()
saved_failures = list(mod.failures); mod.failures.clear()
saved_mono = mod.time.monotonic
mod.time.monotonic = FakeClock([0.0, 5.0])   # elapsed = 5.0 s > 2.0 s WARN
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.run_check("synthetic_slow", lambda: None)
    cap = buf.getvalue()
finally:
    mod.time.monotonic = saved_mono
    per_check_failures = len(mod.failures)
    mod.failures.clear(); mod.failures.extend(saved_failures)
if "RUNTIME-BUDGET: check 'synthetic_slow'" not in cap:
    failures.append(f"(a) per-check overrun expected a WARN, got: {cap}")
if per_check_failures != 0:
    failures.append(f"(a) per-check overrun must WARN not FAIL, got {per_check_failures} failures")
if mod._check_timings and mod._check_timings[-1][1] < 2.0:
    failures.append(f"(a) timing not recorded: {mod._check_timings[-1]}")

# (b) the TOTAL-RUN budget hard-FAILS via main(): monkeypatch the FIRST check
#     to appear to take 999 s (FakeClock advances the monotonic clock by 999 s
#     across its run_check window), with PACK_VALIDATE_DEEP unset (general
#     path → 10 s total budget). Assert main() emits the total-run FAIL and
#     exits non-zero.
import os
saved_deep = os.environ.pop("PACK_VALIDATE_DEEP", None)
# A monotonic sequence: each run_check call reads t0 then t1. The first check
# jumps the clock by 999 s; every later read returns the same large value so
# total_elapsed > 10 s. Provide a generous ramp.
seq = [0.0, 999.0] + [999.0] * 4000
saved_mono2 = mod.time.monotonic
mod.time.monotonic = FakeClock(seq)
mod._check_timings.clear()
buf2 = io.StringIO()
rc = None
try:
    with contextlib.redirect_stdout(buf2):
        try:
            mod.main()
        except SystemExit as e:
            rc = e.code
    cap2 = buf2.getvalue()
finally:
    mod.time.monotonic = saved_mono2
    if saved_deep is not None:
        os.environ["PACK_VALIDATE_DEEP"] = saved_deep
if "RUNTIME-BUDGET: validate-pack total" not in cap2:
    failures.append(f"(b) total-run guard expected a hard-FAIL message, got tail: {cap2[-600:]}")
if rc not in (1,):
    failures.append(f"(b) main() expected non-zero exit on total-run overrun, got rc={rc}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
PY
case $? in
    0) t_pass "§4.7 runtime-budget: per-check WARN (no gate fail) + total-run hard-FAIL via main()" ;;
    *) t_fail "§4.7 runtime-budget guard tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 5: target-tree scoping (§4.6 T) — NO hardcoded REPO_ROOT/backlog
#          fallback in the check body.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: §4.6 (T) no 'tree_dir or REPO_ROOT/backlog' fallback ===\n"

# Gate the EXECUTABLE body of check_migrator_field_faithfulness for the exact
# forbidden fallback shapes (§4.6 (T)): a `tree_dir or ...` default or a
# `REPO_ROOT/"backlog"` fallback INSIDE the check body. Comment/docstring lines
# (which describe the banned pattern) are stripped before the scan — only
# executable code is gated. The impl-reviewer applies the same gate.
python3 - "$VALIDATE" <<'PY'
import sys, re
src = open(sys.argv[1]).read()
m = re.search(
    r"def check_migrator_field_faithfulness\(.*?\n(.*?)\ndef _check_49_first_control_byte",
    src, re.S)
if not m:
    print("FAIL: could not isolate the check body"); sys.exit(1)
body = m.group(1)
# Strip full-line comments and the triple-quoted docstring (prose that names
# the banned pattern) so only executable code is scanned.
body_nodoc = re.sub(r'"""(.*?)"""', "", body, flags=re.S)
exec_lines = []
for line in body_nodoc.splitlines():
    s = line.lstrip()
    if s.startswith("#"):
        continue
    # Drop trailing inline comments.
    exec_lines.append(line.split("#", 1)[0])
exec_src = "\n".join(exec_lines)
bad = []
if "tree_dir or" in exec_src:
    bad.append("'tree_dir or' default in the check body")
if re.search(r'REPO_ROOT\s*/\s*"backlog"', exec_src) or \
        re.search(r"REPO_ROOT\s*/\s*'backlog'", exec_src):
    bad.append('REPO_ROOT/"backlog" fallback in the check body')
if bad:
    print("FAIL:", "; ".join(bad)); sys.exit(1)
print("OK")
PY
case $? in
    0) t_pass "no 'tree_dir or'/REPO_ROOT-backlog fallback in the check body (target-tree scoped)" ;;
    *) t_fail "forbidden target-tree fallback found in the check body (§4.6 T)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"
    exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"
    exit 1
fi
