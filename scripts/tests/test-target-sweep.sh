#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-target-sweep.sh — the release-boundary sweep tool
# (project-template/scripts/target-sweep.sh): determinism, scope,
# epic-only, literal passthrough, and tool-vs-GRAMMAR agreement.
#
# Probe rows (BD-261 plan §P3.1):
#   B18  determinism — each verb run twice on the same tree is
#        byte-identical (also the resume posture: the tool is stateless,
#        so a re-consulted enumeration is byte-identical by construction).
#   B19  sweep scope — done AND superseded phases are excluded from
#        overdue / re-encode-set / kind-set but still listed by enumerate.
#   B20  epic-only — a part carrying `Target:` is never enumerated.
#   B21  literal-token passthrough — an illegal token appears in
#        enumerate verbatim; no verb crashes on it.
#   B22  tool-vs-GRAMMAR agreement — ONE normative table (below): bold /
#        plain / bullet label forms, space-before-colon, a
#        trailing-comment value, a part entry, a garbled token,
#        first-match-wins, a bold-wrapped value, a plain-form Status;
#        `enumerate` output is compared against the table's
#        expected-pairs golden. NO validate-docs.sh invocation anywhere
#        in this test (tool-vs-GATE agreement is a fold-time
#        third-reader fixture, not a CM3 test surface).
# Plus: empty / target-less tree (clean empty enumerations, exit 0),
# missing-tree and missing-vocabulary typed errors, default-dir
# resolution from the script location, and a read-only proof (every
# fixture file's checksum is byte-identical after all runs).
#
# Fixture trees are self-provisioned under mktemp and seeded with the
# SHIPPED implementation-plan _rules.md (the tool reads target-enum from
# the tree's own contract). Cleanup on every exit path.
#
# Usage:    bash scripts/tests/test-target-sweep.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TOOL="$PACK_ROOT/project-template/scripts/target-sweep.sh"
RULES_SRC="$PACK_ROOT/project-template/docs/project/implementation-plan/_rules.md"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-target-sweep.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    %s\n' "$2"
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

# Guard: inputs must exist (fail loud on a misconfigured tree).
for f in "$TOOL" "$RULES_SRC"; do
    if [[ ! -f "$f" ]]; then
        fail "required input present" "missing: $f"
    fi
done

# expect_eq <label> <expected> <actual>
expect_eq() {
    if [[ "$2" == "$3" ]]; then
        pass "$1"
    else
        fail "$1" "expected <<<${2}>>> got <<<${3}>>>"
    fi
}

# ── Main fixture tree (B18/B19/B20/B21 + empty-set + read-only) ────────────
MAIN="$FIXTURE_BASE/main/docs/project/implementation-plan"
mkdir -p "$MAIN"
cp "$RULES_SRC" "$MAIN/_rules.md"

mkphase() { # <dir> <num> <entry-type> <status> <target-or-empty>
    local dir="$1" num="$2" etype="$3" status="$4" target="${5:-}"
    {
        echo "<!-- per-entry source: docs/project/implementation-plan/phase-$num.md -->"
        echo "## Phase $num — Fixture"
        echo "- **Entry-Type**: $etype"
        [[ -n "$status" ]] && echo "- **Status**: $status"
        [[ -n "$target" ]] && echo "- **Target**: $target"
    } > "$dir/phase-$num.md"
}

mkphase "$MAIN" 1  phase-epic in-progress current
mkphase "$MAIN" 2  phase-epic not-started next-release
mkphase "$MAIN" 3  phase-epic blocked     next-minor
mkphase "$MAIN" 4  phase-epic deferred    next-major
mkphase "$MAIN" 5  phase-epic done        current
mkphase "$MAIN" 6  phase-epic superseded  next-release
mkphase "$MAIN" 7  phase-part ""          current
mkphase "$MAIN" 8  phase-epic in-progress ""
mkphase "$MAIN" 9  phase-epic in-progress bogus-token
mkphase "$MAIN" 10 phase-epic not-started future-unassigned

