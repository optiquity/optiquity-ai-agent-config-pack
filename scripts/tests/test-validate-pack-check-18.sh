#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-18.sh — synthetic fixture
# tests for BD-181 generalized Check 18 H2 (trinity H2 structure
# parity at both project-template AND pack-root trinity locations).
#
# These tests exercise the per-location parity logic without mutating
# real trinity files. Each test stages a synthetic trinity (3 markdown
# files inside a tmp directory acting as `trinity_root`), invokes the
# generalized check_trinity_h2_parity() with that root + a label, and
# asserts PASS / FAIL as expected.
#
# Per Override 9 (BD-181 design): the two real invocations in main()
# are INDEPENDENT — pack-root and project-template trinity carry
# different audiences and different rules by design. This test
# exercises both PASS and FAIL paths for each conceptual location
# (project-template-style + pack-root-style trees) plus FAIL paths
# for missing files and forbidden extra H2s.
#
# Usage: bash scripts/tests/test-validate-pack-check-18.sh

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
# Group 0: Module import + function signature accepts new params
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 18 signature ===\n"

python3 -c "
import sys, inspect
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# Function exists.
if not hasattr(mod, 'check_trinity_h2_parity'):
    print('FAIL_MISSING check_trinity_h2_parity')
    sys.exit(1)

# Signature accepts (trinity_root, label) per BD-181 generalization.
sig = inspect.signature(mod.check_trinity_h2_parity)
params = list(sig.parameters.keys())
if 'trinity_root' not in params or 'label' not in params:
    print(f'FAIL_SIG expected (trinity_root, label) params; got {params}')
    sys.exit(1)
print('OK')
" > /tmp/vp-check18-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check18-import.out; then
    t_pass "validate-pack.py imports + check_trinity_h2_parity signature accepts (trinity_root, label)"
else
    t_fail "validate-pack.py import or check_trinity_h2_parity signature check failed" \
        "$(cat /tmp/vp-check18-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: PASS paths — within-trinity parity at synthetic location
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: PASS paths (within-trinity byte parity) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check_with_synthetic_trinity(claude_md: str, agents_md: str,
                                     gemini_md: str, label: str = 'test') -> tuple:
    """Stage 3 synthetic trinity files in a tmp dir; invoke the
    generalized check_trinity_h2_parity against that root. Returns
    (failures_count, captured_output)."""
    tmpdir = tempfile.mkdtemp(prefix='vp-check18-')
    root = pathlib.Path(tmpdir)
    (root / 'CLAUDE.md').write_text(claude_md)
    (root / 'AGENTS.md').write_text(agents_md)
    (root / 'GEMINI.md').write_text(gemini_md)
    saved_failures = list(mod.failures)
    mod.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_trinity_h2_parity(root, label)
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — minimal trinity, all 3 files share the same H2 list.
shared_minimal = "## Quick reference\n\nfoo\n\n## Rules\n\nbar\n"
fc, out = run_check_with_synthetic_trinity(
    shared_minimal, shared_minimal, shared_minimal, label='synth-pt'
)
if fc != 0:
    failures.append(f"T1 (shared minimal PASS) expected 0 failures, got {fc}: {out}")
if "H2 structures match" not in out:
    failures.append(f"T1 missing success message: {out}")

# T2: PASS — GEMINI adds the allowed intrinsic H2s; CLAUDE/AGENTS match.
claude = "## A\n\nx\n\n## B\n\ny\n"
agents = "## A\n\nx\n\n## B\n\ny\n"
gemini = "## A\n\nx\n\n## Agent roster\n\nz\n\n## B\n\ny\n\n## Antigravity CLI operating notes\n\nw\n"
fc, out = run_check_with_synthetic_trinity(claude, agents, gemini, label='synth-pt2')
if fc != 0:
    failures.append(f"T2 (GEMINI intrinsic PASS) expected 0 failures, got {fc}: {out}")
