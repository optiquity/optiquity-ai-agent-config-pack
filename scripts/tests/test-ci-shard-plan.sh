#!/usr/bin/env bash
# scripts/tests/test-ci-shard-plan.sh — BD-219 C3 tests for the single-source
# CI shard partition module scripts/lib/ci-shard-plan.py.
#
# Covers: --emit-matrix (valid JSON, N shards, non-empty, full coverage),
# --assert-coverage (exit 0 on real state; FAIL when a script lands in no
# shard / in two shards / cohesion group split), --shard N --needs-fixtures
# (exactly the fixture-owning shard returns true), graceful degradation on a
# missing/unknown weight, and the parse-equivalence with Check 42's wired-set
# parse.
#
# Usage: bash scripts/tests/test-ci-shard-plan.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE="$REPO_ROOT/scripts/lib/ci-shard-plan.py"

PASS=0
FAIL=0
t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: module present + executable + importable
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: module present + importable ===\n"
if [[ -f "$MODULE" ]]; then
    t_pass "scripts/lib/ci-shard-plan.py present"
else
    t_fail "scripts/lib/ci-shard-plan.py missing"
fi
if [[ -x "$MODULE" ]]; then
    t_pass "scripts/lib/ci-shard-plan.py is executable"
else
    t_fail "scripts/lib/ci-shard-plan.py is not executable"
fi
if python3 -c "import ast; ast.parse(open('$MODULE').read())" 2>/tmp/csp-syntax.out; then
    t_pass "scripts/lib/ci-shard-plan.py parses (valid Python)"
else
    t_fail "syntax error in ci-shard-plan.py" "$(cat /tmp/csp-syntax.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: --emit-matrix → valid JSON, 4 shards, non-empty, full coverage
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: --emit-matrix ===\n"
python3 "$MODULE" --emit-matrix > /tmp/csp-matrix.json 2>/tmp/csp-matrix.err
rc=$?
if [[ $rc -eq 0 ]]; then
    t_pass "--emit-matrix exits 0"
else
    t_fail "--emit-matrix exits $rc" "$(cat /tmp/csp-matrix.err)"
fi
REPO_ROOT="$REPO_ROOT" python3 <<'EOF'
import json, os, sys, re, pathlib
errs = []
try:
    d = json.load(open('/tmp/csp-matrix.json'))
except Exception as e:
    print("FAIL not valid JSON:", e); sys.exit(1)
inc = d.get('include')
if not isinstance(inc, list):
    errs.append("matrix has no 'include' list")
elif len(inc) != 4:
    errs.append(f"expected 4 shards, got {len(inc)}")
seen = set()
for s in (inc or []):
    if not s.get('scripts', '').strip():
        errs.append(f"shard {s.get('shard')} has empty scripts")
    for t in s.get('scripts', '').split():
        if t in seen:
            errs.append(f"script in >1 shard: {t}")
        seen.add(t)
# Coverage: union of shards == wired KEEP set (recompute from the module).
root = os.environ['REPO_ROOT']
spec_path = root + "/scripts/lib/ci-shard-plan.py"
import importlib.util
spec = importlib.util.spec_from_file_location("csp", spec_path)
csp = importlib.util.module_from_spec(spec); spec.loader.exec_module(csp)
wired, allowlist, weights, shards = csp._load_all(4)
keep = set(s for s in wired if s not in allowlist)
if seen != keep:
    errs.append(f"matrix union != wired KEEP set (missing {sorted(keep-seen)}; extra {sorted(seen-keep)})")
if errs:
    print("FAILURES"); [print(" ", e) for e in errs]; sys.exit(1)
print("OK count=%d" % len(seen))
EOF
case $? in
    0) t_pass "--emit-matrix JSON valid: 4 non-empty disjoint shards; union == wired KEEP set" ;;
    *) t_fail "--emit-matrix JSON / coverage assertion failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: --assert-coverage GREEN on real state
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: --assert-coverage (real state) ===\n"
if python3 "$MODULE" --assert-coverage > /tmp/csp-cov.out 2>&1; then
    if grep -q "union == wired_KEEP_set" /tmp/csp-cov.out \
       && grep -q "pairwise-disjoint" /tmp/csp-cov.out \
       && grep -q "co-located in one shard" /tmp/csp-cov.out; then
        t_pass "--assert-coverage exit 0; union==wired, disjoint, cohesion co-located"
    else
        t_fail "--assert-coverage exit 0 but message incomplete" "$(cat /tmp/csp-cov.out)"
    fi
else
    t_fail "--assert-coverage exits non-zero on real state" "$(cat /tmp/csp-cov.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 3: --assert-coverage RED on a broken partition (in-process)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 3: --assert-coverage RED (broken partitions) ===\n"
REPO_ROOT="$REPO_ROOT" python3 <<'EOF'
import os, sys, io, contextlib
import importlib.util
root = os.environ['REPO_ROOT']
spec = importlib.util.spec_from_file_location("csp", root + "/scripts/lib/ci-shard-plan.py")
csp = importlib.util.module_from_spec(spec); spec.loader.exec_module(csp)
errs = []

# Re-implement the core coverage logic check by monkeypatching compute_partition
# so cmd_assert_coverage sees a broken partition.
orig = csp.compute_partition

# (a) dropped script → in no shard.
def drop_one(wired, allowlist, weights, n):
    shards = orig(wired, allowlist, weights, n)
    shards[0].pop()  # drop one
    return shards
