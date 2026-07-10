#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-85.sh — synthetic fixture tests for
# BD-271 Check 85 (`check_narration_twin_content_parity`;
# DESIGN-BD271-check85 FINAL — the single execution authority).
#
# Check 85 enforces regex-CONTENT parity (source bytes + INTEGER-value
# flags, load-bearing) between the two session-state narration-pattern
# twins:
#   - Twin A (pack): `_SESSION_STATE_NARRATION_PATTERNS` in
#     scripts/lib/validate_checks/core.py.
#   - Twin B (client-shipped, READ-ONLY input): `_SS_NARRATION_PATTERNS`
#     inside the `python3 - <<'PYEOF'` heredoc in
#     project-template/scripts/validate-docs.sh.
#
# This test exercises the REAL check function (`check_narration_twin_
# content_parity`) in-process against synthetic `/tmp` twin fixtures that
# reproduce the REAL heredoc shape (a `python3 - <<'PYEOF'` opener + a bare
# `PYEOF` closer) so the heredoc-select/slice logic is actually exercised,
# never bypassed (R4 fixture-realism).
#
# REGISTERED: Check 85 IS in CHECK_REGISTRY (dynamic count-invariant, never
# a hardcoded literal — Group 0).
#
# Coverage:
#   Group 0: Module import + Check 85 symbols + registered + dynamic
#            count-invariant.
#   Group 1: in-process body against `/tmp` twin fixtures — one case per
#            new resolution (no asymmetric coverage):
#     - baseline-clean-aligned-and-sanctioned-bd-td-divergence (PASS —
#       also proves the real #1/#2 sanctioned bd<->td fold)
#     - flag-presence-drift-post-commit (FAIL — the just-occurred bug)
#     - flag-spelling-equivalence-I-IGNORECASE-bareint-flagskw (PASS — F1
#       integer-value canon; the case a naive name-compare would false-fail)
#     - flag-binop-order-independent (PASS — F1 BinOp canon, OR-independent)
#     - flag-binop-value-mismatch (FAIL — 2 != 10)
#     - anchor-drift-update-marker (FAIL — source-verbatim compare)
#     - charclass-drift (FAIL — source-verbatim compare)
#     - quantifier-drift (FAIL — source-verbatim compare)
#     - alternation-drift (FAIL — source-verbatim compare)
#     - absence-via-axis-swap-same-count (FAIL — bidirectional key diff,
#       count parity alone would NOT catch this)
#     - count-mismatch-extra-pattern-one-side (FAIL — F5 count parity)
#     - duplicate-folded-name-wrong-body-mask (FAIL — F5 dup-detect, the
#       last-wins mask)
#     - fold-over-reach-incident-axis-bd-td-token (FAIL — F4-b fold-reach
#       guard)
#     - directionality-violation-td-axis-ships-BD-vocab (FAIL — F5/§5.2
#       directionality guard)
#     - cosmetic-comment-whitespace-implicit-concat-tolerated (PASS — AST
#       discards comments/whitespace, folds implicit-concat literals)
#     - twin-b-unextractable-delimiter-munged (FAIL loud — F6/F7 symmetric)
#     - twin-b-unextractable-assignment-renamed (FAIL loud — F6/F7)
#     - twin-b-unextractable-parse-error (FAIL loud — F6/F7)
#     - twin-a-shape-regression-list-not-tuple (FAIL loud — F6 symmetric)
#     - twin-b-file-wholly-absent-lenient-skip (SKIP — F6 lenient-absent)
#   Group 2: captured drift-FAIL proof artifact (a real RED run captured for
#            the regression record — mirrors test-79 T2's "decisive proof").
#
# Test infra is self-provisioned: every case builds a throwaway `/tmp` tree
# and monkeypatches REPO_ROOT (the Check-80 BITE-1 idiom); no real twin file
# is ever mutated. State is restored on every path.
#
# Usage: bash scripts/tests/test-validate-pack-check-85.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"
export REPO_ROOT VALIDATE

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: Module import + symbols + dynamic count-invariant + registered
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 85 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_narration_twin_content_parity', '_check_85_canon_flags',
           '_CHECK_85_SANCTIONED_FOLDED_NAMES', '_CHECK_85_TWIN_A',
           '_CHECK_85_TWIN_B', '_CHECK_85_BD_TD_FOLD']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 85 not in nums:
    print('FAIL_85_NOT_REGISTERED'); sys.exit(1)
