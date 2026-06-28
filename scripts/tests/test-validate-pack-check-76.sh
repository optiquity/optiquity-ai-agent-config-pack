#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-pack-check-76.sh — synthetic fixture tests for
# BD-246 Check 76 (pack-shipped immutable-file content-integrity;
# DESIGN-RECONCILED.md §2.5 + DESIGN-WIRING-ADDENDUM.md Q3/W2/W3).
#
# Check 76 verifies the pack's OWN copy of the immutable set
# (`_IMMUTABLE_SHIPPED`, the 3 `_rules.md`) against the shipped content-checksum
# manifest `project-template/docs/project/immutable-manifest.txt`. Five legs:
#   (1) SKIP-lenient when the manifest is absent (fresh clone / pre-feature HEAD)
#   (2) parse `# pack-version:` + `<path>  <64-hex>` rows (64-hex sha256)
#   (3) set-equality: manifest row paths (mapped pack-relative) == _IMMUTABLE_SHIPPED
#   (4) content verify (in-process hashlib.sha256), PACK-SIDE version-gated (F-3)
#   (5) structural: verify-immutable.sh ships + is executable + is WIRED into the
#       one-host wiring set (validate.sh ONLY — NOT agent-post-edit-check.sh)
#
# This test exercises Check 76's BODY IN-PROCESS against (a) synthetic /tmp
# REPO_ROOT trees (the monkeypatch seam: save/restore mod.REPO_ROOT + the
# README global + mod.failures) and (b) the live tree, and asserts that 76 IS
# in the registry while the count invariant holds DYNAMICALLY (never a hardcoded
# literal). Test infra is self-provisioned: every synthetic tree is built under
# a /tmp REPO_ROOT; no real shipped file is mutated. Cleanup runs on every exit.
#
# Coverage:
#   Group 0: Module import + Check 76 symbols + dynamic count-invariant +
#            Check 76 REGISTERED (76 in registry; count == the DYNAMIC
#            CHECK_REGISTRY_EXPECTED_COUNT, no literal)
#   Group 1: Synthetic-tree end-to-end (in-process body invocation) —
#            T1  complete tree (manifest + 3 files + verify-immutable.sh
#                executable + wired into validate.sh) PASSES
#            T2  tampered _rules.md (hash mismatch, version-matched) FAILS
#            T3  WHOLLY-ABSENT manifest → lenient SKIP
#            T4  verify-immutable.sh present + executable but NOT wired into
#                validate.sh FAILS (the wired-assertion teeth)
#            T5  verify-immutable.sh MISSING FAILS
#            T6  set-equality breach (an extra manifest row) FAILS
#            T7  version-mismatch (manifest pack-version != README) → tamper is
#                ADVISORY (no fail); set-equality + structural still hard
#            T8  malformed manifest row (not 64-hex) FAILS
#   Group 2: Live-tree in-process body invocation PASSES (C1's real manifest +
#            C3's verify-immutable.sh + W1's wired validate.sh)
#
# Usage: bash scripts/tests/test-validate-pack-check-76.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

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
#          Check 76 REGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 76 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_immutable_manifest', '_IMMUTABLE_SHIPPED',
           '_IMMUTABLE_MANIFEST', '_CHECK_76_CLIENT_VERIFY',
           '_CHECK_76_WIRING_FILES']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# the immutable set is exactly the 3 _rules.md (measure-then-bound).
if len(mod._IMMUTABLE_SHIPPED) != 3:
    print('FAIL_IMMUTABLE_COUNT', mod._IMMUTABLE_SHIPPED); sys.exit(1)
# ONE-host wiring set: validate.sh only (WD-2 — NOT agent-post-edit-check.sh).
if len(mod._CHECK_76_WIRING_FILES) != 1:
    print('FAIL_WIRING_COUNT', mod._CHECK_76_WIRING_FILES); sys.exit(1)
if 'validate.sh' not in mod._CHECK_76_WIRING_FILES[0]:
    print('FAIL_WIRING_HOST', mod._CHECK_76_WIRING_FILES); sys.exit(1)
# the one-host set must NOT demand agent-post-edit-check.sh (the deliberate
# asymmetry — over-asserting would FAIL the correct post-fix state).
if any('agent-post-edit-check' in w for w in mod._CHECK_76_WIRING_FILES):
    print('FAIL_OVER_ASSERT', mod._CHECK_76_WIRING_FILES); sys.exit(1)
# DYNAMIC count invariant — never a hardcoded literal (matches check-70).
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
# Check 76 is REGISTERED: 76 must be in the registry.
nums = [t[0] for t in mod._build_check_registry()]
if 76 not in nums:
    print('FAIL_76_NOT_REGISTERED'); sys.exit(1)