csp.compute_partition = drop_one
rc = csp.cmd_assert_coverage(4)
if rc == 0:
    errs.append("(a) dropped-script partition unexpectedly PASSED --assert-coverage")

# (b) duplicated script → in two shards.
def dup_one(wired, allowlist, weights, n):
    shards = orig(wired, allowlist, weights, n)
    shards[1].append(shards[0][0])  # duplicate shard0's first into shard1
    return shards
csp.compute_partition = dup_one
rc = csp.cmd_assert_coverage(4)
if rc == 0:
    errs.append("(b) duplicated-script partition unexpectedly PASSED --assert-coverage")

# (c) cohesion group split across two shards.
def split_cohesion(wired, allowlist, weights, n):
    shards = orig(wired, allowlist, weights, n)
    # find a cohesion member and move it to a different shard
    for i, sc in enumerate(shards):
        for s in list(sc):
            if csp._basename(s) in csp.FIXTURE_COHESION_GROUP:
                target = (i + 1) % n
                sc.remove(s); shards[target].append(s)
                return shards
    return shards
csp.compute_partition = split_cohesion
rc = csp.cmd_assert_coverage(4)
if rc == 0:
    errs.append("(c) split-cohesion partition unexpectedly PASSED --assert-coverage")

csp.compute_partition = orig
if errs:
    print("FAILURES"); [print(" ", e) for e in errs]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "--assert-coverage RED on (a) dropped, (b) duplicated, (c) split-cohesion partitions" ;;
    *) t_fail "--assert-coverage did not catch a broken partition" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: --shard N --needs-fixtures — exactly the cohesion shard is true
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 4: --shard N --needs-fixtures ===\n"
true_count=0
for n in 1 2 3 4; do
    if python3 "$MODULE" --shard "$n" --needs-fixtures >/dev/null 2>&1; then
        true_count=$((true_count + 1))
    fi
done
if [[ $true_count -eq 1 ]]; then
    t_pass "exactly ONE shard owns the fixture cohesion group (--needs-fixtures)"
else
    t_fail "--needs-fixtures true for $true_count shards (expected exactly 1)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 5: graceful degradation — unknown weight does not break the partition
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 5: graceful degradation (unknown/bad weight) ===\n"
REPO_ROOT="$REPO_ROOT" python3 <<'EOF'
import os, sys
import importlib.util
root = os.environ['REPO_ROOT']
spec = importlib.util.spec_from_file_location("csp", root + "/scripts/lib/ci-shard-plan.py")
csp = importlib.util.module_from_spec(spec); spec.loader.exec_module(csp)
errs = []
# A wired script absent from weights gets DEFAULT_WEIGHT_S.
w = csp._weight_for("scripts/does-not-exist-xyz.sh", {})
if w != csp.DEFAULT_WEIGHT_S:
    errs.append(f"unknown weight should be DEFAULT_WEIGHT_S, got {w}")
# A bad weights row falls back to default (parser tolerance).
weights = csp.load_weights()  # real file
# Partition still valid (assert-coverage still passes) even if weights empty.
wired, allowlist, _, shards = csp._load_all(4)
keep = set(s for s in wired if s not in allowlist)
union = set(s for sc in shards for s in sc)
if union != keep:
    errs.append("partition coverage broken under real weights")
# Now force EMPTY weights → all default → still a valid partition.
shards2 = csp.compute_partition(wired, allowlist, {}, 4)
union2 = set(s for sc in shards2 for s in sc)
if union2 != keep:
    errs.append("partition coverage broken under EMPTY weights (graceful degradation failed)")
if errs:
    print("FAILURES"); [print(" ", e) for e in errs]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "graceful degradation: unknown/empty weights → valid partition + default weight" ;;
    *) t_fail "graceful degradation failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 6: parse equivalence with Check 42's wired-set parse
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 6: wired-set parse equivalence with Check 42 ===\n"
REPO_ROOT="$REPO_ROOT" python3 <<'EOF'
import os, sys, re, pathlib
import importlib.util
root = os.environ['REPO_ROOT']
spec = importlib.util.spec_from_file_location("csp", root + "/scripts/lib/ci-shard-plan.py")
csp = importlib.util.module_from_spec(spec); spec.loader.exec_module(csp)
wf = pathlib.Path(root) / ".github" / "workflows" / "validate-pack.yml"
text = wf.read_text()
csp_wired = set(csp.parse_wired_tests(text))
# BD-219 C2: Check 42 uses the SAME extraction — harvest scripts/...sh tokens
# from the `tests`-job matrix.include[].scripts strings (the static partition
# is the wired-set SSOT; there are no more `run: bash` test runners).
scripts_line = re.compile(r"^\s*scripts:\s*(.+)$")
token = re.compile(r"scripts/[^\s\"']+\.sh")
c42 = set()
for ln in text.splitlines():
    m = scripts_line.match(ln)
    if m:
        c42.update(token.findall(m.group(1)))
if csp_wired != c42:
    print("FAILURES")
    print("  csp-only:", sorted(csp_wired - c42))
    print("  c42-only:", sorted(c42 - csp_wired))
    sys.exit(1)
print("OK count=%d" % len(csp_wired))
EOF
case $? in
    0) t_pass "ci-shard-plan wired-set parse == Check 42 wired-set parse (single source of truth)" ;;
    *) t_fail "wired-set parse divergence between ci-shard-plan and Check 42" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"; exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"; exit 1
fi
