#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-4.sh — synthetic fixture tests for
# Check 4 (README version table vs git tag; `check_readme_version` in
# `scripts/lib/validate_checks/singletons.py`).
#
# WHY THIS FILE EXISTS (BD-093). Check 4 selected `version_rows[-1]` — the LAST
# regex match — while the README version table is ordered NEWEST-FIRST. It
# therefore compared the OLDEST row (`v1`, whose tag has existed since v1) to
# the tag set and passed unconditionally: the guard that exists specifically to
# catch a README↔tag mismatch caught nothing. The production fix selects
# `version_rows[0]`; these tests pin the newest-row selection AND prove the
# guard now BITES (declare-verify-backing: a records-style check must be shown
# failing against a deliberately mismatched input, not merely passing against
# the current tree).
#
# HERMETIC BY CONSTRUCTION. No test here creates a git repo, stages, commits or
# tags anything. Each case monkeypatches `validate_checks.singletons.README`
# (to a synthetic table in a tmp dir) and `validate_checks.singletons.subprocess`
# (to a stub answering `git tag` / `git branch --show-current` /
# `git rev-parse` / `git branch --points-at` with canned output), then invokes
# the check body and asserts PASS/FAIL. That keeps the tests deterministic on
# any runner regardless of the checkout's real branch, tag set, or worktree
# shape — and keeps the suite free of git state changes.
#
# Coverage:
#   Group 0: module import + Check 4 symbols registered
#   Group 1: row selection + the preserved behaviors —
#            T1  newest row selected (NOT the oldest) — multi-row table
#            T2  THE BITE: newest row has no tag, oldest row's tag exists,
#                non-dev branch, primary checkout => FAIL (pre-fix: PASS)
#            T3  newest row matches its tag => PASS
#            T4  bare-major-tag match (`v9` row, `v9` tag) => PASS
#            T5  display→tag qualifier normalization (BD-242 locked scheme):
#                (RC1)/(alpha)/(beta)/(GA)/(work) + bare + PATCH
#            T6  dev-branch allowance (no matching tag, branch `v11-dev`)
#            T7  no-tags skip
#            T8  no version-table rows => FAIL
#   Group 2: linked-worktree allowance (BD-226 RW-agent isolation) —
#            T9  linked worktree whose HEAD carries a dev branch => PASS
#            T10 PRIMARY checkout on `main` at the same commit as a dev
#                branch => FAIL (the allowance must NOT leak into the
#                primary checkout — that is the release-cut mismatch case)
#            T11 linked worktree with NO dev branch at HEAD => FAIL
#   Group 3: end-to-end `validate-pack.py --only-check 4` on the real tree
#
# Usage: bash scripts/tests/test-validate-pack-check-4.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/vp-check4.XXXXXX")"
cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
    return 0
}

assert_contains() {
    local label="$1" haystack="$2" needle="$3"
    case "$haystack" in
        *"$needle"*) t_pass "$label" ;;
        *) t_fail "$label" "expected to find: $needle" ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
# Group 0: module import + Check 4 symbols registered
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: module import + Check 4 symbols ===\n"

# NOTE: every python heredoc/-c body below is QUOTED ('PYEOF' / single-quoted
# -c) and takes its paths from the environment. An UNQUOTED heredoc would let
# the shell run backticks inside Python comments as command substitution.
export VP_REPO_ROOT="$REPO_ROOT"
export VP_VALIDATE="$VALIDATE"
export VP_TMPROOT="$TMPROOT"

G0_OUT="$(python3 -c '
import os, sys
sys.path.insert(0, os.environ["VP_REPO_ROOT"] + "/scripts")
import importlib.util
spec = importlib.util.spec_from_file_location("vp", os.environ["VP_VALIDATE"])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
sing = sys.modules["validate_checks.singletons"]
required = ["check_readme_version", "_check_4_dev_worktree_branch"]
missing = [n for n in required if not hasattr(sing, n)]
print("MISSING " + " ".join(missing) if missing else "OK")
' 2>&1)"

assert_contains "G0.1 validate-pack.py imports + Check 4 symbols present" \
    "$G0_OUT" "OK"

# ─────────────────────────────────────────────────────────────────
# Groups 1 + 2: synthetic README + stubbed git
# ─────────────────────────────────────────────────────────────────

