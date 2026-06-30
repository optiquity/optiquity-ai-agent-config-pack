#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-66.sh — synthetic fixture tests for
# BD-243 Check 66 (Gate 1b: operating-doc bullet-concision gate;
# DESIGN-BD-243-DURABLE-GATES.md §3 Gate 1b).
#
# Check 66 caps per-rule / per-bullet CHARACTER length over the bullet surface
# (the pack + project trinity memory-section bullets + PACK-MEMORY-RATIONALE.md
# rule bullets). A bullet over _CHECK_66_BULLET_CHAR_CAP and NOT covered by a
# pack-ops/.bullet-concision-allowlist.txt record FAILs. VOLUME only — the cap
# is a character count; it asserts nothing about meaning.
#
# REGISTERED at CG-14: the check BODY + constant + allowlist plus the
# CHECK_REGISTRY entry are all live, so Check 66 IS in CHECK_REGISTRY (the count
# is 69). This test exercises Check 66's BODY by calling the function IN-PROCESS
# against (a) synthetic /tmp trees and (b) the live tree, and asserts that 66
# IS in the registry while the count invariant holds DYNAMICALLY (never a
# hardcoded literal). The Group-0 `66 in nums` assertion verifies the
# registration landed.
#
# Test infra is self-provisioned: every synthetic tree is built under a /tmp
# REPO_ROOT; no real bullet-surface file is mutated. Cleanup runs on every exit
# path.
#
# Coverage:
#   Group 0: Module import + Check 66 symbols + dynamic count-invariant +
#            Check 66 REGISTERED
#   Group 1: Synthetic-tree end-to-end (in-process body invocation) —
#            T1 a file whose bullets are all under the cap PASSES
#            T2 an over-cap bullet covered by an allowlist snippet PASSES
#            T3 an over-cap bullet NOT allowlisted FAILS (the teeth)
#            T4 a bullet exactly at the cap PASSES (cap is exclusive: > cap)
#   Group 2: Live-tree in-process body invocation PASSES (the real bullet
#            surface is clean: 0 over-cap outside the allowlist) — exercised
#            via the in-process body call (Check 66's clean run over the live
#            tree is also covered by the full no-flag validate-pack now that it
#            is registered)
#   Group 3: A5-collapse two-heading + project-rename-safe (BD-255 Part A) —
#            the two per-location H2 constants exist; _CHECK_66_BULLET_SURFACE
#            reads `## Pack memory` for pack-root rows + `## Project memory`
#            for project-template rows; a SYNTHETIC project rename to
#            `## Project rules` (with _TRINITY_MEMORY_H2_PROJECT flipped) keeps
#            Check 66 GREEN while the pack-root heading is untouched.
#
# Usage: bash scripts/tests/test-validate-pack-check-66.sh

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
# Group 0: Module import + symbols + dynamic count-invariant +
#          Check 66 REGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 66 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_operating_doc_bullet_concision', '_check_66_load_allowlist',
            '_check_66_iter_bullets', '_CHECK_66_BULLET_CHAR_CAP',
            '_CHECK_66_BULLET_SURFACE']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 66 not in nums:
    print('FAIL_66_NOT_REGISTERED — CG-14 registers Check 66 in '
          'CHECK_REGISTRY (count 63 -> 69)');
    sys.exit(1)
print('OK')
" > /tmp/vp-check66-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check66-import.out; then
    t_pass "imports + Check 66 symbols present + count invariant holds (dynamic) + Check 66 REGISTERED (66 in registry)"
else
    t_fail "Check 66 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check66-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Synthetic-tree end-to-end (in-process body invocation)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Synthetic-tree end-to-end (in-process body) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W5 wave-invariant). The check body now lives in
    validate_checks.doc_concision and reads doc_concision.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


def _patch_attr(mod, name, value):
    """Set attribute `name` on the facade alias AND every loaded
    validate_checks.* submodule that already binds it (BD-256 W5
    wave-invariant). The check body's intra-cluster constant now lives in
    validate_checks.doc_concision; a facade-only patch would NOT bite. This
    reaches the owning module's binding wherever the body resolves it."""
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                setattr(_m, name, value)


failures = []

