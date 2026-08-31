#!/usr/bin/env bash
# scripts/tests/test-pack-provenance-keys.sh — tests for PER-KEY pack
# provenance (`scripts/lib/pack_provenance_keys.py`) and its two consumers,
# `scripts/merge-json.py` and `scripts/merge-toml.py`.
#
# WHAT IS UNDER TEST, AND WHY IT EXISTS
#
# `--update` reaches a structured file with NO recorded BASE. A BASE-less
# three-way cannot tell a stale PACK value from a CLIENT edit: `merge_dict`'s
# "both added with different values" arm keeps the project value wholesale and
# never recurses, so a client who edited ANY key freezes EVERY diverged pack
# key in that file — including keys they never touched. The measured shape is a
# client whose `env` and `permissions` are customised and whose `hooks` is a
# verbatim older pack value: the pack's new `hooks` entry never arrives, on any
# number of runs. The per-key derivation supplies the missing ancestor.
#
# Coverage:
#   Group A — derive_base UNIT (pure data, no git)
#     A1  PASS  : selection prefers the candidate that best explains OURS
#     A2p PASS  : A2's PREMISE — selection alone gives the WRONG answer on
#                 A2's fixture, so A2 cannot pass for the wrong reason
#     A2  PASS  : refinement adopts OURS's value where the pack has held it,
#                 which is what lets the pack's new key arrive
#     A3  PASS  : ties resolve to the OLDEST candidate
#     A4  SPARE : a list element in a NON-selected candidate is never promoted
#                 into the derived BASE (promoting one would silently DELETE a
#                 value the client still holds)
#     A5  PASS  : no candidates -> None (caller keeps base-absent behaviour)
#     A6p PASS  : A6's PREMISE — the SELECTED ancestor really does lack the key
#     A6  PASS  : a key OURS holds that the SELECTED ancestor LACKS is still
#                 refined, so it reaches the BASE instead of freezing
#     A7  SPARE : a client-added SUBTREE no candidate ever held stays ABSENT
#                 from the BASE (an empty ancestor would read as a pack removal)
#     A8  SPARE : the same for a client-added scalar
#     A9  SPARE : a LIST at a key the SELECTED ancestor lacks is never pulled
#                 in from a lower-scoring candidate
#   Group B — merge-json.py INTEGRATION against a scratch git pack
#     B1 PASS  : the pack's new key ARRIVES and every client edit survives, rc 0
#     B2 PASS  : idempotent — re-running on the merged output is a clean no-op
#     B3 BITE  : the SAME inputs WITHOUT the flags freeze the key (rc 2), so
#                the flags are proved load-bearing rather than decorative
#     B4 SPARE : an EXPLICIT positional BASE wins; the derivation never
#                overrides the migrator's recorded ancestor
#     B5 SPARE : an unusable pack root degrades to base-absent, never crashes
#     B6 PASS  : A6's shape END-TO-END — the key the SELECTED ancestor lacks
#                arrives at rc 0 where it used to freeze at rc 2
#   Group C — merge-toml.py INTEGRATION (the same contract, TOML parser)
#     C1 PASS  : the pack's new table key arrives; the client's edit survives
#     C2 BITE  : without the flags the same key freezes
#   Group D — MUTATION: refinement proved load-bearing, in-suite, every run
#     D0-D3    : `_refine` neutered to selection-only must CHANGE the derived
#                BASE, and restoring it must restore the answer
#   Group E — the removal-disclosure contract
#     E1-E3    : the drop census counts dict keys and list elements, and a
#                clean merge stays silent
#     E4-E5    : the count line the helper emits is the one
#                customization-preserve.sh extracts (pinned from BOTH ends)
#
# WHY GROUP D EXISTS AS A TEST RATHER THAN AS A REVIEW NOTE
#
# An earlier revision of this suite passed 21/21 with refinement removed
# entirely: every assertion that named refinement was decided by SELECTION,
# because its fixture was not tied. A guard that cannot fail on the mechanism
# it names is worth nothing, and "the fixture is discriminating" is an
# invariant that quietly rots as fixtures get edited. Group D removes the
# judgement call — it performs the mutation and asserts the answer moves, so
# the suite re-proves its own bite on every run.
#
# Per "Test infra is self-provisioned": every git repo here is created under
# `mktemp -d` and removed on exit. The REAL tree is never mutated. This test is
# NOT fixture-dependent (it reads no built `test-fixtures/<NAME>` directory).
#
# Usage: bash scripts/tests/test-pack-provenance-keys.sh
# Exit 0 on all pass; exit 1 on any failure.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB="$REPO_ROOT/scripts/lib"
MERGE_JSON="$REPO_ROOT/scripts/merge-json.py"
MERGE_TOML="$REPO_ROOT/scripts/merge-toml.py"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}
t_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "want [$2] got [$3]"; fi
}