CKSUM_BEFORE="$(find "$MAIN" -type f | sort | xargs cksum)"

GOLD_ENUM="$(cat <<'EOF'
phase-1 current
phase-2 next-release
phase-3 next-minor
phase-4 next-major
phase-5 current
phase-6 next-release
phase-9 bogus-token
phase-10 future-unassigned
EOF
)"
GOLD_OVERDUE="phase-1 current"
GOLD_REENC="phase-2 next-release"
GOLD_KIND="$(cat <<'EOF'
phase-3 next-minor
phase-4 next-major
EOF
)"

echo "== goldens: four verbs on the main tree (byte-exact) =="
out_enum="$(bash "$TOOL" enumerate "$MAIN")";      rc_enum=$?
out_over="$(bash "$TOOL" overdue "$MAIN")";        rc_over=$?
out_reen="$(bash "$TOOL" re-encode-set "$MAIN")";  rc_reen=$?
out_kind="$(bash "$TOOL" kind-set "$MAIN")";       rc_kind=$?

expect_eq "enumerate golden (incl. numeric phase-10 ordering)" "$GOLD_ENUM" "$out_enum"
expect_eq "overdue golden" "$GOLD_OVERDUE" "$out_over"
expect_eq "re-encode-set golden" "$GOLD_REENC" "$out_reen"
expect_eq "kind-set golden" "$GOLD_KIND" "$out_kind"
expect_eq "all four verbs exit 0" "0 0 0 0" "$rc_enum $rc_over $rc_reen $rc_kind"

echo "== B19: scope bites — spent claims out of the sweep sets, in enumerate =="
if printf '%s\n' "$out_enum" | grep -q '^phase-5 current$' \
   && printf '%s\n' "$out_enum" | grep -q '^phase-6 next-release$'; then
    pass "done + superseded phases still listed by enumerate"
else
    fail "done + superseded phases still listed by enumerate" "$out_enum"
fi
if printf '%s\n' "$out_over" | grep -q 'phase-5' \
   || printf '%s\n' "$out_reen" | grep -q 'phase-6'; then
    fail "done/superseded excluded from overdue + re-encode-set" \
         "overdue=<$out_over> re-encode-set=<$out_reen>"
else
    pass "done/superseded excluded from overdue + re-encode-set"
fi

echo "== B20: epic-only — the part's Target never enumerated =="
if printf '%s\n%s\n%s\n%s\n' "$out_enum" "$out_over" "$out_reen" "$out_kind" \
   | grep -q 'phase-7'; then
    fail "part entry (phase-7) never enumerated by any verb"
else
    pass "part entry (phase-7) never enumerated by any verb"
fi

echo "== B21: literal passthrough — illegal token verbatim, filters silent =="
if printf '%s\n' "$out_enum" | grep -q '^phase-9 bogus-token$'; then
    pass "illegal token appears in enumerate verbatim"
else
    fail "illegal token appears in enumerate verbatim" "$out_enum"
fi
if printf '%s\n%s\n%s\n' "$out_over" "$out_reen" "$out_kind" | grep -q 'phase-9'; then
    fail "illegal token joins no sweep set"
else
    pass "illegal token joins no sweep set"
fi

echo "== B18: determinism — second run byte-identical (stateless resume) =="
det_ok=1
for verb in enumerate overdue re-encode-set kind-set; do
    a="$(bash "$TOOL" "$verb" "$MAIN")"
    b="$(bash "$TOOL" "$verb" "$MAIN")"
    if [[ "$a" != "$b" ]]; then
        det_ok=0
        fail "determinism: $verb run x2 byte-identical" "runs differ"
    fi
done
[[ "$det_ok" -eq 1 ]] && pass "all four verbs byte-identical across re-runs"

