#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-docs-template-fullscan.sh —
# BD-259 standing guard: the shipped template must pass its OWN operating-doc
# gate (project-template/scripts/validate-docs.sh), on the bare template tree
# AND on the fresh-install overlay tree, and the guard's own moving parts must
# stay tethered to the surfaces they mirror.
#
# Seven legs:
#   L1  Bare-template full scan green (the BD's core guard). Runs the REAL
#       shipped gate IN PLACE, deliberately DELEGATING doc enumeration to the
#       gate itself: the gate globs the live tree, so a new not-yet-tracked
#       template doc is scanned exactly as a client install would scan it (a
#       `git ls-files` staging would silently exclude it).
#   L2  IN-set collapse floor: the gate's banner count must stay >= 90
#       (measured 108 = 37 skills + 16x3 agents + 12 prompts + 4 docs/pack +
#       3 trinity + 4 _rules.md; any >=19-doc family loss lands <= 89 and
#       trips). RESIDUAL (honest): a <= 18-doc family collapse ALONE stays
#       >= 90 and escapes this floor; L1 still polices the surviving docs.
#   L3  Allowlist liveness, BOTH directions: every doc:+snippet: record must
#       still match >= 1 live line of its resolved doc (declared mapping with
#       NO backing = dead), and every target: record must still be referenced
#       by >= 1 corpus doc (allow-record for a ref nobody makes = dead).
#       Corpus = the gate's IN set UNION the two install-overlay sources
#       (supporting-docs/METHODOLOGY.md + supporting-docs/INSTALL-PROCEDURES.md).
#       The union amendment is sized to measured necessity: 3 of the 5
#       install-tree target: records have ZERO bare-IN-set refs and would
#       false-red as dead without it.
#   L4  The gate's --self-test exits 0. Honest coverage statement: this leg
#       covers matcher<->self-test-FIXTURE drift (e.g. a future hardcoded
#       heading literal in the bloat matcher) plus the per-axis bite
#       assertions. It does NOT cover a constant<->real-docs heading desync —
#       the self-test bijection leg is value-agnostic by design (matcher and
#       fixtures derive from the same constant, so both sides move together
#       under any rename). That failure mode is L6's job.
#   L5  Install-tree full scan: stage the exact init-project.sh S6 overlay
#       (project-template + the 2 supporting-docs copied into docs/pack/),
#       assert exit 0 AND N_install == N_bare + 2. The RELATIVE form is
#       deliberate — a hard 107 would false-fail every legitimate
#       template-doc addition.
#   L6  docs<->constant heading sync (this test hardcodes NO heading text
#       anywhere): derive the TRINITY_MEMORY_HEADING literal from the SHIPPED
#       gate at runtime and assert all 3 template trinity docs carry that
#       exact H2 line. Rename-neutral by construction: a lock-step rename
#       (3 docs + the constant together) stays green; a ONE-SIDED rename
#       fails LOUD in either direction; a changed constant form fails LOUD
#       (parse-guard, never a silent skip).
#   L7  S6 overlay-set tether: derive the overlay basename set from
#       scripts/init-project.sh's copy lines and assert set-equality with
#       {INSTALL-PROCEDURES.md, METHODOLOGY.md} — the set L3's overlay map
#       and L5's staging hardcode. A third overlay doc fails LOUD; a refactor
#       of the copy-line form fails LOUD (derivation-empty). RESIDUAL
#       (honest): a future overlay added via a form matching NEITHER grep
#       pattern escapes this tether.
#
# Pattern mirrors scripts/tests/test-validate-docs-client-deferred-shipped-docs.sh
# (BD-250): real shipped bytes + the real gate + the real client allowlist;
# PASS/FAIL counters; mktemp + trap cleanup; non-zero exit on any failure.
# Auto-discovered by the ci-shard-plan.py from-disk glob — no manual wiring.
#
# Usage:    bash scripts/tests/test-validate-docs-template-fullscan.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# The REAL shipped surfaces this guard polices.
GATE="$PACK_ROOT/project-template/scripts/validate-docs.sh"
ALLOWLIST="$PACK_ROOT/project-template/scripts/.docs-gate-allowlist.txt"
INIT_SCRIPT="$PACK_ROOT/scripts/init-project.sh"
SRC_METH="$PACK_ROOT/supporting-docs/METHODOLOGY.md"
SRC_INST="$PACK_ROOT/supporting-docs/INSTALL-PROCEDURES.md"

# L2 floor: measured IN-set is 108 docs; any >=19-doc family loss trips.
IN_SET_FLOOR=90

FIXTURE_BASE="$(mktemp -d -t test-vdocs-fullscan.XXXXXX)"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    %s\n' "$2"
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

# Guard: the inputs must exist (a misconfigured tree should fail loud, not
# silently pass).
for f in "$GATE" "$ALLOWLIST" "$INIT_SCRIPT" "$SRC_METH" "$SRC_INST"; do
    if [[ ! -f "$f" ]]; then
        fail "required input present" "missing: $f"
    fi
done

echo "== BD-259 standing guard: shipped template vs its own doc-gate =="