def run_check_in_tree(doc_body, allowlist_text, cap):
    """Build a synthetic /tmp REPO_ROOT with ONE bullet-surface file, an
    optional allowlist, and a monkeypatched cap; run the body; restore;
    return (fails, captured)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check66-")
    root = pathlib.Path(tmpdir)
    (root / "pack-ops").mkdir()
    (root / "SYNTH.md").write_text(doc_body)
    if allowlist_text:
        (root / "pack-ops" / ".bullet-concision-allowlist.txt").write_text(allowlist_text)

    saved_root = mod.REPO_ROOT
    saved_surface = mod._CHECK_66_BULLET_SURFACE
    saved_cap = mod._CHECK_66_BULLET_CHAR_CAP
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    _patch_attr(mod, "_CHECK_66_BULLET_SURFACE", (("SYNTH.md", "## memory"),))
    _patch_attr(mod, "_CHECK_66_BULLET_CHAR_CAP", cap)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_operating_doc_bullet_concision()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        _patch_attr(mod, "_CHECK_66_BULLET_SURFACE", saved_surface)
        _patch_attr(mod, "_CHECK_66_BULLET_CHAR_CAP", saved_cap)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

HEADER = "# SYNTH\n\n## memory\n\n"
SHORT = "- **short rule.** a short bullet under any cap.\n"
# A long bullet built from a known bolded name + filler past the cap.
LONG_NAME = "- **mega rule.** "
LONG = LONG_NAME + ("x" * 200) + "\n"   # ~218 chars

# T1: PASS — all bullets under the cap.
fc, cap_out = run_check_in_tree(HEADER + SHORT + SHORT, "", 100)
if fc != 0:
    failures.append("T1 (under-cap PASS) expected 0 failures, got %d: %s" % (fc, cap_out))
if "0 = clean" not in cap_out:
    failures.append("T1 (under-cap PASS) expected '0 = clean' OK message: %s" % cap_out)

# T2: PASS — an over-cap bullet covered by an allowlist snippet.
ALLOW = "doc: SYNTH.md\nsnippet: - **mega rule.**\nreason: irreducible (synthetic).\n"
fc, cap_out = run_check_in_tree(HEADER + SHORT + LONG, ALLOW, 100)
if fc != 0:
    failures.append("T2 (over-cap allowlisted PASS) expected 0 failures, got %d: %s" % (fc, cap_out))
if "1 over-cap KEEP" not in cap_out:
    failures.append("T2 (over-cap allowlisted PASS) expected '1 over-cap KEEP' in output: %s" % cap_out)

# T3: FAIL — an over-cap bullet NOT allowlisted (the teeth).
fc, cap_out = run_check_in_tree(HEADER + SHORT + LONG, "", 100)
if fc < 1:
    failures.append("T3 (over-cap FAIL) expected >=1 failure, got %d: %s" % (fc, cap_out))
if "Gate 1b bullet over the" not in cap_out:
    failures.append("T3 (over-cap FAIL) expected the Gate-1b FAIL message: %s" % cap_out)
if "mega rule" not in cap_out:
    failures.append("T3 (over-cap FAIL) expected the offending bullet in output: %s" % cap_out)

# T4: PASS — a bullet exactly AT the cap passes (cap is exclusive: > cap FAILs).
exact_body = HEADER + "- **e.** "  # bolded name "- **e.** " then pad to exact cap
# build a bullet whose collapsed length == cap
prefix = "- **e.** "
target_cap = 60
pad = "y" * (target_cap - len(prefix))
exact = prefix + pad + "\n"
fc, cap_out = run_check_in_tree(HEADER + exact, "", target_cap)
if fc != 0:
    failures.append("T4 (exactly-at-cap PASS) expected 0 failures, got %d: %s" % (fc, cap_out))

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T4 (under-cap / over-cap-allowlisted / over-cap-FAIL / exactly-at-cap)" ;;
    *) t_fail "Synthetic-tree check_operating_doc_bullet_concision tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Live-tree in-process body invocation (via the body call, not --only-check 66)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Live-tree in-process body invocation ===\n"

python3 -c "
import sys, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
saved = list(mod.failures); mod.failures.clear()
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    mod.check_operating_doc_bullet_concision()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE_OVER_CAP')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if '0 = clean' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
print(cap.strip())
" > /tmp/vp-check66-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check66-live.out; then
    t_pass "Check 66 body runs clean on the live bullet surface (0 over-cap outside the allowlist)"
else
    t_fail "Check 66 body found an over-cap bullet on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check66-live.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 3: A5-collapse two-heading + project-rename-safe (BD-255 Part A)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: A5-collapse two-heading + project-rename-safe ===\n"

python3 <<EOF
import sys, io, contextlib, tempfile, pathlib, shutil
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W5 wave-invariant). The check body now lives in
    validate_checks.doc_concision and reads doc_concision.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


def _patch_attr(mod, name, value):
    """Set attribute `name` on the facade alias AND every loaded
    validate_checks.* submodule that already binds it (BD-256 W5
    wave-invariant). The check body's intra-cluster constant now lives in
    validate_checks.doc_concision; a facade-only patch would NOT bite. This
    reaches the owning module's binding wherever the body resolves it."""
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                setattr(_m, name, value)


failures = []

# T1: the two per-location H2 constants exist + carry the expected current text.
for name, expected in (
    ("_TRINITY_MEMORY_H2_PACK", "## Pack memory"),
    ("_TRINITY_MEMORY_H2_PROJECT", "## Project memory"),
):
    if not hasattr(mod, name):
        failures.append("T1 missing constant %s" % name)
    elif getattr(mod, name) != expected:
        failures.append("T1 %s == %r, expected %r" % (name, getattr(mod, name), expected))

