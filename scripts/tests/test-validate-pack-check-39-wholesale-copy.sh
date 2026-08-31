#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-39-wholesale-copy.sh — synthetic tests
# for Check 39 FORWARD LEG 3 (wholesale-copy install completeness — BD-293 F1).
#
# Sibling of test-validate-pack-check-39.sh, which covers forward legs 1-2 and
# the reverse legs. Split into its own file (the `-<facet>` suffix convention
# test-validate-pack-check-49-field-faithfulness.sh already uses) because leg 3
# needs a DIFFERENT scaffold shape: a git-initialised repo with a bundle
# directory and a stage body carrying a real copy verb, where the leg-1/2
# scaffolds are non-git trees with a bare map.
#
# What leg 3 asserts. Forward legs 1-2 bound copy sites that ENUMERATE their
# members. A WHOLESALE site (`cp -R "$dir"` / `find "$dir"`) reaches every file
# beneath its source and cannot omit one, while the install map declares
# members one at a time and `cmd_update` dispatches ONLY from that map. A file
# the wholesale site ships but the map does not declare is placed by a fresh
# install AND by a migration, yet is invisible to `--update` — never refreshed,
# never repaired. That is the measured BD-293 F1 state: `plugin.json` and
# `RUNTIME-SUBAGENT-PATTERN.md` shipped in the Antigravity bundle with ZERO map
# rows on ANY axis.
#
# Two parts, so a vacuous pass is impossible:
#   COVERAGE   — every git-TRACKED member of a derived wholesale root is
#                covered on the `cmd_update` axis. NO exemption list.
#   BACKING    — (declare-verify-backing, the absence-of-backing instance) the
#                root set is DERIVED from the copy sites, so a rename moves the
#                assertion with it; when the recursive-copy marker is PRESENT
#                but the derivation resolves nothing — or resolves a root with
#                no tracked member — the leg FAILs instead of measuring an
#                empty set.
#
# invocation-vs-mention: the leg BITES an undeclared member, an off-axis member,
# a nested member a one-segment family `*` cannot reach, a vanished copy site,
# and a vacuous root — and SPARES the real intact tree, a scaffold with no copy
# verb at all, and the COMPOSED-assignment copy site (`local src="$pack_pt/$rel"`,
# the capability-pool shape), which names no single bounded surface and is out of
# scope BY CONSTRUCTION, with no allowlist entry.
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it `git init`s throwaway repos under mktemp). It lives under
# scripts/tests/ and auto-wires into CI via the disk glob (Check 42 / BD-219).
# Per "Test infra is self-provisioned": every case is built in a scratch git
# repo; the REAL tree is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + leg-3 symbols exported + Check 39 still registered
#   Group 1: Real-state-at-HEAD PASS (the real bundle is fully declared) and the
#            real derivation resolves a NON-vacuous surface
#   Group 2: Synthetic PASS/BITE/SPARE against scratch git repos:
#            - T1 PASS  : every member declared with cmd_update -> 0 failures
#            - T2 BITE  : a member with NO map row -> >=1 failure naming it
#            - T3 BITE  : a member declared but OFF the cmd_update axis
#            - T4 PASS  : members covered by a FAMILY row + the `find` idiom
#                         (whose leading `(` exercises the lookbehind)
#            - T5 BITE  : a NESTED member a one-segment family `*` cannot reach
#            - T6 BITE  : BACKING — `cp -R` present but no root resolves
#            - T7 BITE  : BACKING — copy site present, root has no TRACKED member
#            - T8 SPARE : a COMPOSED-assignment copy site adds no root and its
#                         undeclared members are NOT flagged
#            - T9 SPARE : no recursive-copy verb at all -> leg 3 inert (this is
#                         the leg-1/2 scaffold shape; proves no regression there)
#   Group 3: End-to-end validate-pack.py --only-check 39 on HEAD reports leg 3.
#
# Usage: bash scripts/tests/test-validate-pack-check-39-wholesale-copy.sh
# Exit 0 on all pass; exit 1 on any failure.

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

TMPOUT="$(mktemp -d "${TMPDIR:-/tmp}/vp-c39ws.XXXXXX")"
cleanup() { rm -rf "$TMPOUT"; }
trap cleanup EXIT