# ── L1: bare-template full scan green ───────────────────────────────────────
l1_out="$(bash "$GATE" 2>&1)"
l1_rc=$?
if [[ $l1_rc -eq 0 ]]; then
    pass "L1: bare-template full scan exits 0 (the shipped template passes its own gate)"
else
    fail "L1: bare-template full scan should exit 0, got $l1_rc" \
        "fix the doc, or size an allowlist record to exactly one line — never widen"
    printf '%s\n' "$l1_out"
fi

# ── L2: IN-set collapse floor ────────────────────────────────────────────────
n_bare="$(printf '%s\n' "$l1_out" \
    | sed -n -E 's/.*scanning ([0-9]+) operating docs.*/\1/p' | head -1)"
if [[ -z "$n_bare" ]]; then
    fail "L2: banner parse EMPTY (the gate's 'scanning N operating docs' banner form changed — update this leg's parse)"
elif [[ "$n_bare" -ge "$IN_SET_FLOOR" ]]; then
    pass "L2: IN-set size $n_bare >= $IN_SET_FLOOR (no doc-family collapse)"
else
    fail "L2: IN-set size $n_bare < floor $IN_SET_FLOOR" \
        "a whole operating-doc family stopped being scanned (glob/exclude drift in the gate's IN_GLOBS?)"
fi

# ── L3: allowlist liveness, both directions ─────────────────────────────────
l3_out="$(python3 - "$PACK_ROOT" << 'PYEOF'
import glob, os, sys

PACK_ROOT = sys.argv[1]
ROOT = os.path.join(PACK_ROOT, "project-template")
ALLOWLIST = os.path.join(ROOT, "scripts", ".docs-gate-allowlist.txt")

# Corpus mirror of the gate's IN set: validate-docs.sh IN_GLOBS (:108-123)
# minus EXCLUDE_BASENAMES (:124), rooted at project-template/ — plus the two
# install-overlay SOURCES (the L3 corpus amendment; kept honest against S6
# drift by L7).
IN_GLOBS = [
    "CLAUDE.md", "AGENTS.md", "GEMINI.md",
    "docs/pack/*.md",
    "docs/pack/prompts/*.md",
    "skills/*/SKILL.md",
    ".claude/agents/*.md",
    ".codex/agents/*.toml",
    ".agents-plugin/optiquity-agents/agents/*.md",
    "docs/project/backlog/_rules.md",
    "docs/project/implementation-plan/_rules.md",
    "docs/project/changelog/_rules.md",
    "docs/project/groupings/_rules.md",
]
EXCLUDE_BASENAMES = {"HELP-FRAGMENT.md", "_intro.md", "_toc.md"}

# The 2-entry install-overlay map (doc-as-installed -> pack source); L7
# tethers this set to init-project.sh S6 reality.
OVERLAY_MAP = {
    "docs/pack/METHODOLOGY.md": os.path.join(PACK_ROOT, "supporting-docs", "METHODOLOGY.md"),
    "docs/pack/INSTALL-PROCEDURES.md": os.path.join(PACK_ROOT, "supporting-docs", "INSTALL-PROCEDURES.md"),
}

if not os.path.isfile(ALLOWLIST):
    print("L3: allowlist missing: %s" % ALLOWLIST)
    sys.exit(2)

corpus = []
seen = set()
for g in IN_GLOBS:
    for p in sorted(glob.glob(os.path.join(ROOT, g))):
        if os.path.basename(p) in EXCLUDE_BASENAMES or p in seen:
            continue
        seen.add(p)
        corpus.append(p)
corpus += list(OVERLAY_MAP.values())
corpus_text = {}
for p in corpus:
    with open(p, encoding="utf-8") as fh:
        corpus_text[p] = fh.read()

# Parse with the gate's exact grammar: blank-line-separated records, '#'
# comment lines skipped, fields split on the FIRST ':'; a 'target' field
# takes precedence over doc/snippet (mirror of load_allowlist/_commit_record).
records = []
rec = {}
with open(ALLOWLIST, encoding="utf-8") as fh:
    for raw in fh:
        line = raw.rstrip("\n")
        if line.strip().startswith("#"):
            continue
        if line.strip() == "":
            if rec:
                records.append(rec)
            rec = {}
            continue
        if ":" in line:
            k, v = line.split(":", 1)
            rec[k.strip()] = v.strip()
if rec:
    records.append(rec)

if not records:
    print("L3: allowlist parse EMPTY (record grammar drift — update this leg)")
    sys.exit(2)

n_snippet = 0
n_target = 0
dead = []
for r in records:
    target = r.get("target")
    if target:
        n_target += 1
        norm = target.lstrip("./")
        if not any(norm in txt for txt in corpus_text.values()):
            dead.append("dead target: %r — no corpus doc references it" % target)
        continue
    doc, snippet = r.get("doc"), r.get("snippet")
    if not (doc and snippet):
        continue  # the gate ignores incomplete records; so do we
    n_snippet += 1
    path = os.path.join(ROOT, doc)
    if not os.path.isfile(path):
        path = OVERLAY_MAP.get(doc, "")
        if not path or not os.path.isfile(path):
            dead.append("unresolved doc: %r (absent AND unmapped)" % doc)
            continue
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    if not any(snippet in l for l in lines):
        dead.append("dead snippet: doc %r snippet %r — matches no live line" % (doc, snippet))

