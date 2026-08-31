#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-docs-template-fullscan.sh —
# BD-259 standing guard: the shipped template must pass its OWN operating-doc
# gate (project-template/scripts/validate-docs.sh), on the bare template tree
# AND on the fresh-install overlay tree, and the guard's own moving parts must
# stay tethered to the surfaces they mirror.
#
# Eight legs:
#   L1  Bare-template full scan green (the BD's core guard). Runs the REAL
#       shipped gate IN PLACE, deliberately DELEGATING doc enumeration to the
#       gate itself: the gate globs the live tree, so a new not-yet-tracked
#       template doc is scanned exactly as a client install would scan it (a
#       `git ls-files` staging would silently exclude it).
#   L2  IN-set collapse floor: the gate's banner count must stay >= 90
#       (measured 118 = 46 skills + 16x3 agents + 12 prompts + 5 docs/pack +
#       3 trinity + 4 _rules.md; any >=29-doc family loss lands <= 89 and
#       trips). RESIDUAL (honest): a <= 28-doc family collapse ALONE stays
#       >= 90 and escapes this floor; L1 still polices the surviving docs.
#   L3  Allowlist liveness, BOTH directions, over the text the gate actually
#       matches on: every doc:+snippet: record must still match >= 1 live
#       line of its resolved doc (declared mapping with NO backing = dead),
#       and every target: record must still be referenced by >= 1 corpus doc
#       (allow-record for a ref nobody makes = dead). Both directions match
#       over strip_blocks() output, not raw bytes — a snippet or a reference
#       living inside a ``` fence or a DENY-LIST region is invisible to every
#       axis that consumes it, so the record clears nothing and IS dead. The
#       corpus is DERIVED from the gate (IN_GLOBS + EXCLUDE_BASENAMES +
#       strip_blocks parsed out of the shipped file at run time), never
#       hand-copied, and the derived IN set is asserted equal to the gate's
#       own L2 banner so a derivation that silently stops reproducing the
#       gate fails LOUD instead of quietly shrinking. Corpus = that IN set
#       UNION the two install-overlay sources (supporting-docs/METHODOLOGY.md
#       + supporting-docs/INSTALL-PROCEDURES.md); the union amendment is
#       sized to measured necessity: 3 of the 5 install-tree target: records
#       have ZERO bare-IN-set refs and would false-red as dead without it.
#       Five bite sub-passes prove the leg can FAIL: a DENY-LIST-region
#       snippet, a fenced snippet, the same snippet in plain prose (the
#       negative control — must PASS), a gate whose constants no longer parse,
#       and a gate whose strip_blocks parses cleanly but strips nothing (the
#       absence-of-backing case). Both degenerate derivations must fail LOUD —
#       never derive an empty set, never fall back to raw-text matching.
#       RESIDUAL (honest): the BLOAT axis is the one axis that reads RAW
#       lines, so a snippet whose ONLY job is clearing a bloat violation on a
#       trinity bullet that itself sits inside a fence or DENY-LIST region
#       would false-red here. Measured: no such record exists.
#   L4  The gate's --self-test exits 0. Honest coverage statement: this leg
#       covers matcher<->self-test-FIXTURE drift (e.g. a future hardcoded
#       heading literal in the bloat matcher) plus the per-axis bite
#       assertions. It does NOT cover a constant<->real-docs heading desync —
#       the self-test bijection leg is value-agnostic by design (matcher and
#       fixtures derive from the same constant, so both sides move together
#       under any rename). That failure mode is L6's job.
#   L5  Install-tree full scan on the CLIENT shape — the tree an install
#       actually produces, not the template's own layout. Stages the
#       init-project.sh S6 overlay (the 2 supporting-docs copied into
#       docs/pack/) AND the S4 skills fan-out: every pool skill is copied to
#       .claude/ + .codex/ + .agents/skills/<name>/SKILL.md and the root
#       skills/ pool is removed, because an install never materializes that
#       pool under the target. Asserts exit 0 AND the DERIVED relation
#           N_install == N_bare + 2*POOL + 2
#       where POOL is counted from the live tree at run time. The 2*POOL term
#       is the fan-out delta (three installed copies replace one pool copy);
#       the +2 is the S6 overlay pair. The RELATIVE form is deliberate — a
#       hard count would false-fail every legitimate template-doc addition.
#       The two DERIVED-path destructive steps in this file — this pool
#       removal and L8's per-profile S9 removals — route through
#       confined_target(), which resolves the target's PARENT with `pwd -P`
#       and refuses anything that is not a descendant of this test's canonical
#       mktemp -d root, so a symlinked or `..`-escaped component cannot reach
#       outside the fixture. A five-vector bite block asserts that gate still
#       refuses, and runs BEFORE the first delete relies on it. The file's
#       third `rm -rf` is the EXIT trap on the fixture root itself, which is
#       safe by construction and deliberately outside the gate.
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
#   L8  S9 conditional-removal profile matrix: re-run the gate on L5's
#       staged CLIENT-shaped tree once per language profile, with exactly
#       the paths stage_s9_conditional_remove() deletes for that profile
#       removed — so the matrix inherits L5's shape for free. The three
#       rosters are DERIVED from init-project.sh and asserted set-equal to
#       expected (L7's tether pattern), so an S9 roster change fails LOUD
#       instead of drifting silently, and every rostered path is asserted
#       PRESENT in the staged tree before it is deleted: a roster naming a
#       path the client shape does not carry would delete nothing and leave
#       a profile that cannot fail. The matrix runs ONLY when that tether
#       holds — a derived roster this test can no longer vouch for never
#       reaches a removal — and each removal passes confined_target() too.
#       L5 alone is structurally blind here —
#       the S6 overlay keeps every conditional file, so no reference INTO a
#       removed file can show up. Worst case is `none-detected` (a strict
#       superset of every other profile's removals), which is why all 7 run
#       rather than one.
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

