#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-50-codec-single-source.sh —
# dedicated test for Check 50 (OQ-4 single-source codec guard, BD-204
# §4.5). Closes the measured BD-184 wiring asymmetry (EE-2): Check 50
# shipped without a dedicated test.
#
# Check 50 scans validate-pack.py's OWN Python source for a reproduced
# gz64/base64 codec (an `import gzip` / `base64.b64encode` / etc. OUTSIDE
# the bash-seam string literal and outside pure-comment / denylist-literal
# lines). Check 49 must sub-invoke the SHARED batch codec, never a copy.
#
# This test exercises Check 50's matching LOGIC against synthetic source
# lines (via its public helpers) and asserts the end-to-end check is clean
# on HEAD.
#
# Coverage:
#   Group 0: module import + Check 50 symbol registration
#   Group 1: quote-span stripper + forbidden-token detection
#            T1 a BARE codec call is flagged (unquoted residual)
#            T2 a quoted-only token (denylist literal) is NOT flagged
#            T3 a self-quoting comment copy does NOT excuse a bare call
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 50 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-50-codec-single-source.sh

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
# Group 0: module import + symbol registration
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: Module import + Check 50 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_validate_pack_no_reproduced_codec',
    '_check_50_strip_quoted_spans',
    '_CHECK_50_FORBIDDEN_CODEC_TOKENS',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check50-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check50-import.out; then
    t_pass "validate-pack.py imports + Check 50 symbols registered"
else
    t_fail "validate-pack.py import or Check 50 symbol registration failed" \
        "$(cat /tmp/vp-check50-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: quote-span stripper + forbidden-token detection
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: quote-span stripper + forbidden-token logic ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

strip = mod._check_50_strip_quoted_spans
tokens = mod._CHECK_50_FORBIDDEN_CODEC_TOKENS

def has_bare(line):
    residual = strip(line)
    return any(tok in residual for tok in tokens)

failures = []

# T1: a BARE codec call (unquoted) IS flagged.
if not has_bare("    buf = gzip.compress(raw)"):
    failures.append("T1: a bare gzip.compress call should be flagged")

# T2: a quoted-only token (the denylist literal) is NOT flagged.
if has_bare('    "gzip.compress",'):
    failures.append("T2: a quoted-only denylist literal should NOT be flagged")

# T3: a self-quoting comment copy does NOT excuse a real bare call on the
#     same line (the BD-204 C-4.6 F-1 exploit class).
if not has_bare('    out = gzip.compress(x)  # "gzip.compress"'):
    failures.append("T3: a bare call with a self-quoting comment copy should still be flagged")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "quote-span stripper + token logic T1-T3 (bare-flagged / quoted-excused / self-quote-not-excused)" ;;
    *) t_fail "Check 50 quote-span/token logic tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 50 > /tmp/vp-check50-e2e.out 2>&1; then
    if grep -q "Check 50: OQ-4 single-source codec guard" /tmp/vp-check50-e2e.out \
       && grep -q "Check 50 — no reproduced gz64/base64 codec" /tmp/vp-check50-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 50 runs and reports no reproduced codec at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 50 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check50-e2e.out)"
    fi
else
    if grep -q "Check 50: OQ-4 single-source codec guard" /tmp/vp-check50-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 50 ran but found a reproduced codec)" \
            "Tail: $(tail -40 /tmp/vp-check50-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 50 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check50-e2e.out)"
    fi
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
