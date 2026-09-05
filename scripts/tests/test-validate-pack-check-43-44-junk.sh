#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-43-44-junk.sh — junk-injection tests for
# the BD-244 conversion of the two verdict-bearing basename builders in
# validate-pack.py to git-TRACKED enumeration (`ci-guard-measure-then-bound`).
#
# Two builders feed the bare-ref / dangling-ref / project-side-bare-ref checks:
#   _build_basename_index()         (R5) — basename → [paths] resolution index,
#                                          consumed by Check 40 / 43 / 68.
#   _build_pack_only_doc_basenames()(R7) — pack-only-doc basename set, consumed
#                                          by Check 43's bare-prose detector.
# Before BD-244 each walked `REPO_ROOT.rglob("*")` (the raw filesystem), so an
# UNtracked OS/editor artifact (`.DS_Store`, an editor temp) could ENTER the set
# — masking a true dangling ref (R5) or false-firing the bare-prose detector
# (R7). The conversion enumerates `git ls-files` (tracked-only) via the shared
# `_git_tracked_relpaths()` helper, which returns None when git is unavailable /
# not a work tree; each consuming check then SKIPs leniently (mirrors Check 63 /
# Check 69).
#
# This test asserts the junk-immunity property directly on the two builders, the
# helper's None-on-unavailable contract, and the consumer lenient SKIP — modeled
# on scripts/tests/test-validate-pack-check-69.sh (the BD-243 sibling).
#
# Test infra is self-provisioned: every synthetic tree is built under a /tmp
# REPO_ROOT; no real tree is mutated. Cleanup runs on every exit path.
#
# Coverage:
#   Group 0: Module import + the three converted/added symbols present +
#            dynamic registry count-invariant (never a literal — the conversion
#            must not perturb the registry).
#   Group 1: R7 junk-immunity — an UNtracked .DS_Store under a pack-only tree is
#            NOT in _build_pack_only_doc_basenames(); CONTROL: a tracked
#            pack-only .md basename IS in the set.
#   Group 2: R5 junk-immunity — an UNtracked junk basename is NOT in
#            _build_basename_index() (a bare ref to it would not spuriously
#            resolve → the masking path is closed); CONTROL: a tracked basename
#            IS in the index.
#   Group 3: git-unavailable / not-a-work-tree → lenient degradation:
#            _git_tracked_relpaths() / _build_basename_index() /
#            _build_pack_only_doc_basenames() each return None; and the
#            consumers (Check 40 / 43 / 68) SKIP leniently (zero failures + a
#            "skipping (lenient)" message), never an AttributeError on a None
#            index.
#   Group 4: CONTROL — a TRACKED junk-named file IS included by both builders,
#            proving Groups 1/2 pass because the junk is UNTRACKED, not because
#            the builders went blind (analogous to the Check-69 test T5c).
#   Group 5: Live-tree smoke — both builders return a non-empty dict/set against
#            the real HEAD tree (git available) and `.DS_Store` is not a key.
#
# Usage: bash scripts/tests/test-validate-pack-check-43-44-junk.sh

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
# Group 0: Module import + symbols + dynamic registry count-invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + converted symbols + registry invariant ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['_git_tracked_relpaths', '_build_basename_index',
            '_build_pack_only_doc_basenames', 'check_bare_pack_ops_refs',
            'check_project_side_bare_internal_refs', 'check_dangling_file_refs']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# DYNAMIC count invariant — never a hardcoded literal (the conversion must not
# add/remove a check).
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
print('OK')
" > /tmp/vp-check4344-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check4344-import.out; then
    t_pass "imports + converted symbols present + registry count invariant holds (dynamic)"
else
    t_fail "import / symbol / count check failed" \
        "$(cat /tmp/vp-check4344-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Groups 1, 2, 4: builder junk-immunity + tracked-control (in-process,
#                 synthetic git tree)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Groups 1/2/4: builder junk-immunity + tracked control ===\n"