echo "== B22: tool-vs-GRAMMAR agreement (the normative table) =="
# ONE normative table. Each row: an entry authored in a label-form the
# shipped gate grammar admits, and the pair `enumerate` must emit.
#   entry     label form                              expected enumerate row
#   phase-1   "- **Target**: current"                 phase-1 current
#   phase-2   plain "Target: next-release"            phase-2 next-release
#   phase-3   "* Target : next-minor" (space-colon)   phase-3 next-minor
#   phase-4   bold no bullet "**Target**: next-major" phase-4 next-major
#   phase-5   trailing comment "current — see note"   phase-5 current — see note
#   phase-6   part entry with Target                  (absent)
#   phase-7   garbled "nonsense-value"                phase-7 nonsense-value
#   phase-8   TWO Target lines (current, next-major)  phase-8 current   (first match wins)
#   phase-9   bold-wrapped value "**current**"        phase-9 current   (asterisks stripped)
#   phase-10  plain "Status: done" + Target current   phase-10 current  (enumerate only)
# overdue over the same tree = the strip/equality proof:
#   phase-1 + phase-8 + phase-9 (value == current), NOT phase-5 (comment
#   value), NOT phase-10 (done — plain-form Status parsed).
GRAM="$FIXTURE_BASE/grammar/docs/project/implementation-plan"
mkdir -p "$GRAM"
cp "$RULES_SRC" "$GRAM/_rules.md"
cat > "$GRAM/phase-1.md" <<'EOF'
## Phase 1 — canonical bullet-bold
- **Entry-Type**: phase-epic
- **Status**: in-progress
- **Target**: current
EOF
cat > "$GRAM/phase-2.md" <<'EOF'
## Phase 2 — plain labels
Entry-Type: phase-epic
Status: not-started
Target: next-release
EOF
cat > "$GRAM/phase-3.md" <<'EOF'
## Phase 3 — asterisk bullet, space before colon
* Entry-Type : phase-epic
* Status : blocked
* Target : next-minor
EOF
cat > "$GRAM/phase-4.md" <<'EOF'
## Phase 4 — bold, no bullet
**Entry-Type**: phase-epic
**Status**: in-progress
**Target**: next-major
EOF
cat > "$GRAM/phase-5.md" <<'EOF'
## Phase 5 — trailing-comment value
- **Entry-Type**: phase-epic
- **Status**: in-progress
- **Target**: current — see note
EOF
cat > "$GRAM/phase-6.md" <<'EOF'
## Phase 6 — part with a Target (must be skipped)
- **Entry-Type**: phase-part
- **Target**: current
EOF
cat > "$GRAM/phase-7.md" <<'EOF'
## Phase 7 — garbled token
- **Entry-Type**: phase-epic
- **Status**: in-progress
- **Target**: nonsense-value
EOF
cat > "$GRAM/phase-8.md" <<'EOF'
## Phase 8 — two Target lines: first match wins
- **Entry-Type**: phase-epic
- **Status**: in-progress
- **Target**: current
- **Target**: next-major
EOF
cat > "$GRAM/phase-9.md" <<'EOF'
## Phase 9 — bold-wrapped value
- **Entry-Type**: phase-epic
- **Status**: in-progress
- **Target**: **current**
EOF
cat > "$GRAM/phase-10.md" <<'EOF'
## Phase 10 — plain-form done Status
Entry-Type: phase-epic
Status: done
- **Target**: current
EOF

GOLD_GRAM_ENUM="$(cat <<'EOF'
phase-1 current
phase-2 next-release
phase-3 next-minor
phase-4 next-major
phase-5 current — see note
phase-7 nonsense-value
phase-8 current
phase-9 current
phase-10 current
EOF
)"
GOLD_GRAM_OVERDUE="$(cat <<'EOF'
phase-1 current
phase-8 current
phase-9 current
EOF
)"

out_gram_enum="$(bash "$TOOL" enumerate "$GRAM")"
out_gram_over="$(bash "$TOOL" overdue "$GRAM")"
expect_eq "grammar-tree enumerate == the normative table" "$GOLD_GRAM_ENUM" "$out_gram_enum"
expect_eq "grammar-tree overdue (strip + equality + plain-Status scope)" \
          "$GOLD_GRAM_OVERDUE" "$out_gram_over"

