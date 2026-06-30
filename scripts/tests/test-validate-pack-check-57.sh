#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-57.sh — dedicated test for
# BD-197 Check 57 (PROJECT destructive-git-verb enumeration parity,
# Guard-C project).
#
# Check 57 is the PROJECT analog of Check 56 (Guard-C pack). It asserts the
# project-consistent canonical verb set — the measured 8-verb intersection
# checkout/clean/merge/rebase/reset/restore/stash/worktree — appears in every
# project surface that enumerates the No-destructive / agents-never-commit ban
# (project trinity ×3 + the 48 per-agent Hard rules [16 agents × 3 CLIs] +
# agent-run.sh --disallowedTools = 52 surfaces), and that the catch-all
# principle phrase (`including but not limited to`) appears on each of the 3
# trinity surfaces (the open needs-approval rule; the agent files + launcher
# carry a closed enumeration with no catch-all — measure-then-bound,
# surface-scoped). Standalone Check 57 per decision 8 (folding into Check 56
# over-complicates: different canonical verb set + a trinity-only catch-all).
# Format-agnostic matcher: `git <verb>` prose (trinity + agent Hard rules) /
# `Bash(git <verb>:*)` launcher / Codex slash-list `Forbidden: a/b/c/d`.
#
# This test proves the guard PASSes when all 52 surfaces carry the full set
# and FAILs when a verb is dropped from one surface OR the trinity catch-all
# phrase is missing OR a surface is absent — all in a synthetic /tmp tree (it
# NEVER mutates the real tree).
#
# Coverage:
#   Group 0: module import + Check 57 symbol registration
#   Group 1: synthetic-tree end-to-end (mod.REPO_ROOT pointed at /tmp):
#            T1 PASS — all 52 surfaces carry every verb (+ trinity phrase)
#            T2 FAIL — one surface drops a verb (e.g. `worktree` in trinity)
#            T3 FAIL — a trinity surface drops the catch-all principle phrase
#            T4 FAIL — one surface absent
#            T5 PASS — an agent file (NOT trinity) lacks the catch-all phrase
#                      (the phrase is asserted ONLY on the trinity → no FAIL)
#            T6 PASS — word-boundary + slash-run safety: `cleanup` ≠ `clean`,
#                      and a 3-member `(add/remove/prune)` parenthetical does
#                      NOT false-match `add` (which is not an asserted verb
#                      anyway) — a well-formed Codex slash-list surface PASSes
#            T7 FAIL — the launcher form `Bash(git <verb>:*)` is honored:
#                      dropping a verb from the launcher flag block FAILs
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 57 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-57.sh

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
# Group 0: module import + symbol registration
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: Module import + Check 57 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_project_destructive_git_verb_parity',
    '_check_57_verb_present',
    '_CHECK_57_TRINITY_SURFACES',
    '_CHECK_57_PROJECT_AGENTS',
    '_CHECK_57_AGENT_DIRS',
    '_CHECK_57_LAUNCHER_SURFACE',
    '_CHECK_57_CANONICAL_VERBS',
    '_CHECK_57_PRINCIPLE_PHRASE',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check57-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check57-import.out; then
    t_pass "validate-pack.py imports + Check 57 symbols registered"
else
    t_fail "validate-pack.py import or Check 57 symbol registration failed" \
        "$(cat /tmp/vp-check57-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (PASS + injected-FAIL cases)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W3 wave-invariant). The check body now lives in
    validate_checks.discipline_parity and reads discipline_parity.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []

VERBS = list(mod._CHECK_57_CANONICAL_VERBS)
PHRASE = mod._CHECK_57_PRINCIPLE_PHRASE
TRINITY = list(mod._CHECK_57_TRINITY_SURFACES)
AGENTS = list(mod._CHECK_57_PROJECT_AGENTS)
AGENT_DIRS = list(mod._CHECK_57_AGENT_DIRS)
LAUNCHER = mod._CHECK_57_LAUNCHER_SURFACE

# Build the full surface list the check walks: trinity ×3 + 48 agents + launcher.
def all_surfaces():
    s = list(TRINITY)
    for dir_rel, ext in AGENT_DIRS:
        for a in AGENTS:
            s.append(f"{dir_rel}/{a}.{ext}")
    s.append(LAUNCHER)
    return s

def trinity_body(verbs=None, include_phrase=True):
    """A well-formed trinity 'No destructive operations' bullet: every verb as
    a git-verb token + the catch-all principle phrase. (No backticks — this
    body is built inside an unquoted heredoc; the matcher keys on 'git <verb>'
    prose, not on backtick fences.)"""
    vs = VERBS if verbs is None else verbs
    lines = ["- No destructive operations without explicit approval. Before"]
    lines += [f"  any git {v}," for v in vs]
    if include_phrase:
        lines.append(f"  read-only git verbs are allowed; {PHRASE} the ones enumerated.")
    return "\n".join(lines) + "\n"

def agent_prose_body(verbs=None):
    """A well-formed agent Hard rule (Claude + Antigravity bundle .md prose
    form). No backticks (unquoted heredoc)."""
    vs = VERBS if verbs is None else verbs
    lst = ", ".join(f"git {v}" for v in vs)
    return ("- No state-changing git operations, ever. Read-only git verbs "
            f"only. You MAY NOT run {lst}. Inspect via git show <ref>:<path>.\n")