if "intrinsic H2" not in out:
    failures.append(f"T2 missing intrinsic-H2 success message: {out}")

# T3: PASS — pack-root-style with no GEMINI intrinsic H2s (still PASS;
#     intrinsic H2s are allowed but not required).
shared = "## Quick reference\n\nfoo\n\n## Pack memory\n\nbar\n"
fc, out = run_check_with_synthetic_trinity(shared, shared, shared, label='synth-pack-root')
if fc != 0:
    failures.append(f"T3 (pack-root-style PASS) expected 0 failures, got {fc}: {out}")
if "[synth-pack-root]" not in out:
    failures.append(f"T3 label not threaded into output: {out}")

# T4: PASS — label is reflected in OK messages so two real invocations
#     can be distinguished in CI logs.
fc, out = run_check_with_synthetic_trinity(shared, shared, shared, label='project-template')
if fc != 0:
    failures.append(f"T4 (project-template label PASS) expected 0 failures, got {fc}: {out}")
if "[project-template]" not in out:
    failures.append(f"T4 'project-template' label not in OK output: {out}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "PASS paths: byte parity + GEMINI intrinsic carve-out + label threading" ;;
    *) t_fail "Group 1 PASS-path tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: FAIL paths — within-trinity divergence at synthetic location
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: FAIL paths (within-trinity drift) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check(claude_md, agents_md, gemini_md, label='test'):
    tmpdir = tempfile.mkdtemp(prefix='vp-check18-fail-')
    root = pathlib.Path(tmpdir)
    (root / 'CLAUDE.md').write_text(claude_md)
    (root / 'AGENTS.md').write_text(agents_md)
    (root / 'GEMINI.md').write_text(gemini_md)
    saved_failures = list(mod.failures)
    mod.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_trinity_h2_parity(root, label)
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# F1: FAIL — CLAUDE has an H2 missing from AGENTS.
claude = "## A\n\nx\n\n## B\n\ny\n\n## C\n\nz\n"
agents = "## A\n\nx\n\n## B\n\ny\n"
gemini = "## A\n\nx\n\n## B\n\ny\n\n## C\n\nz\n"
fc, out = run_check(claude, agents, gemini, label='synth-fail1')
if fc < 1:
    failures.append(f"F1 (CLAUDE/AGENTS drift) expected ≥1 failure, got {fc}: {out}")
if "CLAUDE.md ↔ AGENTS.md" not in out:
    failures.append(f"F1 missing CLAUDE↔AGENTS divergence message: {out}")
if "synth-fail1/CLAUDE.md only: ## C" not in out:
    failures.append(f"F1 missing precise diff citation: {out}")
if "[synth-fail1]" not in out:
    failures.append(f"F1 label not threaded into FAIL output: {out}")

# F2: FAIL — GEMINI has an extra non-intrinsic H2.
shared = "## A\n\nx\n\n## B\n\ny\n"
gemini_extra = "## A\n\nx\n\n## B\n\ny\n\n## Forbidden\n\nz\n"
fc, out = run_check(shared, shared, gemini_extra, label='synth-fail2')
if fc < 1:
    failures.append(f"F2 (GEMINI extra) expected ≥1 failure, got {fc}: {out}")
if "GEMINI.md H2 structure diverges" not in out:
    failures.append(f"F2 missing GEMINI divergence message: {out}")
if "## Forbidden" not in out:
    failures.append(f"F2 missing precise extra-H2 citation: {out}")

# F3: FAIL — missing file (AGENTS.md absent).
tmpdir = tempfile.mkdtemp(prefix='vp-check18-fail-missing-')
import pathlib as _p
root = _p.Path(tmpdir)
shared = "## A\n\nx\n"
(root / 'CLAUDE.md').write_text(shared)
(root / 'GEMINI.md').write_text(shared)
# AGENTS.md intentionally absent
saved_failures = list(mod.failures)
mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_trinity_h2_parity(root, 'synth-fail3')
    fc = len(mod.failures)
    out = buf.getvalue()
