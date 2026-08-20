#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-94.sh — synthetic tests for Check 94
# (install-merge token-wire guard + Case-3 KEEP-on-success backstop — BD-285 F9).
#
# Check 94 is the BD-285 static wire guard over the install-time 2-way trinity fold.
# ONE registry entry, TWO assertions (ROI-2):
#   LEG 1 (declare-verify-backing): the column-4 action token scripts/init-project.sh
#          WRITES into a class=="trinity" `_cp_record` row MUST equal the token the
#          client resolve-merge-conflicts SKILL.md Case-3 Locate selector READS
#          (`$2=="trinity" && $4=="<token>"`). Verified BOTH directions (writer
#          present + reader present + equal), so a declared selector with NO matching
#          writer (absence-of-backing) FAILs, not only a both-exist mismatch. The
#          literals are read from both sources (never hardcoded).
#   LEG 2 (SHOULD-3 / Δ2 / P3): the SKILL.md Case-3 `### On success` block MUST NOT
#          carry an AFFIRMATIVE `.user-orig` removal verb (rm/remove/delete/unlink).
#          The LEGITIMATE negated KEEP sentence ("does NOT remove `<file>.user-orig`")
#          is SPARED; a Case-2-style affirmative "remove the `.user-orig` sidecar"
#          BITEs. The scan is scoped to the Case-3 On-success region only.
#
# invocation-vs-mention (declare-verify-backing): the guard BITES a broken wire, an
# absence-of-backing selector, AND an affirmative on-success removal, and SPARES the
# real intact tree + the negated KEEP sentence.
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it `git init`s throwaway repos in /tmp REPO_ROOTs). It lives under
# scripts/tests/ and auto-wires into CI via the disk glob (Check 42 / BD-219). Per
# "Test infra is self-provisioned": every case is built in a /tmp scratch git repo;
# the REAL tree is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 94 symbol registration + DYNAMIC count invariant
#   Group 1: Real-state-at-HEAD PASS (the real tree's install-merge wire is intact)
#   Group 2: Synthetic PASS/BITE/SPARE against /tmp git repos (monkeypatch REPO_ROOT):
#            - T1 PASS  : matched wire (init writes + skill selects same token) + a
#                         KEEP on-success block → 0 failures + clean message
#            - T2 BITE  : wire mismatch (init writes merge-3way, skill selects
#                         merge-2way) → >=1 failure naming WIRE BROKEN
#            - T3 BITE  : absence-of-backing (skill selects merge-2way, init has NO
#                         trinity `_cp_record` writer) → >=1 failure
#            - T4 BITE  : affirmative on-success `.user-orig` removal → >=1 failure
#            - T5 SPARE : the negated KEEP sentence ("does NOT remove `.user-orig`")
#                         is NOT flagged (the current-tree shape) → 0 failures
#            - T6 SKIP  : REPO_ROOT at a NON-git dir → git-unavailable → SKIP-lenient
#            - T7 SKIP  : a wire surface untracked (only SKILL.md tracked) → SKIP
#   Group 3: End-to-end validate-pack.py --only-check 94 on HEAD.
#
# Usage: bash scripts/tests/test-validate-pack-check-94.sh
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

# ─────────────────────────────────────────────────────────────────
# Group 0: Module import + Check 94 symbol registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 94 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not hasattr(mod, 'check_install_merge_wire'):
    print('FAIL_MISSING check_install_merge_wire'); sys.exit(1)
# Check 94 must be registered EXACTLY ONCE AND the expected-count constant must
# equal the computed registry length (Check 59's DYNAMIC invariant — proves the
# Check-94 add + the 90->91 count bump landed together). NO hardcoded count literal
# here: the endorsed per-check-test pattern (see test-validate-pack-check-92.sh),
# because a hardcoded literal re-breaks on the NEXT check add.
nums = [t[0] for t in mod._build_check_registry()]
if 94 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if nums.count(94) != 1:
    print('FAIL_DUP_REGISTERED', nums.count(94)); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
print('OK')
" > /tmp/vp-check94-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check94-import.out; then
    t_pass "validate-pack.py imports + Check 94 registered EXACTLY ONCE + DYNAMIC count invariant holds"
else
    t_fail "validate-pack.py import / Check 94 registration / count invariant failed" \
        "$(cat /tmp/vp-check94-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS (real tree's install-merge wire is intact)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD PASS ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []
saved = list(mod.failures); mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_install_merge_wire()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 94 expected 0 failures, got {len(new)}: {cap}")
if "wire intact" not in cap:
    failures.append(f"real-state PASS message missing clean marker: {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 94 PASSes (the real install-merge wire is intact + Case-3 KEEPs .user-orig)" ;;
    *) t_fail "real-state Check 94 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic /tmp git-repo PASS/BITE/SPARE tests (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic /tmp git-repo PASS/BITE/SPARE tests ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, subprocess, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule. Check 94's body lives in validate_checks.install_merge_wire and
    resolves its git root via install_merge_wire.REPO_ROOT (through _git_ls_files)
    plus its file reads; a facade-only patch would NOT bite."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root

INIT = "scripts/init-project.sh"
SKILL = "project-template/skills/resolve-merge-conflicts/SKILL.md"

def init_sh(token):
    """A minimal init-project.sh with ONE class=="trinity" _cp_record writing
    `token` in column 4 (the action/wire token)."""
    return ("#!/usr/bin/env bash\nset -euo pipefail\n"
            "s7_reconcile_append_row() {\n"
            "    local rel=\"$1\"\n"
            "    _cp_record \"merged-with-customization\" \"trinity\" \"$rel\" \""
            + token + "\" \\\n"
            "        \"${rel}.user-orig\" \"-\" \"install 2-way trinity fold\"\n"
            "}\n")

def init_sh_no_trinity():
    """An init-project.sh with NO class=="trinity" _cp_record (a generic row only)
    — the absence-of-backing writer case."""
    return ("#!/usr/bin/env bash\nset -euo pipefail\n"
            "foo() { _cp_record \"x\" \"generic\" \"$rel\" \"merged\" \"-\" \"-\" \"n\"; }\n")

def skill_md(sel_token, onsucc_body):
    """A minimal SKILL.md with a Case-3 Locate selector reading `sel_token` and a
    Case-3 `### On success` block carrying `onsucc_body`. A Case-2 `### On success`
    with an affirmative `.v10-*` removal is included ABOVE Case 3 to prove the LEG-2
    scan is scoped to the Case-3 region only (a Case-2 removal must NOT trip it)."""
    return (
        "---\nname: resolve-merge-conflicts\n---\n\n"
        "## Case 2 — trinity fold\n\n### On success\n\n"
        "write the fold; remove the `.v10-customized` sidecar and the `.v10-base` stash.\n\n"
        "## Locate the install fold rows (Case 3)\n\n"
        "```bash\n"
        "awk -F'\\t' '\n  $2==\"trinity\" && $4==\"" + sel_token + "\" { print }\n' \"$F\"\n"
        "```\n\n"
        "## Case 3 — install 2-way trinity fold\n\n"
        "Body.\n\n### Gate\n\nStuff.\n\n### On success\n\n"
        + onsucc_body + "\n\n"
        "## Report\n\nDone.\n"
    )

# The current-tree KEEP shape: a NEGATED "does NOT remove `<file>.user-orig`" plus a
# "Leave the `.user-orig` sidecar in place" — both KEEP statements (must be SPARED).
KEEP_BODY = ("Only when every gate leg passes: write the fold to the live file. "
             "**Case 3 does NOT remove `<file>.user-orig` on success (UNLIKE Case 2 "
             "— there is no pre-install backup; `.user-orig` is the sole recovery "
             "copy).** Leave the `.user-orig` sidecar in place.")
# A Case-2-style AFFIRMATIVE removal accidentally copied into Case 3 (must BITE).
REMOVE_BODY = ("Only when every gate leg passes: write the fold to the live file; "
               "remove the `.user-orig` sidecar and the stash (both recoverable).")

SKILL_UNTRACKED_ONLY = "SKILL_ONLY"

failures = []

