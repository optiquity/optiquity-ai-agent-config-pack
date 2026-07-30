#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-pack-check-91.sh — BD-136 Check 91 (client
# trinity marker-section well-formedness, validate_checks.trinity_markers).
#
# Covers the V-1..V-8 surface with POSITIVE + NEGATIVE cases, the V-5
# symmetry WARN (never a failure), and the PYTHON half of the S2 shared
# fence cross-check (scripts/tests/fixtures/marker-fence-grammar/ — the bash
# half lives in test-marker-preserve-bd136.sh). The two hand-rolled parsers
# (the bash merge engine + this Python validator) MUST agree on the pinned
# fence predicate; this asserts the Python side matches the committed
# EXPECTED-TOKENS.tsv.
#
#   V-1 orphan / nesting / unclosed          -> fail
#   V-2 heading-inside-Shape-A (partial wrap) -> fail; seed-slot H3 exception ok
#   V-3 unterminated fenced code block        -> fail; fenced markers inert (pass)
#   V-4 missing `## Project addenda` seed      -> fail (trinity-only)
#   V-5 asymmetric marker-pair counts          -> WARN (not fail; trinity-only)
#   V-6 dup H2/H3 name in Shape A + Shape B     -> fail
#   V-7 `[CONDITIONAL]` literal in a trinity    -> fail (trinity-only, O-3)
#   V-8 malformed `renamed-from` annotation     -> fail (syntactic only)
#
# Portability (BD-276): scratch trinity roots are made with Python
# tempfile.mkdtemp (inherently portable — no `mktemp -t prefix.XXXXXX`).
#
# Usage: bash scripts/tests/test-validate-pack-check-91.sh
# Exit 0 on all pass; exit 1 on any failure.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"
FENCE_FX="$REPO_ROOT/scripts/tests/fixtures/marker-fence-grammar"

PASS=0
FAIL=0
t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: module import + signature
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: module import + Check 91 signature ===\n"

REPO_ROOT="$REPO_ROOT" python3 <<'PYEOF' > /tmp/vp-check91-import.out 2>&1
import os, sys, inspect
sys.path.insert(0, os.path.join(os.environ["REPO_ROOT"], "scripts", "lib"))
from validate_checks import trinity_markers as tm
if not hasattr(tm, "check_trinity_marker_wellformed"):
    print("FAIL_MISSING check_trinity_marker_wellformed"); sys.exit(1)
sig = inspect.signature(tm.check_trinity_marker_wellformed)
params = list(sig.parameters.keys())
if "trinity_root" not in params or "label" not in params:
    print(f"FAIL_SIG expected (trinity_root, label); got {params}"); sys.exit(1)
defaults = {n: p.default for n, p in sig.parameters.items()
            if p.default is not inspect.Parameter.empty}
if defaults.get("trinity_root") is not None:
    print(f"FAIL_DEF expected trinity_root=None; got {defaults.get('trinity_root')!r}"); sys.exit(1)
if defaults.get("label") != "project-template":
    print(f"FAIL_DEF expected label=project-template; got {defaults.get('label')!r}"); sys.exit(1)
if not hasattr(tm, "_count_real_marker_tokens"):
    print("FAIL_MISSING _count_real_marker_tokens (fence cross-check helper)"); sys.exit(1)
print("OK")
PYEOF
if grep -q "^OK$" /tmp/vp-check91-import.out; then
    t_pass "trinity_markers imports; signature (trinity_root=None, label='project-template'); fence helper present"
else
    t_fail "module import / signature check failed" "$(cat /tmp/vp-check91-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: POSITIVE — well-formed markers pass (Shape A, Shape B,
#          renamed-from, seed-slot H3 exception)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: POSITIVE cases pass ===\n"

REPO_ROOT="$REPO_ROOT" python3 <<'PYEOF'
import os, sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, os.path.join(os.environ["REPO_ROOT"], "scripts", "lib"))
from validate_checks import trinity_markers as tm
from validate_checks import core

BT = chr(96) * 3                       # ``` — avoids shell backtick issues
SEED = ("## Project addenda\n\n"
        "<!-- Project addenda go here. This heading is pack-owned. -->\n"
        "<!-- BEGIN project-owned -->\n<!-- END project-owned -->\n")

