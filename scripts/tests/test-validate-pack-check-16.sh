#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-16.sh — synthetic-fixture
# tests for BD-183 generalized Check 16 (Trinity ## Project addenda H2)
# at both project-template AND pack-root trinity locations, including
# the BD-183 §2.4 Option (b) per-surface exemption mechanism
# (`_CHECK_16_EXEMPT_SURFACES` short-circuit).
#
# These tests exercise the per-location enforcement logic without
# mutating real trinity files. Each test stages a synthetic trinity
# (3 markdown files inside a tmp directory acting as `trinity_root`),
# invokes the generalized check_trinity_addenda_h2() with that root
# + a label, and asserts PASS / FAIL as expected.
#
# Per Override 9 (BD-183 design, mirroring BD-181): the real
# invocations in main() are INDEPENDENT — pack-root and
# project-template trinity carry different audiences and different
# rules by design.
#
# Per BD-183 §2.4 Option (b) (user-approved 2026-05-21): Check 16
# enforces TEMPLATE-ONLY infrastructure tied to Procedure 5-C.2
# client reconciliation. Pack-root trinity (canonical ops-doc, never
# reconciled) is enumerated in `_CHECK_16_EXEMPT_SURFACES`; the check
# short-circuits with an OK (exempt) message for exempt surfaces.
# Groups 5 and 6 below cover the exemption mechanism (unit-level
# short-circuit logic + e2e main() invocation regression guard).
#
# Usage: bash scripts/tests/test-validate-pack-check-16.sh

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
# Group 0: Module import + Check 16 signature accepts new params
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 16 signature ===\n"

python3 -c "
import sys, inspect
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# Check 16 function exists.
if not hasattr(mod, 'check_trinity_addenda_h2'):
    print('FAIL_MISSING check_trinity_addenda_h2')
    sys.exit(1)
# Check 16 signature accepts (trinity_root, label).
sig = inspect.signature(mod.check_trinity_addenda_h2)
params = list(sig.parameters.keys())
if 'trinity_root' not in params or 'label' not in params:
    print(f'FAIL_SIG_C16 expected (trinity_root, label); got {params}')
    sys.exit(1)
# Defaults: trinity_root=None sentinel; label='project-template'.
defaults = {n: p.default for n, p in sig.parameters.items()
            if p.default is not inspect.Parameter.empty}
if defaults.get('trinity_root') is not None:
    print(f'FAIL_DEF_C16 expected trinity_root default None; got {defaults.get(\"trinity_root\")!r}')
    sys.exit(1)
if defaults.get('label') != 'project-template':
    print(f'FAIL_DEF_C16 expected label default project-template; got {defaults.get(\"label\")!r}')
    sys.exit(1)
print('OK')
" > /tmp/vp-check16-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check16-import.out; then
    t_pass "validate-pack.py imports + Check 16 signature accepts (trinity_root, label) with sentinel-None default"