TMPOUT="$(mktemp -d "${TMPDIR:-/tmp}/ppk.XXXXXX")"
cleanup() { rm -rf "$TMPOUT"; }
trap cleanup EXIT

# ─────────────────────────────────────────────────────────────────
# Group A: derive_base unit behaviour (pure data, no git)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group A: derive_base unit ===\n"

a_out="$TMPOUT/groupA.txt"
python3 - "$LIB" > "$a_out" 2>&1 <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from pack_provenance_keys import derive_base, _score

# Candidates are OLDEST-FIRST, as historical_docs returns them.
old = {"env": {"A": "", "B": "pack"}, "hooks": {"Post": ["x"]},
       "allow": ["p1", "p2"]}
new = {"env": {"A": "", "B": "pack2"}, "hooks": {"Post": ["x"], "Pre": ["y"]},
       "allow": ["p1", "p2", "p3"]}

# A1 — the measured client shape: env edited, hooks a verbatim OLD pack value.
ours = {"env": {"A": "client", "B": "pack"}, "hooks": {"Post": ["x"]},
        "allow": ["p1", "p2", "mine"]}
base = derive_base(ours, [old, new])
# A1: selection preferred `old` (it explains ours better than `new` does).
print("A1", base["env"]["B"] == "pack")

# A2 — REFINEMENT, on a fixture only refinement can answer.
#
# The fixture is built so SELECTION gives the WRONG value at the probed key.
# `r_old` wins selection on the four `bulk` leaves, but its `hooks` is NOT
# ours's — ours's `hooks` is a verbatim `r_mid` value. So the BASE holds ours's
# `hooks` only if step 2 walked the key and adopted it; selection alone yields
# `r_old`'s. (The previous fixture here was decided by selection, which left
# this assertion unable to fail on refinement at all. Group D now proves the
# distinction by mutation instead of trusting this comment.)
r_old = {"bulk": {"k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4"},
         "hooks": {"Post": ["OLD"]}}
r_mid = {"bulk": {"k1": "z1", "k2": "z2", "k3": "z3", "k4": "z4"},
         "hooks": {"Post": ["MID"]}}
r_ours = {"bulk": {"k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4"},
          "hooks": {"Post": ["MID"]}}
# A2p: the PREMISE — selection picks r_old, and r_old is wrong at `hooks`.
print("A2p", _score(r_ours, r_old) > _score(r_ours, r_mid)
      and r_old["hooks"] != r_ours["hooks"])
r_base = derive_base(r_ours, [r_old, r_mid])
# A2: only refinement can put ours's `hooks` value into the ancestor, which is
#     what makes the merge read a pack change there as an update to deliver.
print("A2", r_base["hooks"] == {"Post": ["MID"]})

# A3 — a genuine tie must resolve to the OLDEST candidate.
tie_old = {"k": "same", "marker": "OLD"}
tie_new = {"k": "same", "marker": "NEW"}
tb = derive_base({"k": "same"}, [tie_old, tie_new])
print("A3", tb["marker"] == "OLD")

