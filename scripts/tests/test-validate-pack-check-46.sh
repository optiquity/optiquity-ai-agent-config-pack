#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-46.sh — synthetic fixture
# tests for BD-196 (C6) Check 46 (boundary + spawn-rule pointer
# manifests; ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §4.3 + §9.6).
#
# Check 46 has two halves over two manifest files:
#   (a) reference-resolution — every surface named in
#       pack-ops/.boundary-pointer-manifest.txt + pack-ops/.spawn-rule-
#       manifest.txt exists AND carries its expected resolving pointer.
#   (b) anti-restate (SC7-bounded) — no `## Pack memory` imperative BODY
#       (>= 60 chars, whitespace-normalized) reappears verbatim in a
#       spawn-rule reference surface or spawn-relevant skill.
#
# These tests stage synthetic trees inside a tmp REPO_ROOT, invoke
# Check 46 against the tmp tree, and assert PASS / FAIL as expected
# without mutating any real pack-ops file. Cleanup runs on every exit
# path.
#
# Coverage:
#   Group 0: Module import + Check 46 symbol registration
#   Group 1: Synthetic-tree end-to-end:
#            T1 PASS — both manifests resolve, no restatement
#            T2 FAIL — boundary surface missing its pointer
#            T3 FAIL — boundary surface does not exist on disk
#            T4 FAIL — verbatim imperative-body restatement reintroduced
#            T5 PASS — a one-line NAME-bearing reference does NOT storm
#                      (the SC7 / §4.2 12/12 false-positive shape)
#            T6 FAIL — spawn reference surface lost its `## Pack memory`
#                      canonical pointer
#   Group 2: End-to-end validate-pack.py exit-status on HEAD (Check 46 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-46.sh

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
# Group 0: Module import + new symbol reachable
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 46 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_boundary_and_spawn_pointer_manifests',
    '_parse_manifest_records',
    '_check_46_extract_pack_memory_imperative_bodies',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check46-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check46-import.out; then
    t_pass "validate-pack.py imports + Check 46 symbols registered"
else
    t_fail "validate-pack.py import or Check 46 symbol registration failed" \
        "$(cat /tmp/vp-check46-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Synthetic-tree end-to-end (PASS + injected-FAIL cases)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# A synthetic `## Pack memory` corpus with ONE rule whose imperative BODY
# is long enough (>= 60 chars) to be an anti-restate candidate.
LONG_BODY = (
    "Every spawn-relevant imperative is authored exactly once in the "
    "canonical home and never restated verbatim anywhere downstream."
)
RULE_NAME = "Single authored imperative"
CLAUDE_MD = (
    "# CLAUDE.md — synthetic\n"
    "\n"
    "## Pack memory (project-local learnings)\n"
    "\n"
    f"- **{RULE_NAME}.** {LONG_BODY}\n"
    "\n"
    "## Project goals (synthetic)\n"
)

def build_tree(root, *, boundary_records, spawn_records, surfaces,
               restate_into=None, ref_files=None):
    """Materialize a synthetic REPO_ROOT.

    boundary_records: list of (surface_relpath, pointer) for the boundary
                      manifest.
    spawn_records:    list of (slug, references_text) for the spawn manifest.
    surfaces:         dict relpath -> file text to create.
    restate_into:     relpath of a spawn-relevant surface to inject the
                      verbatim LONG_BODY into (anti-restate FAIL trigger).
    ref_files:        dict basename -> text for the spawn reference surfaces.
    """
    root = pathlib.Path(root)
    (root / "CLAUDE.md").write_text(CLAUDE_MD)
    (root / "pack-ops").mkdir(exist_ok=True)

    # Boundary manifest.
    bm = ["# boundary manifest (synthetic)\n"]
    for surface, pointer in boundary_records:
        bm.append(f"surface:   {surface}\n")
        bm.append(f"pointer:   {pointer}\n")
        bm.append(f"role:      synthetic\n\n")
    (root / "pack-ops" / ".boundary-pointer-manifest.txt").write_text("".join(bm))

    # Spawn manifest.
    sm = ["# spawn manifest (synthetic)\n"]
    for slug, refs in spawn_records:
        sm.append(f"slug:       {slug}\n")
        sm.append("canonical:  ## Pack memory\n")
        sm.append(f"references: {refs}\n\n")
    (root / "pack-ops" / ".spawn-rule-manifest.txt").write_text("".join(sm))

    # Surfaces (boundary-pointer-carrying files).
    for rel, text in (surfaces or {}).items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    # Spawn reference surfaces (the check looks for PACK-AGENTS.md /
    # PACK-CHAT.md under pack-ops/).
    default_refs = {
        "PACK-AGENTS.md": "Agent permission rules. See trinity ## Pack memory.\n",
        "PACK-CHAT.md": "Behavioral rules. See trinity ## Pack memory.\n",
    }
    rf = dict(default_refs)
    rf.update(ref_files or {})
    for basename, text in rf.items():
        (root / "pack-ops" / basename).write_text(text)

    # Anti-restate scan surfaces the check reads from .claude/skills/*.
    skills = [
        "commit-discipline", "review", "planning", "implementation-report",
    ]
    for s in skills:
        d = root / ".claude" / "skills" / s
        d.mkdir(parents=True, exist_ok=True)
        body = "# skill (synthetic)\nOperationalizes rules; no imperative restate.\n"
        if restate_into == f".claude/skills/{s}/SKILL.md":
            body += "\nRestated: " + LONG_BODY + "\n"
        (d / "SKILL.md").write_text(body)