def run(cc, aa=None, gg=None, label="scratch"):
    aa = cc if aa is None else aa
    gg = cc if gg is None else gg
    d = pathlib.Path(tempfile.mkdtemp(prefix="vp-c91-pos-"))
    (d / "CLAUDE.md").write_text(cc)
    (d / "AGENTS.md").write_text(aa)
    (d / "GEMINI.md").write_text(gg)
    saved = list(core.failures); core.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            tm.check_trinity_marker_wellformed(d, label)
        n = len(core.failures); out = buf.getvalue()
    finally:
        core.failures.clear(); core.failures.extend(saved)
        shutil.rmtree(d, ignore_errors=True)
    return n, out

failures = []

# P1: minimal valid seed only (Shape A empty seed).
n, out = run(SEED)
if n != 0:
    failures.append(f"P1 minimal seed expected 0 failures, got {n}: {out}")
if "well-formed" not in out:
    failures.append(f"P1 missing OK message: {out}")

# P2: Shape A body-wrap inside a pack section + valid seed.
shape_a = "## Build rules\npack body\n<!-- BEGIN project-owned -->\nmy extra\n<!-- END project-owned -->\n" + SEED
n, out = run(shape_a)
if n != 0:
    failures.append(f"P2 Shape A expected 0 failures, got {n}: {out}")

# P3: Shape B project-original + Shape B renamed-from override + valid seed.
shape_b = (
    '<!-- BEGIN project-owned -->\n## My Original\nbody\n<!-- END project-owned -->\n'
    '<!-- BEGIN project-owned: renamed-from "## Language-specific coding rules" -->\n'
    '## Swift rules\nbody2\n<!-- END project-owned -->\n' + SEED)
n, out = run(shape_b)
if n != 0:
    failures.append(f"P3 Shape B + renamed-from expected 0 failures, got {n}: {out}")

# P4: seed-slot H3 exception — H3 subsections inside the `## Project addenda`
# Shape A body are allowed (V-2 seed exception).
seed_h3 = ("## Project addenda\n\n<!-- Project addenda go here. -->\n"
           "<!-- BEGIN project-owned -->\n### Sub one\nbody\n### Sub two\nmore\n"
           "<!-- END project-owned -->\n")
n, out = run(seed_h3)
if n != 0:
    failures.append(f"P4 seed-slot H3 exception expected 0 failures, got {n}: {out}")

# P5: fenced markers are INERT — an all-fenced authoring example passes
# trivially (this is exactly the PM-CHAT.md / C6 shape). Uses a NON-trinity
# scratch dir? No — trinity requires the seed; so seed + a fenced example block.
fenced_ok = (SEED + "## How to add content\n\n" + BT + "\n"
             "<!-- BEGIN project-owned -->\nexample\n<!-- END project-owned -->\n"
             + BT + "\n")
n, out = run(fenced_ok)
if n != 0:
    failures.append(f"P5 fenced-inert example expected 0 failures, got {n}: {out}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
PYEOF
case $? in
    0) t_pass "POSITIVE: minimal seed, Shape A, Shape B + renamed-from, seed-slot H3, fenced-inert all pass" ;;
    *) t_fail "Group 1 POSITIVE cases failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: NEGATIVE — each V-rule bites with a distinct diagnostic
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: NEGATIVE cases (each V-rule bites) ===\n"

REPO_ROOT="$REPO_ROOT" python3 <<'PYEOF'
import os, sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, os.path.join(os.environ["REPO_ROOT"], "scripts", "lib"))
from validate_checks import trinity_markers as tm
from validate_checks import core

BT = chr(96) * 3
SEED = ("## Project addenda\n\n<!-- Project addenda go here. -->\n"
        "<!-- BEGIN project-owned -->\n<!-- END project-owned -->\n")

def run(content, label="scratch"):
    d = pathlib.Path(tempfile.mkdtemp(prefix="vp-c91-neg-"))
    for n in ("CLAUDE.md", "AGENTS.md", "GEMINI.md"):
        (d / n).write_text(content)
    saved = list(core.failures); core.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            tm.check_trinity_marker_wellformed(d, label)
        n = len(core.failures); out = buf.getvalue()
    finally:
        core.failures.clear(); core.failures.extend(saved)
        shutil.rmtree(d, ignore_errors=True)
    return n, out

failures = []

def expect_fail(name, content, marker):
    n, out = run(content)
    if n < 1:
        failures.append(f"{name} expected >=1 failure, got {n}: {out}")
    elif marker not in out:
        failures.append(f"{name} missing {marker!r} in output: {out}")