# A4 — `mine` is a client-added list element. A LOWER-scoring candidate that
#      happens to contain it must NOT pull it into the BASE: merge_list reads a
#      BASE-only element as a project removal, so a cross-candidate promotion
#      would silently DROP a value the client still holds. Only the SELECTED
#      ancestor's list may appear.
other = {"env": {"A": "zzz", "B": "zzz"}, "hooks": {"Zed": ["q"]},
         "allow": ["mine"]}
b4 = derive_base(ours, [other, old, new])
print("A4", "mine" not in b4["allow"])

# A5 — nothing to derive from.
print("A5", derive_base(ours, []) is None)

# A6 — a key OURS holds that the SELECTED ancestor does NOT.
#      `u_old` wins selection on `bulk` and PREDATES `hooks` entirely, while
#      ours carries a verbatim `u_mid` `hooks`. Refining only the selected
#      ancestor's own keys never visits `hooks`, so it never reaches the BASE
#      and the merge falls back to "both added with different values -> keep
#      project value" — the exact freeze this module exists to close, at rc 2
#      with a sidecar. B6 runs this same shape end-to-end.
u_old = {"bulk": {"k%d" % i: "v%d" % i for i in range(10)}}
u_mid = {"bulk": {"k%d" % i: "m%d" % i for i in range(10)},
         "hooks": {"Post": ["x"]}}
u_ours = {"bulk": {"k%d" % i: "v%d" % i for i in range(10)},
          "hooks": {"Post": ["x"]}}
# A6p: the PREMISE — the selected ancestor really is the one WITHOUT the key.
print("A6p", "hooks" not in u_old
      and _score(u_ours, u_old) > _score(u_ours, u_mid))
u_base = derive_base(u_ours, [u_old, u_mid])
print("A6", u_base.get("hooks") == {"Post": ["x"]})

# A7 — the union walk must not INVENT an ancestor. A subtree no candidate has
#      ever held is a genuine client addition: it stays ABSENT from the BASE,
#      because recording an empty ancestor would make the three-way read it as
#      "the pack removed everything here".
c_ours = dict(u_ours, mine={"deep": ["client-only"]})
print("A7", "mine" not in derive_base(c_ours, [u_old, u_mid]))

# A8 — the same for a client-added scalar.
s_ours = dict(u_ours, my_scalar="client-only")
print("A8", "my_scalar" not in derive_base(s_ours, [u_old, u_mid]))

# A9 — the A4 rule, at a key the SELECTED ancestor lacks. A lower-scoring
#      candidate holds a SUBSET of ours's list; it must NOT become the
#      ancestor, or merge_list would read ours's extra element as a project
#      removal and drop a value the client still holds.
l_ours = dict(u_ours, allow=["p1", "p2", "mine"])
l_other = {"bulk": {}, "allow": ["p1", "p2"]}
print("A9", "allow" not in derive_base(l_ours, [u_old, l_other, u_mid]))
PY

while read -r name got; do
    t_eq "A: $name" "True" "$got"
done < <(grep -E '^A[0-9]p? ' "$a_out")
if ! grep -qE '^A9 ' "$a_out"; then
    t_fail "Group A did not run to completion" "$(tail -5 "$a_out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group B: merge-json.py integration against a scratch git pack
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group B: merge-json.py integration ===\n"

PACKR="$TMPOUT/pack"
SRC_REL="project-template/.claude/settings.json"
mkdir -p "$PACKR/project-template/.claude"
(
  cd "$PACKR" || exit 1
  git init -q .
  git config user.email t@t; git config user.name t
) >/dev/null 2>&1

# v1 — the release the client installed from.
cat > "$PACKR/$SRC_REL" <<'JSON'
{
  "env": {"XCODE_SCHEME": "", "AGENT_CAPABILITIES": "planning"},
  "permissions": {"allow": ["p1", "p2"]},
  "hooks": {"Post": [{"matcher": "Edit"}]}
}
JSON
( cd "$PACKR" && git add -A && git commit -qm v1 ) >/dev/null 2>&1

