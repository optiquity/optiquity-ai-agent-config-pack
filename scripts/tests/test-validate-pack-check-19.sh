#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-19.sh — synthetic-fixture
# tests for BD-183 generalized Check 19 (Trinity templates free of
# body scaffolding) at both project-template AND pack-root trinity
# locations.
#
# These tests exercise the per-location enforcement logic without
# mutating real trinity files. Each test stages a synthetic trinity
# (3 markdown files inside a tmp directory acting as `trinity_root`),
# invokes the generalized check_trinity_no_scaffolding_comments()
# with that root + a label, and asserts PASS / FAIL as expected.
#
# Per Override 9 (BD-183 design, mirroring BD-181): the real
# invocations in main() are INDEPENDENT — pack-root and
# project-template trinity carry different audiences and different
# rules by design.
#
# Note: Check 19 is STRICT by default — the scaffolding-comment regex
# + base ALLOWED_OPENINGS allowlist reject any other HTML comment,
# pack-root included (it ships zero markers). A bounded, project-
# template-scoped admission set (`_CHECK_19_MARKER_SURFACES`) ALSO
# permits exactly the three BD-136 project-owned marker prefixes
# (`OPTIONAL: keep this section`, `BEGIN project-owned`, `END project-
# owned`) on the client trinity surface only; every other surface
# keeps the strict base allowlist.
#
# Usage: bash scripts/tests/test-validate-pack-check-19.sh

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
# Group 0: Module import + Check 19 signature accepts new params
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 19 signature ===\n"

python3 -c "
import sys, inspect
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# Check 19 function exists.
if not hasattr(mod, 'check_trinity_no_scaffolding_comments'):
    print('FAIL_MISSING check_trinity_no_scaffolding_comments')
    sys.exit(1)
sig = inspect.signature(mod.check_trinity_no_scaffolding_comments)
params = list(sig.parameters.keys())
if 'trinity_root' not in params or 'label' not in params:
    print(f'FAIL_SIG_C19 expected (trinity_root, label); got {params}')
    sys.exit(1)
defaults = {n: p.default for n, p in sig.parameters.items()
            if p.default is not inspect.Parameter.empty}
if defaults.get('trinity_root') is not None:
    print(f'FAIL_DEF_C19 expected trinity_root default None; got {defaults.get(\"trinity_root\")!r}')
    sys.exit(1)
if defaults.get('label') != 'project-template':
    print(f'FAIL_DEF_C19 expected label default project-template; got {defaults.get(\"label\")!r}')
    sys.exit(1)
print('OK')
" > /tmp/vp-check19-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check19-import.out; then
    t_pass "validate-pack.py imports + Check 19 signature accepts (trinity_root, label) with sentinel-None default"