# T2: _CHECK_66_BULLET_SURFACE reads the per-location constant — pack-root rows
# use _TRINITY_MEMORY_H2_PACK; project-template rows use _TRINITY_MEMORY_H2_PROJECT.
surface = dict(mod._CHECK_66_BULLET_SURFACE)
pack_rows = ["CLAUDE.md", "AGENTS.md", "GEMINI.md"]
proj_rows = ["project-template/CLAUDE.md", "project-template/AGENTS.md",
             "project-template/GEMINI.md"]
for r in pack_rows:
    if surface.get(r) is not mod._TRINITY_MEMORY_H2_PACK:
        failures.append("T2 pack-root row %s heading is not _TRINITY_MEMORY_H2_PACK (got %r)" % (r, surface.get(r)))
for r in proj_rows:
    if surface.get(r) is not mod._TRINITY_MEMORY_H2_PROJECT:
        failures.append("T2 project-template row %s heading is not _TRINITY_MEMORY_H2_PROJECT (got %r)" % (r, surface.get(r)))

def run66_in_tree(files, surface, allowlist_text=""):
    """Build a /tmp REPO_ROOT with the given {rel: text} files + an optional
    allowlist; run Check 66 with the given surface tuple; restore; return
    (fails, captured)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check66-g3-")
    root = pathlib.Path(tmpdir)
    for rel, text in files.items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)
    if allowlist_text:
        (root / "pack-ops").mkdir(parents=True, exist_ok=True)
        (root / "pack-ops" / ".bullet-concision-allowlist.txt").write_text(allowlist_text)
    saved_root = mod.REPO_ROOT
    saved_surface = mod._CHECK_66_BULLET_SURFACE
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    _patch_attr(mod, "_CHECK_66_BULLET_SURFACE", surface)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_operating_doc_bullet_concision()
        fails = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        _patch_attr(mod, "_CHECK_66_BULLET_SURFACE", saved_surface)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return fails, captured

SHORT = "- **short rule.** a short bullet under any cap.\n"

# T3: with the CURRENT headings, both locations resolve + scan (PASS). A
# pack-root file with `## Pack memory` + a project file with `## Project memory`.
pack_doc = "# C\n\n## Pack memory\n\n" + SHORT
proj_doc = "# C\n\n## Project memory\n\n" + SHORT
surface = (
    ("CLAUDE.md", mod._TRINITY_MEMORY_H2_PACK),
    ("project-template/CLAUDE.md", mod._TRINITY_MEMORY_H2_PROJECT),
)
fails, cap = run66_in_tree({"CLAUDE.md": pack_doc,
                            "project-template/CLAUDE.md": proj_doc}, surface)
if fails:
    failures.append("T3 (current headings) expected PASS, got fails: %s" % cap)
if "2 bullet-surface file(s) scanned" not in cap:
    failures.append("T3 (current headings) expected both files scanned: %s" % cap)

# T4: SYNTHETIC project rename to `## Project rules` (BD-245), with
# _TRINITY_MEMORY_H2_PROJECT flipped in lockstep — Check 66 stays GREEN, the
# project bullets are still found under the new heading, and the pack-root
# heading is UNTOUCHED (still `## Pack memory`). Simulate by passing a surface
# tuple that uses the renamed project heading constant value.
renamed_project_heading = "## Project rules"
proj_doc_renamed = "# C\n\n## Project rules\n\n" + SHORT
surface_renamed = (
    # pack-root UNTOUCHED — still _TRINITY_MEMORY_H2_PACK / `## Pack memory`.
    ("CLAUDE.md", mod._TRINITY_MEMORY_H2_PACK),
    # project-template uses the RENAMED heading (the BD-245 one-constant flip).
    ("project-template/CLAUDE.md", renamed_project_heading),
)
fails, cap = run66_in_tree({"CLAUDE.md": pack_doc,
                            "project-template/CLAUDE.md": proj_doc_renamed},
                           surface_renamed)
if fails:
    failures.append("T4 (synthetic project rename) expected PASS, got fails: %s" % cap)
if "2 bullet-surface file(s) scanned" not in cap:
    failures.append("T4 (synthetic project rename) expected both files scanned (project bullets found under the renamed heading): %s" % cap)
# Assert the pack-root constant is STILL `## Pack memory` (rename did not touch it).
if mod._TRINITY_MEMORY_H2_PACK != "## Pack memory":
    failures.append("T4 pack-root heading was changed by the project rename (regression)")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "A5-collapse two-heading + project-rename-safe (T1-T4: constants exist; per-location surface; current headings PASS; synthetic project rename stays GREEN with pack-root untouched)" ;;
    *) t_fail "A5-collapse two-heading / project-rename-safe tests failed (see Python output)" ;;
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