# HEAD — adds a hooks key and an allow entry (the update that must arrive).
cat > "$PACKR/$SRC_REL" <<'JSON'
{
  "env": {"XCODE_SCHEME": "", "AGENT_CAPABILITIES": "planning"},
  "permissions": {"allow": ["p1", "p2", "p3"]},
  "hooks": {"Post": [{"matcher": "Edit"}], "Pre": [{"matcher": "Agent"}]}
}
JSON
( cd "$PACKR" && git add -A && git commit -qm head ) >/dev/null 2>&1

# OURS — the v1 blob plus ordinary client customisation in env + permissions.
# `hooks` is UNTOUCHED and therefore a verbatim v1 pack value: the key the
# client is missing is NOT the key the client edited, which is the whole point.
OURS="$TMPOUT/ours.json"
cat > "$OURS" <<'JSON'
{
  "env": {"XCODE_SCHEME": "my-scheme", "AGENT_CAPABILITIES": "planning"},
  "permissions": {"allow": ["p1", "p2", "client-tool"]},
  "hooks": {"Post": [{"matcher": "Edit"}]}
}
JSON

probe() {  # probe <merged-json> — emit "<hasPre> [<scheme>] <allow-csv>"
    # The scheme is bracketed because one expected value is the EMPTY string
    # (B4), and a bare empty field would collapse under `read`'s whitespace
    # splitting — shifting every later field and making the assertion compare
    # the wrong values.
    python3 - "$1" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print("Pre" in d.get("hooks", {}),
      "[" + d["env"]["XCODE_SCHEME"] + "]",
      ",".join(d["permissions"]["allow"]))
PY
}

# B1 — with the derivation.
B1="$TMPOUT/b1.json"; rc=0
python3 "$MERGE_JSON" "" "$OURS" "$PACKR/$SRC_REL" --output "$B1" \
    --pack-authored-base "$PACKR" --pack-source "$SRC_REL" \
    > "$TMPOUT/b1.err" 2>&1 || rc=$?
t_eq "B1 rc is 0 (clean merge, so no sidecar and no reconciliation loop)" "0" "$rc"
read -r b1_pre b1_scheme b1_allow <<< "$(probe "$B1")"
t_eq "B1 the pack's new hooks key ARRIVES" "True" "$b1_pre"
t_eq "B1 the client's env edit survives" "[my-scheme]" "$b1_scheme"
t_eq "B1 allow keeps the client entry AND gains the pack entry" \
    "p1,p2,p3,client-tool" "$b1_allow"

# B2 — idempotence: feed the merged output back in.
B2="$TMPOUT/b2.json"; rc=0
python3 "$MERGE_JSON" "" "$B1" "$PACKR/$SRC_REL" --output "$B2" \
    --pack-authored-base "$PACKR" --pack-source "$SRC_REL" \
    > "$TMPOUT/b2.err" 2>&1 || rc=$?
t_eq "B2 second pass rc is 0" "0" "$rc"
t_eq "B2 second pass is byte-identical to the first (converged)" \
    "same" "$(cmp -s "$B1" "$B2" && echo same || echo differ)"

# B3 — BITE: identical inputs, flags REMOVED. The guard must be load-bearing.
B3="$TMPOUT/b3.json"; rc=0
python3 "$MERGE_JSON" "" "$OURS" "$PACKR/$SRC_REL" --output "$B3" \
    > "$TMPOUT/b3.err" 2>&1 || rc=$?
t_eq "B3 BITE: without the derivation the merge warns (rc 2 -> sidecar)" "2" "$rc"
read -r b3_pre _ _ <<< "$(probe "$B3")"
t_eq "B3 BITE: without the derivation the pack's new key does NOT arrive" \
    "False" "$b3_pre"