printf "\n=== Groups 1+2: row selection, preserved behaviors, worktree allowance ===\n"

G12_OUT="$(python3 <<'PYEOF' 2>&1
import contextlib
import io
import os
import pathlib
import sys

sys.path.insert(0, os.environ["VP_REPO_ROOT"] + "/scripts")
import importlib.util
spec = importlib.util.spec_from_file_location("vp", os.environ["VP_VALIDATE"])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
sing = sys.modules["validate_checks.singletons"]

TMPROOT = pathlib.Path(os.environ["VP_TMPROOT"])


class FakeCompleted:
    def __init__(self, stdout="", returncode=0):
        self.stdout = stdout
        self.stderr = ""
        self.returncode = returncode


class FakeSubprocess:
    """Answers only the four git shapes Check 4 issues. Anything else -> rc=1.

    The failure-injection kwargs exercise the DEGRADATION branches, which
    the happy-path cases cannot reach: `git` absent entirely
    (FileNotFoundError from `git tag`), an OSError out of `rev-parse`, and
    non-zero returncodes from `rev-parse` / `branch --points-at`. Each must
    degrade to "no allowance" (or the documented lenient skip) — never to a
    silent PASS."""

    def __init__(self, tags, branch, linked, points_at,
                 tag_raises=None, revparse_raises=None,
                 revparse_rc=0, points_at_rc=0):
        self.tags = tags
        self.branch = branch
        self.linked = linked
        self.points_at = points_at
        self.tag_raises = tag_raises
        self.revparse_raises = revparse_raises
        self.revparse_rc = revparse_rc
        self.points_at_rc = points_at_rc

    def run(self, cmd, **kw):
        if cmd[:2] == ["git", "tag"]:
            if self.tag_raises is not None:
                raise self.tag_raises
            return FakeCompleted("\n".join(self.tags))
        if cmd[:2] == ["git", "branch"] and "--show-current" in cmd:
            return FakeCompleted(self.branch)
        if cmd[:2] == ["git", "branch"] and "--points-at" in cmd:
            return FakeCompleted("\n".join(self.points_at), self.points_at_rc)
        # `--git-common-dir` first: exact element match, but keep the
        # more-specific flag ahead of `--git-dir` for readability.
        if "--git-common-dir" in cmd:
            if self.revparse_raises is not None:
                raise self.revparse_raises
            return FakeCompleted("/repo/.git", self.revparse_rc)
        if "--git-dir" in cmd:
            if self.revparse_raises is not None:
                raise self.revparse_raises
            return FakeCompleted("/repo/.git/worktrees/wt" if self.linked
                                 else "/repo/.git", self.revparse_rc)
        return FakeCompleted("", 1)


# A multi-row NEWEST-FIRST table, the real README's shape.
def table(rows):
    out = ["| Version | Date | Key Additions |", "|---|---|---|"]
    for r in rows:
        out.append("| %s | May 2026 | notes |" % r)
    return "\n".join(out) + "\n"


NEWEST_FIRST = ["v11.0 (RC1)", "v10.1", "v10.0", "v9.0", "v8.0", "v1"]


def run_case(name, readme_text, tags, branch="main", linked=False,
             points_at=(), **inject):
    """Invoke check_readme_version against a synthetic README + stubbed git.

    Returns (n_failures, captured_stdout)."""
    readme = TMPROOT / ("README-%s.md" % name)
    readme.write_text(readme_text)

    saved_readme = sing.README
    saved_sub = sing.subprocess
    saved_failures = list(mod.failures)
    mod.failures.clear()
    sing.README = readme
    sing.subprocess = FakeSubprocess(list(tags), branch, linked,
                                     list(points_at), **inject)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            sing.check_readme_version()
        n = len(mod.failures)
    finally:
        sing.README = saved_readme
        sing.subprocess = saved_sub
        mod.failures.clear()
        mod.failures.extend(saved_failures)
    return n, buf.getvalue()


ALL_TAGS = ["v10.1", "v10.0", "v10", "v9.0", "v9", "v8.0", "v8", "v1"]

