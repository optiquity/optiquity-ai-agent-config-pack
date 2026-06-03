#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-removed-doc-advisory.sh
#
# Tests for the JC-5 soft-advisory removed-doc guard (Check 48, BD-195
# C6). The guard WARNs — and NEVER fail()s — when a citation in either
# regenerated mirror (pack-ops/CHANGELOG.md, pack-ops/BACKLOG.md)
# resolves to a doc REMOVED from the repo. The core contract under test:
# the advisory is NON-FATAL (validate-pack exits 0 / PASS) WITH the WARN
# lines present, and it never appends to the `failures` fire-set.
#
# Group 0 — module import + new symbols reachable.
# Group 1 — UNIT: run check_removed_doc_advisory() against a synthetic
#           tmp mirror; assert WARN emitted, `failures` unchanged,
#           and the live `-V2` collision basenames are NOT matched.
# Group 2 — END-TO-END: validate-pack.py exits 0 on HEAD WITH Check 48
#           WARN lines present (asserting the advisory is non-fatal).
#
# Usage: bash scripts/tests/test-validate-pack-check-removed-doc-advisory.sh

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
# Group 0: Module import + Check 48 symbol registration
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 48 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_removed_doc_advisory',
    'warn',
    '_REMOVED_DOC_BASENAMES',
    '_REMOVED_DOC_SCAN_FILES',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-rmadv-import.out 2>&1

if grep -q "^OK$" /tmp/vp-rmadv-import.out; then
    t_pass "validate-pack.py imports + Check 48 symbols registered"
else
    t_fail "validate-pack.py import or Check 48 symbol registration failed" \
        "$(cat /tmp/vp-rmadv-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: UNIT — synthetic mirror; warn-only + collision-safety
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: UNIT — warn-only behavior on a synthetic mirror ===\n"

TMP_UNIT="$(mktemp -d)"
trap 'rm -rf "$TMP_UNIT"' EXIT
mkdir -p "$TMP_UNIT/pack-ops"
# Synthetic mirror: 2 removed-doc citations (one backticked, one
# path-form) + 1 LIVE `-V2` basename that must NOT be matched + 1
# longer basename that must NOT be matched.
cat > "$TMP_UNIT/pack-ops/CHANGELOG.md" <<'EOF'
- Supersedes GEMINI-CLI-ANALYSIS.md (removed; should WARN).
- See `supporting-docs/V10-PREDESIGN.md` (removed; should WARN).
- The live `ARCHITECTURE-BD-185-V2.md` must NOT match (collision).
- A FOO-PLAN-BD-185.md longer basename must NOT match.
EOF

python3 -c "
import sys, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# Repoint the guard at the synthetic tmp tree; scan only the synthetic
# CHANGELOG mirror.
from pathlib import Path
mod.REPO_ROOT = Path('$TMP_UNIT')
mod._REMOVED_DOC_SCAN_FILES = ('pack-ops/CHANGELOG.md',)

failures_before = len(mod.failures)
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    mod.check_removed_doc_advisory()
out = buf.getvalue()
failures_after = len(mod.failures)

warn_lines = [l for l in out.splitlines() if l.startswith('WARN:')]
problems = []
# (a) advisory must NOT change the fire-set
if failures_after != failures_before:
    problems.append('advisory appended to failures (%d -> %d)' % (failures_before, failures_after))
# (b) exactly the 2 removed-doc citations WARNed
if len(warn_lines) != 2:
    problems.append('expected 2 WARN lines, got %d: %r' % (len(warn_lines), warn_lines))
# (c) both removed docs named
if not any('GEMINI-CLI-ANALYSIS.md' in l for l in warn_lines):
    problems.append('GEMINI-CLI-ANALYSIS.md not WARNed')
if not any('V10-PREDESIGN.md' in l for l in warn_lines):
    problems.append('V10-PREDESIGN.md not WARNed')
# (d) live -V2 collision + longer basename NOT matched
if any('BD-185-V2' in l for l in warn_lines):
    problems.append('live ARCHITECTURE-BD-185-V2.md falsely matched')
if any('FOO-PLAN-BD-185' in l for l in warn_lines):
    problems.append('longer FOO-PLAN-BD-185.md basename falsely matched')
# (e) no FAIL: lines emitted by the advisory
if any(l.startswith('FAIL:') for l in out.splitlines()):
    problems.append('advisory emitted a FAIL: line')

if problems:
    print('FAIL ' + ' | '.join(problems))
    sys.exit(1)
print('OK')
" > /tmp/vp-rmadv-unit.out 2>&1

if grep -q "^OK$" /tmp/vp-rmadv-unit.out; then
    t_pass "check_removed_doc_advisory WARNs (2) without touching failures; collisions safe"
else
    t_fail "unit warn-only / collision-safety assertion failed" \
        "$(cat /tmp/vp-rmadv-unit.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 2: END-TO-END — advisory is NON-FATAL on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: END-TO-END — validate-pack.py exit 0 WITH Check 48 WARNs ===\n"

if python3 "$VALIDATE" > /tmp/vp-rmadv-e2e.out 2>&1; then
    # Exit 0 (PASS). Now confirm Check 48 ran AND emitted WARN lines for
    # the K3.12/K3.13 removed-doc citations — i.e. the advisory is
    # present yet non-fatal.
    if grep -q "Check 48: JC-5 soft-advisory removed-doc guard" /tmp/vp-rmadv-e2e.out \
       && grep -qE "^WARN: pack-ops/CHANGELOG\.md:.* cites .* — a removed doc" /tmp/vp-rmadv-e2e.out \
       && grep -qE "^WARN: pack-ops/BACKLOG\.md:.* cites .* — a removed doc" /tmp/vp-rmadv-e2e.out \
       && grep -q "PASSED — all checks clean" /tmp/vp-rmadv-e2e.out; then
        t_pass "validate-pack.py exits 0 (PASS) WITH Check 48 WARN lines present (non-fatal)"
    else
        t_fail "validate-pack.py exited 0 but Check 48 WARN/PASS evidence not detected" \
            "Check 48 lines: $(grep -E 'Check 48|^WARN: pack-ops' /tmp/vp-rmadv-e2e.out | head -6)"
    fi
else
    t_fail "validate-pack.py exited NON-ZERO on HEAD — the advisory must be soft (exit 0)" \
        "Tail: $(tail -20 /tmp/vp-rmadv-e2e.out)"
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
