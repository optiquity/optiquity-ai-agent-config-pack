#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-68.sh — synthetic fixture tests for
# BD-243 Check 68 (Gate 3: dangling-reference gate;
# DESIGN-BD-243-DURABLE-GATES.md §3 Gate 3).
#
# Check 68 extracts file/path references (backtick bare-ref, markdown
# hyperlink, and the NEW qualified-path backtick) from the operating-doc IN set
# + the deliverable surface, and FAILs on any reference whose target does not
# exist — a dead pointer. A ref resolves via direct path / basename index; an
# anchor-windowed ("archived"/"does not exist") ref is intentional non-
# existence (auto-cleared); else the pack-ops/.dangling-ref-allowlist.txt
# (token-keyed) must clear it.
#
# This test exercises Check 68's BODY IN-PROCESS against (a) synthetic /tmp
# trees and (b) the live tree, and asserts that 68 IS in CHECK_REGISTRY while
# the count invariant holds DYNAMICALLY (never a hardcoded literal).
#
# Test infra is self-provisioned (synthetic /tmp REPO_ROOT). Cleanup on every
# exit path.
#
# Coverage:
#   Group 0: Module import + Check 68 symbols + dynamic count-invariant +
#            Check 68 REGISTERED
#   Group 1: Synthetic-tree end-to-end (in-process body invocation) —
#            T1 a ref that resolves (target exists) PASSES
#            T2 a dangling ref cleared by an anchor phrase ("archived") PASSES
#            T3 a dangling ref cleared by an allowlist token PASSES
#            T4 a dangling ref NOT cleared FAILS (the teeth)
#            T5 a qualified-path dangling ref NOT cleared FAILS (the new axis)
#            T6 a MOVED file FAILS even though its basename exists elsewhere
#               (the qualified branch resolves NO path by bare basename)
#            T7 leg A — a client-install-relative path resolves against the
#               project-template/ prefix
#            T8 leg B — an install-map DEST resolves against its pack SOURCE
#            T9 leg B is load-bearing — the same tree with no install map FAILS
#            T10 the scanned set is git-TRACKED — an UNTRACKED file carrying a
#               dangling ref is neither scanned nor reported
#            T14/T15/T16 every qualified RESOLUTION leg is git-TRACKED too —
#               a target written after `git add` resolves on no leg (direct /
#               leg A / leg B), so the verdict is identical on a developer box
#               and on a fresh CI clone
#            T11/T12/T13 the two history-tree EXCLUDE members are ENTRY-shaped
#               — `<tree>/_rules.md` is IN scope and a per-entry body is OUT;
#               a tree-wide prefix instead scans 0 files and leaves the same
#               bad reference unreported
#   Group 2: Live-tree in-process body invocation PASSES (0 dangling outside
#            the allowlist; the dangling-ref fix landed) — exercised via the
#            in-process body call (Check 68's clean live-tree run is also
#            covered by the full no-flag validate-pack now that it is registered)
#   Group 3: the lenient-SKIP branch (REPO_ROOT is not a git work tree), pinned
#            with a fixture that CARRIES a dangling ref — so the pass can only
#            come from the SKIP branch. This is what makes Group 1's git-init
#            load-bearing rather than decorative: without it T4-T12 would pass
#            vacuously off the SKIP path.
#
# Usage: bash scripts/tests/test-validate-pack-check-68.sh

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
#          Check 68 REGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 68 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_dangling_file_refs', '_check_68_load_allowlist',
            '_CHECK_68_QUALIFIED_PATH_PATTERN', '_CHECK_68_INCLUDE_TREES',
            '_CHECK_68_EXCLUDE_PREFIXES', '_build_basename_index',
            '_git_tracked_relpaths', '_client_install_dest_to_source',
            '_strip_code_blocks', '_CHECK_40_ANCHOR_PHRASES']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 68 not in nums:
    print('FAIL_68_NOT_REGISTERED — Check 68 must be in CHECK_REGISTRY');
    sys.exit(1)
# The two history-tree EXCLUDE members are ENTRY-shaped, not TREE-shaped, so
# each stream's _rules.md write-contract stays on the existence axis.
pfx = mod._CHECK_68_EXCLUDE_PREFIXES
if 'changelog/v' not in pfx or 'changelog/' in pfx:
    print('FAIL_EXCLUDE_SHAPE — changelog member must be the entry-shaped '
          'changelog/v, never the tree-wide changelog/:', pfx); sys.exit(1)