# ── T1: the newest row is the one selected (NOT the oldest) ────────────────
n, out = run_case("t1", table(NEWEST_FIRST), ALL_TAGS + ["v11.0-RC1"])
print("T1 selected_newest=%s selected_oldest=%s failures=%d"
      % ("v11.0 (RC1)" in out, "version v1 " in out, n))

# ── T2: THE BITE. Newest row has NO tag; the OLDEST row's tag (v1) DOES
#        exist; branch is non-dev; primary checkout. Pre-fix this PASSED
#        (it compared v1). Post-fix it must FAIL. ─────────────────────────
n, out = run_case("t2", table(NEWEST_FIRST), ALL_TAGS, branch="main")
print("T2 failures=%d mentions_current=%s mentions_tagform=%s"
      % (n, "v11.0 (RC1)" in out, "v11.0-RC1" in out))

# ── T3: newest row matches its tag ─────────────────────────────────────────
n, out = run_case("t3", table(NEWEST_FIRST), ALL_TAGS + ["v11.0-RC1"],
                  branch="main")
print("T3 failures=%d matched=%s" % (n, "matches git tag" in out))

# ── T4: bare-major-tag match preserved (`v9` row against the `v9` tag) ─────
n, out = run_case("t4", table(["v9", "v8.0", "v1"]), ALL_TAGS, branch="main")
print("T4 failures=%d matched=%s" % (n, "matches git tag" in out))

# ── T5: display->tag qualifier normalization (BD-242 locked scheme) ────────
t5 = []
for disp, tag in (("v11.0 (RC1)", "v11.0-RC1"),
                  ("v11.0 (alpha)", "v11.0-alpha"),
                  ("v11.0 (beta)", "v11.0-beta"),
                  ("v11.0 (GA)", "v11.0-GA"),
                  ("v11.0 (work)", "v11.0-work"),
                  ("v11.0", "v11.0"),
                  ("v11.0.1", "v11.0.1")):
    n, out = run_case("t5-" + tag, table([disp] + NEWEST_FIRST[1:]),
                      ALL_TAGS + [tag], branch="main")
    t5.append("%s->%s:%s" % (disp, tag, "ok" if n == 0 else "FAILED"))
print("T5 " + " ".join(t5))

# ── T6: dev-branch allowance preserved ─────────────────────────────────────
n, out = run_case("t6", table(NEWEST_FIRST), ALL_TAGS, branch="v11-dev")
print("T6 failures=%d dev_allowance=%s" % (n, "dev branch" in out))

# ── T7: no-tags skip preserved ─────────────────────────────────────────────
n, out = run_case("t7", table(NEWEST_FIRST), [], branch="main")
print("T7 failures=%d skipped=%s" % (n, "no git tags" in out))

# ── T8: no version-table rows => FAIL ──────────────────────────────────────
n, out = run_case("t8", "# README\n\nNo table here.\n", ALL_TAGS)
print("T8 failures=%d" % n)

# ── T9: linked worktree whose HEAD carries a dev branch => allowance ───────
n, out = run_case("t9", table(NEWEST_FIRST), ALL_TAGS,
                  branch="worktree-agent-abc123", linked=True,
                  points_at=["v11-dev", "worktree-agent-abc123"])
print("T9 failures=%d worktree_allowance=%s" % (n, "linked worktree" in out))

# ── T10: PRIMARY checkout on main at the same commit as a dev branch.
#         The worktree allowance must NOT fire (release-cut mismatch). ─────
n, out = run_case("t10", table(NEWEST_FIRST), ALL_TAGS,
                  branch="main", linked=False,
                  points_at=["main", "v11-dev"])
print("T10 failures=%d worktree_allowance=%s" % (n, "linked worktree" in out))

# ── T11: linked worktree with NO dev branch at HEAD => still FAIL ──────────
n, out = run_case("t11", table(NEWEST_FIRST), ALL_TAGS,
                  branch="worktree-agent-abc123", linked=True,
                  points_at=["worktree-agent-abc123"])
print("T11 failures=%d" % n)

# ── T12: git ABSENT (FileNotFoundError) => the documented lenient skip.
#         The docstring advertises a no-git skip; T7 only covered no-TAGS. ──
n, out = run_case("t12", table(NEWEST_FIRST), ALL_TAGS, branch="main",
                  tag_raises=FileNotFoundError("git"))