# L2 floor: measured IN-set is 118 docs; any >=29-doc family loss trips.
# The floor stays 90 under the gate's UNION skill globs: the bare template
# banner is 118, comfortably clear. The UNION is what makes that true — a gate
# REPLACING the pool glob with the three client globs would scan 118-46=72 on
# the bare template, below this floor.
IN_SET_FLOOR=90

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-vdocs-fullscan.XXXXXX")"
# Canonicalise the fixture root ONCE, physically: mktemp -d inherits whatever
# TMPDIR carries (a symlinked component, a `..` segment), and every containment
# decision below compares against this value, so it must already be resolved.
#
# The emptiness test is FIRST and is load-bearing. `mktemp -d` failure leaves
# $FIXTURE_BASE empty under `set -uo pipefail` (no -e) and this script keeps
# running, and `cd ""` SUCCEEDS in bash — canonicalising an empty root would
# silently resolve it to the CALLER'S cwd (the repo), which is the one input
# that turns this test's fixture-local `rm -rf` into a live one. So an
# unusable fixture root is fatal here rather than guarded at each use site.
if [[ -n "$FIXTURE_BASE" ]]; then
    FIXTURE_BASE="$(cd -- "$FIXTURE_BASE" 2>/dev/null && pwd -P)"
fi
if [[ -z "$FIXTURE_BASE" || ! -d "$FIXTURE_BASE" ]]; then
    echo "  FAIL: fixture root: mktemp -d under TMPDIR='${TMPDIR:-/tmp}' produced no usable directory — refusing to run (every path in this test is built from it, including all three rm -rf targets)"
    echo
    echo "=== Results: 0 passed, 1 failed ==="
    exit 1
fi
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    %s\n' "$2"
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