# V-1 orphan END (no open BEGIN) — otherwise valid seed present.
expect_fail("V-1 orphan",
            SEED + "## Sec\nbody\n<!-- END project-owned -->\n",
            "orphan END marker")

# V-1 unclosed BEGIN (no END).
expect_fail("V-1 unclosed",
            SEED + "## Sec\n<!-- BEGIN project-owned -->\ndangling\n",
            "unclosed BEGIN marker")

# V-1 nested BEGIN inside an open region.
expect_fail("V-1 nested",
            SEED + "## Sec\n<!-- BEGIN project-owned -->\n<!-- BEGIN project-owned -->\nx\n<!-- END project-owned -->\n",
            "nested BEGIN marker")

# V-2 heading inside a Shape A region (partial wrap) under a non-seed host.
expect_fail("V-2 heading-in-Shape-A",
            SEED + "## Sec\n<!-- BEGIN project-owned -->\nbody first\n## Sneaky\n<!-- END project-owned -->\n",
            "heading inside a Shape A region")

# V-3 unterminated fenced code block (would swallow subsequent markers).
expect_fail("V-3 unterminated-fence",
            SEED + "## Sec\nbody\n" + BT + "\n<!-- BEGIN project-owned -->\nx\n<!-- END project-owned -->\n",
            "unterminated fenced code block")

# V-3 (reinforce): a real BEGIN whose matching END is hidden inside a
# balanced fence -> the END is inert -> the BEGIN orphans (V-1 via fence-aware).
expect_fail("V-3 fenced-END-orphans-BEGIN",
            SEED + "## Sec\n<!-- BEGIN project-owned -->\nbody\n" + BT + "\n<!-- END project-owned -->\n" + BT + "\n",
            "unclosed BEGIN marker")

# V-4 missing `## Project addenda` seed entirely (trinity-only).
expect_fail("V-4 missing-seed", "## Sec\nbody\n", "missing `## Project addenda` H2")

# V-4 addenda H2 present but NO marker pair inside it.
expect_fail("V-4 empty-addenda",
            "## Project addenda\n\n<!-- Project addenda go here. -->\n",
            "carries no project-owned marker pair")

# V-6 same H2 name in Shape A and Shape B.
expect_fail("V-6 dup-both-shapes",
            "## Dup\npack\n<!-- BEGIN project-owned -->\nshapeA\n<!-- END project-owned -->\n"
            "<!-- BEGIN project-owned -->\n## Dup\nshapeB\n<!-- END project-owned -->\n" + SEED,
            "appears in both a Shape A and a Shape B")

# V-7 `[CONDITIONAL]` literal in a trinity file (O-3 any-literal).
expect_fail("V-7 conditional-H2",
            SEED + "## [CONDITIONAL] Legacy\nbody\n", "`[CONDITIONAL]` literal present")
expect_fail("V-7 conditional-prose",
            SEED + "## Sec\nsee the [CONDITIONAL] note\n", "`[CONDITIONAL]` literal present")

# V-8 malformed renamed-from: no quoted name.
expect_fail("V-8 renamed-noquote",
            '<!-- BEGIN project-owned: renamed-from ## Foo -->\n## Bar\nbody\n<!-- END project-owned -->\n' + SEED,
            "annotation with no double-quoted heading name")

# V-8 malformed renamed-from: quoted name not a `## `/`### ` heading line.
expect_fail("V-8 renamed-badname",
            '<!-- BEGIN project-owned: renamed-from "Foo" -->\n## Bar\nbody\n<!-- END project-owned -->\n' + SEED,
            "is not an exact")

# V-8 malformed renamed-from: unbalanced quote.
expect_fail("V-8 renamed-unbalanced",
            '<!-- BEGIN project-owned: renamed-from "## Foo -->\n## Bar\nbody\n<!-- END project-owned -->\n' + SEED,
            "unbalanced quote")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
PYEOF
case $? in
    0) t_pass "NEGATIVE: V-1/V-2/V-3/V-4/V-6/V-7/V-8 each bite with a distinct diagnostic" ;;
    *) t_fail "Group 2 NEGATIVE cases failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: V-5 trinity-symmetry is a WARN, never a failure
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 3: V-5 symmetry WARN (not a failure) ===\n"