print("T12 failures=%d skipped=%s" % (n, "git not available" in out))

# ── T13: rev-parse raises OSError inside the worktree probe => NO allowance.
#         Degradation must be a loud FAIL, never a silent PASS. ────────────
n, out = run_case("t13", table(NEWEST_FIRST), ALL_TAGS,
                  branch="worktree-agent-abc123", linked=True,
                  points_at=["v11-dev"],
                  revparse_raises=OSError("rev-parse exploded"))
print("T13 failures=%d worktree_allowance=%s" % (n, "linked worktree" in out))

# ── T14: rev-parse returns non-zero => NO allowance. ──────────────────────
n, out = run_case("t14", table(NEWEST_FIRST), ALL_TAGS,
                  branch="worktree-agent-abc123", linked=True,
                  points_at=["v11-dev"], revparse_rc=1)
print("T14 failures=%d worktree_allowance=%s" % (n, "linked worktree" in out))

# ── T15: `branch --points-at` returns non-zero => NO allowance. ───────────
n, out = run_case("t15", table(NEWEST_FIRST), ALL_TAGS,
                  branch="worktree-agent-abc123", linked=True,
                  points_at=["v11-dev"], points_at_rc=1)
print("T15 failures=%d worktree_allowance=%s" % (n, "linked worktree" in out))

# ── T16/T17: THE N6 BITE — branches that merely CONTAIN "dev" are not dev
#         branches. A bare substring test grants them the pre-release
#         allowance; segment matching must refuse it. ────────────────────
for _tid, _lookalike in (("T16", "main-devops"), ("T17", "feature/device-x")):
    n, out = run_case(_tid.lower(), table(NEWEST_FIRST), ALL_TAGS,
                      branch="worktree-agent-abc123", linked=True,
                      points_at=[_lookalike])
    print("%s lookalike=%s failures=%d allowance=%s"
          % (_tid, _lookalike, n, "linked worktree" in out))

# ── T18: the same bite on the PRIMARY-checkout path — the one that reaches
#         CI. `main-devops` must NOT earn the dev-branch allowance. ───────
n, out = run_case("t18", table(NEWEST_FIRST), ALL_TAGS, branch="main-devops")
print("T18 failures=%d dev_allowance=%s" % (n, "dev branch" in out))

# ── T19: every REAL dev-branch spelling still earns the allowance (the
#         anchoring must not over-tighten). ───────────────────────────────
t19 = []
for _b in ("dev", "dev/topic", "v11-dev", "v10-dev", "v11-dev-fixes"):
    n, out = run_case("t19-" + _b.replace("/", "_"), table(NEWEST_FIRST),
                      ALL_TAGS, branch=_b)
    t19.append("%s:%s" % (_b, "ok" if n == 0 else "FAILED"))
print("T19 " + " ".join(t19))
PYEOF
)"

printf "%s\n" "$G12_OUT" | sed 's/^/    | /'

assert_contains "T1 newest row (v11.0 (RC1)) is the selected row" \
    "$G12_OUT" "T1 selected_newest=True"
assert_contains "T1 oldest row (v1) is NOT the selected row" \
    "$G12_OUT" "selected_oldest=False"
assert_contains "T2 THE BITE — newest row without a tag FAILs on a non-dev primary checkout" \
    "$G12_OUT" "T2 failures=1"
assert_contains "T2 failure message names the current display version" \
    "$G12_OUT" "mentions_current=True"
assert_contains "T2 failure message names the normalized tag form" \
    "$G12_OUT" "mentions_tagform=True"
assert_contains "T3 newest row matching its tag PASSes" \
    "$G12_OUT" "T3 failures=0 matched=True"
assert_contains "T4 bare-major-tag match preserved" \
    "$G12_OUT" "T4 failures=0 matched=True"