# ─────────────────────────────────────────────────────────────────
# Group 0: Module import + leg-3 symbols + Check 39 registration
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + leg-3 symbols exported ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
# Leg 3 adds NO registry entry — it is a leg on Check 39. Assert BOTH: the
# leg-3 symbols re-export through the facade (the __all__ three-source-union
# rule), and the registry count invariant still holds UNCHANGED (proving the
# leg was added WITHOUT a count bump, so the README check-inventory bijection
# Check 80 enforces is untouched).
for sym in ('_CHECK_39_WHOLESALE_SCRIPTS', '_CHECK_39_PACK_VAR_ASSIGN',
            '_CHECK_39_WHOLESALE_USE', '_CHECK_39_WHOLESALE_MARKER',
            '_check_39_wholesale_roots', '_check_39_wholesale_marker_present'):
    if not hasattr(mod, sym):
        print('FAIL_MISSING', sym); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if nums.count(39) != 1:
    print('FAIL_CHECK39_REGISTRATION', nums.count(39)); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
print('OK')
" > "$TMPOUT/import.out" 2>&1

if grep -q "^OK$" "$TMPOUT/import.out"; then
    t_pass "facade re-exports the leg-3 symbols + Check 39 registered once + count invariant holds (no registry growth)"
else
    t_fail "leg-3 symbol export / Check 39 registration / count invariant failed" \
        "$(cat "$TMPOUT/import.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD PASS ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, io, contextlib