else
    t_fail "validate-pack.py import or Check 19 signature check failed" \
        "$(cat /tmp/vp-check19-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Check 19 PASS paths
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Check 19 PASS paths (no body scaffolding) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check19(claude_md, agents_md, gemini_md, label='test'):
    tmpdir = tempfile.mkdtemp(prefix='vp-check19-pass-')
    root = pathlib.Path(tmpdir)
    (root / 'CLAUDE.md').write_text(claude_md)
    (root / 'AGENTS.md').write_text(agents_md)
    (root / 'GEMINI.md').write_text(gemini_md)
    saved = list(mod.failures)
    mod.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_trinity_no_scaffolding_comments(root, label)
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.failures.clear()
        mod.failures.extend(saved)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — minimal trinity, no HTML comments at all (mirrors pack-root
# trinity at HEAD: no template scaffolding, no comments).
no_comments = "## Foo\n\nbody\n\n## Bar\n\nbaz\n"
fc, out = run_check19(no_comments, no_comments, no_comments, label='synth-pack-root-style')
if fc != 0:
    failures.append(f"T1 (no comments PASS) expected 0 failures, got {fc}: {out}")
if "free of body-section scaffolding" not in out:
    failures.append(f"T1 missing success message: {out}")
if "[synth-pack-root-style]" not in out:
    failures.append(f"T1 label not threaded: {out}")

# T2: PASS — three legitimate HTML comment types (HOW TO USE TEMPLATE +
# Project addenda go here + Trinity-rule exception).
claude = ("<!-- HOW TO USE THIS TEMPLATE\nFoo bar baz.\n-->\n\n"
          "## Project addenda\n\n"
          "<!-- Project addenda go here. -->\n")
agents = claude
gemini = (claude + "\n<!-- Trinity-rule exception: Gemini-intrinsic H2s -->\n")
fc, out = run_check19(claude, agents, gemini, label='synth-template-style')
if fc != 0:
    failures.append(f"T2 (legit comments PASS) expected 0 failures, got {fc}: {out}")

# T3: PASS — explicit project-template label preserves prior behavior.
fc, out = run_check19(no_comments, no_comments, no_comments, label='project-template')
if fc != 0:
    failures.append(f"T3 (project-template label) expected 0 failures, got {fc}: {out}")
if "[project-template]" not in out:
    failures.append(f"T3 'project-template' label not in OK output: {out}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 19 PASS paths: no comments + allowed scaffolding + label threading" ;;
    *) t_fail "Group 1 Check 19 PASS tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Check 19 FAIL paths
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Check 19 FAIL paths (body scaffolding present) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check19(claude_md, agents_md, gemini_md, label='test'):
    tmpdir = tempfile.mkdtemp(prefix='vp-check19-fail-')
    root = pathlib.Path(tmpdir)
    (root / 'CLAUDE.md').write_text(claude_md)
    (root / 'AGENTS.md').write_text(agents_md)
    (root / 'GEMINI.md').write_text(gemini_md)
    saved = list(mod.failures)
    mod.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_trinity_no_scaffolding_comments(root, label)
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.failures.clear()
        mod.failures.extend(saved)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# F1: FAIL — body scaffolding comment in CLAUDE.
bad = ("## Foo\n\nbody\n\n"
       "<!-- Fill in the platform-specific defaults for this project. -->\n\n"
       "## Bar\n\nbaz\n")
clean = "## Foo\n\nbody\n\n## Bar\n\nbaz\n"
fc, out = run_check19(bad, clean, clean, label='synth-bad-claude')
if fc < 1:
    failures.append(f"F1 (scaffolding in CLAUDE) expected >=1 failure, got {fc}: {out}")
if "fresh-install scaffolding" not in out:
    failures.append(f"F1 missing scaffolding-comment message: {out}")
if "synth-bad-claude/CLAUDE.md" not in out:
    failures.append(f"F1 label not threaded into FAIL output: {out}")

# F2: FAIL — body scaffolding comment in AGENTS.
fc, out = run_check19(clean, bad, clean, label='synth-bad-agents')
if fc < 1:
    failures.append(f"F2 (scaffolding in AGENTS) expected >=1 failure, got {fc}: {out}")
if "synth-bad-agents/AGENTS.md" not in out:
    failures.append(f"F2 label not threaded into FAIL output: {out}")

# F3: FAIL — body scaffolding comment in GEMINI.
fc, out = run_check19(clean, clean, bad, label='synth-bad-gemini')
if fc < 1:
    failures.append(f"F3 (scaffolding in GEMINI) expected >=1 failure, got {fc}: {out}")
if "synth-bad-gemini/GEMINI.md" not in out:
    failures.append(f"F3 label not threaded into FAIL output: {out}")

# F4: FAIL — missing file.
tmpdir = tempfile.mkdtemp(prefix='vp-check19-fail-missing-')
root = pathlib.Path(tmpdir)
clean = "## Foo\n\nbody\n"
(root / 'CLAUDE.md').write_text(clean)
(root / 'GEMINI.md').write_text(clean)
# AGENTS.md absent
saved = list(mod.failures)
mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_trinity_no_scaffolding_comments(root, 'synth-fail-missing')
    fc = len(mod.failures)
    out = buf.getvalue()
finally:
    mod.failures.clear()
    mod.failures.extend(saved)
    shutil.rmtree(tmpdir, ignore_errors=True)
if fc < 1:
    failures.append(f"F4 (missing file) expected >=1 failure, got {fc}: {out}")
if "AGENTS.md — file missing" not in out:
    failures.append(f"F4 missing 'file missing' message: {out}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 19 FAIL paths: scaffolding in each of CLAUDE/AGENTS/GEMINI + missing file" ;;
    *) t_fail "Group 2 Check 19 FAIL tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: Override 9 isolation — Check 19 invocations independent
#          across roots (no cross-location coupling)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: Override 9 — Check 19 invocations independent (no cross-location coupling) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Two synthetic trinity roots: one Check-19-clean, one with scaffolding.
# Per Override 9, each invocation operates only on its own root; no
# cross-root pollution.

tmpdir = tempfile.mkdtemp(prefix='vp-check19-override9-')
root_a = pathlib.Path(tmpdir) / 'loc-a'
root_b = pathlib.Path(tmpdir) / 'loc-b'
root_a.mkdir(parents=True)
root_b.mkdir(parents=True)

# Location A: clean (pack-root-style).
clean = "## Foo\n\nbody\n"
(root_a / 'CLAUDE.md').write_text(clean)
(root_a / 'AGENTS.md').write_text(clean)
(root_a / 'GEMINI.md').write_text(clean)

# Location B: scaffolding present (template-style with drift).
dirty = ("## Foo\n\nbody\n\n"
         "<!-- Fill in the platform-specific defaults for this project. -->\n\n"
         "## Project addenda\n\n"
         "<!-- Project addenda go here. -->\n")
(root_b / 'CLAUDE.md').write_text(dirty)
(root_b / 'AGENTS.md').write_text(dirty)
(root_b / 'GEMINI.md').write_text(dirty)

saved = list(mod.failures)

# Invocation 1: clean root.
mod.failures.clear()
buf_a = io.StringIO()
with contextlib.redirect_stdout(buf_a):
    mod.check_trinity_no_scaffolding_comments(root_a, 'loc-a')
fc_a = len(mod.failures)
out_a = buf_a.getvalue()

# Invocation 2: dirty root.
mod.failures.clear()
buf_b = io.StringIO()
with contextlib.redirect_stdout(buf_b):
    mod.check_trinity_no_scaffolding_comments(root_b, 'loc-b')
fc_b = len(mod.failures)
out_b = buf_b.getvalue()

mod.failures.clear()
mod.failures.extend(saved)
shutil.rmtree(tmpdir, ignore_errors=True)

# Clean root must PASS (Override 9: location B's failures don't leak in).
if fc_a != 0:
    failures.append(f"Override 9 violation — clean location A flagged failures: {out_a}")
# Dirty root must FAIL (Override 9: location A's clean state doesn't bail B out).
if fc_b == 0:
    failures.append(f"Override 9 violation — dirty location B reported clean: {out_b}")
# Location A output must NOT mention location B's file paths.
if "loc-b" in out_a:
    failures.append(f"Override 9 — location A output leaks location B label: {out_a}")
# Location B output must NOT mention location A's file paths.
if "loc-a" in out_b:
    failures.append(f"Override 9 — location B output leaks location A label: {out_b}")
# Each output must carry its own label.
if "[loc-a]" not in out_a:
    failures.append(f"Override 9 — location A label missing: {out_a}")
if "loc-b/" not in out_b:  # FAIL lines use the label/file form, not the bracket form
    failures.append(f"Override 9 — location B label-prefix missing from FAIL output: {out_b}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Override 9 — Check 19 invocations independent; no cross-location coupling; no label cross-pollution" ;;
    *) t_fail "Group 3 Override 9 tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: Backward compatibility — default args preserve original
#          single-location project-template behavior
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: Backward compatibility (default args for Check 19) ===\n"

python3 <<EOF
import sys, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# T1: Check 19 — no-arg call against real project-template trinity PASSes.
saved = list(mod.failures)
mod.failures.clear()
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    mod.check_trinity_no_scaffolding_comments()
fc = len(mod.failures)
out = buf.getvalue()
mod.failures.clear()
mod.failures.extend(saved)
if fc != 0:
    failures.append(f"T1 Check 19 no-arg call unexpectedly FAILED ({fc}): {out}")
if "[project-template]" not in out:
    failures.append(f"T1 Check 19 default label not project-template: {out}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Backward compat: default args preserve project-template single-location behavior for Check 19" ;;
    *) t_fail "Group 4 backward-compat tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 5: End-to-end validate-pack.py — Check 19 main() invocation
#          state (BD-183 land state: Check 19 [project-template] +
#          [pack-root] BOTH run full check body; no exemption applies)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: End-to-end validate-pack.py — Check 19 main() state (BD-183) ===\n"

python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 19 > /tmp/vp-check19-e2e.out 2>&1
e2e_status=$?

# validate-pack.py must exit 0 (all checks clean post-BD-183).
if [[ $e2e_status -eq 0 ]]; then
    t_pass "validate-pack.py exits 0 with BD-183 changes applied"
else
    t_fail "validate-pack.py did not exit 0 — REGRESSION" \
        "Tail: $(tail -15 /tmp/vp-check19-e2e.out)"
fi

# Check 19 [project-template] header MUST appear (regression guard).
if grep -q "Check 19 \[project-template\]" /tmp/vp-check19-e2e.out; then
    t_pass "Check 19 [project-template] invocation runs in main()"
else
    t_fail "Check 19 [project-template] header missing — REGRESSION" \
        "Tail: $(tail -15 /tmp/vp-check19-e2e.out)"
fi

# Check 19 [pack-root] header MUST appear (BD-183 landed; pre-check clean).
if grep -q "Check 19 \[pack-root\]" /tmp/vp-check19-e2e.out; then
    t_pass "Check 19 [pack-root] invocation runs in main() (BD-183 landed)"
else
    t_fail "Check 19 [pack-root] header missing — BD-183 pack-root invocation not added" \
        "Tail: $(tail -15 /tmp/vp-check19-e2e.out)"
fi

# Check 19 [pack-root] must report clean (full check body runs; no exemption).
if grep -q "OK: \[pack-root\] All three trinity templates free of body-section scaffolding" /tmp/vp-check19-e2e.out; then
    t_pass "Check 19 [pack-root] reports clean (pre-check empirically confirmed; no exemption applies)"
else
    t_fail "Check 19 [pack-root] did not report clean — UNEXPECTED" \
        "Tail: $(tail -15 /tmp/vp-check19-e2e.out)"
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