def run_check(files, track_all=True):
    """git init a /tmp repo, write `files` (relpath -> content), optionally track
    them, run Check 94 against it via monkeypatched REPO_ROOT. Returns
    (failures_count, captured)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check94-")
    root = pathlib.Path(tmpdir)
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=root, check=True)
    (root / "README.md").write_text("scratch\n")
    for rel, content in files.items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
    if track_all:
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    else:
        # track ONLY the SKILL.md (leave init-project.sh untracked) — the
        # untracked-surface SKIP case.
        subprocess.run(["git", "add", "README.md", SKILL], cwd=root, check=True)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_install_merge_wire()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

def run_check_nongit():
    tmpdir = tempfile.mkdtemp(prefix="vp-check94-nongit-")
    root = pathlib.Path(tmpdir)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_install_merge_wire()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — matched wire (same token both ends) + KEEP on-success → 0 failures.
fc, cap = run_check({INIT: init_sh("merge-2way"), SKILL: skill_md("merge-2way", KEEP_BODY)})
if fc != 0:
    failures.append(f"T1 (PASS — matched wire + KEEP) expected 0 failures, got {fc}: {cap}")
if "wire intact" not in cap:
    failures.append(f"T1 PASS message missing clean marker: {cap}")

# T2: BITE — wire mismatch (init writes merge-3way, skill selects merge-2way) → the
# selector has no matching writer.
fc, cap = run_check({INIT: init_sh("merge-3way"), SKILL: skill_md("merge-2way", KEEP_BODY)})
if fc < 1:
    failures.append(f"T2 (BITE — wire mismatch) expected >=1 failure, got {fc}: {cap}")
if "WIRE BROKEN" not in cap:
    failures.append(f"T2 BITE must name the WIRE BROKEN mismatch: {cap}")

# T3: BITE — absence-of-backing (skill selects merge-2way, init has NO trinity
# _cp_record writer). A declared selector with no matching writer must FAIL.
fc, cap = run_check({INIT: init_sh_no_trinity(), SKILL: skill_md("merge-2way", KEEP_BODY)})
if fc < 1:
    failures.append(f"T3 (BITE — absence-of-backing) expected >=1 failure, got {fc}: {cap}")
if "writer is absent" not in cap and "no matching writer" not in cap:
    failures.append(f"T3 BITE must report the missing/absent writer: {cap}")

# T4: BITE — an affirmative Case-2-style `.user-orig` removal in the Case-3
# On-success block. The Case-2 `.v10-*` removal ABOVE Case 3 must NOT trip it
# (scope proof) — only the Case-3 affirmative removal.
fc, cap = run_check({INIT: init_sh("merge-2way"), SKILL: skill_md("merge-2way", REMOVE_BODY)})
if fc < 1:
    failures.append(f"T4 (BITE — affirmative on-success removal) expected >=1 failure, got {fc}: {cap}")
if "AFFIRMATIVE" not in cap:
    failures.append(f"T4 BITE must name the AFFIRMATIVE .user-orig removal: {cap}")

# T5: SPARE — the negated KEEP sentence (current-tree shape) must NOT be flagged,
# AND the Case-2 `.v10-*` affirmative removal ABOVE Case 3 must NOT bite (LEG-2 scope
# is the Case-3 region only). Same inputs as T1 — an explicit no-false-positive pin.
fc, cap = run_check({INIT: init_sh("merge-2way"), SKILL: skill_md("merge-2way", KEEP_BODY)})
if fc != 0:
    failures.append(f"T5 (SPARE — negated KEEP + Case-2-scope) expected 0 failures, got {fc}: {cap}")

# T6: SKIP — REPO_ROOT at a NON-git directory → git ls-files unavailable → SKIP.
fc, cap = run_check_nongit()
if fc != 0:
    failures.append(f"T6 (SKIP — non-git dir) expected 0 failures, got {fc}: {cap}")
if "skipping (lenient)" not in cap:
    failures.append(f"T6 SKIP message missing 'skipping (lenient)': {cap}")
if "git ls-files unavailable" not in cap:
    failures.append(f"T6 SKIP must report git-unavailable: {cap}")

# T7: SKIP — a wire surface untracked (only SKILL.md tracked, init-project.sh not) →
# not both tracked → SKIP-lenient (a pre-BD-285 HEAD is never a violation).
fc, cap = run_check({INIT: init_sh("merge-2way"), SKILL: skill_md("merge-2way", KEEP_BODY)},
                    track_all=False)
if fc != 0:
    failures.append(f"T7 (SKIP — untracked surface) expected 0 failures, got {fc}: {cap}")
if "not both git-tracked" not in cap:
    failures.append(f"T7 SKIP must report the untracked wire surface: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic tests (T1 matched-wire PASS; T2 wire-mismatch BITE names WIRE BROKEN; T3 absence-of-backing BITE; T4 affirmative on-success removal BITE + Case-2-scope proof; T5 negated-KEEP SPARE; T6 non-git SKIP; T7 untracked-surface SKIP)" ;;
    *) t_fail "Synthetic Check 94 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 94 > /tmp/vp-check94-e2e.out 2>&1; then
    if grep -q "Check 94: install-merge token-wire guard" /tmp/vp-check94-e2e.out \
       && grep -q "wire intact" /tmp/vp-check94-e2e.out; then
        t_pass "validate-pack.py --only-check 94 exits 0; Check 94 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 94 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check94-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check94-e2e.out)"
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