# B4 — SPARE: an EXPLICIT base must win over the derivation. This base claims
# the client's own value as the ancestor, so a correct three-way takes THEIRS
# at that key; the derived base would have kept OURS. The two answers differ,
# which is what makes the assertion able to detect an override.
EXPL="$TMPOUT/explicit-base.json"
cat > "$EXPL" <<'JSON'
{
  "env": {"XCODE_SCHEME": "my-scheme", "AGENT_CAPABILITIES": "planning"},
  "permissions": {"allow": ["p1", "p2", "client-tool"]},
  "hooks": {"Post": [{"matcher": "Edit"}]}
}
JSON
B4="$TMPOUT/b4.json"
python3 "$MERGE_JSON" "$EXPL" "$OURS" "$PACKR/$SRC_REL" --output "$B4" \
    --pack-authored-base "$PACKR" --pack-source "$SRC_REL" \
    > "$TMPOUT/b4.err" 2>&1
read -r _ b4_scheme _ <<< "$(probe "$B4")"
t_eq "B4 SPARE: the explicit positional BASE wins over the derivation" \
    "[]" "$b4_scheme"

# B5 — SPARE: an unusable pack root degrades to base-absent, never rc 1.
B5="$TMPOUT/b5.json"; rc=0
python3 "$MERGE_JSON" "" "$OURS" "$PACKR/$SRC_REL" --output "$B5" \
    --pack-authored-base "$TMPOUT/definitely-not-a-repo" --pack-source "$SRC_REL" \
    > "$TMPOUT/b5.err" 2>&1 || rc=$?
t_eq "B5 SPARE: an unusable pack root degrades (rc 2), it does not error (rc 1)" \
    "2" "$rc"
t_eq "B5 SPARE: output was still produced" \
    "yes" "$([ -s "$B5" ] && echo yes || echo no)"

# B6 — A6's shape END-TO-END: the client best matches an ancestor that
# PREDATES a key they nevertheless hold. Its own source path, so its history
# is independent of Group B's two commits above.
F3_REL="project-template/.claude/f3.json"
python3 - "$PACKR/$F3_REL" <<'PY'
import json, sys
# c1 — the oldest release: no `hooks` key at all.
json.dump({"bulk": {"k%d" % i: "v%d" % i for i in range(10)}},
          open(sys.argv[1], "w"), indent=2)
PY
( cd "$PACKR" && git add -A && git commit -qm f3-c1 ) >/dev/null 2>&1
python3 - "$PACKR/$F3_REL" <<'PY'
import json, sys
# c2 — `bulk` moved on and `hooks` was introduced.
json.dump({"bulk": {"k%d" % i: "m%d" % i for i in range(10)},
           "hooks": {"Post": ["x"]}}, open(sys.argv[1], "w"), indent=2)
PY
( cd "$PACKR" && git add -A && git commit -qm f3-c2 ) >/dev/null 2>&1
python3 - "$PACKR/$F3_REL" <<'PY'
import json, sys
# HEAD — the pack adds `hooks.Pre`; this is the update that must arrive.
json.dump({"bulk": {"k%d" % i: "m%d" % i for i in range(10)},
           "hooks": {"Post": ["x"], "Pre": ["y"]}},
          open(sys.argv[1], "w"), indent=2)
PY
( cd "$PACKR" && git add -A && git commit -qm f3-head ) >/dev/null 2>&1

# OURS — still on c1's `bulk`, carrying c2's `hooks` verbatim.
F3_OURS="$TMPOUT/f3-ours.json"
python3 - "$F3_OURS" <<'PY'
import json, sys
json.dump({"bulk": {"k%d" % i: "v%d" % i for i in range(10)},
           "hooks": {"Post": ["x"]}}, open(sys.argv[1], "w"), indent=2)
PY

B6="$TMPOUT/b6.json"; rc=0
python3 "$MERGE_JSON" "" "$F3_OURS" "$PACKR/$F3_REL" --output "$B6" \
    --pack-authored-base "$PACKR" --pack-source "$F3_REL" \
    > "$TMPOUT/b6.err" 2>&1 || rc=$?