REPO_ROOT="$REPO_ROOT" python3 <<'PYEOF'
import os, sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, os.path.join(os.environ["REPO_ROOT"], "scripts", "lib"))
from validate_checks import trinity_markers as tm
from validate_checks import core

SEED = ("## Project addenda\n\n<!-- Project addenda go here. -->\n"
        "<!-- BEGIN project-owned -->\n<!-- END project-owned -->\n")
# CLAUDE has an EXTRA Shape B section (2 pairs) vs AGENTS/GEMINI (1 pair each).
extra = "<!-- BEGIN project-owned -->\n## My Section\nbody\n<!-- END project-owned -->\n" + SEED

d = pathlib.Path(tempfile.mkdtemp(prefix="vp-c91-v5-"))
(d / "CLAUDE.md").write_text(extra)
(d / "AGENTS.md").write_text(SEED)
(d / "GEMINI.md").write_text(SEED)
saved = list(core.failures); core.failures.clear()
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    tm.check_trinity_marker_wellformed(d, "scratch")
n = len(core.failures); out = buf.getvalue()
core.failures.clear(); core.failures.extend(saved)
shutil.rmtree(d, ignore_errors=True)

problems = []
if n != 0:
    problems.append(f"V-5 asymmetry must NOT fail; got {n} failures: {out}")
if "WARN:" not in out or "V-5" not in out:
    problems.append(f"V-5 asymmetry must emit a WARN naming V-5: {out}")
if problems:
    print("FAILURES"); [print(" ", p) for p in problems]; sys.exit(1)
print("OK")
PYEOF
case $? in
    0) t_pass "V-5 asymmetric pair counts emit a WARN and do NOT fail the check" ;;
    *) t_fail "Group 3 V-5 symmetry-warn test failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: PYTHON half of the S2 shared fence cross-check
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 4: S2 fence cross-check (Python parser matches EXPECTED-TOKENS.tsv) ===\n"

REPO_ROOT="$REPO_ROOT" FENCE_FX="$FENCE_FX" python3 <<'PYEOF'
import os, sys, pathlib
sys.path.insert(0, os.path.join(os.environ["REPO_ROOT"], "scripts", "lib"))
from validate_checks import trinity_markers as tm

fx = pathlib.Path(os.environ["FENCE_FX"])
tsv = fx / "EXPECTED-TOKENS.tsv"
if not tsv.is_file():
    print(f"FAILURES\n  EXPECTED-TOKENS.tsv missing at {tsv}"); sys.exit(1)

problems = []
seen = 0
for line in tsv.read_text().splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    fname, expected = line.split("\t")
    got = tm._count_real_marker_tokens(fx / fname)
    seen += 1
    if got != int(expected):
        problems.append(f"{fname}: Python parser got {got} real tokens, "
                        f"EXPECTED-TOKENS.tsv says {expected}")
if seen == 0:
    problems.append("EXPECTED-TOKENS.tsv had no data rows")
if problems:
    print("FAILURES"); [print(" ", p) for p in problems]; sys.exit(1)
print(f"OK ({seen} fixture files cross-checked)")
PYEOF
case $? in
    0) t_pass "Python fence parser matches the committed EXPECTED-TOKENS.tsv (bash<->Python S2 cross-check)" ;;
    *) t_fail "Group 4 S2 fence cross-check failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 5: end-to-end — validate-pack --only-check 91 exits 0 on the
#          landed (C4-seeded) trinity + C3-re-prepped PM-CHAT.md
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 5: e2e validate-pack --only-check 91 ===\n"

python3 "$VALIDATE" --only-check 91 > /tmp/vp-check91-e2e.out 2>&1
e2e_status=$?
if [[ $e2e_status -eq 0 ]]; then
    t_pass "validate-pack.py --only-check 91 exits 0 on the landed trinity + seed marker files"
else
    t_fail "validate-pack.py --only-check 91 did not exit 0 — REGRESSION" \
        "Tail: $(tail -15 /tmp/vp-check91-e2e.out)"
fi
if grep -q "Check 91 \[project-template\]" /tmp/vp-check91-e2e.out; then
    t_pass "Check 91 [project-template] invocation runs in main()"
else
    t_fail "Check 91 [project-template] header missing — registration regression" \
        "Tail: $(tail -15 /tmp/vp-check91-e2e.out)"
fi

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