if 'backlog/BD-' not in pfx or 'backlog/' in pfx:
    print('FAIL_EXCLUDE_SHAPE — backlog member must be the entry-shaped '
          'backlog/BD-, never the tree-wide backlog/:', pfx); sys.exit(1)
# _build_basename_index takes an OPTIONAL pre-fetched tracked list, so Check 68
# reuses ONE git ls-files for both the index and its scope walk.
import inspect
_p = inspect.signature(mod._build_basename_index).parameters
if 'rels' not in _p or _p['rels'].default is not None:
    print('FAIL_INDEX_SIGNATURE — expected an optional rels=None parameter:',
          list(_p)); sys.exit(1)
# The install-map reverse parser BITES against the real inventory (not merely
# importable): it must yield entries, and a known DEST must map to its SOURCE.
_d2s = mod._client_install_dest_to_source()
if not _d2s:
    print('FAIL_DEST_TO_SOURCE_EMPTY — the reverse install map parsed nothing');
    sys.exit(1)
if _d2s.get('docs/pack/METHODOLOGY.md') != 'supporting-docs/METHODOLOGY.md':
    print('FAIL_DEST_TO_SOURCE_MAPPING — docs/pack/METHODOLOGY.md should map '
          'to supporting-docs/METHODOLOGY.md, got:',
          _d2s.get('docs/pack/METHODOLOGY.md')); sys.exit(1)
print('OK')
" > /tmp/vp-check68-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check68-import.out; then
    t_pass "imports + Check 68 symbols present + count invariant holds (dynamic) + Check 68 REGISTERED + EXCLUDE members entry-shaped + index takes a pre-fetched rels + the install-map reverse parser resolves a known DEST"
else
    t_fail "Check 68 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check68-import.out)"
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
    """Set attribute \`name\` on the facade alias AND every loaded
    validate_checks.* submodule that already binds it (BD-256 W2
    wave-invariant). The check body's intra-cluster constant now lives in
    validate_checks.boundary_refs; a facade-only patch would NOT bite. This
    reaches the owning module's binding wherever the body resolves it."""
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                setattr(_m, name, value)


failures = []

import subprocess

def _git_init_and_add(root):
    """Make the synthetic /tmp tree a git repo and TRACK its built files.
    Check 68 resolves refs against \`_build_basename_index()\`, which since
    BD-244 enumerates git ls-files (tracked-only) — so a synthetic tree MUST
    be a git work tree with its files staged, else the builder returns None
    and the check lenient-SKIPs (no resolution)."""
    env = {"GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
           "HOME": str(root), "PATH": __import__("os").environ.get("PATH", "")}
    subprocess.run(["git", "init", "-q"], cwd=root, env=env, check=True)
    subprocess.run(["git", "add", "-A"], cwd=root, env=env, check=True)

def run_check_in_tree(builder, allowlist_text, include_trees=("docs",),
                      exclude_prefixes=None, post_add=None):
    """Build a synthetic /tmp REPO_ROOT, monkeypatch the scope to the given
    include trees (and the operating-doc families to nothing), run the body,
    restore, return (fails, captured).

    include_trees    — override _CHECK_68_INCLUDE_TREES for this run.
    exclude_prefixes — override _CHECK_68_EXCLUDE_PREFIXES for this run
                       (None = ship default), so a leg can compare an
                       ENTRY-shaped member against a TREE-wide one.
    post_add         — a builder run AFTER git add, so its files stay
                       UNTRACKED; this is how the tracked-set legs get a file
                       that exists on disk but must never be scanned.
    """
    tmpdir = tempfile.mkdtemp(prefix="vp-check68-")
    root = pathlib.Path(tmpdir)
    (root / "pack-ops").mkdir()
    builder(root)
    if allowlist_text:
        (root / "pack-ops" / ".dangling-ref-allowlist.txt").write_text(allowlist_text)
    _git_init_and_add(root)
    if post_add is not None:
        post_add(root)

    saved_root = mod.REPO_ROOT
    saved_inc = mod._CHECK_68_INCLUDE_TREES
    saved_exc = mod._CHECK_68_EXCLUDE_PREFIXES
    saved_fams = mod._CHECK_OPERATING_DOC_FAMILIES
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    _patch_attr(mod, "_CHECK_68_INCLUDE_TREES", tuple(include_trees))
    if exclude_prefixes is not None:
        _patch_attr(mod, "_CHECK_68_EXCLUDE_PREFIXES", tuple(exclude_prefixes))
    _patch_attr(mod, "_CHECK_OPERATING_DOC_FAMILIES", ())   # only the include tree is scope
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_dangling_file_refs()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        _patch_attr(mod, "_CHECK_68_INCLUDE_TREES", saved_inc)
        _patch_attr(mod, "_CHECK_68_EXCLUDE_PREFIXES", saved_exc)
        _patch_attr(mod, "_CHECK_OPERATING_DOC_FAMILIES", saved_fams)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)