if sorted(mod._CHECK_85_SANCTIONED_FOLDED_NAMES) != ['XX-past-action', 'per-XX']:
    print('FAIL_SANCTIONED_SET', sorted(mod._CHECK_85_SANCTIONED_FOLDED_NAMES))
    sys.exit(1)
print('OK')
" > /tmp/vp-check85-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check85-import.out; then
    t_pass "imports + Check 85 symbols present + Check 85 REGISTERED (85 in registry) + dynamic count invariant holds + sanctioned set == {XX-past-action, per-XX}"
else
    t_fail "Check 85 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check85-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1 + Group 2: in-process body against /tmp twin fixtures
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: in-process body against /tmp twin fixtures ===\n"

python3 <<'PYEOF' > /tmp/vp-check85-driver.out 2>&1
import os
import sys
import io
import contextlib
import tempfile
import pathlib
import shutil

REPO_ROOT = os.environ["REPO_ROOT"]
VALIDATE = os.environ["VALIDATE"]
sys.path.insert(0, os.path.join(REPO_ROOT, "scripts"))

import importlib.util
spec = importlib.util.spec_from_file_location("vp", VALIDATE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W8 wave-invariant). Check 85's body resolves
    REPO_ROOT via the moved core seam (imported `from .core` into
    session_state's own namespace), so a facade-only patch would not
    reliably bite every binding."""
    mod.REPO_ROOT = root
    for name, m in list(sys.modules.items()):
        if name == "validate_checks" or name.startswith("validate_checks."):
            if hasattr(m, "REPO_ROOT"):
                m.REPO_ROOT = root


def run_body():
    saved = list(mod.failures)
    mod.failures.clear()
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        mod.check_narration_twin_content_parity()
    fails = list(mod.failures)
    mod.failures.clear()
    mod.failures.extend(saved)
    return fails, buf.getvalue()


def run_on_tree(tmpdir):
    saved_root = mod.REPO_ROOT
    _patch_root(tmpdir)
    try:
        fails, cap = run_body()
    finally:
        _patch_root(saved_root)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return fails, cap


# ── Fixture builders — reproduce the REAL shapes (bare tuple assignment in
# core.py; a `python3 - <<'PYEOF'` heredoc closing bare `PYEOF` in
# validate-docs.sh) so the heredoc select/slice logic is actually exercised.

def build_tree(a_body, b_body=None, b_present=True):
    tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check85-"))
    core_dir = tmpdir / "scripts" / "lib" / "validate_checks"
    core_dir.mkdir(parents=True)
    (core_dir / "core.py").write_text(
        "import re\n\n_SESSION_STATE_NARRATION_PATTERNS = (\n"
        + a_body + "\n)\n"
    )
    if b_present:
        vd_dir = tmpdir / "project-template" / "scripts"
        vd_dir.mkdir(parents=True)
        body_text = b_body if b_body is not None else ""
        content = (
            "#!/usr/bin/env bash\n"
            "echo before\n"
            "python3 - <<'PYEOF'\n"
            "import re\n\n"
            "_SS_NARRATION_PATTERNS = (\n" + body_text + "\n)\n"
            "PYEOF\n"
            "echo after\n"
        )
        (vd_dir / "validate-docs.sh").write_text(content)
    return tmpdir


def build_tree_raw_b(a_body, b_content):
    tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check85-"))
    core_dir = tmpdir / "scripts" / "lib" / "validate_checks"
    core_dir.mkdir(parents=True)
    (core_dir / "core.py").write_text(
        "import re\n\n_SESSION_STATE_NARRATION_PATTERNS = (\n"
        + a_body + "\n)\n"
    )
    vd_dir = tmpdir / "project-template" / "scripts"
    vd_dir.mkdir(parents=True)
    (vd_dir / "validate-docs.sh").write_text(b_content)
    return tmpdir


def build_tree_raw_a(a_content, b_body):
    tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check85-"))
    core_dir = tmpdir / "scripts" / "lib" / "validate_checks"
    core_dir.mkdir(parents=True)
    (core_dir / "core.py").write_text(a_content)
    vd_dir = tmpdir / "project-template" / "scripts"
    vd_dir.mkdir(parents=True)
    content = (
        "#!/usr/bin/env bash\n"
        "echo before\n"
        "python3 - <<'PYEOF'\n"
        "import re\n\n"
        "_SS_NARRATION_PATTERNS = (\n" + b_body + "\n)\n"
        "PYEOF\n"
        "echo after\n"
    )
    (vd_dir / "validate-docs.sh").write_text(content)
    return tmpdir


# ── Baseline aligned twins (6 axes; #1/#2 are the sanctioned bd<->td pair;
# the other 4 are shared verbatim — mirrors the live 11-pattern shape at a
# manageable fixture size).
BASE_A = r'''    ("bd-past-action", re.compile(r"BD-\d+\s+(deleted|added)")),
    ("per-bd", re.compile(r"per BD-\d+")),
    ("carry-over", re.compile(r"carried from|carry-over", re.I)),
    ("incident", re.compile(r"\bincident\b", re.I)),
    ("post-commit", re.compile(r"post-Commit")),
    ("update-marker", re.compile(r"\bUPDATE-\d")),'''

BASE_B = r'''    ("td-past-action", re.compile(r"TD-\d+\s+(deleted|added)")),
    ("per-td", re.compile(r"per TD-\d+")),
    ("carry-over", re.compile(r"carried from|carry-over", re.I)),
    ("incident", re.compile(r"\bincident\b", re.I)),
    ("post-commit", re.compile(r"post-Commit")),
    ("update-marker", re.compile(r"\bUPDATE-\d")),'''

CASES = []


def add(name, factory, expect, must_contain=None):
    CASES.append((name, factory, expect, must_contain))


# 1 — baseline: clean aligned twins; ALSO proves the real #1/#2 sanctioned
# bd<->td fold (bd-past-action/per-bd <-> td-past-action/per-td) is
# tolerated.
add(
    "baseline-clean-aligned-and-sanctioned-bd-td-divergence",
    lambda: build_tree(BASE_A, BASE_B),
    "PASS",
)

# 2 — one-side flag PRESENCE drift (the just-occurred BD-252/253 bug class).
add(
    "flag-presence-drift-post-commit",
    lambda: build_tree(
        BASE_A,
        BASE_B.replace(
            '("post-commit", re.compile(r"post-Commit")),',
            '("post-commit", re.compile(r"post-Commit", re.I)),',
        ),
    ),
    "FAIL",
    ["post-commit"],
)

# 3 — flag-SPELLING equivalence: re.I / re.IGNORECASE / bare 2 / flags=re.I
# all canonicalize to the same integer (2) regardless of which spelling is
# used on which side.
FLAGEQ_A = r'''    ("axis-i", re.compile(r"foo", re.I)),
    ("axis-ignorecase", re.compile(r"bar", re.IGNORECASE)),
    ("axis-bareint", re.compile(r"baz", 2)),
    ("axis-flagskw", re.compile(r"qux", flags=re.I)),'''
FLAGEQ_B = r'''    ("axis-i", re.compile(r"foo", re.IGNORECASE)),
    ("axis-ignorecase", re.compile(r"bar", 2)),
    ("axis-bareint", re.compile(r"baz", flags=re.I)),
    ("axis-flagskw", re.compile(r"qux", re.I)),'''
add(
    "flag-spelling-equivalence-I-IGNORECASE-bareint-flagskw",
    lambda: build_tree(FLAGEQ_A, FLAGEQ_B),
    "PASS",
)

# 4 — re.I|re.M vs re.M|re.I: BinOp OR is order-independent.
BINOP_ORDER_A = r'''    ("axis-order", re.compile(r"foo", re.I|re.M)),'''
BINOP_ORDER_B = r'''    ("axis-order", re.compile(r"foo", re.M|re.I)),'''
add(
    "flag-binop-order-independent",
    lambda: build_tree(BINOP_ORDER_A, BINOP_ORDER_B),
    "PASS",
)

# 5 — re.I vs re.I|re.M: 2 != 10, a genuine flag-value mismatch.
BINOP_MISMATCH_A = r'''    ("axis-order", re.compile(r"foo", re.I)),'''
BINOP_MISMATCH_B = r'''    ("axis-order", re.compile(r"foo", re.I|re.M)),'''
add(
    "flag-binop-value-mismatch",
    lambda: build_tree(BINOP_MISMATCH_A, BINOP_MISMATCH_B),
    "FAIL",
    ["axis-order"],
)

# 6 — anchor drift (\b dropped on one side) — source-verbatim compare.
add(
    "anchor-drift-update-marker",
    lambda: build_tree(
        BASE_A,
        BASE_B.replace(
            r'("update-marker", re.compile(r"\bUPDATE-\d")),',
            r'("update-marker", re.compile(r"UPDATE-\d")),',
        ),
    ),
    "FAIL",
    ["update-marker"],
)

# 7 — char-class drift ([0-9] vs [0-8]).
CHARCLASS_A = r'''    ("digit-axis", re.compile(r"[0-9]+")),'''
CHARCLASS_B = r'''    ("digit-axis", re.compile(r"[0-8]+")),'''
add(
    "charclass-drift",
    lambda: build_tree(CHARCLASS_A, CHARCLASS_B),
    "FAIL",
    ["digit-axis"],
)

# 8 — quantifier drift (\d+ vs \d*).
QTY_A = r'''    ("qty-axis", re.compile(r"\d+")),'''
QTY_B = r'''    ("qty-axis", re.compile(r"\d*")),'''
add(
    "quantifier-drift",
    lambda: build_tree(QTY_A, QTY_B),
    "FAIL",
    ["qty-axis"],
)

# 9 — alternation drift (a branch added).
ALT_A = r'''    ("alt-axis", re.compile(r"(a|b)")),'''
ALT_B = r'''    ("alt-axis", re.compile(r"(a|b|c)")),'''
add(
    "alternation-drift",
    lambda: build_tree(ALT_A, ALT_B),
    "FAIL",
    ["alt-axis"],
)

# 10 — absence via a same-count axis swap (count parity alone would NOT
# catch this; the bidirectional key diff must).
SWAP_A = r'''    ("axis-x", re.compile(r"foo")),
    ("axis-y", re.compile(r"bar")),'''
SWAP_B = r'''    ("axis-x", re.compile(r"foo")),
    ("axis-z", re.compile(r"bar")),'''
add(
    "absence-via-axis-swap-same-count",
    lambda: build_tree(SWAP_A, SWAP_B),
    "FAIL",
    ["MISSING"],
)

# 11 — count mismatch (an extra pattern on one side).
COUNTMIS_A = r'''    ("axis-x", re.compile(r"foo")),
    ("axis-y", re.compile(r"bar")),'''
COUNTMIS_B = r'''    ("axis-x", re.compile(r"foo")),
    ("axis-y", re.compile(r"bar")),
    ("axis-extra", re.compile(r"baz")),'''
add(
    "count-mismatch-extra-pattern-one-side",
    lambda: build_tree(COUNTMIS_A, COUNTMIS_B),
    "FAIL",
    ["COUNT"],
)

# 12 — duplicate folded-name (the demonstrated last-wins wrong-body mask).
DUP_A = r'''    ("dup-axis", re.compile(r"foo")),
    ("dup-axis", re.compile(r"bar")),'''
DUP_B = r'''    ("dup-axis", re.compile(r"foo")),
    ("other-axis", re.compile(r"baz")),'''
add(
    "duplicate-folded-name-wrong-body-mask",
    lambda: build_tree(DUP_A, DUP_B),
    "FAIL",
    ["DUPLICATE"],
)

# 13 — fold-over-reach: a bd/td token appears on the NON-sanctioned
# "incident" axis on both sides.
add(
    "fold-over-reach-incident-axis-bd-td-token",
    lambda: build_tree(
        BASE_A.replace(
            r'("incident", re.compile(r"\bincident\b", re.I)),',
            r'("incident", re.compile(r"\bincident\b|BD-\d+", re.I)),',
        ),
        BASE_B.replace(
            r'("incident", re.compile(r"\bincident\b", re.I)),',
            r'("incident", re.compile(r"\bincident\b|TD-\d+", re.I)),',
        ),
    ),
    "FAIL",
    ["incident", "sanctioned"],
)

# 14 — directionality violation: the client twin's sanctioned
# "td-past-action" axis ships pack (BD-) vocabulary instead of TD-.
add(
    "directionality-violation-td-axis-ships-BD-vocab",
    lambda: build_tree(
        BASE_A,
        BASE_B.replace(
            r'("td-past-action", re.compile(r"TD-\d+\s+(deleted|added)")),',
            r'("td-past-action", re.compile(r"BD-\d+\s+(deleted|added)")),',
        ),
    ),
    "FAIL",
    ["directionality"],
)

# 15 — cosmetic divergence (comment wording + whitespace + an
# implicit-string-concat split) — AST discards comments/whitespace and
# folds implicit-concat literals, so this must PASS.
COSMETIC_B = BASE_B.replace(
    '("post-commit", re.compile(r"post-Commit")),',
    '("post-commit", re.compile(\n'
    '        r"post-"\n'
    '        r"Commit"\n'
    "    )),  # legitimate per-twin comment differs from pack's wording",
)
add(
    "cosmetic-comment-whitespace-implicit-concat-tolerated",
    lambda: build_tree(BASE_A, COSMETIC_B),
    "PASS",
)

# 16 — Twin-B present-but-unextractable: the heredoc delimiter is munged
# (closer never matches the bare opener delimiter) — FAIL loud, never a
# silent slice-to-EOF.
add(
    "twin-b-unextractable-delimiter-munged",
    lambda: build_tree_raw_b(
        BASE_A,
        "#!/usr/bin/env bash\necho before\n"
        "python3 - <<'PYEOF'\nimport re\n\n"
        "_SS_NARRATION_PATTERNS = (\n" + BASE_B + "\n)\n"
        "ENDPY\necho after\n",
    ),
    "FAIL",
    ["validate-docs.sh", "extraction failed"],
)

# 17 — Twin-B present-but-unextractable: the assignment symbol is renamed.
add(
    "twin-b-unextractable-assignment-renamed",
    lambda: build_tree_raw_b(
        BASE_A,
        "#!/usr/bin/env bash\necho before\n"
        "python3 - <<'PYEOF'\nimport re\n\n"
        "_SS_NARRATION_PATTERNS_RENAMED = (\n" + BASE_B + "\n)\n"
        "PYEOF\necho after\n",
    ),
    "FAIL",
    ["validate-docs.sh", "extraction failed"],
)

# 18 — Twin-B present-but-unextractable: a syntax error inside the sliced
# heredoc body.
add(
    "twin-b-unextractable-parse-error",
    lambda: build_tree_raw_b(
        BASE_A,
        "#!/usr/bin/env bash\necho before\n"
        "python3 - <<'PYEOF'\nimport re\n\n"
        "_SS_NARRATION_PATTERNS = (\n"
        '    ("broken" re.compile(r"x")),\n'
        ")\nPYEOF\necho after\n",
    ),
    "FAIL",
    ["validate-docs.sh", "extraction failed"],
)

# 19 — Twin-A shape regression: the tuple literal is munged into a list —
# FAIL loud, symmetric with the Twin-B legs above (F6).
add(
    "twin-a-shape-regression-list-not-tuple",
    lambda: build_tree_raw_a(
        "import re\n\n_SESSION_STATE_NARRATION_PATTERNS = [\n"
        + BASE_A + "\n]\n",
        BASE_B,
    ),
    "FAIL",
    ["core.py", "extraction failed"],
)

# 20 — Twin-B FILE wholly absent — the ONLY lenient case (F6).
add(
    "twin-b-file-wholly-absent-lenient-skip",
    lambda: build_tree(BASE_A, None, b_present=False),
    "SKIP",
)


def _eval_case(name, factory, expect, must_contain):
    try:
        tmpdir = factory()
    except Exception as exc:  # fixture construction itself must not crash
        return False, f"fixture construction raised {type(exc).__name__}: {exc}"
    try:
        fails, cap = run_on_tree(tmpdir)
    except Exception as exc:  # the check body itself must never crash
        return False, f"check body raised {type(exc).__name__}: {exc}"

    joined = " | ".join(fails)
    if expect == "PASS":
        if fails:
            return False, "expected PASS, got FAIL(s): " + joined[:300]
        if "folded-parity holds" not in cap:
            return False, "expected the clean OK message, got: " + cap[:300]
    elif expect == "FAIL":
        if not fails:
            return False, "expected a FAIL, got none. cap=" + cap[:300]
    elif expect == "SKIP":
        if fails:
            return False, "expected lenient SKIP, got FAIL(s): " + joined[:300]
        if "skipping" not in cap:
            return False, "expected the skip message, got: " + cap[:300]
    else:
        return False, f"unknown expect={expect!r}"

    if must_contain:
        hay = joined + " " + cap
        for s in must_contain:
            if s not in hay:
                return False, f"expected substring {s!r} not found in: " + hay[:300]
    return True, ""


def _sanitize(s):
    return s.replace("\n", " / ").replace("::", " : ")


for case_name, case_factory, case_expect, case_must in CASES:
    ok, detail = _eval_case(case_name, case_factory, case_expect, case_must)
    if ok:
        print(f"RESULT_OK::{case_name}")
    else:
        print(f"RESULT_BAD::{case_name}::{_sanitize(detail)}")

# ── Group 2 — captured drift-FAIL proof artifact (regression record). ──
print("\n=== Group 2: captured drift-FAIL proof artifact ===")
tmpdir = build_tree(
    BASE_A,
    BASE_B.replace(
        '("post-commit", re.compile(r"post-Commit")),',
        '("post-commit", re.compile(r"post-Commit", re.I)),',
    ),
)
fails, cap = run_on_tree(tmpdir)
print(cap)
if fails:
    print("CAPTURED_FAIL_COUNT:", len(fails))
    for f in fails:
        print("CAPTURED_FAIL:", f)
    print("RESULT_OK::group2-captured-drift-artifact")
else:
    print("RESULT_BAD::group2-captured-drift-artifact::expected a captured FAIL, got none")

print("DRIVER_DONE")
PYEOF

cat /tmp/vp-check85-driver.out

while IFS= read -r line; do
    case "$line" in
        RESULT_OK::*)
            name="${line#RESULT_OK::}"
            t_pass "$name"
            ;;
        RESULT_BAD::*)
            rest="${line#RESULT_BAD::}"
            name="${rest%%::*}"
            detail="${rest#*::}"
            t_fail "$name" "$detail"
            ;;
    esac
done < /tmp/vp-check85-driver.out

if ! grep -q "^DRIVER_DONE$" /tmp/vp-check85-driver.out; then
    t_fail "Check 85 Group 1/2 driver did not complete (crash or exception before DRIVER_DONE)" \
        "$(tail -40 /tmp/vp-check85-driver.out)"
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