print('OK')
" > /tmp/vp-check76-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check76-import.out; then
    t_pass "imports + Check 76 symbols present + _IMMUTABLE_SHIPPED is 3 + one-host wiring (validate.sh only, no agent-post-edit-check) + count invariant holds (dynamic) + Check 76 REGISTERED"
else
    t_fail "Check 76 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check76-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Synthetic-tree end-to-end (in-process body invocation)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Synthetic-tree end-to-end (in-process body) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib, os, stat, hashlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Project-relative immutable paths (the manifest stores these client-relative
# rows; the pack-side leg maps docs/project/X -> project-template/docs/project/X).
PROJ_RELS = [
    "docs/project/backlog/_rules.md",
    "docs/project/implementation-plan/_rules.md",
    "docs/project/changelog/_rules.md",
]
MANIFEST_REL = "project-template/docs/project/immutable-manifest.txt"
VERIFY_REL = "project-template/scripts/verify-immutable.sh"
VALIDATE_SH_REL = "project-template/scripts/validate.sh"
README_VERSION = "v11.0"

def build_tree(*, files=None, manifest_version="v11.0", readme_version="v11.0",
               include_manifest=True, manifest_extra_rows=None,
               manifest_malformed=False, include_verify=True,
               verify_executable=True, wire_validate=True):
    """Build a synthetic /tmp REPO_ROOT.
      files: dict project-rel -> body for the 3 _rules.md (defaults to a
             distinct body per file).
      manifest_*: control the manifest header version + row set.
      include_verify / verify_executable / wire_validate: control the
             structural (ship + executable + wired) assertion inputs.
    Returns the tmpdir Path (caller removes it)."""
    tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check76-"))
    if files is None:
        files = {r: ("rules body for %s\n" % r) for r in PROJ_RELS}
    # write the pack-side _rules.md files
    for rel, body in files.items():
        p = tmpdir / "project-template" / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(body)
    # README version table (first vN.M data row)
    readme = tmpdir / "README.md"
    readme.write_text(
        "| Version | Date | Notes |\n"
        "|---|---|---|\n"
        "| %s | May 2026 | synthetic |\n" % readme_version
    )
    # manifest
    if include_manifest:
        rows = []
        for rel in PROJ_RELS:
            body = files[rel]
            h = hashlib.sha256(body.encode("utf-8")).hexdigest()
            rows.append("%s  %s" % (rel, h))
        if manifest_extra_rows:
            rows.extend(manifest_extra_rows)
        if manifest_malformed:
            rows.append("docs/project/backlog/_rules.md  NOTHEX")
        man = tmpdir / MANIFEST_REL
        man.parent.mkdir(parents=True, exist_ok=True)
        header = (
            "# immutable-manifest.txt — synthetic\n"
            "# pack-version: %s\n"
            "# Format: <project-relative-path>  <sha256>\n"
            "#\n" % manifest_version
        )
        man.write_text(header + "\n".join(rows) + "\n")
    # verify-immutable.sh
    if include_verify:
        vp = tmpdir / VERIFY_REL
        vp.parent.mkdir(parents=True, exist_ok=True)
        vp.write_text("#!/usr/bin/env bash\n# integrity check\n")
        if verify_executable:
            os.chmod(vp, os.stat(vp).st_mode | stat.S_IXUSR | stat.S_IXGRP
                     | stat.S_IXOTH)
        else:
            os.chmod(vp, 0o644)
    # validate.sh host (wired or not)
    vs = tmpdir / VALIDATE_SH_REL
    vs.parent.mkdir(parents=True, exist_ok=True)
    if wire_validate:
        vs.write_text('#!/usr/bin/env bash\n'
                      '"\$SCRIPT_DIR/verify-immutable.sh" || EXIT_CODE=1\n')
    else:
        vs.write_text('#!/usr/bin/env bash\n# this host does not call it\n')
    return tmpdir