else
    t_fail "validate-pack.py import or Check 16 signature check failed" \
        "$(cat /tmp/vp-check16-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Check 16 PASS paths
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Check 16 PASS paths (## Project addenda H2 + placeholder) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check16(claude_md, agents_md, gemini_md, label='test'):
    tmpdir = tempfile.mkdtemp(prefix='vp-check16-pass-')
    root = pathlib.Path(tmpdir)
    (root / 'CLAUDE.md').write_text(claude_md)
    (root / 'AGENTS.md').write_text(agents_md)
    (root / 'GEMINI.md').write_text(gemini_md)
    saved = list(mod.failures)
    mod.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_trinity_addenda_h2(root, label)
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.failures.clear()
        mod.failures.extend(saved)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — minimal trinity, all 3 carry ## Project addenda + placeholder.
valid = "## Foo\n\nbody\n\n## Project addenda\n\n<!-- Project addenda go here. Project-original H2 sections... -->\n"
fc, out = run_check16(valid, valid, valid, label='synth-pt-pass')
if fc != 0:
    failures.append(f"T1 PASS expected 0 failures, got {fc}: {out}")
if "H2 with placeholder" not in out:
    failures.append(f"T1 missing success message: {out}")
if "[synth-pt-pass]" not in out:
    failures.append(f"T1 label not threaded: {out}")

# T2: PASS — explicit project-template label preserves prior behavior.
fc, out = run_check16(valid, valid, valid, label='project-template')
if fc != 0:
    failures.append(f"T2 (project-template label) expected 0 failures, got {fc}: {out}")
if "[project-template]" not in out:
    failures.append(f"T2 'project-template' label not in OK output: {out}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 16 PASS paths: byte parity at synthetic trinity + label threading" ;;
    *) t_fail "Group 1 Check 16 PASS tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Check 16 FAIL paths
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Check 16 FAIL paths ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check16(claude_md, agents_md, gemini_md, label='test'):
    tmpdir = tempfile.mkdtemp(prefix='vp-check16-fail-')
    root = pathlib.Path(tmpdir)
    (root / 'CLAUDE.md').write_text(claude_md)
    (root / 'AGENTS.md').write_text(agents_md)
    (root / 'GEMINI.md').write_text(gemini_md)
    saved = list(mod.failures)
    mod.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_trinity_addenda_h2(root, label)
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.failures.clear()
        mod.failures.extend(saved)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# F1: FAIL — missing ## Project addenda H2 entirely.
no_h2 = "## Foo\n\nbody\n\n## Bar\n\nbaz\n"
fc, out = run_check16(no_h2, no_h2, no_h2, label='synth-fail-no-h2')
if fc < 1:
    failures.append(f"F1 (missing H2) expected >=1 failure, got {fc}: {out}")
if "missing '## Project addenda' H2" not in out:
    failures.append(f"F1 missing 'missing H2' message: {out}")
if "synth-fail-no-h2/CLAUDE.md" not in out:
    failures.append(f"F1 label not threaded into FAIL output: {out}")

# F2: FAIL — H2 present but placeholder marker missing.
h2_no_placeholder = "## Foo\n\nbody\n\n## Project addenda\n\n(some prose without the marker)\n"
fc, out = run_check16(h2_no_placeholder, h2_no_placeholder, h2_no_placeholder, label='synth-fail-no-marker')
if fc < 1:
    failures.append(f"F2 (missing placeholder marker) expected >=1 failure, got {fc}: {out}")
if "missing HTML-comment placeholder marker" not in out:
    failures.append(f"F2 missing placeholder-marker message: {out}")

# F3: FAIL — file missing entirely.
tmpdir = tempfile.mkdtemp(prefix='vp-check16-fail-missing-')
root = pathlib.Path(tmpdir)
valid = "## Project addenda\n\n<!-- Project addenda go here. -->\n"
(root / 'CLAUDE.md').write_text(valid)
(root / 'GEMINI.md').write_text(valid)
# AGENTS.md absent
saved = list(mod.failures)
mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_trinity_addenda_h2(root, 'synth-fail-missing')
    fc = len(mod.failures)
    out = buf.getvalue()
finally:
    mod.failures.clear()
    mod.failures.extend(saved)
    shutil.rmtree(tmpdir, ignore_errors=True)
if fc < 1:
    failures.append(f"F3 (missing file) expected >=1 failure, got {fc}: {out}")
if "AGENTS.md — file missing" not in out:
    failures.append(f"F3 missing 'file missing' message: {out}")
if "synth-fail-missing/AGENTS.md" not in out:
    failures.append(f"F3 label not threaded into missing-file message: {out}")

# F4: FAIL — non-exempt label against a trinity with no ## Project addenda H2
# fails normally. This proves the exemption mechanism is label-specific:
# only labels in _CHECK_16_EXEMPT_SURFACES short-circuit; arbitrary labels
# (here 'synth-pack-root-style') run the full check body and fail correctly
# when content is missing. This is the empirical-pre-check failure mode
# documented in BD-183 §2.2 — pack-root trinity at HEAD has no ## Project
# addenda H2 (template-only concept). Without the BD-183 §2.4 Option (b)
# exemption, the real 'pack-root' label would also fail this way.
pack_root_style = "## Quick reference\n\nfoo\n\n## Pack memory\n\nbar\n"
fc, out = run_check16(pack_root_style, pack_root_style, pack_root_style, label='synth-pack-root-style')
if fc != 3:
    failures.append(f"F4 (pack-root-style, non-exempt label) expected exactly 3 failures, got {fc}: {out}")
if "missing '## Project addenda' H2" not in out:
    failures.append(f"F4 missing 'missing H2' message: {out}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 16 FAIL paths: missing H2 + missing placeholder + missing file + non-exempt-label template-only mismatch" ;;
    *) t_fail "Group 2 Check 16 FAIL tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: Override 9 isolation — Check 16 invocations independent
#          across roots (no cross-location coupling)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: Override 9 — Check 16 invocations independent (no cross-location coupling) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Two synthetic trinity roots: one with the ## Project addenda H2 +
# placeholder (PASSes), one without (FAILs). Per Override 9, each
# invocation operates only on its own root; no cross-root pollution.
tmpdir = tempfile.mkdtemp(prefix='vp-check16-override9-')
root_a = pathlib.Path(tmpdir) / 'loc-a'
root_b = pathlib.Path(tmpdir) / 'loc-b'
root_a.mkdir(parents=True)
root_b.mkdir(parents=True)

valid = "## Foo\n\n## Project addenda\n\n<!-- Project addenda go here. -->\n"
no_h2 = "## Foo\n\nbody\n"
for n in ('CLAUDE.md', 'AGENTS.md', 'GEMINI.md'):
    (root_a / n).write_text(valid)
    (root_b / n).write_text(no_h2)

saved = list(mod.failures)

# Invocation 1: location A (clean — PASSes).
mod.failures.clear()
buf_a = io.StringIO()
with contextlib.redirect_stdout(buf_a):
    mod.check_trinity_addenda_h2(root_a, 'c16-loc-a')
fc_a = len(mod.failures)
out_a = buf_a.getvalue()

# Invocation 2: location B (failing — produces 3 FAILures).
mod.failures.clear()
buf_b = io.StringIO()
with contextlib.redirect_stdout(buf_b):
    mod.check_trinity_addenda_h2(root_b, 'c16-loc-b')
fc_b = len(mod.failures)
out_b = buf_b.getvalue()

mod.failures.clear()
mod.failures.extend(saved)
shutil.rmtree(tmpdir, ignore_errors=True)

if fc_a != 0:
    failures.append(f"Override 9 (Check 16) — clean location A flagged failures: {out_a}")
if fc_b != 3:
    failures.append(f"Override 9 (Check 16) — failing location B expected 3 failures, got {fc_b}: {out_b}")
# Leak prevention (both directions): neither location's output references the other's label.
if "c16-loc-b" in out_a:
    failures.append(f"Override 9 (Check 16) — A leaks B label: {out_a}")
if "c16-loc-a" in out_b:
    failures.append(f"Override 9 (Check 16) — B leaks A label: {out_b}")
# Label presence (both directions; parity with -19.sh Group 3): each output must
# carry its own label. Location A (PASS path) carries the bracket form `[label]`
# in the section header + OK lines; location B (FAIL path) carries the
# `label/name` form in FAIL lines per `check_trinity_addenda_h2`'s
# `fail(f"{label}/{name} — …")` message shape.
if "[c16-loc-a]" not in out_a:
    failures.append(f"Override 9 (Check 16) — location A label missing from PASS output: {out_a}")
if "c16-loc-b/" not in out_b:  # FAIL lines use the label/file form, not the bracket form
    failures.append(f"Override 9 (Check 16) — location B label-prefix missing from FAIL output: {out_b}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Override 9 — Check 16 invocations independent; no cross-location coupling; no label cross-pollution" ;;
    *) t_fail "Group 3 Override 9 tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: Backward compatibility — default args preserve original
#          single-location project-template behavior
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: Backward compatibility (default args for Check 16) ===\n"

python3 <<EOF
import sys, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# T1: Check 16 — no-arg call against real project-template trinity PASSes.
saved = list(mod.failures)
mod.failures.clear()
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    mod.check_trinity_addenda_h2()
fc = len(mod.failures)
out = buf.getvalue()
mod.failures.clear()
mod.failures.extend(saved)
if fc != 0:
    failures.append(f"T1 Check 16 no-arg call unexpectedly FAILED ({fc}): {out}")
if "[project-template]" not in out:
    failures.append(f"T1 Check 16 default label not project-template: {out}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Backward compat: default args preserve project-template single-location behavior for Check 16" ;;
    *) t_fail "Group 4 backward-compat tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 5: Check 16 per-surface exemption mechanism (BD-183 §2.4
#          Option (b)) — unit-level coverage of
#          `_CHECK_16_EXEMPT_SURFACES` short-circuit logic
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: Check 16 per-surface exemption mechanism ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# E0: _CHECK_16_EXEMPT_SURFACES constant exists and contains 'pack-root'.
if not hasattr(mod, '_CHECK_16_EXEMPT_SURFACES'):
    failures.append("E0 _CHECK_16_EXEMPT_SURFACES constant missing")
elif 'pack-root' not in mod._CHECK_16_EXEMPT_SURFACES:
    failures.append(f"E0 'pack-root' not in _CHECK_16_EXEMPT_SURFACES; got {mod._CHECK_16_EXEMPT_SURFACES!r}")

# E1: Exempt label short-circuits BEFORE reading any trinity files.
# Stage an EMPTY trinity_root (no CLAUDE.md, no AGENTS.md, no GEMINI.md)
# and call with label='pack-root'. If the exemption short-circuits as
# designed, the check returns OK without attempting any file reads
# (zero failures, OK exempt message).
tmpdir = tempfile.mkdtemp(prefix='vp-check16-exempt-empty-')
root = pathlib.Path(tmpdir)
# Intentionally do NOT create any files.
saved = list(mod.failures)
mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_trinity_addenda_h2(root, 'pack-root')
    fc = len(mod.failures)
    out = buf.getvalue()
finally:
    mod.failures.clear()
    mod.failures.extend(saved)
    shutil.rmtree(tmpdir, ignore_errors=True)
if fc != 0:
    failures.append(f"E1 exempt label expected 0 failures (short-circuit before file reads), got {fc}: {out}")
if "surface exempt" not in out:
    failures.append(f"E1 missing 'surface exempt' message: {out}")
if "[pack-root]" not in out:
    failures.append(f"E1 label not threaded into exempt OK: {out}")

# E2: Exempt label short-circuits even when trinity_root HAS files
# that would otherwise FAIL the body check. This proves the exemption
# is purely label-based, not content-based.
tmpdir = tempfile.mkdtemp(prefix='vp-check16-exempt-failing-')
root = pathlib.Path(tmpdir)
# Stage trinity files that would FAIL the body check (no ## Project addenda H2).
failing_content = "## Foo\n\nbody\n\n## Bar\n\nbaz\n"
for n in ('CLAUDE.md', 'AGENTS.md', 'GEMINI.md'):
    (root / n).write_text(failing_content)
mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_trinity_addenda_h2(root, 'pack-root')
    fc = len(mod.failures)
    out = buf.getvalue()
finally:
    mod.failures.clear()
    mod.failures.extend(saved)
    shutil.rmtree(tmpdir, ignore_errors=True)
if fc != 0:
    failures.append(f"E2 exempt label with failing content expected 0 failures (label-based short-circuit), got {fc}: {out}")
if "surface exempt" not in out:
    failures.append(f"E2 missing 'surface exempt' message: {out}")
if "missing '## Project addenda' H2" in out:
    failures.append(f"E2 body-check FAIL message leaked past short-circuit: {out}")

# E3: Non-exempt label with otherwise-identical failing content correctly FAILs.
# This proves the exemption is label-specific: changing only the label
# from 'pack-root' (exempt) to 'project-template' (non-exempt) flips
# the result from OK to FAIL on the SAME fixture content.
tmpdir = tempfile.mkdtemp(prefix='vp-check16-nonexempt-failing-')
root = pathlib.Path(tmpdir)
for n in ('CLAUDE.md', 'AGENTS.md', 'GEMINI.md'):
    (root / n).write_text(failing_content)
mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_trinity_addenda_h2(root, 'project-template')
    fc = len(mod.failures)
    out = buf.getvalue()
finally:
    mod.failures.clear()
    mod.failures.extend(saved)
    shutil.rmtree(tmpdir, ignore_errors=True)
if fc != 3:
    failures.append(f"E3 non-exempt label with failing content expected 3 failures, got {fc}: {out}")
if "surface exempt" in out:
    failures.append(f"E3 surface-exempt message leaked into non-exempt invocation: {out}")
if "missing '## Project addenda' H2" not in out:
    failures.append(f"E3 expected body-check FAIL message not emitted: {out}")

# E4: Header line is printed BEFORE the short-circuit (so CI logs retain
# uniform per-check section structure). The exempt invocation's section
# block should contain BOTH the header AND the OK exempt message.
tmpdir = tempfile.mkdtemp(prefix='vp-check16-header-order-')
root = pathlib.Path(tmpdir)
mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_trinity_addenda_h2(root, 'pack-root')
    out = buf.getvalue()
finally:
    mod.failures.clear()
    mod.failures.extend(saved)
    shutil.rmtree(tmpdir, ignore_errors=True)
header_idx = out.find("── Check 16 [pack-root]:")
exempt_idx = out.find("surface exempt")
if header_idx < 0:
    failures.append(f"E4 section header not emitted for exempt invocation: {out}")
elif exempt_idx < 0:
    failures.append(f"E4 exempt OK message not emitted: {out}")
elif header_idx > exempt_idx:
    failures.append(f"E4 header must precede exempt OK; header_idx={header_idx}, exempt_idx={exempt_idx}: {out}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 16 per-surface exemption: label-based short-circuit; isolation from non-exempt; header-before-OK order" ;;
    *) t_fail "Group 5 exemption-mechanism tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 6: End-to-end validate-pack.py — Check 16 main() invocation
#          state (BD-183 §2.4 Option (b) land state: Check 16
#          [project-template] runs full body; Check 16 [pack-root]
#          runs and short-circuits via per-surface exemption)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 6: End-to-end validate-pack.py — Check 16 main() state (BD-183 §2.4 Option (b)) ===\n"

python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check16-e2e.out 2>&1
e2e_status=$?

# validate-pack.py must exit 0 (all checks clean post-BD-183 Option (b)).
if [[ $e2e_status -eq 0 ]]; then
    t_pass "validate-pack.py exits 0 with BD-183 Option (b) changes applied"
else
    t_fail "validate-pack.py did not exit 0 — REGRESSION" \
        "Tail: $(tail -15 /tmp/vp-check16-e2e.out)"
fi

# Check 16 [project-template] header MUST appear (regression guard).
if grep -q "Check 16 \[project-template\]" /tmp/vp-check16-e2e.out; then
    t_pass "Check 16 [project-template] invocation runs in main()"
else
    t_fail "Check 16 [project-template] header missing — REGRESSION" \
        "Tail: $(tail -15 /tmp/vp-check16-e2e.out)"
fi

# Check 16 [pack-root] header MUST appear (BD-183 §2.4 Option (b) landed —
# pack-root invocation runs but short-circuits via the per-surface
# exemption mechanism).
if grep -q "Check 16 \[pack-root\]" /tmp/vp-check16-e2e.out; then
    t_pass "Check 16 [pack-root] invocation runs in main() (BD-183 §2.4 Option (b) landed)"
else
    t_fail "Check 16 [pack-root] header missing — BD-183 Option (b) invocation not added" \
        "Tail: $(tail -15 /tmp/vp-check16-e2e.out)"
fi

# Check 16 [pack-root] MUST short-circuit with the exempt OK message
# (forcing-function regression guard: if someone removes the exemption
# check from `check_trinity_addenda_h2` or removes "pack-root" from
# `_CHECK_16_EXEMPT_SURFACES`, this assertion fails because the check
# would either FAIL on the missing H2 or emit the regular check-body
# OK messages instead of the exempt OK).
if grep -q "OK: \[pack-root\] surface exempt — Check 16 is template-only" /tmp/vp-check16-e2e.out; then
    t_pass "Check 16 [pack-root] correctly short-circuits via _CHECK_16_EXEMPT_SURFACES (template-only exemption)"
else
    t_fail "Check 16 [pack-root] did NOT short-circuit with exempt message — exemption mechanism regression" \
        "Tail: $(tail -15 /tmp/vp-check16-e2e.out)"
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