t_eq "B6 rc is 0 (no warning, so no sidecar and no reconciliation loop)" "0" "$rc"
t_eq "B6 the key the SELECTED ancestor lacks still receives the pack's update" \
    "True" "$(python3 -c "import json;print('Pre' in json.load(open('$B6')).get('hooks',{}))")"
t_eq "B6 the pack's OTHER updates arrive too (the client never edited bulk)" \
    "True" "$(python3 -c "import json;print(json.load(open('$B6'))['bulk']['k0']=='m0')")"

# ─────────────────────────────────────────────────────────────────
# Group C: merge-toml.py integration
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group C: merge-toml.py integration ===\n"

TSRC_REL="project-template/.codex/config.toml"
mkdir -p "$PACKR/project-template/.codex"
printf 'model = "a"\n\n[providers.one]\nurl = "u1"\n' > "$PACKR/$TSRC_REL"
( cd "$PACKR" && git add -A && git commit -qm toml-v1 ) >/dev/null 2>&1
printf 'model = "a"\n\n[providers.one]\nurl = "u1"\n\n[providers.two]\nurl = "u2"\n' \
    > "$PACKR/$TSRC_REL"
( cd "$PACKR" && git add -A && git commit -qm toml-head ) >/dev/null 2>&1

TOURS="$TMPOUT/ours.toml"
printf 'model = "client-model"\n\n[providers.one]\nurl = "u1"\n' > "$TOURS"

toml_probe() {
    python3 - "$1" <<'PY'
import sys, tomllib
d = tomllib.loads(open(sys.argv[1]).read())
print("two" in d.get("providers", {}), d.get("model"))
PY
}

C1="$TMPOUT/c1.toml"; rc=0
python3 "$MERGE_TOML" "" "$TOURS" "$PACKR/$TSRC_REL" --output "$C1" \
    --pack-authored-base "$PACKR" --pack-source "$TSRC_REL" \
    > "$TMPOUT/c1.err" 2>&1 || rc=$?
t_eq "C1 rc is 0" "0" "$rc"
read -r c1_two c1_model <<< "$(toml_probe "$C1")"
t_eq "C1 the pack's new table ARRIVES" "True" "$c1_two"
t_eq "C1 the client's scalar edit survives" "client-model" "$c1_model"

C2="$TMPOUT/c2.toml"; rc=0
python3 "$MERGE_TOML" "" "$TOURS" "$PACKR/$TSRC_REL" --output "$C2" \
    > "$TMPOUT/c2.err" 2>&1 || rc=$?
read -r _ c2_model <<< "$(toml_probe "$C2")"
t_eq "C2 BITE: without the derivation the merge warns (rc 2)" "2" "$rc"
t_eq "C2 BITE: the client edit is kept, but by CONFLICT not by ancestry" \
    "client-model" "$c2_model"

# ─────────────────────────────────────────────────────────────────
# Group D: MUTATION — refinement proved load-bearing, in-suite
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group D: refinement mutation ===\n"

d_out="$TMPOUT/groupD.txt"
python3 - "$LIB" > "$d_out" 2>&1 <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pack_provenance_keys as P

# D0 — the symbol this group neuters must EXIST. Without this, a rename or an
#      inlining would leave the group mutating nothing and passing anyway,
#      which is the failure mode the whole group is here to prevent.
print("D0", hasattr(P, "_refine"))

# A2's fixture: selection alone gives the WRONG `hooks`.
r_old = {"bulk": {"k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4"},
         "hooks": {"Post": ["OLD"]}}
r_mid = {"bulk": {"k1": "z1", "k2": "z2", "k3": "z3", "k4": "z4"},
         "hooks": {"Post": ["MID"]}}
r_ours = {"bulk": {"k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4"},
          "hooks": {"Post": ["MID"]}}