echo "== empty / target-less tree: clean empty enumerations, exit 0 =="
EMPTY="$FIXTURE_BASE/empty/docs/project/implementation-plan"
mkdir -p "$EMPTY"
cp "$RULES_SRC" "$EMPTY/_rules.md"
mkphase "$EMPTY" 1 phase-epic in-progress ""
e_enum="$(bash "$TOOL" enumerate "$EMPTY")";     rc1=$?
e_over="$(bash "$TOOL" overdue "$EMPTY")";       rc2=$?
e_reen="$(bash "$TOOL" re-encode-set "$EMPTY")"; rc3=$?
e_kind="$(bash "$TOOL" kind-set "$EMPTY")";      rc4=$?
expect_eq "empty enumerate message" "(no targets)" "$e_enum"
expect_eq "empty overdue message" "(no overdue targets)" "$e_over"
expect_eq "empty re-encode-set message" "(no re-encode targets)" "$e_reen"
expect_eq "empty kind-set message" "(no kind-set targets)" "$e_kind"
expect_eq "empty tree: all verbs exit 0" "0 0 0 0" "$rc1 $rc2 $rc3 $rc4"

echo "== typed errors: missing tree + missing vocabulary =="
missing_err="$(bash "$TOOL" enumerate "$FIXTURE_BASE/does-not-exist" 2>&1)"
rc_missing=$?
if [[ "$rc_missing" -eq 2 && "$missing_err" == *"no implementation-plan tree"* ]]; then
    pass "missing tree: exit 2 + typed error"
else
    fail "missing tree: exit 2 + typed error" "rc=$rc_missing out=<$missing_err>"
fi

NOVOCAB="$FIXTURE_BASE/novocab/docs/project/implementation-plan"
mkdir -p "$NOVOCAB"
grep -v '^- target-enum:' "$RULES_SRC" > "$NOVOCAB/_rules.md"
mkphase "$NOVOCAB" 1 phase-epic in-progress current
nv_err="$(bash "$TOOL" overdue "$NOVOCAB" 2>&1)"
rc_nv=$?
if [[ "$rc_nv" -eq 2 && "$nv_err" == *"vocabulary is undefined"* ]]; then
    pass "filter verb without target-enum: exit 2 + typed error"
else
    fail "filter verb without target-enum: exit 2 + typed error" "rc=$rc_nv out=<$nv_err>"
fi
nv_enum="$(bash "$TOOL" enumerate "$NOVOCAB")"
rc_nv_enum=$?
expect_eq "enumerate still works without target-enum (verbatim passthrough)" \
          "phase-1 current" "$nv_enum"
expect_eq "enumerate without target-enum exits 0" "0" "$rc_nv_enum"

echo "== default-dir resolution from the script's install location =="
FAKEROOT="$FIXTURE_BASE/fakeroot"
mkdir -p "$FAKEROOT/scripts" "$FAKEROOT/docs/project"
cp "$TOOL" "$FAKEROOT/scripts/target-sweep.sh"
chmod +x "$FAKEROOT/scripts/target-sweep.sh"
cp -R "$MAIN" "$FAKEROOT/docs/project/implementation-plan"
dd_out="$(cd "$FIXTURE_BASE" && bash "$FAKEROOT/scripts/target-sweep.sh" enumerate)"
expect_eq "no-dir-arg run resolves docs/project/implementation-plan from install root" \
          "$GOLD_ENUM" "$dd_out"

echo "== read-only proof: fixture bytes untouched after all runs =="
CKSUM_AFTER="$(find "$MAIN" -type f | sort | xargs cksum)"
expect_eq "main-tree checksums identical before/after every verb run" \
          "$CKSUM_BEFORE" "$CKSUM_AFTER"

echo ""
echo "test-target-sweep: $passes passed, $fails failed"
[[ "$fails" -eq 0 ]] || exit 1
exit 0