python3 - "$REPO_ROOT" "$VALIDATE" <<'EOF'
import sys, tempfile, pathlib, shutil
sys.path.insert(0, sys.argv[1] + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', sys.argv[2])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W2 wave-invariant). The check body now lives in
    validate_checks.boundary_refs and reads boundary_refs.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


def _patch_attr(mod, name, value):
    """Set attribute `name` on the facade alias AND every loaded
    validate_checks.* submodule that already binds it (BD-256 W2
    wave-invariant). The check body's intra-cluster constant now lives in
    validate_checks.boundary_refs; a facade-only patch would NOT bite. This
    reaches the owning module's binding wherever the body resolves it."""
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                setattr(_m, name, value)


import subprocess

failures = []

def _git_init_and_add(root):
    """Make the synthetic /tmp tree a git repo and TRACK its built files. The
    converted builders enumerate git ls-files — so a synthetic tree MUST be a
    git work tree with its files staged, or the builders return None (lenient).
    Junk the test injects AFTER this stays UNtracked, which is exactly how the
    tracked-only builders ignore gitignored OS junk."""
    env = {"GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
           "HOME": str(root), "PATH": __import__("os").environ.get("PATH", "")}
    subprocess.run(["git", "init", "-q"], cwd=root, env=env, check=True)
    subprocess.run(["git", "add", "-A"], cwd=root, env=env, check=True)

def build_in_tree(builder, post_add=None):
    """Build a synthetic /tmp REPO_ROOT, git-init + track its files, optionally
    inject UNtracked junk via post_add (runs AFTER git add), monkeypatch
    mod.REPO_ROOT + the Check-43 pack-only constants so 'maintenance-docs' is
    the pack-only tree, call BOTH builders, restore, return (index, pack_only)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check4344-")
    root = pathlib.Path(tmpdir)
    builder(root)
    _git_init_and_add(root)
    if post_add is not None:
        post_add(root)

    saved_root = mod.REPO_ROOT
    saved_trees = mod._CHECK_43_PACK_ONLY_DOC_TREES
    saved_allow = mod._CHECK_43_ALLOWLIST
    _patch_root(mod, root)
    _patch_attr(mod, "_CHECK_43_PACK_ONLY_DOC_TREES", ("maintenance-docs",))
    _patch_attr(mod, "_CHECK_43_ALLOWLIST", {})
    try:
        index = mod._build_basename_index()
        pack_only = mod._build_pack_only_doc_basenames()
    finally:
        _patch_root(mod, saved_root)
        _patch_attr(mod, "_CHECK_43_PACK_ONLY_DOC_TREES", saved_trees)
        _patch_attr(mod, "_CHECK_43_ALLOWLIST", saved_allow)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (index, pack_only)

# A pack-only tree (maintenance-docs/) with ONE tracked .md doc.
def base_tree(root):
    (root / "maintenance-docs").mkdir()
    (root / "maintenance-docs" / "DESIGN-NOTE.md").write_text("# a pack-only doc\n")

# ── Group 1: R7 junk-immunity ──
# Inject an UNtracked .DS_Store under the pack-only tree AFTER git add.
def inject_dsstore(root):
    (root / ".gitignore").write_text(".DS_Store\n")
    (root / "maintenance-docs" / ".DS_Store").write_bytes(b"\x00\x01junk")
index, pack_only = build_in_tree(base_tree, post_add=inject_dsstore)
if pack_only is None:
    failures.append("G1 (R7 junk-immunity) builder returned None in a git tree")
else:
    if ".DS_Store" in pack_only:
        failures.append("G1 (R7 junk-immunity) untracked .DS_Store leaked into "
                        "_build_pack_only_doc_basenames(): %s" % sorted(pack_only))
    # CONTROL: the tracked pack-only .md basename IS in the set (builder not blind).
    if "DESIGN-NOTE.md" not in pack_only:
        failures.append("G1 CONTROL the tracked pack-only doc basename is MISSING "
                        "from _build_pack_only_doc_basenames(): %s" % sorted(pack_only))

# ── Group 2: R5 junk-immunity ──
# Inject an UNtracked junk-named file under a tracked dir AFTER git add.
def inject_junkref(root):
    (root / "maintenance-docs" / "JUNKREF.md").write_text("untracked junk\n")
index, pack_only = build_in_tree(base_tree, post_add=inject_junkref)
if index is None:
    failures.append("G2 (R5 junk-immunity) builder returned None in a git tree")
else:
    if "JUNKREF.md" in index:
        failures.append("G2 (R5 junk-immunity) untracked JUNKREF.md leaked into "
                        "_build_basename_index() (a bare ref to it would "
                        "spuriously resolve): keys=%s" % sorted(index))
    # CONTROL: the tracked .md basename IS in the index (builder not blind).
    if "DESIGN-NOTE.md" not in index:
        failures.append("G2 CONTROL the tracked doc basename is MISSING from "
                        "_build_basename_index(): keys=%s" % sorted(index))

# ── Group 4: CONTROL — a TRACKED junk-named file IS included ──
# Same junk basename, but TRACKED (no post_add → it is git-added), so BOTH
# builders MUST include it — proving Groups 1/2 pass because the junk is
# UNTRACKED, not because the builders went blind.
def tracked_junk_tree(root):
    (root / "maintenance-docs").mkdir()
    (root / "maintenance-docs" / "DESIGN-NOTE.md").write_text("# a pack-only doc\n")
    (root / "maintenance-docs" / "JUNKREF.md").write_text("a TRACKED junk-named file\n")
index, pack_only = build_in_tree(tracked_junk_tree)
if index is None or pack_only is None:
    failures.append("G4 CONTROL builder returned None in a git tree")
else:
    if "JUNKREF.md" not in index:
        failures.append("G4 CONTROL a TRACKED JUNKREF.md is MISSING from "
                        "_build_basename_index() (the builder went blind): "
                        "keys=%s" % sorted(index))
    if "JUNKREF.md" not in pack_only:
        failures.append("G4 CONTROL a TRACKED JUNKREF.md (pack-only tree) is "
                        "MISSING from _build_pack_only_doc_basenames(): %s"
                        % sorted(pack_only))

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "builder junk-immunity G1 (R7) + G2 (R5) + G4 (tracked control)" ;;
    *) t_fail "builder junk-immunity / control tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: git-unavailable / not-a-work-tree → lenient degradation
#          (helper + both builders return None; consumers SKIP leniently)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: git-unavailable → None helper/builders + consumer SKIP ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W2 wave-invariant). The check body now lives in
    validate_checks.boundary_refs and reads boundary_refs.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []

# A /tmp REPO_ROOT that is NOT a git work tree (no git init). It carries the
# minimal structure each consumer needs to PASS its own pre-index guard so the
# index-None SKIP path is actually reached:
#   Check 40 needs pack-ops/ to exist (else it skips before the index build).
#   Check 43 / 68 reach the index build directly.
tmpdir = tempfile.mkdtemp(prefix="vp-check4344-nogit-")
root = pathlib.Path(tmpdir)
(root / "pack-ops").mkdir()
(root / "pack-ops" / "PACK-OPS.md").write_text("# a doc with a bare \`REF.md\` ref\n")
(root / "maintenance-docs").mkdir()
(root / "maintenance-docs" / "DESIGN.md").write_text("# pack-only\n")

def run_with_root(fn):
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures); mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            result = fn()
        new_failures = list(mod.failures)
        cap = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear(); mod.failures.extend(saved_failures)
    return result, new_failures, cap

# Helper returns None on a non-git tree.
res, _, _ = run_with_root(mod._git_tracked_relpaths)
if res is not None:
    failures.append("G3 _git_tracked_relpaths() did not return None on a non-git tree: %r" % res)

# R5 builder returns None.
res, _, _ = run_with_root(mod._build_basename_index)
if res is not None:
    failures.append("G3 _build_basename_index() did not return None on a non-git tree: %r" % res)

# R7 builder returns None.
res, _, _ = run_with_root(mod._build_pack_only_doc_basenames)
if res is not None:
    failures.append("G3 _build_pack_only_doc_basenames() did not return None on a non-git tree: %r" % res)

# Each consumer SKIPs leniently: zero new failures + a "skipping (lenient)"
# message, never an AttributeError on a None index.
for name, fn in (("Check 40", mod.check_bare_pack_ops_refs),
                 ("Check 43", mod.check_project_side_bare_internal_refs),
                 ("Check 68", mod.check_dangling_file_refs)):
    try:
        _, new_failures, cap = run_with_root(fn)
    except Exception as e:
        failures.append("G3 %s raised %r on a non-git tree (expected lenient SKIP)" % (name, e))
        continue
    if new_failures:
        failures.append("G3 %s produced failures on a non-git tree (expected lenient SKIP): %s" % (name, new_failures))
    if "skipping (lenient)" not in cap:
        failures.append("G3 %s did not print a 'skipping (lenient)' message: %s" % (name, cap))

shutil.rmtree(tmpdir, ignore_errors=True)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "git-unavailable → helper/both builders return None + Check 40/43/68 SKIP leniently" ;;
    *) t_fail "git-unavailable lenient-degradation test failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 5: Live-tree smoke (git available; builders non-empty; no .DS_Store)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: Live-tree smoke ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
index = mod._build_basename_index()
pack_only = mod._build_pack_only_doc_basenames()
if index is None or pack_only is None:
    print('FAIL_LIVE_NONE — builder returned None on the live (git) tree'); sys.exit(1)
if not index:
    print('FAIL_LIVE_INDEX_EMPTY'); sys.exit(1)
if not pack_only:
    print('FAIL_LIVE_PACKONLY_EMPTY'); sys.exit(1)
if '.DS_Store' in index:
    print('FAIL_LIVE_DSSTORE_IN_INDEX — the live tree carries a tracked .DS_Store?'); sys.exit(1)
if '.DS_Store' in pack_only:
    print('FAIL_LIVE_DSSTORE_IN_PACKONLY'); sys.exit(1)
print('OK')
" > /tmp/vp-check4344-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check4344-live.out; then
    t_pass "live-tree builders non-empty + no .DS_Store key (git available)"
else
    t_fail "live-tree smoke failed" "$(cat /tmp/vp-check4344-live.out)"
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