def codex_slash_body(verbs=None):
    """A well-formed Codex auditor .toml Hard rule (slash-list form)."""
    vs = VERBS if verbs is None else verbs
    # >=4-member slash list so the matcher's slash-run rule applies.
    return ("- **No state-changing git operations, ever.** Read-only git verbs "
            f"only (status/diff/log/show). Forbidden: {'/'.join(vs)}.\n")

def launcher_body(verbs=None):
    """A well-formed agent-run.sh launcher flag block (Bash(git <verb>:*))."""
    vs = VERBS if verbs is None else verbs
    flags = " ".join(f'"Bash(git {v}:*)"' for v in vs)
    return f"CLAUDE_READONLY_FLAGS=(\n    \"--disallowedTools\"\n    {flags}\n)\n"

def body_for(surface, verbs=None, include_phrase=True):
    if surface in TRINITY:
        return trinity_body(verbs=verbs, include_phrase=include_phrase)
    if surface == LAUNCHER:
        return launcher_body(verbs=verbs)
    if surface.endswith(".toml"):
        return codex_slash_body(verbs=verbs)
    return agent_prose_body(verbs=verbs)

def run(overrides=None, drop_surface=None):
    """overrides: {surface: body_text}; drop_surface: a surface to OMIT."""
    overrides = overrides or {}
    tmpdir = tempfile.mkdtemp(prefix="vp-check57-")
    root = pathlib.Path(tmpdir)
    for s in all_surfaces():
        if s == drop_surface:
            continue
        p = root / s
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(overrides.get(s, body_for(s)))
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_project_destructive_git_verb_parity()
        n = len(mod.failures)
        cap = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return n, cap

# T1: PASS — all 52 surfaces carry every verb (+ trinity catch-all phrase).
n, cap = run()
if n != 0:
    failures.append(f"T1 (all consistent) expected PASS, got {n}: {cap}")

# T2: FAIL — a trinity surface drops a verb (worktree).
short = [v for v in VERBS if v != "worktree"]
n, cap = run(overrides={"project-template/CLAUDE.md": trinity_body(verbs=short)})
if n < 1 or "worktree" not in cap or "CLAUDE.md" not in cap:
    failures.append(f"T2 (dropped verb in trinity) expected FAIL naming worktree+CLAUDE.md, got {n}: {cap}")

# T3: FAIL — a trinity surface drops the catch-all principle phrase.
n, cap = run(overrides={"project-template/AGENTS.md": trinity_body(include_phrase=False)})
if n < 1 or "principle phrase" not in cap or "AGENTS.md" not in cap:
    failures.append(f"T3 (dropped trinity phrase) expected FAIL, got {n}: {cap}")

# T4: FAIL — one surface absent.
n, cap = run(drop_surface="project-template/.agents-plugin/optiquity-agents/agents/coder.md")
if n < 1 or "not found" not in cap:
    failures.append(f"T4 (absent surface) expected FAIL, got {n}: {cap}")

# T5: PASS — an AGENT file (not trinity) lacking the catch-all phrase is fine
# (the phrase is asserted ONLY on the trinity). The agent prose body carries
# every verb but no catch-all phrase → still PASSes.
n, cap = run()  # agent_prose_body never includes PHRASE by construction
if n != 0:
    failures.append(f"T5 (agent lacks catch-all, asserted trinity-only) expected PASS, got {n}: {cap}")

# T6: PASS — word-boundary + slash-run safety. A Codex slash-list surface with
# an extra benign 3-member parenthetical (add/remove/prune) and a cleanup
# token still carries every real verb, so it PASSes; no false verb match.
codex_safe = codex_slash_body() + (
    "Note: worktree (add/remove/prune) cleanup is described, not a deny verb.\n")
n, cap = run(overrides={"project-template/.codex/agents/reviewer.toml": codex_safe})
if n != 0:
    failures.append(f"T6 (word-boundary/slash-run safety) expected PASS, got {n}: {cap}")

# T7: FAIL — the launcher Bash(git <verb>:*) form is honored: drop a verb from
# the launcher flag block → FAIL naming the launcher + the dropped verb.
n, cap = run(overrides={LAUNCHER: launcher_body(verbs=[v for v in VERBS if v != "stash"])})
if n < 1 or "stash" not in cap or "agent-run.sh" not in cap:
    failures.append(f"T7 (dropped verb in launcher Bash(git ...:*) form) expected FAIL naming stash+agent-run.sh, got {n}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T7 (parity PASS + dropped-verb/dropped-trinity-phrase/absent-surface FAIL + trinity-only-phrase + word-boundary/slash-run safety + launcher-form honored)" ;;
    *) t_fail "End-to-end check_project_destructive_git_verb_parity tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 57 > /tmp/vp-check57-e2e.out 2>&1; then
    if grep -q "Check 57: BD-197 PROJECT destructive-git-verb enumeration parity" /tmp/vp-check57-e2e.out \
       && grep -q "Check 57 (Guard-C project) — destructive-git-verb enumeration parity holds" /tmp/vp-check57-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 57 runs and reports project verb-parity clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 57 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check57-e2e.out)"
    fi
else
    if grep -q "Check 57: BD-197 PROJECT destructive-git-verb enumeration parity" /tmp/vp-check57-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 57 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check57-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 57 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check57-e2e.out)"
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