finally:
    mod.failures.clear()
    mod.failures.extend(saved_failures)
    shutil.rmtree(tmpdir, ignore_errors=True)
if fc < 1:
    failures.append(f"F3 (missing AGENTS.md) expected ≥1 failure, got {fc}: {out}")
if "AGENTS.md — file missing" not in out:
    failures.append(f"F3 missing 'file missing' message: {out}")
if "synth-fail3/AGENTS.md" not in out:
    failures.append(f"F3 label not threaded into missing-file message: {out}")

# F4: FAIL — GEMINI intrinsic carve-out does NOT bail out CLAUDE↔AGENTS divergence.
#     If CLAUDE and AGENTS disagree, the GEMINI carve-out is irrelevant.
claude = "## A\n\nx\n\n## B\n\ny\n"
agents = "## A\n\nx\n"
gemini = "## A\n\nx\n\n## B\n\ny\n\n## Agent roster\n\nz\n"
fc, out = run_check(claude, agents, gemini, label='synth-fail4')
if fc < 1:
    failures.append(f"F4 (CLAUDE/AGENTS drift, GEMINI valid) expected ≥1 failure, got {fc}: {out}")
if "CLAUDE.md ↔ AGENTS.md" not in out:
    failures.append(f"F4 must surface CLAUDE↔AGENTS drift before GEMINI check: {out}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "FAIL paths: CLAUDE/AGENTS drift + GEMINI extra + missing file + label threading" ;;
    *) t_fail "Group 2 FAIL-path tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: Override 9 — independent invocations do not cross-compare
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: Override 9 — invocations are independent ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Stage TWO synthetic trinity locations with DIFFERENT H2 contents.
# Per Override 9 (pack-root and project-template carry different
# audiences and different rules by design), each invocation MUST
# only check parity WITHIN its own trinity_root — NOT across roots.

tmpdir = tempfile.mkdtemp(prefix='vp-check18-override9-')
root_a = pathlib.Path(tmpdir) / 'location-a'
root_b = pathlib.Path(tmpdir) / 'location-b'
root_a.mkdir(parents=True)
root_b.mkdir(parents=True)

# Location A trinity — internally byte-identical, content "A-flavored".
content_a = "## Quick reference\n\n(A)\n\n## A-only rules\n\n(A)\n"
(root_a / 'CLAUDE.md').write_text(content_a)
(root_a / 'AGENTS.md').write_text(content_a)
(root_a / 'GEMINI.md').write_text(content_a)

# Location B trinity — internally byte-identical BUT WITH COMPLETELY
# DIFFERENT H2 STRUCTURE from location A.
content_b = "## Quick reference\n\n(B)\n\n## B-only rules\n\n(B)\n\n## Pack memory\n\n(B)\n"
(root_b / 'CLAUDE.md').write_text(content_b)
(root_b / 'AGENTS.md').write_text(content_b)
(root_b / 'GEMINI.md').write_text(content_b)

# Run both invocations independently; capture failures separately.
saved_failures = list(mod.failures)

# Invocation 1: location A
mod.failures.clear()
buf_a = io.StringIO()
with contextlib.redirect_stdout(buf_a):
    mod.check_trinity_h2_parity(root_a, 'loc-a')
fc_a = len(mod.failures)
out_a = buf_a.getvalue()

# Invocation 2: location B
mod.failures.clear()
buf_b = io.StringIO()
with contextlib.redirect_stdout(buf_b):
    mod.check_trinity_h2_parity(root_b, 'loc-b')
fc_b = len(mod.failures)
out_b = buf_b.getvalue()

mod.failures.clear()
mod.failures.extend(saved_failures)
shutil.rmtree(tmpdir, ignore_errors=True)