def run(build_kwargs):
    tmpdir = tempfile.mkdtemp(prefix="vp-check46-")
    root = pathlib.Path(tmpdir)
    build_tree(root, **build_kwargs)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_boundary_and_spawn_pointer_manifests()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return len(new_failures), captured

GOOD_SURFACES = {
    "README.md": "Layout: BOUNDARY-DEFINITION.md is the boundary SSOT.\n",
    "docs/x.md": "see BOUNDARY-DEFINITION.md for placement.\n",
}
GOOD_BOUNDARY = [("README.md", "BOUNDARY-DEFINITION.md"),
                 ("docs/x.md", "BOUNDARY-DEFINITION.md")]
GOOD_SPAWN = [("agents-never-commit", 'PACK-AGENTS.md § "Agent permission rules"'),
              ("triage-all-fix-all", 'PACK-CHAT.md § "Behavioral rules"')]

# T1: PASS — both manifests resolve; no restatement.
fc, cap = run(dict(boundary_records=GOOD_BOUNDARY, spawn_records=GOOD_SPAWN,
                   surfaces=GOOD_SURFACES))
if fc != 0:
    failures.append(f"T1 (all resolve PASS) expected 0 failures, got {fc}: {cap}")

# T2: FAIL — boundary surface present but MISSING its pointer.
bad_surfaces = dict(GOOD_SURFACES)
bad_surfaces["docs/x.md"] = "this file no longer mentions the boundary doc.\n"
fc, cap = run(dict(boundary_records=GOOD_BOUNDARY, spawn_records=GOOD_SPAWN,
                   surfaces=bad_surfaces))
if fc < 1:
    failures.append(f"T2 (missing pointer FAIL) expected >=1 failure, got {fc}: {cap}")
if "no longer carries its expected" not in cap:
    failures.append(f"T2 expected missing-pointer diagnostic: {cap}")

# T3: FAIL — boundary surface does not exist on disk.
fc, cap = run(dict(
    boundary_records=GOOD_BOUNDARY + [("docs/missing.md", "BOUNDARY-DEFINITION.md")],
    spawn_records=GOOD_SPAWN, surfaces=GOOD_SURFACES))
if fc < 1:
    failures.append(f"T3 (missing surface FAIL) expected >=1 failure, got {fc}: {cap}")
if "does NOT exist on disk" not in cap:
    failures.append(f"T3 expected missing-surface diagnostic: {cap}")

# T4: FAIL — verbatim imperative BODY reintroduced into a spawn-relevant skill.
fc, cap = run(dict(boundary_records=GOOD_BOUNDARY, spawn_records=GOOD_SPAWN,
                   surfaces=GOOD_SURFACES,
                   restate_into=".claude/skills/review/SKILL.md"))
if fc < 1:
    failures.append(f"T4 (anti-restate FAIL) expected >=1 failure, got {fc}: {cap}")
if "anti-restate violation" not in cap:
    failures.append(f"T4 expected anti-restate diagnostic: {cap}")

# T5: PASS — a one-line NAME-bearing reference must NOT storm (SC7 bound).
#     Inject the rule NAME (not the BODY) into a spawn reference surface.
ref_with_name = {
    "PACK-AGENTS.md": (
        f'Agent permission rules. "{RULE_NAME}" — see trinity ## Pack memory '
        "\`[rationale: single-authored-imperative]\`.\n"
    ),
}
fc, cap = run(dict(boundary_records=GOOD_BOUNDARY, spawn_records=GOOD_SPAWN,
                   surfaces=GOOD_SURFACES, ref_files=ref_with_name))
if fc != 0:
    failures.append(
        f"T5 (name-bearing reference must NOT storm) expected 0 failures, "
        f"got {fc}: {cap}"
    )

# T6: FAIL — spawn reference surface lost its `## Pack memory` canonical pointer.
ref_no_canonical = {
    "PACK-AGENTS.md": "Agent permission rules. (canonical pointer removed.)\n",
}
fc, cap = run(dict(boundary_records=GOOD_BOUNDARY,
                   spawn_records=[("agents-never-commit",
                                   'PACK-AGENTS.md § "Agent permission rules"')],
                   surfaces=GOOD_SURFACES, ref_files=ref_no_canonical))
if fc < 1:
    failures.append(f"T6 (lost canonical pointer FAIL) expected >=1 failure, got {fc}: {cap}")
if "no longer points at the canonical home" not in cap:
    failures.append(f"T6 expected lost-canonical diagnostic: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T6 (resolve / missing-pointer / missing-surface / anti-restate / SC7-no-storm / lost-canonical)" ;;
    *) t_fail "End-to-end check_boundary_and_spawn_pointer_manifests tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check46-e2e.out 2>&1; then
    if grep -q "Check 46: boundary + spawn-rule pointer manifests" /tmp/vp-check46-e2e.out \
       && grep -q "Check 46 — boundary manifest:" /tmp/vp-check46-e2e.out \
       && grep -q "anti-restate: 0 verbatim imperative-body restatements" /tmp/vp-check46-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 46 runs and reports both manifests resolve + 0 restatements at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 46 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check46-e2e.out)"
    fi
else
    if grep -q "Check 46: boundary + spawn-rule pointer manifests" /tmp/vp-check46-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 46 ran but found a resolution/restate violation)" \
            "Tail: $(tail -40 /tmp/vp-check46-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 46 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check46-e2e.out)"
    fi
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