sys.path.insert(0, os.environ['REPO_ROOT'] + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', os.environ['VALIDATE'])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# The derivation must resolve a NON-vacuous surface on the real tree —
# otherwise this group would "pass" on a leg that measures nothing.
roots = mod._check_39_wholesale_roots()
if not roots:
    failures.append("real tree resolves NO wholesale copy root")
if not mod._check_39_wholesale_marker_present():
    failures.append("real tree reports the recursive-copy marker ABSENT")

saved = list(mod.failures); mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_cmd_update_symmetry()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 39 expected 0 failures, got {len(new)}: {cap}")
if "wholesale-copied member(s)" not in cap:
    failures.append(f"real-state PASS message does not report leg 3: {cap}")
if "0 wholesale-copied member(s)" in cap:
    failures.append(f"leg 3 forward-checked ZERO members (vacuous): {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK  roots=" + ",".join(sorted(roots)))
EOF
case $? in
    0) t_pass "real-state-at-HEAD leg 3 PASSes on a NON-vacuous surface (a root resolves; every member is cmd_update-covered)" ;;
    *) t_fail "real-state Check 39 leg 3 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic scratch git-repo PASS/BITE/SPARE tests
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic scratch git-repo PASS/BITE/SPARE tests ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, subprocess, io, contextlib
sys.path.insert(0, os.environ['REPO_ROOT'] + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', os.environ['VALIDATE'])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule. Check 39's body lives in validate_checks.boundary_refs and
    resolves its git root via boundary_refs.REPO_ROOT (through
    _git_tracked_relpaths) plus its file reads; a facade-only patch would NOT
    bite."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


def init_sh(files_rows, glob_rows, copy_kind="literal", root_dir="bundle"):
    """A minimal init-project.sh: one stage function carrying the copy site,
    plus both install-map blocks.

    copy_kind:
      literal  — `local bundle_src="$PACK/project-template/<root_dir>"` +
                 `cp -R "$bundle_src" ...` (the bounded shape leg 3 derives)
      find     — the migrator idiom, written `< <(find "$bundle_src" -type f)`
                 so the leading `(` exercises the lookbehind. `cp -R` is ALSO
                 present (on an unrelated composed var) so the BACKING marker
                 is satisfied without adding a second literal root.
      composed — `local src="$pack_pt/$rel"` + `cp -R "$src" ...` (the
                 capability-pool shape: a runtime expression, no bounded
                 surface)
      none     — no wholesale verb at all (the leg-1/2 scaffold shape)
    """
    out = ["#!/usr/bin/env bash\nset -euo pipefail\n", "stage_x() {\n"]
    if copy_kind == "literal":
        out.append(f'    local bundle_src="$PACK/project-template/{root_dir}"\n')
        out.append('    cp -R "$bundle_src" "$TARGET/"\n')
    elif copy_kind == "find":
        out.append(f'    local bundle_src="$PACK/project-template/{root_dir}"\n')
        out.append('    local pack_pt="$PACK/project-template"\n')
        out.append('    local other="$pack_pt/$rel"\n')
        out.append('    cp -R "$other" "$TARGET/"\n')
        out.append('    while IFS= read -r f; do :; done < <(find "$bundle_src" -type f)\n')
    elif copy_kind == "composed":
        out.append('    local pack_pt="$PACK/project-template"\n')
        out.append('    local src="$pack_pt/$rel"\n')
        out.append('    cp -R "$src" "$(dirname "$dst")/"\n')
    out.append("}\n")
    out.append("# _CLIENT_INSTALLED_FILES_START\n")
    for src, dest, stages, cls in files_rows:
        out.append(f"#   {src}  ->  {dest}  [stage:{stages}]  [class:{cls}]\n")
    out.append("# _CLIENT_INSTALLED_FILES_END\n")
    out.append("# _CLIENT_INSTALLED_GLOBS_START\n")
    for src, dest, stages, cls in glob_rows:
        out.append(f"#   {src}  ->  {dest}  [stage:{stages}]  [class:{cls}]\n")
    out.append("# _CLIENT_INSTALLED_GLOBS_END\n")
    return "".join(out)


def build(tmp, init_text, tracked, untracked=()):
    root = pathlib.Path(tmp)
    (root / "scripts").mkdir(parents=True, exist_ok=True)
    (root / "scripts" / "init-project.sh").write_text(init_text)
    # Check 39 returns early without this dir; keep it EMPTY so forward legs
    # 1-2 check zero files and cannot pollute leg 3's verdict.
    (root / "project-template" / "docs" / "pack").mkdir(parents=True, exist_ok=True)
    for rel in tracked:
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("x\n")
    for rel in untracked:
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("x\n")
    subprocess.run(["git", "init", "-q", "."], cwd=root, capture_output=True)
    subprocess.run(["git", "add", "scripts/init-project.sh", *tracked],
                   cwd=root, capture_output=True)
    return root


def run(root):
    _patch_root(root)
    saved = list(mod.failures); mod.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_cmd_update_symmetry()
        return list(mod.failures), buf.getvalue()
    finally:
        mod.failures.clear(); mod.failures.extend(saved)


REAL = mod.REPO_ROOT
results = []


def case(name, expect, needle, init_text, tracked, untracked=()):
    tmp = tempfile.mkdtemp(prefix="vp39ws-")
    try:
        root = build(tmp, init_text, tracked, untracked)
        fails, cap = run(root)
        if expect == "pass":
            if fails:
                results.append(f"{name}: expected 0 failures, got {len(fails)}: {fails}")
            elif needle and needle not in cap:
                results.append(f"{name}: clean but message lacks {needle!r}: {cap}")
        else:
            if not fails:
                results.append(f"{name}: expected >=1 failure, got 0. out={cap}")
            elif needle and not any(needle in f for f in fails):
                results.append(f"{name}: bit, but no failure names {needle!r}: {fails}")
    finally:
        _patch_root(REAL)
        shutil.rmtree(tmp, ignore_errors=True)


ROW_A = ("project-template/bundle/a.md", ".bundle/a.md", "S2,cmd_update", "generic")
ROW_B = ("project-template/bundle/b.json", ".bundle/b.json", "S2,cmd_update", "generic")
ROW_B_OFFAXIS = ("project-template/bundle/b.json", ".bundle/b.json", "S2", "generic")

# T1 PASS — every member declared on the cmd_update axis.
case("T1 PASS all-declared", "pass", "2 wholesale-copied member(s)",
     init_sh([ROW_A, ROW_B], []),
     ["project-template/bundle/a.md", "project-template/bundle/b.json"])

# T2 BITE — a member with NO map row (the measured BD-293 F1 shape).
case("T2 BITE undeclared-member", "bite", "no `cmd_update` coverage",
     init_sh([ROW_A], []),
     ["project-template/bundle/a.md", "project-template/bundle/b.json"])

# T3 BITE — declared, but the row omits cmd_update: same un-refreshable harm.
case("T3 BITE off-cmd_update-axis", "bite", "b.json",
     init_sh([ROW_A, ROW_B_OFFAXIS], []),
     ["project-template/bundle/a.md", "project-template/bundle/b.json"])

# T4 PASS — members covered by a FAMILY row (the real bundle's shape) reached
# via the `find` idiom, whose leading `(` exercises the lookbehind.
case("T4 PASS family-row + find-idiom", "pass", "3 wholesale-copied member(s)",
     init_sh([("project-template/bundle/plugin.json", ".bundle/plugin.json",
               "S2,cmd_update", "self")],
             [("project-template/bundle/agents/*", ".bundle/agents/*",
               "S2,cmd_update", "self")],
             copy_kind="find"),
     ["project-template/bundle/plugin.json",
      "project-template/bundle/agents/x.md",
      "project-template/bundle/agents/y.md"])

# T5 BITE — a NESTED member. The family `*` matches within ONE path segment, so
# `agents/*` cannot reach `agents/sub/z.md`; the wholesale copy site reaches it.
case("T5 BITE nested-member-family-star-cannot-reach", "bite", "agents/sub/z.md",
     init_sh([("project-template/bundle/plugin.json", ".bundle/plugin.json",
               "S2,cmd_update", "self")],
             [("project-template/bundle/agents/*", ".bundle/agents/*",
               "S2,cmd_update", "self")]),
     ["project-template/bundle/plugin.json",
      "project-template/bundle/agents/x.md",
      "project-template/bundle/agents/sub/z.md"])

# T6 BITE (BACKING) — `cp -R` present but the literal assignment was rewritten
# into a composed form, so NO root resolves. Must not pass vacuously.
case("T6 BITE backing-no-root-resolves", "bite", "NO wholesale copy site resolves",
     init_sh([ROW_A, ROW_B], [], copy_kind="composed"),
     ["project-template/bundle/a.md", "project-template/bundle/b.json"])

# T7 BITE (BACKING) — copy site present, root exists, every member UNTRACKED:
# the coverage assertion would be vacuously true.
case("T7 BITE backing-vacuous-root", "bite", "NO git-tracked file",
     init_sh([ROW_A], []),
     [], untracked=["project-template/bundle/a.md"])

# T8 SPARE — a COMPOSED-assignment copy site alongside a literal one adds NO
# root, so its undeclared members are not flagged. Proves the capability-pool
# shape is out of scope BY CONSTRUCTION, with no allowlist entry.
composed_plus_literal = init_sh([ROW_A], []).replace(
    "}\n# _CLIENT_INSTALLED_FILES_START",
    '    local pack_pt="$PACK/project-template"\n'
    '    local src="$pack_pt/$rel"\n'
    '    cp -R "$src" "$(dirname "$dst")/"\n'
    "}\n# _CLIENT_INSTALLED_FILES_START",
)
case("T8 SPARE composed-assignment-not-a-root", "pass",
     "1 derived copy root(s)",
     composed_plus_literal,
     ["project-template/bundle/a.md", "project-template/pool/undeclared.md"])

# T9 SPARE — no recursive-copy verb at all: leg 3 is inert. This is the shape
# test-validate-pack-check-39.sh's leg-1/2 scaffolds use, so it proves leg 3
# did not regress them.
case("T9 SPARE no-copy-verb-leg3-inert", "pass", "0 wholesale-copied member(s)",
     init_sh([ROW_A], [], copy_kind="none"),
     ["project-template/bundle/a.md", "project-template/bundle/b.json"])

if results:
    print("FAILURES")
    for r in results:
        print("  ", r)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "synthetic PASS/BITE/SPARE matrix (T1-T9): leg 3 bites undeclared, off-axis, nested, no-root, vacuous-root; spares composed-assignment + verbless scaffold" ;;
    *) t_fail "synthetic Check 39 leg-3 matrix failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end --only-check 39 on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end --only-check 39 on HEAD ===\n"

if python3 "$VALIDATE" --only-check 39 > "$TMPOUT/e2e.out" 2>&1; then
    if grep -q "wholesale-copied member(s)" "$TMPOUT/e2e.out"; then
        t_pass "validate-pack.py --only-check 39 exits 0 and reports leg 3 on HEAD"
    else
        t_fail "--only-check 39 exited 0 but did not report leg 3" "$(cat "$TMPOUT/e2e.out")"
    fi
else
    t_fail "validate-pack.py --only-check 39 failed on HEAD" "$(cat "$TMPOUT/e2e.out")"
fi

printf "\n──────────────────────────────────────────\n"
printf "Check 39 leg-3 tests: %d passed, %d failed\n" "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