print("L3: %d records (%d snippet + %d target) against %d corpus docs; %d dead"
      % (len(records), n_snippet, n_target, len(corpus), len(dead)))
for d in dead:
    print("  " + d)
sys.exit(1 if dead else 0)
PYEOF
)"
l3_rc=$?
if [[ $l3_rc -eq 0 ]]; then
    pass "L3: allowlist liveness both directions ($(printf '%s' "$l3_out" | head -1 | sed 's/^L3: //'))"
else
    fail "L3: allowlist liveness" "$(printf '%s' "$l3_out" | tr '\n' '; ')"
fi

# ── L4: the gate's --self-test exits 0 ──────────────────────────────────────
l4_out="$(bash "$GATE" --self-test 2>&1)"
l4_rc=$?
if [[ $l4_rc -eq 0 ]]; then
    pass "L4: gate --self-test exits 0 (matcher<->fixture agreement + per-axis bites hold)"
else
    fail "L4: gate --self-test should exit 0, got $l4_rc" \
        "$(printf '%s' "$l4_out" | tail -5 | tr '\n' '; ')"
fi

# ── L5: install-tree full scan (the exact S6 overlay) ───────────────────────
INSTALL_ROOT="$FIXTURE_BASE/install"
mkdir -p "$INSTALL_ROOT"
cp -R "$PACK_ROOT/project-template/." "$INSTALL_ROOT/"
cp "$SRC_METH" "$SRC_INST" "$INSTALL_ROOT/docs/pack/"
l5_out="$(bash "$INSTALL_ROOT/scripts/validate-docs.sh" 2>&1)"
l5_rc=$?
n_install="$(printf '%s\n' "$l5_out" \
    | sed -n -E 's/.*scanning ([0-9]+) operating docs.*/\1/p' | head -1)"
if [[ $l5_rc -ne 0 ]]; then
    fail "L5: install-tree (S6 overlay) full scan should exit 0, got $l5_rc" \
        "$(printf '%s' "$l5_out" | grep -E '\[(history|deferred|bloat|dangling)\]|FAIL' | head -5 | tr '\n' '; ')"
elif [[ -z "$n_install" ]]; then
    fail "L5: install-tree banner parse EMPTY (banner form changed — update this leg's parse)"
elif [[ -z "$n_bare" ]]; then
    fail "L5: cannot check N_install == N_bare + 2 (L2's bare-banner parse was empty)"
elif [[ "$n_install" -eq $((n_bare + 2)) ]]; then
    pass "L5: install-tree scan exits 0 with $n_install docs == N_bare $n_bare + 2 (the S6 overlay pair)"
else
    fail "L5: install-tree doc count $n_install != N_bare $n_bare + 2" \
        "the S6 overlay changed the installed IN set — reconcile with L7's tether"
fi

# ── L6: docs<->constant heading sync (derives, never hardcodes) ─────────────
heading="$(grep -m1 -E '^TRINITY_MEMORY_HEADING = "' "$GATE" \
    | sed -E 's/^TRINITY_MEMORY_HEADING = "([^"]*)".*/\1/')"
if [[ -z "$heading" ]]; then
    fail "L6: heading parse EMPTY (gate constant form changed — update this leg's derivation)"
else
    l6_ok=1
    for f in CLAUDE.md AGENTS.md GEMINI.md; do
        if ! grep -qxF "$heading" "$PACK_ROOT/project-template/$f"; then
            fail "L6: $f lacks the gate's exact heading line '$heading' — one-sided rename (docs<->TRINITY_MEMORY_HEADING desync); rename BOTH sides in the same commit"
            l6_ok=0
        fi
    done
    if [[ $l6_ok -eq 1 ]]; then
        pass "L6: all 3 template trinity docs carry the gate's exact heading line '$heading'"
    fi
fi

# ── L7: S6 overlay-set tether ───────────────────────────────────────────────
derived="$(grep -F '$TARGET/docs/pack/' "$INIT_SCRIPT" \
    | grep -E 'supporting-docs/[A-Za-z0-9_.-]+\.md' | grep -vE '^[[:space:]]*#' \
    | sed -E 's|.*supporting-docs/([A-Za-z0-9_.-]+\.md).*|\1|' | sort -u)"
if [[ -z "$derived" ]]; then
    fail "L7: derivation EMPTY (S6 copy-line form changed — update this leg)"
elif [[ "$derived" == $'INSTALL-PROCEDURES.md\nMETHODOLOGY.md' ]]; then
    pass "L7: init-project.sh S6 overlay set == {INSTALL-PROCEDURES.md, METHODOLOGY.md} (L3 map + L5 staging stay honest)"
else
    fail "L7: init-project.sh S6 overlay set != the guard's staged/mapped set {INSTALL-PROCEDURES.md, METHODOLOGY.md} — update L3's overlay map + L5's staging cp set + this expected set in the SAME commit" \
        "derived: $(printf '%s' "$derived" | tr '\n' ' ')"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