shipped = P.derive_base(r_ours, [r_old, r_mid])

original = P._refine
P._refine = lambda ours, selected, candidates: selected  # selection only
try:
    mutant = P.derive_base(r_ours, [r_old, r_mid])
finally:
    P._refine = original

# D1 — removing refinement must CHANGE the derived BASE. If it does not, every
#      assertion above that names refinement is inert on refinement.
print("D1", shipped != mutant)
# D2 — and in the specific direction claimed: only the shipped path records
#      OURS's value; selection alone records the selected ancestor's.
print("D2", shipped["hooks"] == {"Post": ["MID"]}
      and mutant["hooks"] == {"Post": ["OLD"]})
# D3 — restoring the symbol restores the answer, so D1/D2 measured the
#      mutation and not some incidental state.
print("D3", P.derive_base(r_ours, [r_old, r_mid]) == shipped)
PY

while read -r name got; do
    t_eq "D: $name" "True" "$got"
done < <(grep -E '^D[0-9] ' "$d_out")
if ! grep -qE '^D3 ' "$d_out"; then
    t_fail "Group D did not run to completion" "$(tail -5 "$d_out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group E: the removal-disclosure contract
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group E: removal disclosure ===\n"

e_out="$TMPOUT/groupE.txt"
python3 - "$LIB" > "$e_out" 2>&1 <<'PY'
import io
import sys
sys.path.insert(0, sys.argv[1])
import pack_provenance_keys as P

# A derived BASE lets the three-way honour a pack RETIREMENT, which removes a
# value the client still holds at rc 0 — no warning, no sidecar. Correct, and
# it must not be silent.
ours = {"keep": "v1", "retired": "x", "allow": ["a", "b", "c"]}
merged = {"keep": "v2", "allow": ["a", "b"]}

census = P.removed_from_ours(ours, merged)
# E1 — both shapes are counted: a dict key and a list element.
print("E1", len(census) == 2
      and any(c == "retired" for c in census)
      and any(c.startswith("allow[]") for c in census))

buf = io.StringIO()
n = P.emit_removal_notices(ours, merged, buf)
lines = buf.getvalue().splitlines()
# E2 — the machine line is FIRST and carries the exact count.
print("E2", n == 2
      and lines[0] == "notice: " + P.NOTICE_COUNT_PREFIX + "2")

buf2 = io.StringIO()
# E3 — a merge that dropped nothing says NOTHING. A disclosure that fires on
#      every clean run is noise, and noise is what gets filtered out.
print("E3", P.emit_removal_notices(merged, merged, buf2) == 0
      and buf2.getvalue() == "")
PY

while read -r name got; do
    t_eq "E: $name" "True" "$got"
done < <(grep -E '^E[0-9] ' "$e_out")
if ! grep -qE '^E3 ' "$e_out"; then
    t_fail "Group E did not run to completion" "$(tail -5 "$e_out")"
fi

# E4/E5 — the count line is a CONTRACT between two files: the helper emits it,
# `lib/customization-preserve.sh` extracts it into the disposition report.
# Pinned from BOTH ends — the extractor is run against real producer output
# (E4), and the consumer is confirmed to be the file that carries it (E5).
python3 - "$LIB" > "$TMPOUT/e4.log" 2>&1 <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pack_provenance_keys as P
P.emit_removal_notices({"a": 1, "b": 2, "c": 3}, {"a": 1}, sys.stdout)
PY
e4=$(sed -n 's/^notice: pack-retired-removals=\([0-9][0-9]*\)$/\1/p' \
    "$TMPOUT/e4.log" | head -1)
t_eq "E4 the disposition extractor reads the helper's own count line" "2" "$e4"
t_eq "E5 that extractor is the one customization-preserve.sh carries" \
    "1" "$(grep -c 'pack-retired-removals=' "$LIB/customization-preserve.sh")"

# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "  PASS: %d\n  FAIL: %d\n" "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