assert_contains "T5 (RC1) normalizes to v11.0-RC1"   "$G12_OUT" "v11.0 (RC1)->v11.0-RC1:ok"
assert_contains "T5 (alpha) normalizes to v11.0-alpha" "$G12_OUT" "v11.0 (alpha)->v11.0-alpha:ok"
assert_contains "T5 (beta) normalizes to v11.0-beta"  "$G12_OUT" "v11.0 (beta)->v11.0-beta:ok"
assert_contains "T5 (GA) normalizes to v11.0-GA"      "$G12_OUT" "v11.0 (GA)->v11.0-GA:ok"
assert_contains "T5 (work) normalizes to v11.0-work"  "$G12_OUT" "v11.0 (work)->v11.0-work:ok"
assert_contains "T5 bare v11.0 normalizes to itself"  "$G12_OUT" "v11.0->v11.0:ok"
assert_contains "T5 PATCH form v11.0.1 normalizes to itself" "$G12_OUT" "v11.0.1->v11.0.1:ok"
assert_contains "T6 dev-branch allowance preserved" \
    "$G12_OUT" "T6 failures=0 dev_allowance=True"
assert_contains "T7 no-tags skip preserved" \
    "$G12_OUT" "T7 failures=0 skipped=True"
assert_contains "T8 a README with no version rows FAILs" \
    "$G12_OUT" "T8 failures=1"
assert_contains "T9 linked worktree off a dev branch is allowed" \
    "$G12_OUT" "T9 failures=0 worktree_allowance=True"
assert_contains "T12 git absent => documented lenient skip" \
    "$G12_OUT" "T12 failures=0 skipped=True"
assert_contains "T13 rev-parse OSError => no worktree allowance (loud FAIL)" \
    "$G12_OUT" "T13 failures=1 worktree_allowance=False"
assert_contains "T14 rev-parse non-zero rc => no worktree allowance" \
    "$G12_OUT" "T14 failures=1 worktree_allowance=False"
assert_contains "T15 points-at non-zero rc => no worktree allowance" \
    "$G12_OUT" "T15 failures=1 worktree_allowance=False"
assert_contains "T16 'main-devops' is NOT a dev branch (worktree path)" \
    "$G12_OUT" "T16 lookalike=main-devops failures=1 allowance=False"
assert_contains "T17 'feature/device-x' is NOT a dev branch (worktree path)" \
    "$G12_OUT" "T17 lookalike=feature/device-x failures=1 allowance=False"
assert_contains "T18 'main-devops' earns no allowance on the CI-reachable primary path" \
    "$G12_OUT" "T18 failures=1 dev_allowance=False"
assert_contains "T19 bare 'dev' still allowed"        "$G12_OUT" "dev:ok"
assert_contains "T19 'dev/topic' still allowed"       "$G12_OUT" "dev/topic:ok"
assert_contains "T19 'v11-dev' still allowed"         "$G12_OUT" "v11-dev:ok"
assert_contains "T19 'v10-dev' still allowed"         "$G12_OUT" "v10-dev:ok"
assert_contains "T19 'v11-dev-fixes' still allowed"   "$G12_OUT" "v11-dev-fixes:ok"
assert_contains "T10 primary checkout on main does NOT get the worktree allowance" \
    "$G12_OUT" "T10 failures=1 worktree_allowance=False"
assert_contains "T11 linked worktree with no dev branch at HEAD still FAILs" \
    "$G12_OUT" "T11 failures=1"

# ─────────────────────────────────────────────────────────────────
# Group 3: end-to-end against the real tree
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: end-to-end validate-pack.py --only-check 4 ===\n"

if python3 "$VALIDATE" --only-check 4 > "$TMPROOT/e2e.out" 2>&1; then
    t_pass "G3.1 --only-check 4 exits 0 against the real tree"
else
    t_fail "G3.1 --only-check 4 exits non-zero against the real tree" \
        "$(cat "$TMPROOT/e2e.out")"
fi

if grep -q "Check 4: README version table vs git tag" "$TMPROOT/e2e.out"; then
    t_pass "G3.2 Check 4 banner present in the run"
else
    t_fail "G3.2 Check 4 banner missing" "$(cat "$TMPROOT/e2e.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "PASS: %d\n" "$PASS"
printf "FAIL: %d\n" "$FAIL"

if [[ $FAIL -eq 0 ]]; then
    printf "\nAll Check 4 tests PASSED (%d/%d).\n" "$PASS" "$((PASS + FAIL))"
    exit 0
else
    printf "\nFAILED — %d test(s) failed.\n" "$FAIL"
    exit 1
fi