def run_in_tree(tmpdir):
    """Run check_immutable_manifest with REPO_ROOT + README monkeypatched to the
    synthetic tree; restore everything; return (new_failure_count, captured)."""
    saved_root = mod.REPO_ROOT
    saved_readme = mod.README
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = tmpdir
    mod.README = tmpdir / "README.md"
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_immutable_manifest()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.README = saved_readme
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — complete tree (manifest + 3 files + verify exec + wired).
fc, cap = run_in_tree(build_tree())
if fc != 0:
    failures.append("T1 (complete tree PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "row-paths == _IMMUTABLE_SHIPPED" not in cap:
    failures.append("T1 (complete tree PASS) expected the clean message: %s" % cap)
if "wired into validate.sh" not in cap:
    failures.append("T1 (complete tree PASS) expected the wired confirmation: %s" % cap)

# T2: FAIL — tampered _rules.md (hash mismatch, version-matched).
tampered = {r: ("rules body for %s\n" % r) for r in PROJ_RELS}
tdir = build_tree(files=tampered)
# overwrite one pack file AFTER the manifest captured its original hash
(tdir / "project-template" / PROJ_RELS[0]).write_text("MUTATED CONTENT\n")
fc, cap = run_in_tree(tdir)
if fc < 1:
    failures.append("T2 (tamper FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "CONTENT INTEGRITY MISMATCH" not in cap:
    failures.append("T2 (tamper FAIL) expected the integrity-mismatch message: %s" % cap)
if "backlog/_rules.md" not in cap:
    failures.append("T2 (tamper FAIL) expected the tampered file named: %s" % cap)

# T3: lenient SKIP — wholly-absent manifest.
fc, cap = run_in_tree(build_tree(include_manifest=False))
if fc != 0:
    failures.append("T3 (absent-manifest SKIP) expected 0 failures, got %d: %s" % (fc, cap))
if "absent — skipping (lenient" not in cap:
    failures.append("T3 (absent-manifest SKIP) expected the lenient-skip message: %s" % cap)

# T4: FAIL — verify-immutable.sh present + executable but NOT wired into
#     validate.sh (the wired-assertion teeth).
fc, cap = run_in_tree(build_tree(wire_validate=False))
if fc < 1:
    failures.append("T4 (not-wired FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "NOT wired into this host" not in cap:
    failures.append("T4 (not-wired FAIL) expected the not-wired message: %s" % cap)
if "validate.sh" not in cap:
    failures.append("T4 (not-wired FAIL) expected validate.sh named: %s" % cap)

# T5: FAIL — verify-immutable.sh MISSING entirely.
fc, cap = run_in_tree(build_tree(include_verify=False))
if fc < 1:
    failures.append("T5 (verify-missing FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "is MISSING" not in cap:
    failures.append("T5 (verify-missing FAIL) expected the MISSING message: %s" % cap)

# T6: FAIL — set-equality breach (an extra manifest row for a non-immutable path).
extra = ["docs/project/backlog/_intro.md  " + ("a" * 64)]
fc, cap = run_in_tree(build_tree(manifest_extra_rows=extra))
if fc < 1:
    failures.append("T6 (set-equality FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "NOT in _IMMUTABLE_SHIPPED" not in cap:
    failures.append("T6 (set-equality FAIL) expected the extra-path message: %s" % cap)

# T7: version mismatch — tamper becomes ADVISORY (no fail); set-equality +
#     structural still hard. Build with manifest version != README, then tamper.
tdir = build_tree(manifest_version="v10.0", readme_version="v11.0")
(tdir / "project-template" / PROJ_RELS[0]).write_text("MUTATED UNDER VERSION MISMATCH\n")
fc, cap = run_in_tree(tdir)
if fc != 0:
    failures.append("T7 (version-mismatch advisory) expected 0 failures, got %d: %s" % (fc, cap))
if "ADVISORY" not in cap:
    failures.append("T7 (version-mismatch advisory) expected the ADVISORY message: %s" % cap)

# T8: FAIL — malformed manifest row (hash not 64-hex).
fc, cap = run_in_tree(build_tree(manifest_malformed=True))
if fc < 1:
    failures.append("T8 (malformed-row FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "malformed row" not in cap:
    failures.append("T8 (malformed-row FAIL) expected the malformed-row message: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T8 (complete-PASS / tamper-FAIL / absent-SKIP / not-wired-FAIL / verify-missing-FAIL / set-equality-FAIL / version-mismatch-advisory / malformed-row-FAIL)" ;;
    *) t_fail "Synthetic-tree check_immutable_manifest tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Live-tree in-process body invocation
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
    mod.check_immutable_manifest()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if 'row-paths == _IMMUTABLE_SHIPPED' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
if 'wired into validate.sh' not in cap:
    print('FAIL_NO_WIRED_MSG', cap); sys.exit(1)
print('OK')
print(cap.strip())
" > /tmp/vp-check76-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check76-live.out; then
    t_pass "Check 76 body runs clean on the live tree (C1's manifest + set-equality + content-hash + C3's verify-immutable.sh wired into W1's validate.sh)"
else
    t_fail "Check 76 body found an integrity/wiring gap on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check76-live.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"
    echo "=== Results: $PASS passed, $FAIL failed ==="
    exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"
    echo "=== Results: $PASS passed, $FAIL failed ==="
    exit 1
fi