# Both invocations MUST PASS independently, even though their H2 lists
# are completely different from each other.
if fc_a != 0:
    failures.append(f"Override 9 violation — location A flagged within-trinity drift: {out_a}")
if fc_b != 0:
    failures.append(f"Override 9 violation — location B flagged within-trinity drift: {out_b}")

# Output for location A must NOT mention location-B H2 names (no cross-pollution).
if "B-only rules" in out_a:
    failures.append(f"Override 9 violation — location A output leaks location B H2 names: {out_a}")
if "A-only rules" in out_b:
    failures.append(f"Override 9 violation — location B output leaks location A H2 names: {out_b}")

# Each output must carry its own label only.
if "[loc-a]" not in out_a or "[loc-b]" in out_a:
    failures.append(f"Override 9 — location A output mis-labeled: {out_a}")
if "[loc-b]" not in out_b or "[loc-a]" in out_b:
    failures.append(f"Override 9 — location B output mis-labeled: {out_b}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Override 9 — invocations independent; no cross-location compare; no label cross-pollution" ;;
    *) t_fail "Group 3 Override 9 tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: Backward compatibility — default args preserve original
#          single-location project-template behavior
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: Backward compatibility (default args) ===\n"

python3 <<EOF
import sys, io, contextlib, inspect
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# T1: Default params must reproduce the original project-template
#     behavior — call with no args, expect target = REPO_ROOT/project-template,
#     label = 'project-template'.
sig = inspect.signature(mod.check_trinity_h2_parity)
defaults = {name: param.default for name, param in sig.parameters.items()
            if param.default is not inspect.Parameter.empty}
if defaults.get('label') != 'project-template':
    failures.append(f"T1 default label mismatch: expected 'project-template', got {defaults.get('label')!r}")

# T2: No-arg call must run against the real project-template trinity
#     (which PASSes at HEAD per pre-implementation drift check).
saved_failures = list(mod.failures)
mod.failures.clear()
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    mod.check_trinity_h2_parity()
fc = len(mod.failures)
out = buf.getvalue()
mod.failures.clear()
mod.failures.extend(saved_failures)
if fc != 0:
    failures.append(f"T2 no-arg call against real project-template trinity unexpectedly FAILED ({fc}): {out}")
if "[project-template]" not in out:
    failures.append(f"T2 no-arg call did not use 'project-template' label: {out}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Backward compat: default args preserve project-template single-location behavior" ;;
    *) t_fail "Group 4 backward-compat tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 5: End-to-end validate-pack.py — both invocations execute
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: End-to-end validate-pack.py runs both invocations ===\n"
printf "  NOTE: end-to-end exit status is NOT a PASS gate here.\n"
printf "        BD-181 pre-implementation empirical drift check (per BACKLOG)\n"
printf "        confirms pack-root trinity has pre-existing H2 drift at HEAD.\n"
printf "        This test only confirms that BOTH invocations actually execute.\n"

python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 18 > /tmp/vp-check18-e2e.out 2>&1 || true

# Confirm both invocations ran (their headers appear in the output).
if grep -q "Check 18 \[project-template\]" /tmp/vp-check18-e2e.out \
   && grep -q "Check 18 \[pack-root\]" /tmp/vp-check18-e2e.out; then
    t_pass "validate-pack.py runs Check 18 H2 against BOTH trinity locations"
else
    t_fail "validate-pack.py did not run Check 18 against both locations" \
        "Tail: $(tail -10 /tmp/vp-check18-e2e.out)"
fi

# Confirm project-template invocation reports clean.
if grep -q "OK: \[project-template\] CLAUDE.md ↔ AGENTS.md H2 structures match" /tmp/vp-check18-e2e.out; then
    t_pass "[project-template] invocation reports clean (regression guard for backward compat)"
else
    t_fail "[project-template] invocation did not report clean — REGRESSION" \
        "Tail: $(tail -20 /tmp/vp-check18-e2e.out)"
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