# Confinement gate for this test's two DERIVED-path destructive steps (L5's
# skills-pool removal, L8's per-profile S9 removals): returns 0 only when $1 is
# a descendant of the canonical fixture root and is therefore safe to hand to
# `rm -rf`. Both steps route through it, so "confined to this test's own
# mktemp -d fixture" is ENFORCED in one place rather than asserted twice.
#
# The file's third `rm -rf` is the EXIT trap on $FIXTURE_BASE itself. It does
# NOT route through this gate and must not: the fixture root's own parent
# resolves outside the fixture, so the gate correctly refuses it. That trap is
# safe by construction instead — the root is validated non-empty AND -d above,
# and the trap is installed only after that validation passes.
#
# It resolves the target's PARENT and compares PHYSICAL paths, because that is
# the property that actually constrains the delete:
#   - `rm -rf` on a symlink unlinks the LINK itself, so only the DIRECTORY
#     components can reach outside the fixture — and they reach out through a
#     symlinked component and through a `..` segment alike;
#   - a lexical prefix test sees neither: inside [[ ]] the `*` in
#     "$FIXTURE_BASE"/* matches slashes, so "$FIXTURE_BASE/../elsewhere"
#     satisfies the prefix, and no string test resolves a symlink at all.
# `cd … && pwd -P` collapses both vectors into one comparison — which is also
# why the fixture root is canonicalised once above instead of compared raw.
#
# A TRAILING SLASH is REFUSED, not stripped, and that is load-bearing: the
# first bullet's premise holds only for the un-slashed form. On BSD,
# `rm -rf <symlink>/` deletes the link's TARGET DIRECTORY while `rm -rf
# <symlink>` unlinks only the link. Stripping the slash would decide on one
# string while the callers hand `rm -rf` a different one, so the thing checked
# and the thing deleted would not be the same path. Neither call site can
# produce a trailing slash, so refusing costs nothing and keeps the contract
# above true without qualification.
confined_target() {   # $1 = absolute path about to be removed
    local target="$1" leaf parent real_parent
    [[ -n "$FIXTURE_BASE" && -n "$target" ]] || return 1
    [[ "$target" != */ ]] || return 1
    leaf="${target##*/}"
    [[ -n "$leaf" && "$leaf" != "." && "$leaf" != ".." ]] || return 1
    parent="${target%/*}"
    [[ -n "$parent" ]] || parent="/"
    real_parent="$(cd -- "$parent" 2>/dev/null && pwd -P)" || return 1
    [[ -n "$real_parent" ]] || return 1
    [[ "$real_parent" == "$FIXTURE_BASE" || "$real_parent" == "$FIXTURE_BASE"/* ]]
}

# Guard: the inputs must exist (a misconfigured tree should fail loud, not
# silently pass).
for f in "$GATE" "$ALLOWLIST" "$INIT_SCRIPT" "$SRC_METH" "$SRC_INST"; do
    if [[ ! -f "$f" ]]; then
        fail "required input present" "missing: $f"
    fi
done

echo "== BD-259 standing guard: shipped template vs its own doc-gate =="

# ── Confinement-gate bite: the interlock must be able to REFUSE ─────────────
# An interlock correctly stays silent on a healthy tree, so nothing else in
# this file would notice if a refactor neutered confined_target() — every
# other predicate here carries an in-file bite, and a safety gate is the last
# one that should not. These five vectors assert the gate's decision directly,
# so forcing it to allow (or to refuse) everything reds this leg. They run
# BEFORE L5 and L8, the two steps whose deletes depend on the gate.
#
# The symlink vector points at $PACK_ROOT: it must resolve somewhere real and
# OUTSIDE the fixture, or the vector would pass for the wrong reason (a failed
# `cd` rather than a refused resolution). The link lives INSIDE the fixture and
# the EXIT trap unlinks it without following it — `rm -rf` on a directory
# unlinks the symlinks it contains rather than recursing through them.
CT_BITE_DIR="$FIXTURE_BASE/ct-bite"
mkdir -p "$CT_BITE_DIR"
ln -s "$PACK_ROOT" "$CT_BITE_DIR/ctlink"

ct_bite_ok=1
bite_ct() {   # $1 label  $2 want-rc (0 = ALLOW, 1 = REFUSE)  $3 target  $4 root to decide under
    local label="$1" want="$2" p="$3" base="$4" got
    ( FIXTURE_BASE="$base"; confined_target "$p" )
    got=$?
    if [[ "$got" -ne "$want" ]]; then
        fail "confinement bite [$label]: expected rc $want, got $got" \
            "target '$p' decided under fixture root '$base'"
        ct_bite_ok=0
    fi
}
bite_ct "a legitimate fixture path is ALLOWED"      0 "$CT_BITE_DIR/probe"          "$FIXTURE_BASE"
bite_ct "a '..' escape is REFUSED"                  1 "$CT_BITE_DIR/../../probe"    "$FIXTURE_BASE"
bite_ct "a symlinked directory component is REFUSED" 1 "$CT_BITE_DIR/ctlink/scripts" "$FIXTURE_BASE"
bite_ct "a trailing slash is REFUSED"               1 "$CT_BITE_DIR/probe/"         "$FIXTURE_BASE"
bite_ct "an empty fixture root REFUSES everything"  1 "$CT_BITE_DIR/probe"          ""
[[ $ct_bite_ok -eq 1 ]] && pass "confinement gate bites: 1 legitimate path admitted, 4 escape vectors refused ('..', symlinked component, trailing slash, empty root)"

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
# Written out once and invoked repeatedly (the real allowlist, then the bite
# fixtures below), so there is exactly ONE copy of the predicate.
#
# argv: GATE  ROOT  ALLOWLIST  EXPECT_IN_SET|""  OVERLAY_SRC...
# exit: 0 = every record live | 1 = dead record(s) / IN-set mismatch
#       2 = STRUCTURAL failure (a derivation that would otherwise go silently
#           inert: unparseable gate constants, empty corpus, unreadable input)
L3_PY="$FIXTURE_BASE/l3-liveness.py"
cat > "$L3_PY" << 'PYEOF'
import ast, glob, os, re, sys

GATE, ROOT, ALLOWLIST, EXPECT = sys.argv[1:5]
OVERLAY_SRCS = [s for s in sys.argv[5:] if s]

# ---------------------------------------------------------------------------
# DERIVE the gate's IN-set definition FROM THE SHIPPED GATE. This test keeps
# no second copy of IN_GLOBS / EXCLUDE_BASENAMES / strip_blocks. A hand-copied
# mirror is an independent encoding surface: it can disagree with the gate on
# any glob or any exclude basename and still report green, because nothing
# compares the two. Deriving collapses the two surfaces into one, so that
# disagreement has nowhere to live.
#
# Every derivation below fails LOUD (exit 2) on an empty or unparseable
# result. That is the load-bearing guard: a silently-empty IN_GLOBS would
# yield an empty corpus and make every liveness question vacuously true, and a
# silently non-stripping strip_blocks would restore exactly the raw-text match
# this leg exists to replace.
# ---------------------------------------------------------------------------
try:
    with open(GATE, encoding="utf-8") as fh:
        gate_src = fh.read()
except OSError as e:
    print("L3: cannot read the gate at %s (%s)" % (GATE, e))
    sys.exit(2)

m = re.search(r"^IN_GLOBS\s*=\s*(\[[^\]]*\])", gate_src, re.M)
if not m:
    print("L3: DERIVATION FAILED — no `IN_GLOBS = [...]` literal at line start "
          "in %s; the gate's constant form changed, so update this leg's "
          "derivation (never fall back to a hand-copy)" % GATE)
    sys.exit(2)
try:
    IN_GLOBS = ast.literal_eval(m.group(1))
except (ValueError, SyntaxError) as e:
    print("L3: DERIVATION FAILED — IN_GLOBS literal did not evaluate (%s)" % e)
    sys.exit(2)
if not isinstance(IN_GLOBS, list) or not IN_GLOBS:
    print("L3: DERIVATION EMPTY — IN_GLOBS evaluated to %r; an empty glob list "
          "would make the corpus empty and every record vacuously live" % (IN_GLOBS,))
    sys.exit(2)

m = re.search(r"^EXCLUDE_BASENAMES\s*=\s*(\{[^}]*\})", gate_src, re.M)
if not m:
    print("L3: DERIVATION FAILED — no `EXCLUDE_BASENAMES = {...}` literal at "
          "line start in %s; update this leg's derivation" % GATE)
    sys.exit(2)
try:
    EXCLUDE_BASENAMES = ast.literal_eval(m.group(1))
except (ValueError, SyntaxError) as e:
    print("L3: DERIVATION FAILED — EXCLUDE_BASENAMES did not evaluate (%s)" % e)
    sys.exit(2)
# `{}` evaluates to a DICT, not an empty set — so a set-type assertion is also
# the empty-literal guard. A genuinely empty exclusion set cannot be written in
# `{...}` form at all, so `not a set` always means the form changed.
if not isinstance(EXCLUDE_BASENAMES, set):
    print("L3: DERIVATION FAILED — EXCLUDE_BASENAMES evaluated to %r, not a "
          "set; the gate's constant form changed" % (EXCLUDE_BASENAMES,))
    sys.exit(2)

m = re.search(r"^def strip_blocks\(text\):\n(?:[ \t].*\n|\n)+", gate_src, re.M)
if not m:
    print("L3: DERIVATION FAILED — no `def strip_blocks(text):` body found in "
          "%s; update this leg's derivation" % GATE)
    sys.exit(2)
_ns = {}
try:
    exec(m.group(0), _ns)
except Exception as e:                                    # noqa: BLE001
    print("L3: DERIVATION FAILED — extracted strip_blocks did not compile (%s)" % e)
    sys.exit(2)
strip_blocks = _ns.get("strip_blocks")
if not callable(strip_blocks):
    print("L3: DERIVATION FAILED — extracted strip_blocks is not callable")
    sys.exit(2)
# Integrity probe on the DERIVED function: a truncated or refactored extraction
# that yields a pass-through would silently restore raw-text matching. KEEP
# lines must survive; FENCED and DENIED lines must be blanked.
_probe = strip_blocks(
    "KEEP-A\n```\nFENCED-B\n```\n<!-- DENY-LIST-CONTENT-START -->\n"
    "DENIED-C\n<!-- DENY-LIST-CONTENT-END -->\nKEEP-D")
if ("KEEP-A" not in _probe or "KEEP-D" not in _probe
        or any("FENCED-B" in l or "DENIED-C" in l for l in _probe)):
    print("L3: DERIVED strip_blocks DOES NOT STRIP — probe returned %r; the "
          "leg would silently degrade to raw-text matching" % (_probe,))
    sys.exit(2)

# ---------------------------------------------------------------------------
# Corpus = the derived IN set, rooted at ROOT, UNION the install-overlay
# SOURCES. The installed key is derived from each source's own basename, so
# this leg holds no overlay basename literal either; L7 tethers the source set
# itself to init-project.sh's S6 copy lines.
# ---------------------------------------------------------------------------
corpus = []
seen = set()
for g in IN_GLOBS:
    for p in sorted(glob.glob(os.path.join(ROOT, g))):
        if os.path.basename(p) in EXCLUDE_BASENAMES or p in seen:
            continue
        if not os.path.isfile(p):
            continue
        seen.add(p)
        corpus.append(p)
n_in = len(corpus)
if n_in == 0:
    print("L3: DERIVED corpus EMPTY at ROOT=%s — %d globs matched nothing; "
          "every liveness question would be vacuously true" % (ROOT, len(IN_GLOBS)))
    sys.exit(2)
# The derivation must REPRODUCE the gate, not merely parse: assert the derived
# IN set equals the gate's own banner count for the same tree.
if EXPECT and n_in != int(EXPECT):
    print("L3: derived IN set %d != the gate's own banner %d for ROOT=%s — the "
          "derivation has stopped reproducing iter_in_set() (a filter beyond "
          "IN_GLOBS/EXCLUDE_BASENAMES?); reconcile this leg with the gate"
          % (n_in, int(EXPECT), ROOT))
    sys.exit(1)

OVERLAY_MAP = {}
for src in OVERLAY_SRCS:
    if os.path.isfile(src):
        OVERLAY_MAP["docs/pack/" + os.path.basename(src)] = src

if not os.path.isfile(ALLOWLIST):
    print("L3: allowlist missing: %s" % ALLOWLIST)
    sys.exit(2)

# Every corpus doc as the gate sees it: strip_blocks output, not raw bytes.
corpus_stripped = {}
for p in corpus + sorted(OVERLAY_MAP.values()):
    with open(p, encoding="utf-8") as fh:
        corpus_stripped[p] = "\n".join(strip_blocks(fh.read()))

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
        norm = target[2:] if target.startswith("./") else target
        # The DANGLING axis reads strip_blocks output, so a reference that
        # only ever appears inside a fence or a DENY-LIST region raises no
        # violation and the target: record clears nothing.
        if not any(norm in txt for txt in corpus_stripped.values()):
            dead.append("dead target: %r — no corpus doc references it outside "
                        "a ``` fence / DENY-LIST region" % target)
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
        lines = strip_blocks(fh.read())
    if not any(snippet in l for l in lines):
        dead.append("dead snippet: doc %r snippet %r — matches no line the gate "
                    "actually scans (inside a ``` fence or a DENY-LIST region, "
                    "so it clears nothing)" % (doc, snippet))

print("L3: %d records (%d snippet + %d target) against %d corpus docs "
      "(%d derived IN + %d overlay; %d globs / %d excludes derived from the "
      "gate); %d dead"
      % (len(records), n_snippet, n_target, len(corpus_stripped), n_in,
         len(corpus_stripped) - n_in, len(IN_GLOBS), len(EXCLUDE_BASENAMES),
         len(dead)))
for d in dead:
    print("  " + d)
sys.exit(1 if dead else 0)
PYEOF

l3_out="$(python3 "$L3_PY" "$GATE" "$PACK_ROOT/project-template" "$ALLOWLIST" \
    "$n_bare" "$SRC_METH" "$SRC_INST" 2>&1)"
l3_rc=$?
# The derived-IN-vs-banner tether is armed only when $n_bare parsed. If L2's
# parse came up empty the tether ran INERT — the derivation could have stopped
# reproducing iter_in_set() entirely and this leg would still print `pass`,
# quoting a derived-IN count that nothing compared. A real dead-record failure
# is still the more specific answer, so it is reported first.
if [[ $l3_rc -ne 0 ]]; then
    fail "L3: allowlist liveness" "$(printf '%s' "$l3_out" | tr '\n' '; ')"
elif [[ -z "$n_bare" ]]; then
    fail "L3: refusing to pass — L2's bare-banner parse was empty, so the derived-IN-set tether ran DISARMED and this leg proved only that no record is dead; fix L2's parse, then re-run"
else
    pass "L3: allowlist liveness both directions ($(printf '%s' "$l3_out" | head -1 | sed 's/^L3: //'))"
fi

# ── L3 bite: the leg must be able to FAIL ───────────────────────────────────
# A liveness predicate that cannot red is not a guard. Five fixtures, all
# inside this test's own mktemp -d: a DENY-LIST-region snippet, a fenced
# snippet, the SAME snippet in plain prose as the negative control, and two
# gates whose derivation must fail LOUD rather than go inert.
#
# The DENY-LIST fixture is the one that cannot be dropped: fences and
# DENY-LIST regions are independent blanking mechanisms, and 2 of the 8 shipped
# docs that carry a DENY-LIST region contain no fence at all, so a fence-only
# fixture would leave the deny-list path unexercised on exactly those docs.
BITE_DIR="$FIXTURE_BASE/l3-bite"
BITE_TOKEN="ZZ-L3-BITE-SENTINEL"
mkdir -p "$BITE_DIR/deny" "$BITE_DIR/fence" "$BITE_DIR/plain"

{ echo "# L3 bite fixture"
  echo "<!-- DENY-LIST-CONTENT-START -->"
  echo "$BITE_TOKEN"
  echo "<!-- DENY-LIST-CONTENT-END -->"; } > "$BITE_DIR/deny/CLAUDE.md"
{ echo "# L3 bite fixture"
  echo '```'
  echo "$BITE_TOKEN"
  echo '```'; } > "$BITE_DIR/fence/CLAUDE.md"
{ echo "# L3 bite fixture"
  echo "$BITE_TOKEN"; } > "$BITE_DIR/plain/CLAUDE.md"
for v in deny fence plain; do
    { echo "doc: CLAUDE.md"
      echo "snippet: $BITE_TOKEN"
      echo "reason: L3 bite fixture"; } > "$BITE_DIR/$v/allow.txt"
done

# A gate with NO parseable constants, and a gate whose strip_blocks is a
# pass-through (parses fine, strips nothing — the absence-of-backing case).
echo "# a gate that declares no IN_GLOBS" > "$BITE_DIR/gate-noconst.sh"
{ echo 'IN_GLOBS = ["CLAUDE.md"]'
  echo 'EXCLUDE_BASENAMES = {"_toc.md"}'
  echo 'def strip_blocks(text):'
  echo '    return text.splitlines()'; } > "$BITE_DIR/gate-nostrip.sh"

l3_bite_ok=1
bite_l3() {   # $1 label  $2 expected-rc  $3 gate  $4 root  $5 allowlist
    local label="$1" want="$2" bgate="$3" broot="$4" ballow="$5" bout brc
    bout="$(python3 "$L3_PY" "$bgate" "$broot" "$ballow" "" 2>&1)"
    brc=$?
    if [[ "$brc" -ne "$want" ]]; then
        fail "L3 bite [$label]: expected rc $want, got $brc" \
            "$(printf '%s' "$bout" | tr '\n' '; ')"
        l3_bite_ok=0
    fi
}
bite_l3 "DENY-LIST-region snippet is DEAD"        1 "$GATE" "$BITE_DIR/deny"  "$BITE_DIR/deny/allow.txt"
bite_l3 "fenced snippet is DEAD"                  1 "$GATE" "$BITE_DIR/fence" "$BITE_DIR/fence/allow.txt"
bite_l3 "plain-prose snippet is LIVE (control)"   0 "$GATE" "$BITE_DIR/plain" "$BITE_DIR/plain/allow.txt"
bite_l3 "unparseable gate constants fail LOUD"    2 "$BITE_DIR/gate-noconst.sh" "$BITE_DIR/plain" "$BITE_DIR/plain/allow.txt"
bite_l3 "non-stripping strip_blocks fails LOUD"   2 "$BITE_DIR/gate-nostrip.sh" "$BITE_DIR/plain" "$BITE_DIR/plain/allow.txt"
[[ $l3_bite_ok -eq 1 ]] && pass "L3 bite: all 5 fixtures behave (deny-list + fenced snippets red; the same snippet in prose stays green; both degenerate derivations fail loud)"

# ── L4: the gate's --self-test exits 0 ──────────────────────────────────────
l4_out="$(bash "$GATE" --self-test 2>&1)"
l4_rc=$?
if [[ $l4_rc -eq 0 ]]; then
    pass "L4: gate --self-test exits 0 (matcher<->fixture agreement + per-axis bites hold)"
else
    fail "L4: gate --self-test should exit 0, got $l4_rc" \
        "$(printf '%s' "$l4_out" | tail -5 | tr '\n' '; ')"
fi

# ── L5: install-tree full scan (the CLIENT shape) ───────────────────────────
# The shape an install actually produces, not the template's own layout: the
# S6 overlay (2 supporting-docs into docs/pack/) AND the S4 skills fan-out
# (stage_s4_skills in scripts/init-project.sh — cited by SYMBOL, line numbers
# drift). S4 copies each pool skill to .claude/ + .codex/ + .agents/ and never
# materializes the pool itself under the target, so the staged tree drops it.
INSTALL_ROOT="$FIXTURE_BASE/install"
mkdir -p "$INSTALL_ROOT"
cp -R "$PACK_ROOT/project-template/." "$INSTALL_ROOT/"
cp "$SRC_METH" "$SRC_INST" "$INSTALL_ROOT/docs/pack/"

# POOL is counted from the LIVE tree, never hardcoded — it is the term that
# scales the fan-out below and the expected count further down. It counts
# SKILL.md FILES, not directories, because that is what the gate's
# `skills/*/SKILL.md` glob counts: a skill directory carrying no SKILL.md is
# absent from BOTH banners, so counting it would inflate the 2*POOL term by 2
# with no matching movement in the observed count — a gap no message could
# explain.
#
# The loop still iterates DIRECTORIES, exactly as stage_s4_skills() does, so
# the two counts can be compared. stage_s4_skills() copies SKILL.md
# unconditionally after its `[[ -d ]]` test, so a SKILL.md-less skill directory
# BREAKS a real install; skipping it silently would let this leg stay green
# over a tree state the thing it models cannot survive.
pool_dirs=0
pool_count=0
for skill_dir in "$INSTALL_ROOT/skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    pool_dirs=$((pool_dirs + 1))
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    skill_name="$(basename "$skill_dir")"
    for tool in claude codex agents; do
        mkdir -p "$INSTALL_ROOT/.${tool}/skills/$skill_name"
        cp "$skill_dir/SKILL.md" "$INSTALL_ROOT/.${tool}/skills/$skill_name/SKILL.md"
    done
    pool_count=$((pool_count + 1))
done
if [[ "$pool_dirs" -ne "$pool_count" ]]; then
    fail "L5: $pool_dirs skill directories but $pool_count carry SKILL.md — stage_s4_skills() iterates directories and copies SKILL.md unconditionally, so the difference breaks a real install; POOL counts files (the gate's skills/*/SKILL.md glob) and cannot absorb it"
fi

# Remove the pool — the one destructive step in this leg. It goes through the
# shared confinement gate (which is where the non-empty, no-`..`, no-symlink
# and inside-the-fixture properties are actually decided); `:?` stays as the
# expansion-time backstop for an unset variable.
if confined_target "$INSTALL_ROOT/skills"; then
    rm -rf "${INSTALL_ROOT:?}/skills"
else
    fail "L5: refusing to remove the skills pool — '$INSTALL_ROOT/skills' does not resolve to a descendant of this test's fixture root '$FIXTURE_BASE' (empty, symlinked, or '..'-escaped path)"
fi

if [[ "$pool_count" -eq 0 ]]; then
    fail "L5: S4 fan-out staged 0 skills (project-template/skills/*/ empty or renamed) — the client shape would be indistinguishable from the template shape and this leg would prove nothing"
fi

l5_out="$(bash "$INSTALL_ROOT/scripts/validate-docs.sh" 2>&1)"
l5_rc=$?
n_install="$(printf '%s\n' "$l5_out" \
    | sed -n -E 's/.*scanning ([0-9]+) operating docs.*/\1/p' | head -1)"
# N_install == N_bare + 2*POOL + 2 — every term DERIVED. The 2*POOL term is the
# fan-out delta (three installed copies replace the one pool copy the bare
# banner counted); the +2 is the S6 overlay pair.
if [[ -n "$n_bare" && "$pool_count" -gt 0 ]]; then
    n_expect=$((n_bare + 2 * pool_count + 2))
else
    n_expect=""
fi
if [[ $l5_rc -ne 0 ]]; then
    fail "L5: client-shape (S4 fan-out + S6 overlay) full scan should exit 0, got $l5_rc" \
        "$(printf '%s' "$l5_out" | grep -E '\[(history|deferred|bloat|dangling)\]|FAIL' | head -5 | tr '\n' '; ')"
elif [[ -z "$n_install" ]]; then
    fail "L5: client-shape banner parse EMPTY (banner form changed — update this leg's parse)"
elif [[ -z "$n_expect" ]]; then
    fail "L5: cannot check the derived relation (N_bare='$n_bare', POOL=$pool_count — one of the two derivations came up empty)"
elif [[ "$n_install" -eq "$n_expect" ]]; then
    pass "L5: client-shape scan exits 0 with $n_install docs == N_bare $n_bare + 2*POOL $pool_count + 2 (S4 fan-out delta + the S6 overlay pair)"
else
    fail "L5: client-shape doc count $n_install != expected $n_expect" \
        "N_bare=$n_bare POOL=$pool_count expected=N_bare+2*POOL+2=$n_expect observed=$n_install — either the S4 fan-out arity changed (stage_s4_skills), or the S6 overlay changed the installed IN set (reconcile with L7's tether), or the gate's skill globs stopped covering both tree shapes"
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

# ── L8: S9 conditional-removal install-profile matrix ───────────────────────
# L5 measures the S6 overlay, which KEEPS every conditional file — so it is
# structurally blind to any reference INTO a file S9 removes. This leg copies
# L5's staged $INSTALL_ROOT once per language profile, deletes exactly the
# paths stage_s9_conditional_remove() (scripts/init-project.sh) names for that
# profile, and asserts the shipped gate still exits 0.
#
# The three rosters are DERIVED from stage_s9_conditional_remove() in
# scripts/init-project.sh at run time, then asserted set-equal to the expected
# sets below -- the same derive-and-tether pattern L7 uses 12 lines earlier.
# Hardcoding alone would drift silently: if S9 gained a removal path, a
# hardcoded roster would keep deleting the old set and stay green. With the
# derivation, an S9 roster change fails LOUD here, and an empty derivation
# (the copy-line form changed) fails LOUD too rather than silently removing
# nothing.
#
# Worst case is `none-detected`, not `python-only`: none-detected removes
# python ∪ swift ∪ proto, a strict SUPERSET of python-only's swift ∪ proto,
# and at least one live reference targets a python-set path.
S9_PY_EXPECTED="pyproject.toml pyrightconfig.json scripts/bootstrap-python.sh scripts/format-python.sh scripts/test-python.sh scripts/validate-python.sh server"
S9_SW_EXPECTED="scripts/bootstrap-swift.sh scripts/format-swift.sh scripts/test-swift.sh scripts/validate-swift.sh"
S9_PR_EXPECTED="proto scripts/proto-gen.sh scripts/validate-proto.sh"

# Extract one language block's removal roster from stage_s9_conditional_remove:
# the `for f in ... ; do` list (with backslash continuations) PLUS the
# `[[ -d "$TARGET/<dir>" ]]` directory special-cases. Sorted + deduped so the
# comparison is order-insensitive.
derive_s9_set() {
    awk -v want="$1" '
        /^stage_s9_conditional_remove\(\)/ { inf = 1 }
        inf && /^\}/                       { inf = 0 }
        !inf { next }
        /if \(\( has_python == 0 \)\)/  { blk = "py"; inlist = 0; next }
        /if \(\( has_swift  *== 0 \)\)/ { blk = "sw"; inlist = 0; next }
        /if \(\( has_proto  *== 0 \)\)/ { blk = "pr"; inlist = 0; next }
        blk != "" && (inlist || /for f in/) {
            line = $0
            sub(/^.*for f in /, "", line)
            sub(/;[ \t]*do.*/, "", line)
            gsub(/\\/, "", line)
            n = split(line, a, /[ \t]+/)
            for (i = 1; i <= n; i++) if (a[i] != "" && blk == want) print a[i]
            inlist = ($0 ~ /\\[ \t]*$/) ? 1 : 0
            next
        }
        blk == want && /\[\[ -d "\$TARGET\// {
            if (match($0, /\$TARGET\/[A-Za-z0-9_.-]+/))
                print substr($0, RSTART + 8, RLENGTH - 8)
        }
    ' "$INIT_SCRIPT" | sort -u | tr '\n' ' ' | sed 's/ $//'
}

S9_PY_SET="$(derive_s9_set py)"
S9_SW_SET="$(derive_s9_set sw)"
S9_PR_SET="$(derive_s9_set pr)"

s9_tether_ok=1
for pair in "py:$S9_PY_SET:$S9_PY_EXPECTED" "sw:$S9_SW_SET:$S9_SW_EXPECTED" "pr:$S9_PR_SET:$S9_PR_EXPECTED"; do
    tag="${pair%%:*}"
    rest="${pair#*:}"
    got="${rest%%:*}"
    want="${rest#*:}"
    if [[ -z "$got" ]]; then
        fail "L8: S9 roster derivation EMPTY for '$tag' (stage_s9_conditional_remove's removal-line form changed — update derive_s9_set)"
        s9_tether_ok=0
    elif [[ "$got" != "$want" ]]; then
        fail "L8: S9 roster for '$tag' derived from init-project.sh != this test's expected set — reconcile BOTH in the same commit" \
            "derived: $got | expected: $want"
        s9_tether_ok=0
    fi
done
[[ $s9_tether_ok -eq 1 ]] && pass "L8 tether: all 3 S9 rosters derived from stage_s9_conditional_remove() match the expected sets (a roster change fails loud here)"

l8_fails=0
run_profile() {
    prof="$1"
    removals="$2"
    pdir="$FIXTURE_BASE/s9-$prof"
    cp -R "$INSTALL_ROOT" "$pdir"
    for rel in $removals; do
        # A rostered path that does not EXIST in the client shape removes
        # nothing, leaving a profile that cannot fail. Assert the deletion is
        # load-bearing before performing it — the S4 fan-out reshapes the tree,
        # so this is not a standing given.
        if [[ ! -e "$pdir/$rel" ]]; then
            l8_fails=$((l8_fails + 1))
            fail "L8[$prof]: S9 roster names '$rel' but the client-shaped tree does not carry it — the removal is a no-op and this profile proves nothing; reconcile stage_s9_conditional_remove() with the installed shape"
            continue
        fi
        # $rel is DERIVED (awk over init-project.sh), so it is the least
        # trustworthy component of any path this test deletes: the derivation's
        # character class admits `..`, and a `-e` test passes on a traversal.
        # Same gate as L5's, for the same reason.
        if ! confined_target "$pdir/$rel"; then
            l8_fails=$((l8_fails + 1))
            fail "L8[$prof]: refusing to remove roster path '$rel' — '$pdir/$rel' does not resolve to a descendant of this test's fixture root '$FIXTURE_BASE'; a derived roster must never reach outside the fixture"
            continue
        fi
        rm -rf "${pdir:?}/$rel"
    done
    pout="$(bash "$pdir/scripts/validate-docs.sh" 2>&1)"
    prc=$?
    if [[ $prc -ne 0 ]]; then
        l8_fails=$((l8_fails + 1))
        fail "L8[$prof]: install profile should exit 0, got $prc" \
            "$(printf '%s' "$pout" | grep -E '\[(history|deferred|bloat|dangling)\]' | head -5 | tr '\n' '; ')"
    fi
}

if [[ $s9_tether_ok -ne 1 ]]; then
    # The rosters DRIVE the removals below. A derivation this test has just
    # failed to vouch for must not reach `rm -rf`, and a matrix run on a
    # drifted roster would model no install anyone can ship.
    fail "L8: S9 roster tether failed — refusing to run the profile matrix (its removals are driven by the derived rosters; fix the derivation or the expected sets, then re-run)"
elif [[ -d "$INSTALL_ROOT" ]]; then
    run_profile keepall ""
    run_profile swift-only "$S9_PY_SET $S9_PR_SET"
    run_profile python-only "$S9_SW_SET $S9_PR_SET"
    run_profile swift-py "$S9_PR_SET"
    run_profile py-proto "$S9_SW_SET"
    run_profile swift-proto "$S9_PY_SET"
    run_profile none-detected "$S9_PY_SET $S9_SW_SET $S9_PR_SET"
    if [[ $l8_fails -eq 0 ]]; then
        pass "L8: all 7 S9 language profiles scan clean (a reference into a conditionally-removed file would red the worst-case none-detected profile)"
    fi
else
    fail "L8: L5's \$INSTALL_ROOT was never staged — cannot run the S9 profile matrix"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