import re as _re


def scanned_count(captured):
    """The \`N file(s) scanned\` term out of the OK line, or -1 if absent."""
    m = _re.search(r"(\d+) file\(s\) scanned", captured)
    return int(m.group(1)) if m else -1

# T1: PASS — a ref that resolves (the target file exists in the tree).
def b1(root):
    (root / "docs").mkdir()
    (root / "docs" / "real-target.md").write_text("the target exists\n")
    (root / "docs" / "citer.md").write_text("see \`real-target.md\` for details\n")
fc, cap = run_check_in_tree(b1, "")
if fc != 0:
    failures.append("T1 (resolving ref PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "complete" not in cap:
    failures.append("T1 (resolving ref PASS) expected the complete OK message: %s" % cap)

# T2: PASS — a dangling ref cleared by an anchor phrase ("archived").
def b2(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("from the now-archived \`OLD-DOC.md\` (removed)\n")
fc, cap = run_check_in_tree(b2, "")
if fc != 0:
    failures.append("T2 (anchor-cleared PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "anchor-cleared" not in cap:
    failures.append("T2 (anchor-cleared PASS) expected 'anchor-cleared' in output: %s" % cap)

# T3: PASS — a dangling ref cleared by an allowlist token.
def b3(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("the per-entry grammar is \`BD-NNN.md\`\n")
ALLOW = "token: BD-NNN.md\nreason: grammar placeholder (synthetic).\n"
fc, cap = run_check_in_tree(b3, ALLOW)
if fc != 0:
    failures.append("T3 (allowlisted-token PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "allowlisted" not in cap:
    failures.append("T3 (allowlisted-token PASS) expected 'allowlisted' in output: %s" % cap)

# T4: FAIL — a dangling bare ref NOT cleared (the teeth).
def b4(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("see \`MISSING-DOC.md\` for details\n")
fc, cap = run_check_in_tree(b4, "")
if fc < 1:
    failures.append("T4 (dangling bare FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "dangling reference" not in cap:
    failures.append("T4 (dangling bare FAIL) expected the dangling FAIL message: %s" % cap)
if "MISSING-DOC.md" not in cap:
    failures.append("T4 (dangling bare FAIL) expected the offending token in output: %s" % cap)

# T5: FAIL — a dangling QUALIFIED-path ref NOT cleared (the new axis: the
#     bare-ref pattern's /-exclusion would miss this; the qualified pattern
#     catches it).
def b5(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("removed \`pack-ops/GONE-DOC.md\` here\n")
fc, cap = run_check_in_tree(b5, "")
if fc < 1:
    failures.append("T5 (dangling qualified FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "pack-ops/GONE-DOC.md" not in cap:
    failures.append("T5 (dangling qualified FAIL) expected the qualified-path token in output: %s" % cap)

# T6: FAIL — a MOVED file. The cited QUALIFIED path holds nothing, but a file
#     of the SAME BASENAME exists elsewhere in the tree (and so is in the
#     basename index). Resolving on that basename is precisely how a reference
#     to a moved file stayed green; the qualified branch must NOT do it.
def b6(root):
    (root / "docs").mkdir()
    (root / "docs" / "real-target.md").write_text("the target exists HERE\n")
    (root / "docs" / "citer.md").write_text(
        "see \`docs/WRONGDIR/real-target.md\` for details\n")
fc, cap = run_check_in_tree(b6, "")
if fc < 1:
    failures.append("T6 (moved-file qualified FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "docs/WRONGDIR/real-target.md" not in cap:
    failures.append("T6 (moved-file qualified FAIL) expected the stale path in output: %s" % cap)

# T7: PASS — leg A. A CLIENT-audience relative path that has no pack-repo file
#     at its literal path, but does exist under the project-template/ install
#     prefix. With the basename fallback gone (T6), this can only resolve on
#     leg A.
def b7(root):
    (root / "docs").mkdir()
    (root / "project-template" / "docs" / "pack").mkdir(parents=True)
    (root / "project-template" / "docs" / "pack" / "LEGA-DOC.md").write_text("shipped\n")
    (root / "docs" / "citer.md").write_text("see \`docs/pack/LEGA-DOC.md\`\n")
fc, cap = run_check_in_tree(b7, "")
if fc != 0:
    failures.append("T7 (leg A client-install prefix) expected 0 failures, got %d: %s" % (fc, cap))

# T8: PASS — leg B. The cited path is an install-map DEST whose pack-storage
#     SOURCE exists; NOTHING lives under project-template/, so leg A cannot
#     fire and only the dest->source reverse map can resolve it.
INV = [
    "#!/usr/bin/env bash",
    "# _CLIENT_INSTALLED_FILES_START",
    "#   supporting-docs/LEGB-DOC.md  ->  docs/pack/LEGB-DOC.md  [stage:S6]",
    "# _CLIENT_INSTALLED_FILES_END",
]

def _legb_tree(root, with_inventory):
    (root / "docs").mkdir()
    (root / "supporting-docs").mkdir()
    (root / "supporting-docs" / "LEGB-DOC.md").write_text("pack-stored source\n")
    (root / "docs" / "citer.md").write_text("see \`docs/pack/LEGB-DOC.md\`\n")
    if with_inventory:
        (root / "scripts").mkdir()
        (root / "scripts" / "init-project.sh").write_text("\n".join(INV) + "\n")

fc, cap = run_check_in_tree(lambda r: _legb_tree(r, True), "")
if fc != 0:
    failures.append("T8 (leg B install-map reverse) expected 0 failures, got %d: %s" % (fc, cap))

# T9: FAIL — leg B is LOAD-BEARING. Identical tree with the install map
#     REMOVED: the reverse map is empty (lenient {}), so the same reference now
#     has no resolution leg left and must FAIL. Without this, T8 could be
#     passing off some other leg.
fc, cap = run_check_in_tree(lambda r: _legb_tree(r, False), "")
if fc < 1:
    failures.append("T9 (leg B removed -> FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "docs/pack/LEGB-DOC.md" not in cap:
    failures.append("T9 (leg B removed -> FAIL) expected the DEST token in output: %s" % cap)

# T10: PASS — the scanned set is git-TRACKED. An UNTRACKED file is written into
#      the include tree AFTER git add; it carries an uncleared dangling ref, so
#      a filesystem walk would scan it and FAIL. The tracked selection must not
#      see it, and the scanned-file count must stay at the tracked 1.
def b10(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("nothing to resolve here\n")

def b10_untracked(root):
    (root / "docs" / "untracked-junk.md").write_text(
        "see \`NEVER-SCANNED-DOC.md\` here\n")

fc, cap = run_check_in_tree(b10, "", post_add=b10_untracked)
if fc != 0:
    failures.append("T10 (untracked file excluded) expected 0 failures, got %d: %s" % (fc, cap))
if "NEVER-SCANNED-DOC.md" in cap:
    failures.append("T10 (untracked file excluded) an untracked file was scanned: %s" % cap)
if scanned_count(cap) != 1:
    failures.append("T10 (untracked file excluded) expected exactly 1 scanned file, got %d: %s"
                    % (scanned_count(cap), cap))

# T11: FAIL — the history-tree EXCLUDE member is ENTRY-shaped, so a stream's
#      _rules.md write-contract stays IN scope while a per-entry body is OUT.
#      Both files carry the same uncleared dangling ref; exactly one is scanned.
def b11(root):
    (root / "changelog").mkdir()
    (root / "changelog" / "_rules.md").write_text("write per \`RULES-TARGET.md\`\n")
    (root / "changelog" / "v11.0.md").write_text("history cites \`RULES-TARGET.md\`\n")

fc, cap = run_check_in_tree(b11, "", include_trees=("changelog",))
if fc != 1:
    failures.append("T11 (entry-shaped EXCLUDE) expected exactly 1 failure, got %d: %s" % (fc, cap))
if "changelog/_rules.md" not in cap:
    failures.append("T11 (entry-shaped EXCLUDE) expected changelog/_rules.md to be scanned: %s" % cap)
if "changelog/v11.0.md" in cap:
    failures.append("T11 (entry-shaped EXCLUDE) a per-entry body was scanned: %s" % cap)

TREEWIDE = tuple(
    "changelog/" if p == "changelog/v" else p for p in mod._CHECK_68_EXCLUDE_PREFIXES)

# T12: the SAME tree under a TREE-WIDE changelog/ prefix stops scanning the
#      write-contract at all, so its bad ref goes unreported. Run both shapes
#      with the ref ALLOWLISTED so each emits an OK line, and compare the
#      scanned-file counts: exactly 1 under the entry-shaped member, exactly 0
#      under the tree-wide one. This pins WHAT the entry-shaped member buys.
T12_ALLOW = "token: RULES-TARGET.md\nreason: synthetic KEEP for the count leg.\n"
fc_entry, cap_entry = run_check_in_tree(b11, T12_ALLOW, include_trees=("changelog",))
fc_wide, cap_wide = run_check_in_tree(b11, T12_ALLOW, include_trees=("changelog",),
                                      exclude_prefixes=TREEWIDE)
if (fc_entry, fc_wide) != (0, 0):
    failures.append("T12 (EXCLUDE-shape count leg) expected 0 failures on both runs, got %d/%d: %s | %s"
                    % (fc_entry, fc_wide, cap_entry, cap_wide))
if scanned_count(cap_entry) != 1:
    failures.append("T12 entry-shaped changelog/v should scan exactly the write-contract (1), got %d: %s"
                    % (scanned_count(cap_entry), cap_entry))
if scanned_count(cap_wide) != 0:
    failures.append("T12 tree-wide changelog/ should scan nothing (0), got %d: %s"
                    % (scanned_count(cap_wide), cap_wide))

# T13: FAIL — the tree-wide shape is what the entry-shaped member replaced, so
#      prove the difference is a REPORTING difference and not just a count one:
#      the same uncleared ref that T11 reports must go UNREPORTED tree-wide.
fc, cap = run_check_in_tree(b11, "", include_trees=("changelog",),
                            exclude_prefixes=TREEWIDE)
if fc != 0:
    failures.append("T13 (tree-wide EXCLUDE) expected 0 failures, got %d: %s" % (fc, cap))
if "changelog/_rules.md" in cap:
    failures.append("T13 (tree-wide EXCLUDE) the write-contract should be out of scope: %s" % cap)

# T14/T15/T16: FAIL — every qualified resolution leg tests git-TRACKED
#      membership, not the filesystem. Each target is written AFTER git add, so
#      it EXISTS on disk but is invisible to git. A filesystem-existence leg
#      would resolve all three and report green on a developer box while CI,
#      which never sees the files, saw an unresolvable reference. One leg per
#      converted rung: direct, leg A, leg B.
def b14(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("see \`docs/untracked-target.md\`\n")

def b14_untracked(root):
    (root / "docs" / "untracked-target.md").write_text("on disk, untracked\n")

fc, cap = run_check_in_tree(b14, "", post_add=b14_untracked)
if fc < 1:
    failures.append("T14 (direct leg: untracked target) expected >=1 failure, got %d: %s" % (fc, cap))
if "docs/untracked-target.md" not in cap:
    failures.append("T14 (direct leg: untracked target) expected the token in output: %s" % cap)

def b15(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("see \`docs/pack/LEGA-UNTRACKED.md\`\n")

def b15_untracked(root):
    d = root / "project-template" / "docs" / "pack"
    d.mkdir(parents=True)
    (d / "LEGA-UNTRACKED.md").write_text("on disk under the install prefix, untracked\n")

fc, cap = run_check_in_tree(b15, "", post_add=b15_untracked)
if fc < 1:
    failures.append("T15 (leg A: untracked install-prefix target) expected >=1 failure, got %d: %s" % (fc, cap))
if "docs/pack/LEGA-UNTRACKED.md" not in cap:
    failures.append("T15 (leg A: untracked install-prefix target) expected the token in output: %s" % cap)

INV_UNTRACKED = [
    "#!/usr/bin/env bash",
    "# _CLIENT_INSTALLED_FILES_START",
    "#   supporting-docs/LEGB-UNTRACKED.md  ->  docs/pack/LEGB-UNTRACKED.md  [stage:S6]",
    "# _CLIENT_INSTALLED_FILES_END",
]

def b16(root):
    (root / "docs").mkdir()
    (root / "scripts").mkdir()
    (root / "scripts" / "init-project.sh").write_text("\n".join(INV_UNTRACKED) + "\n")
    (root / "docs" / "citer.md").write_text("see \`docs/pack/LEGB-UNTRACKED.md\`\n")

def b16_untracked(root):
    d = root / "supporting-docs"
    d.mkdir()
    (d / "LEGB-UNTRACKED.md").write_text("pack-storage source on disk, untracked\n")

fc, cap = run_check_in_tree(b16, "", post_add=b16_untracked)
if fc < 1:
    failures.append("T16 (leg B: untracked install-map source) expected >=1 failure, got %d: %s" % (fc, cap))
if "docs/pack/LEGB-UNTRACKED.md" not in cap:
    failures.append("T16 (leg B: untracked install-map source) expected the token in output: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T16 (resolving / anchor-cleared / allowlisted / dangling-bare-FAIL / dangling-qualified-FAIL / moved-file-FAIL / leg-A / leg-B / leg-B-load-bearing / untracked-excluded / entry-shaped-EXCLUDE x3 / untracked-unresolvable x3)" ;;
    *) t_fail "Synthetic-tree check_dangling_file_refs tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Live-tree in-process body invocation (via the body call, not --only-check 68)
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
    mod.check_dangling_file_refs()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE_DANGLING')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if 'complete' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
print(cap.strip())
" > /tmp/vp-check68-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check68-live.out; then
    t_pass "Check 68 body runs clean on the live tree (0 dangling ref outside the allowlist; the dangling-ref fix landed)"
else
    t_fail "Check 68 body found a dangling ref outside the allowlist on the live tree OR no clean message" \
        "$(tail -25 /tmp/vp-check68-live.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 3: REPO_ROOT is not a git work tree -> lenient SKIP
# The fixture CARRIES an uncleared dangling ref in the include tree, so a
# non-lenient implementation would FAIL it — the pass can only come from the
# SKIP branch. This also pins WHY Group 1 git-inits its fixtures: off this
# path the negative legs would report 0 failures for the wrong reason.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: not-a-git-work-tree -> lenient SKIP ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(mod, root):
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


def _patch_attr(mod, name, value):
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                setattr(_m, name, value)


failures = []

# Deliberately NOT a git work tree, and NOT inside one: /tmp is outside the
# pack checkout, so git ls-files finds no work tree and the builder returns
# None.
tmpdir = tempfile.mkdtemp(prefix="vp-check68-nogit-")
root = pathlib.Path(tmpdir)
(root / "pack-ops").mkdir()
(root / "docs").mkdir()
(root / "docs" / "citer.md").write_text("see \`ABSENT-DOC.md\` for details\n")

saved_root = mod.REPO_ROOT
saved_inc = mod._CHECK_68_INCLUDE_TREES
saved_fams = mod._CHECK_OPERATING_DOC_FAMILIES
saved_failures = list(mod.failures)
mod.failures.clear()
_patch_root(mod, root)
_patch_attr(mod, "_CHECK_68_INCLUDE_TREES", ("docs",))
_patch_attr(mod, "_CHECK_OPERATING_DOC_FAMILIES", ())
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_dangling_file_refs()
    n = len(mod.failures)
    cap = buf.getvalue()
finally:
    _patch_root(mod, saved_root)
    _patch_attr(mod, "_CHECK_68_INCLUDE_TREES", saved_inc)
    _patch_attr(mod, "_CHECK_OPERATING_DOC_FAMILIES", saved_fams)
    mod.failures.clear()
    mod.failures.extend(saved_failures)
    shutil.rmtree(tmpdir, ignore_errors=True)

if n != 0:
    failures.append("G3 expected the lenient SKIP (0 failures), got %d: %s" % (n, cap))
if "skipping (lenient)" not in cap:
    failures.append("G3 expected the lenient-SKIP notice, got: %s" % cap)
if "file(s) scanned" in cap:
    failures.append("G3 the check scanned instead of skipping: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "non-git REPO_ROOT carrying a dangling ref -> lenient SKIP (proves Group 1's git-init is load-bearing, not decorative)" ;;
    *) t_fail "Check 68 lenient-SKIP branch tests failed (see Python output)" ;;
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
