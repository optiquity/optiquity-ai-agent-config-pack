#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-trinity-template-obeyable.sh — BD-294 D3: the shipped
# trinity template's OWN instructions must be obeyable by the merge engine that
# ships with it.
#
# The gap this closes: nothing else in the battery asserts that a client who does
# what project-template/{CLAUDE,AGENTS,GEMINI}.md tells them to do can still
# graft on the next update. Every other trinity test drives a hand-written
# fixture, so it stays green whether the shipped template is obeyable or not.
# This file derives its input FROM THE SHIPPED FILE, so it cannot drift away
# from what actually ships.
#
#   T-0  the shipped template carries no instruction the engine undoes, and
#        every fill-me value sits inside a shipped project-owned pair.
#   T-1  obey-the-template round-trip: fill every placeholder as instructed,
#        feed the result through marker_preserve_trinity with an EMPTY base (the
#        resolve-merge-conflicts Case-3 gate), require merged-with-customization,
#        every filled value present in DEST, and no placeholder left in DEST.
#   T-2  optional-section round-trip, four legs: (a) the sanctioned same-name
#        Shape B suppression is clean and drops the pack body; (b) a raw
#        heading+body deletion is silently reverted, so the template must not
#        instruct it; (c) a deletion that also removes the OPTIONAL: comment
#        misattributes to the PRECEDING section, so the template must not
#        instruct it; (d) Shape-B-wrapping a section while keeping its shipped
#        inner seed pair nests, and fails loud.
#   T-3  the shipped preamble equals the reference fixture's preamble.
#   T-4  the two entry-path setup guides agree with the template about
#        optional sections: they say suppress (never delete), name the
#        mechanism and the reason inside the step itself, offer no
#        delete-it-instead escape hatch, and never frame an unused optional
#        section as a removal candidate.
#   T-5  the document those OPTIONAL: hints hand the client off to
#        (docs/pack/PM-CHAT.md) is present, carries the section they name, and
#        instructs no deletion of a shipped section either.
#
# Legs (b) and (c) are written as implications — "IF the hazard is live THEN the
# shipped text must not steer a client into it" — so that a future engine fix
# that removes the hazard does not red this file, while the shipped wording is
# asserted unconditionally and reds the moment a delete-instruction returns.
#
# Usage:    bash scripts/tests/test-trinity-template-obeyable.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
TEMPLATE_DIR="$REPO_ROOT/project-template"
FIXTURE_DIR="$REPO_ROOT/test-fixtures/v11-trinity-marker-prepped"

# BD-276: portable full-template mktemp (never `mktemp -d -t prefix.XXXXXX`,
# which leaves a literal XXXXXX on BSD).
FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/bd294-obeyable.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0
pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}
assert_eq() { if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "$2" "$3"; fi; }

# Count matching lines, branching on grep's OWN exit status (0 match, 1 no
# match, >1 error). Never `|| echo 0` — that would swallow a real grep error.
count_matches() {
    local pat="$1" file="$2" n rc
    n=$(grep -cE "$pat" "$file")
    rc=$?
    if [[ "$rc" -eq 0 ]]; then printf '%s' "$n"
    elif [[ "$rc" -eq 1 ]]; then printf '0'
    else printf 'GREP-ERROR-%s' "$rc"; fi
}
count_fixed() {
    local pat="$1" file="$2" n rc
    n=$(grep -cF -- "$pat" "$file")
    rc=$?
    if [[ "$rc" -eq 0 ]]; then printf '%s' "$n"
    elif [[ "$rc" -eq 1 ]]; then printf '0'
    else printf 'GREP-ERROR-%s' "$rc"; fi
}
# Count matching OCCURRENCES, not matching lines. Required for the flattened
# streams below: a flattened file is ONE line, so `grep -c` on it can only ever
# report 0 or 1 and would silently drop the duplicate-detection a raw scan has.
count_occurrences() {
    local pat="$1" file="$2" out rc
    out=$(grep -oE "$pat" "$file")
    rc=$?
    if [[ "$rc" -eq 0 ]]; then printf '%s' "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
    elif [[ "$rc" -eq 1 ]]; then printf '0'
    else printf 'GREP-ERROR-%s' "$rc"; fi
}

# shellcheck disable=SC1091
source "$LIB_DIR/three-way.sh"
export _CP_PACK_ROOT="$REPO_ROOT"
# shellcheck disable=SC1091
source "$LIB_DIR/customization-preserve.sh"

if ! declare -F marker_preserve_trinity >/dev/null 2>&1; then
    echo "FATAL: marker_preserve_trinity not sourced (customization-preserve.sh must source marker-preserve.sh)"
    exit 1
fi

TRINITY_FILES="CLAUDE AGENTS GEMINI"
PAIR_BEGIN='<!-- BEGIN project-owned -->'
PAIR_END='<!-- END project-owned -->'
CLEAN_DISP="merged-with-customization"
NEEDS_DISP="customization-detected-needs-reconciliation"
# The suppress-not-delete wording the five OPTIONAL: comments must carry.
SUPPRESS_PHRASE='suppress it — do not delete it'
# The instruction vocabulary that must NOT ship (each steers a client into a
# path the engine undoes).
BANNED_DELETE_A='delete the entire section'
BANNED_DELETE_B=', or delete section'
BANNED_BLOCK_A='HOW TO USE THIS TEMPLATE'
BANNED_BLOCK_B='Fill in placeholders and remove this block'

STATE="$FIXTURE_BASE/state"
newstate() { rm -rf "$STATE"; customization_preserve_init "$STATE" ".pre-update" >/dev/null; }
last_col() { tail -1 "$STATE/dispositions.tsv" | awk -F'\t' -v c="$1" '{print $c}'; }
last_disp()  { last_col 1; }
last_notes() { last_col 7; }

# Run the engine in its EMPTY-BASE Regime B path — the same call the
# resolve-merge-conflicts skill's Case-3 gate makes. Echoes nothing; the
# caller reads last_disp / last_notes and the DEST file.
run_engine() {
    local ours="$1" theirs="$2" rel="$3" dest="$4"
    newstate
    marker_preserve_trinity "" "$ours" "$theirs" "$rel" "$dest"
}

# ─────────────────────────────────────────────────────────────────────────
echo "== CONTROLS: the harness must discriminate before any reading counts =="
# ─────────────────────────────────────────────────────────────────────────
# Without these, a harness that returned one constant would "pass" every leg
# below. All three must land on DIFFERENT dispositions.
mkdir -p "$FIXTURE_BASE/ctl"
printf '## Sec1\npack body\n' > "$FIXTURE_BASE/ctl/pack.md"
printf '## Sec1\npack body\n%s\nMINE\n%s\n' "$PAIR_BEGIN" "$PAIR_END" \
    > "$FIXTURE_BASE/ctl/wrapped.md"
printf '## Sec1\npack body CLIENT EDITED OUTSIDE THE MARKERS\n%s\nMINE\n%s\n' \
    "$PAIR_BEGIN" "$PAIR_END" > "$FIXTURE_BASE/ctl/dirty.md"
printf '## Sec1\npack body\n## Sec2\nbrand new pack section\n' \
    > "$FIXTURE_BASE/ctl/newcanon.md"

run_engine "$FIXTURE_BASE/ctl/pack.md" "$FIXTURE_BASE/ctl/pack.md" \
    "ctl-same" "$FIXTURE_BASE/ctl/d1.md"
ctl_same="$(last_disp)"
run_engine "$FIXTURE_BASE/ctl/wrapped.md" "$FIXTURE_BASE/ctl/newcanon.md" \
    "ctl-clean" "$FIXTURE_BASE/ctl/d2.md"
ctl_clean="$(last_disp)"
run_engine "$FIXTURE_BASE/ctl/dirty.md" "$FIXTURE_BASE/ctl/newcanon.md" \
    "ctl-dirty" "$FIXTURE_BASE/ctl/d3.md"
ctl_dirty="$(last_disp)"

assert_eq "control: identical file -> unchanged-pack" "unchanged-pack" "$ctl_same"
assert_eq "control: in-marker addition -> $CLEAN_DISP" "$CLEAN_DISP" "$ctl_clean"
assert_eq "control: out-of-marker edit -> $NEEDS_DISP" "$NEEDS_DISP" "$ctl_dirty"
if [[ "$ctl_same" == "$ctl_clean" || "$ctl_clean" == "$ctl_dirty" \
   || "$ctl_same" == "$ctl_dirty" ]]; then
    echo "FATAL: controls do not discriminate — every reading below is meaningless."
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────
echo "== T-0: the shipped template instructs nothing the engine undoes =="
# ─────────────────────────────────────────────────────────────────────────
for name in $TRINITY_FILES; do
    f="$TEMPLATE_DIR/$name.md"
    assert_eq "T-0 $name.md: '$BANNED_DELETE_A' occurrences" \
        "0" "$(count_fixed "$BANNED_DELETE_A" "$f")"
    assert_eq "T-0 $name.md: '$BANNED_DELETE_B' occurrences" \
        "0" "$(count_fixed "$BANNED_DELETE_B" "$f")"
    assert_eq "T-0 $name.md: '$BANNED_BLOCK_A' occurrences" \
        "0" "$(count_fixed "$BANNED_BLOCK_A" "$f")"
    assert_eq "T-0 $name.md: '$BANNED_BLOCK_B' occurrences" \
        "0" "$(count_fixed "$BANNED_BLOCK_B" "$f")"
    # The first H2 is the pinned `## Project Identity` heading. The exact
    # string is a user decision and two shipped documents quote it verbatim
    # (skills/resolve-merge-conflicts/SKILL.md and
    # supporting-docs/PRE-RECONCILE-v10-to-v11.md), so a silent
    # re-capitalisation would break both cross-references with nothing else
    # in the battery to catch it. This also pins the FIRST-ness the identity
    # lines depend on: anything above the first H2 is preamble, which is
    # grafted from the pack verbatim and cannot hold a client's value.
    assert_eq "T-0 $name.md: first H2 is the pinned '## Project Identity'" \
        "## Project Identity" "$(sed -n '/^## /{p;q;}' "$f")"
    # Every OPTIONAL: comment carries the suppress-not-delete pointer — PER
    # COMMENT, never a whole-file count parity. A parity holds even when a
    # shipped comment loses its pointer and the phrase reappears on an
    # unrelated line, so a genuinely defective comment would ship green.
    n_opt="$(count_matches '^<!-- OPTIONAL:' "$f")"
    # The per-comment scan below is a per-LINE conjunction, so it is only
    # exact while every OPTIONAL: comment opens and closes on one line.
    # Assert that precondition rather than assume it: a future line-wrapped
    # comment must red here, not slip through unmeasured.
    n_closed="$(count_matches '^<!-- OPTIONAL:.*-->[[:space:]]*$' "$f")"
    assert_eq "T-0 $name.md: every OPTIONAL: comment is single-line (per-comment scan is exact)" \
        "$n_opt" "$n_closed"
    n_sup="$(count_matches "^<!-- OPTIONAL:.*$SUPPRESS_PHRASE" "$f")"
    assert_eq "T-0 $name.md: every OPTIONAL: comment ITSELF carries the suppress pointer" \
        "$n_opt" "$n_sup"
    if [[ "$n_opt" == "0" ]]; then
        fail "T-0 $name.md: expected optional-section comments to exist" \
             ">0 OPTIONAL: comments" "0"
    else
        pass "T-0 $name.md: $n_opt OPTIONAL: comment(s) present (assertion is not vacuous)"
    fi
    # Every fill-me placeholder sits INSIDE a shipped project-owned pair.
    out_of_marker="$(awk -v b="$PAIR_BEGIN" -v e="$PAIR_END" '
        index($0, b) > 0 { depth++; next }
        index($0, e) > 0 { depth--; next }
        depth == 0 && /\[[A-Z][A-Z_][A-Z_]/ { n++ }
        END { print n + 0 }' "$f")"
    assert_eq "T-0 $name.md: placeholder tokens OUTSIDE every marker pair" \
        "0" "$out_of_marker"
    in_marker="$(awk -v b="$PAIR_BEGIN" -v e="$PAIR_END" '
        index($0, b) > 0 { depth++; next }
        index($0, e) > 0 { depth--; next }
        depth > 0 && /\[[A-Z][A-Z_][A-Z_]/ { n++ }
        END { print n + 0 }' "$f")"
    if [[ "$in_marker" -lt 3 ]]; then
        fail "T-0 $name.md: in-marker placeholder count (guard is not vacuous)" \
             ">=3" "$in_marker"
    else
        pass "T-0 $name.md: $in_marker placeholder line(s) inside a shipped pair"
    fi
done

# ─────────────────────────────────────────────────────────────────────────
echo "== T-1: obey-the-template round-trip (shipped file is the input) =="
# ─────────────────────────────────────────────────────────────────────────
# Mechanically do what the template tells a client to do: replace every
# placeholder with a sentinel value. Nothing else — after BD-294 the shipped
# template asks for no deletions (T-0 asserts that), so filling is the whole
# instruction set.
fill_template() {
    awk '
      {
        line = $0
        gsub(/\[PROJECT_NAME\]/,     "SENTINELPROJECTNAME",  line)
        gsub(/\[PLATFORM_TARGETS\]/, "SENTINELTARGETS",      line)
        gsub(/\[TRANSPORT\]/,        "SENTINELTRANSPORT",    line)
        if (line ~ /^\[[A-Z][A-Z_]+ /) {
            tok = line
            sub(/^\[/, "", tok)
            sub(/[^A-Z_].*$/, "", tok)
            line = "SENTINELFILL" tok " — filled in by the project."
        }
        print line
      }' "$1"
}

for name in $TRINITY_FILES; do
    canon="$TEMPLATE_DIR/$name.md"
    filled="$FIXTURE_BASE/$name.filled.md"
    dest="$FIXTURE_BASE/$name.dest.md"
    fill_template "$canon" > "$filled"

    # The fill step itself must have done something, or T-1 proves nothing.
    n_sent_src="$(count_matches 'SENTINEL' "$filled")"
    if [[ "$n_sent_src" -lt 5 ]]; then
        fail "T-1 $name.md: fill step substituted enough values (not vacuous)" \
             ">=5 sentinel lines" "$n_sent_src"
    else
        pass "T-1 $name.md: fill step produced $n_sent_src sentinel line(s)"
    fi
    assert_eq "T-1 $name.md: no placeholder token left in the filled client file" \
        "0" "$(count_matches '\[[A-Z][A-Z_][A-Z_]' "$filled")"

    run_engine "$filled" "$canon" "$name.md" "$dest"
    assert_eq "T-1 $name.md: a client who obeyed the template grafts clean" \
        "$CLEAN_DISP" "$(last_disp)"
    assert_eq "T-1 $name.md: every filled value survives into the live file" \
        "$n_sent_src" "$(count_matches 'SENTINEL' "$dest")"
    assert_eq "T-1 $name.md: no placeholder is restored into the live file" \
        "0" "$(count_matches '\[[A-Z][A-Z_][A-Z_]' "$dest")"
done

# ─────────────────────────────────────────────────────────────────────────
echo "== T-2: optional-section handling, four legs =="
# ─────────────────────────────────────────────────────────────────────────
CANON="$TEMPLATE_DIR/CLAUDE.md"
OPT_HEADING='## gRPC and Proto3 rules'

# Locate the OPTIONAL comment, its heading, and the next H2 after it.
read -r OPT_LN HEAD_LN NEXT_LN <<EOF  # ci-fragility: allow-shell-active-heredoc
$(awk -v h="$OPT_HEADING" '
    /^<!-- OPTIONAL:/ { last_opt = NR }
    $0 == h { head = NR; opt = last_opt; next }
    head && NR > head && /^## / && !nxt { nxt = NR }
    END { print opt, head, nxt }' "$CANON")
EOF

if [[ -z "${OPT_LN:-}" || -z "${HEAD_LN:-}" || -z "${NEXT_LN:-}" \
      || "$OPT_LN" -lt 1 || "$HEAD_LN" -le "$OPT_LN" || "$NEXT_LN" -le "$HEAD_LN" ]]; then
    fail "T-2 anchor: located the optional section in the shipped CLAUDE.md" \
         "OPT < HEAD < NEXT" "OPT=$OPT_LN HEAD=$HEAD_LN NEXT=$NEXT_LN"
else
    pass "T-2 anchor: '$OPT_HEADING' — comment L$OPT_LN, heading L$HEAD_LN, next H2 L$NEXT_LN"
fi
# The OPTIONAL: comment is lexically the LAST body line of the PRECEDING
# section — this adjacency is what makes leg (c) misattribute.
assert_eq "T-2 anchor: the OPTIONAL: comment sits directly above its heading" \
    "1" "$((HEAD_LN - OPT_LN))"

# (a) sanctioned suppression — same-name Shape B override.
awk -v h="$HEAD_LN" -v x="$NEXT_LN" -v b="$PAIR_BEGIN" -v e="$PAIR_END" '
    NR < h { print }
    NR == h { print b; print $0; print ""; print "Not applicable to this project."; print e }
    NR > h && NR < x { next }
    NR >= x { print }' "$CANON" > "$FIXTURE_BASE/opt-a.md"
# (b) raw deletion of heading+body, OPTIONAL: comment left behind.
awk -v h="$HEAD_LN" -v x="$NEXT_LN" '
    NR < h { print } NR >= h && NR < x { next } NR >= x { print }' \
    "$CANON" > "$FIXTURE_BASE/opt-b.md"
# (c) literal "delete the entire section" — the comment goes too.
awk -v o="$OPT_LN" -v x="$NEXT_LN" '
    NR < o { print } NR >= o && NR < x { next } NR >= x { print }' \
    "$CANON" > "$FIXTURE_BASE/opt-c.md"
# (d) Shape-B wrap that KEEPS the shipped inner seed pair -> nested pair.
awk -v h="$HEAD_LN" -v x="$NEXT_LN" -v b="$PAIR_BEGIN" -v e="$PAIR_END" '
    NR == h { print b }
    NR >= h && NR < x - 1 { print; next }
    NR == x - 1 { print e; print $0; next }
    { print }' "$CANON" > "$FIXTURE_BASE/opt-d.md"

# Leg (a) — the path the shipped comment now points at MUST work.
run_engine "$FIXTURE_BASE/opt-a.md" "$CANON" "CLAUDE.md" "$FIXTURE_BASE/opt-a.dest"
assert_eq "T-2 (a): same-name Shape B suppression grafts clean" \
    "$CLEAN_DISP" "$(last_disp)"
assert_eq "T-2 (a): the pack's placeholder body is gone from the live file" \
    "0" "$(count_fixed '[GRPC_RULES' "$FIXTURE_BASE/opt-a.dest")"
assert_eq "T-2 (a): the project's own body is in the live file" \
    "1" "$(count_fixed 'Not applicable to this project.' "$FIXTURE_BASE/opt-a.dest")"

# The shipped instruction vocabulary, asserted UNCONDITIONALLY. This is the leg
# that reds if a `delete the entire section` instruction ever returns.
delete_instructions=0
for name in $TRINITY_FILES; do
    n="$(count_fixed "$BANNED_DELETE_A" "$TEMPLATE_DIR/$name.md")"
    delete_instructions=$((delete_instructions + n))
done

# Leg (b) — raw deletion. Measure the hazard, then require that the shipped
# template does not steer a client into it.
run_engine "$FIXTURE_BASE/opt-b.md" "$CANON" "CLAUDE.md" "$FIXTURE_BASE/opt-b.dest"
disp_b="$(last_disp)"
restored_b="$(count_fixed "$OPT_HEADING" "$FIXTURE_BASE/opt-b.dest")"
packbody_b="$(count_fixed '[GRPC_RULES' "$FIXTURE_BASE/opt-b.dest")"
echo "  (measured) leg (b) raw deletion -> $disp_b ; heading restored=$restored_b ; pack body restored=$packbody_b"
if [[ "$disp_b" == "$CLEAN_DISP" && "$restored_b" != "0" ]]; then
    assert_eq "T-2 (b): deletion is silently reverted, so no shipped comment may instruct a deletion" \
        "0" "$delete_instructions"
else
    pass "T-2 (b): raw deletion is no longer a silent revert ($disp_b, restored=$restored_b)"
fi

# Leg (c) — the literal reading. The comment is the preceding section's last
# body line, so removing it blames a section the client never touched.
run_engine "$FIXTURE_BASE/opt-c.md" "$CANON" "CLAUDE.md" "$FIXTURE_BASE/opt-c.dest"
disp_c="$(last_disp)"
notes_c="$(last_notes)"
echo "  (measured) leg (c) delete-with-comment -> $disp_c"
echo "  (measured) leg (c) notes: $notes_c"
blames_other=0
case "$notes_c" in
    *"$OPT_HEADING"*) blames_other=0 ;;
    *"## "*)          blames_other=1 ;;
esac
if [[ "$disp_c" == "$NEEDS_DISP" && "$blames_other" -eq 1 ]]; then
    assert_eq "T-2 (c): deleting the comment misattributes to another section, so no shipped comment may instruct 'delete the entire section'" \
        "0" "$delete_instructions"
    for name in $TRINITY_FILES; do
        assert_eq "T-2 (c): $name.md tells the client to suppress, not delete" \
            "5" "$(count_fixed "$SUPPRESS_PHRASE" "$TEMPLATE_DIR/$name.md")"
    done
else
    pass "T-2 (c): deleting the OPTIONAL: comment no longer misattributes ($disp_c)"
fi
assert_eq "T-2 (c): the literal deletion is never a silent clean revert" \
    "0" "$([[ "$disp_c" == "$CLEAN_DISP" ]] && printf 1 || printf 0)"

# Leg (d) — the interaction PRE-RECONCILE-v10-to-v11.md §(d) documents.
# Non-vacuity: the section we wrapped must ACTUALLY contain a shipped seed pair,
# otherwise nothing is nested and the leg proves nothing. Count BEGIN markers
# strictly inside the section body, not in the whole file.
inner_pairs="$(awk -v h="$HEAD_LN" -v x="$NEXT_LN" -v b="$PAIR_BEGIN" '
    NR > h && NR < x && index($0, b) > 0 { n++ }
    END { print n + 0 }' "$CANON")"
if [[ "$inner_pairs" -lt 1 ]]; then
    fail "T-2 (d): the wrapped section really does ship an inner seed pair (not vacuous)" \
         ">=1 BEGIN marker inside the section body" "$inner_pairs"
else
    pass "T-2 (d): the wrapped section ships $inner_pairs inner seed pair(s) — the nest is real"
fi
run_engine "$FIXTURE_BASE/opt-d.md" "$CANON" "CLAUDE.md" "$FIXTURE_BASE/opt-d.dest"
assert_eq "T-2 (d): a Shape B wrap that keeps the shipped inner pair fails loud" \
    "$NEEDS_DISP" "$(last_disp)"
case "$(last_notes)" in
    *"nested BEGIN marker"*)
        pass "T-2 (d): the failure names the nested BEGIN marker" ;;
    *)  fail "T-2 (d): the failure names the nested BEGIN marker" \
            "notes contain 'nested BEGIN marker'" "$(last_notes)" ;;
esac

# ─────────────────────────────────────────────────────────────────────────
echo "== T-3: the shipped preamble equals the reference fixture's preamble =="
# ─────────────────────────────────────────────────────────────────────────
# Measured with the ENGINE's own extractor, so this asserts the same bytes the
# engine's Step-6 preamble comparison reads.
for name in $TRINITY_FILES; do
    shipped="$TEMPLATE_DIR/$name.md"
    reference="$FIXTURE_DIR/$name.md"
    if [[ ! -f "$reference" ]]; then
        fail "T-3 $name.md: reference fixture present" "$reference exists" "missing"
        continue
    fi
    _mp_extract_preamble "$shipped"   > "$FIXTURE_BASE/$name.pre.ship"
    _mp_extract_preamble "$reference" > "$FIXTURE_BASE/$name.pre.fix"
    if cmp -s "$FIXTURE_BASE/$name.pre.ship" "$FIXTURE_BASE/$name.pre.fix"; then
        pass "T-3 $name.md: shipped preamble == reference fixture preamble"
    else
        fail "T-3 $name.md: shipped preamble == reference fixture preamble" \
            "$(cat "$FIXTURE_BASE/$name.pre.fix")" \
            "$(cat "$FIXTURE_BASE/$name.pre.ship")"
    fi
    # The preamble is the H1 and nothing else — any prose above the first H2 is
    # unreachable by a marker pair and is grafted from the pack verbatim.
    assert_eq "T-3 $name.md: shipped preamble is the H1 line only" \
        "# $name.md" "$(sed -n '1p' "$FIXTURE_BASE/$name.pre.ship")"
    assert_eq "T-3 $name.md: no placeholder in the preamble" \
        "0" "$(count_matches '\[[A-Z][A-Z_][A-Z_]' "$FIXTURE_BASE/$name.pre.ship")"
done

# ─────────────────────────────────────────────────────────────────────────
echo "== T-4: the setup guides agree with the template about optional sections =="
# ─────────────────────────────────────────────────────────────────────────
# The trinity comment is not the only place a client is told what to do with an
# optional section. The two entry-path guides say it too, in prose, and a client
# on day one reads THOSE. If they disagree with the template the client is
# steered into the silent revert T-2 (b) measures.
#
# SCOPE NOTE — this is deliberately NOT a blanket "no `delete ... section`" grep
# over these files. Deleting a section is SAFE when the section is absent from
# the new pack canonical (nothing to restore from) and is the DEFECT only when
# the canonical still ships it. Other shipped docs legitimately instruct a
# deletion for the safe case (e.g. a v10 heading retired in v11). This group is
# keyed to the OPTIONAL-section step specifically, which is the unsafe case:
# those sections ARE in the shipped canonical.
SETUP_GUIDES="SETUP-NEW SETUP-EXISTING"
SUPPORTING_DIR="$REPO_ROOT/supporting-docs"

# Non-vacuity precondition: the canonical really does still ship the sections
# these guides talk about, so a deletion really would be reverted.
shipped_optional="$(count_fixed '<!-- OPTIONAL:' "$TEMPLATE_DIR/CLAUDE.md")"
if [[ "$shipped_optional" -lt 1 ]]; then
    fail "T-4 precondition: the canonical still ships OPTIONAL sections" \
         ">=1" "$shipped_optional"
else
    pass "T-4 precondition: the canonical ships $shipped_optional OPTIONAL section(s) — a deletion would be reverted"
fi

for guide in $SETUP_GUIDES; do
    g="$SUPPORTING_DIR/$guide.md"
    if [[ ! -f "$g" ]]; then
        fail "T-4 $guide.md: guide present" "$g exists" "missing"
        continue
    fi
    # Non-vacuity: the guide must actually carry an optional-section step,
    # otherwise both assertions below pass 0 == 0.
    n_ref="$(count_fixed 'OPTIONAL:' "$g")"
    if [[ "$n_ref" -lt 1 ]]; then
        fail "T-4 $guide.md: carries an optional-section step (guard is not vacuous)" \
             ">=1 reference to the OPTIONAL: hint" "$n_ref"
        continue
    fi
    pass "T-4 $guide.md: carries $n_ref optional-section reference(s) — assertions are not vacuous"

    # Flattened FIRST. These guides wrap their prose, so a line-based scan is
    # blind to a wrapped instruction: measured, a wrapped "Delete the / optional
    # sections" reads 0 on the raw bytes and 1 on the flattened ones.
    guideflat="$FIXTURE_BASE/$guide.flat.txt"
    tr '\n\t' '  ' < "$g" | tr -s ' ' > "$guideflat"
    # Verb-family-complete, and anchored to the bare imperative rather than to
    # any inflection: the correct step legitimately reads "rather than deleting
    # it" and "a plain deletion is silently undone", so a blanket inflected ban
    # would red the very sentences this leg exists to protect.
    assert_eq "T-4 $guide.md: does not tell the client to DELETE the optional sections" \
        "0" "$(count_occurrences '(^|[^A-Za-z])([Dd]elete|[Rr]emove|[Dd]rop|[Ss]trip) the optional' "$guideflat")"
    assert_eq "T-4 $guide.md: tells the client to SUPPRESS them instead" \
        "1" "$(count_occurrences '[Ss]uppress the optional' "$guideflat")"
    # The instruction must name the mechanism, not just the verb — and it must
    # do so INSIDE the optional-section step, not merely somewhere in the file.
    # (A whole-file count would couple this to unrelated prose: SETUP-EXISTING
    # names the same mechanism again in its adopting-overlapping-content
    # paragraph, which has nothing to do with optional sections.)
    step="$FIXTURE_BASE/$guide.step.txt"
    awk '/[Ss]uppress the optional/ { instep = 1 }
         instep && /^[0-9]+\. / && !/[Ss]uppress the optional/ { exit }
         instep { print }' "$g" > "$step"
    step_lines="$(awk 'END { print NR + 0 }' "$step")"
    if [[ "$step_lines" -lt 2 ]]; then
        fail "T-4 $guide.md: the optional-section step was located (guard is not vacuous)" \
             ">=2 lines" "$step_lines"
        continue
    fi
    pass "T-4 $guide.md: optional-section step located ($step_lines lines)"
    if [[ "$(count_matches 'same-name Shape B|same-name project-owned marker pair' "$step")" -ge 1 ]]; then
        pass "T-4 $guide.md: the step itself names the same-name Shape B mechanism"
    else
        fail "T-4 $guide.md: the step itself names the same-name Shape B mechanism" \
             "mechanism named within the step" "$(cat "$step")"
    fi
    # And the step must say WHY, so a client cannot read it as arbitrary style.
    if [[ "$(count_matches 'silently undone|no message|restores the section' "$step")" -ge 1 ]]; then
        pass "T-4 $guide.md: the step says why deletion is wrong"
    else
        fail "T-4 $guide.md: the step says why deletion is wrong" \
             "step explains the silent revert" "$(cat "$step")"
    fi

    # The realistic return path is not a straight revert (the legs above
    # catch that) — it is a well-meaning editor ADDING an alternative while
    # leaving every correct word in place. Keyed to the OFFER vocabulary
    # rather than the verb, because the correct step legitimately contains
    # "deleting", "deletion" and "don't delete", and a blanket verb ban would
    # red the text this group exists to protect.
    #
    # Flattened first: these guides wrap their prose, and a line-based scan
    # is exactly what let a delete-instruction survive the first census.
    stepflat="$FIXTURE_BASE/$guide.step.flat.txt"
    tr '\n\t' '  ' < "$step" | tr -s ' ' > "$stepflat"
    assert_eq "T-4 $guide.md: the step offers no delete-it-instead escape hatch" \
        "0" "$(count_matches '(^|[^A-Za-z])([Yy]ou (may|can|could|might)|[Oo]r|[Aa]lternatively,?) (simply |just )?(remove|delete|drop|strip)|[Ii]f you prefer' "$stepflat")"

    # Whole-guide, and in the NOUN family rather than the verb family: the
    # guide must never frame an unused optional section as a removal
    # candidate. This is a different lexical family from the step legs above
    # — a noun phrase far from any imperative — which is why it needs its own
    # assertion. It reuses the flattened stream built above.
    assert_eq "T-4 $guide.md: frames an unused optional section as suppression, never removal" \
        "0" "$(count_matches 'candidates? for (removal|deletion)' "$guideflat")"
done

# ─────────────────────────────────────────────────────────────────────────
echo ""
echo "== T-5: the doc the OPTIONAL: hints hand off to agrees with them =="
# ─────────────────────────────────────────────────────────────────────────
# Every OPTIONAL: comment ends by naming a section of docs/pack/PM-CHAT.md, so
# that document is part of the shipped instruction: a client who follows the
# hint lands there. T-0 bans the delete-instruction vocabulary in the three
# trinity files, but nothing banned it in the document those files hand off to,
# and a `delete the entire section` instruction shipped there. Deleting a
# section the canonical still ships is the path T-2 (b) measures as silently
# reverted, so the ban belongs on both surfaces or on neither.
#
# SCOPE NOTE — bounded to this one document, deliberately NOT a tree-wide grep
# (see T-4's scope note: instructing a deletion is legitimate for a section the
# canonical no longer ships). Measured on the shipped bytes this document
# instructs no section deletion at all, so the pattern below is sized exactly to
# a legitimate set of zero. Should a genuine safe-case deletion instruction ever
# be added here it will red — a false alarm, which is the safe direction, and the
# answer then is to narrow this pattern's scope, never to weaken the pattern.
PM_CHAT="$TEMPLATE_DIR/docs/pack/PM-CHAT.md"
PM_SECTION='## How to add project-owned content to trinity files'
PM_POINTER='docs/pack/PM-CHAT.md § "How to add project-owned content to trinity files"'
if [[ ! -f "$PM_CHAT" ]]; then
    fail "T-5: the document the OPTIONAL: hints name is present" "$PM_CHAT exists" "missing"
else
    # Load-bearing backing (not mere existence): every OPTIONAL: hint must
    # actually carry the pointer, and the pointer must actually resolve to a
    # real section — otherwise these bans guard a document no client reaches.
    for name in $TRINITY_FILES; do
        n_opt="$(count_fixed '<!-- OPTIONAL:' "$TEMPLATE_DIR/$name.md")"
        if [[ "$n_opt" -lt 1 ]]; then
            fail "T-5 $name.md: carries OPTIONAL: hints (guard is not vacuous)" ">=1" "$n_opt"
        else
            assert_eq "T-5 $name.md: all $n_opt OPTIONAL: hint(s) name the PM-CHAT.md section" \
                "$n_opt" "$(count_fixed "$PM_POINTER" "$TEMPLATE_DIR/$name.md")"
        fi
    done
    assert_eq "T-5: the pointer resolves — PM-CHAT.md carries the named section" \
        "1" "$(count_fixed "$PM_SECTION" "$PM_CHAT")"

    assert_eq "T-5 PM-CHAT.md: '$BANNED_DELETE_A' occurrences" \
        "0" "$(count_fixed "$BANNED_DELETE_A" "$PM_CHAT")"
    assert_eq "T-5 PM-CHAT.md: '$BANNED_DELETE_B' occurrences" \
        "0" "$(count_fixed "$BANNED_DELETE_B" "$PM_CHAT")"

    # Wrap-immune and verb-family-complete: a fixed literal is evaded by a line
    # wrap or a synonym, which is how this one survived. Anchored to the bare
    # imperative and never to an inflection — the corrected text reads "Deleting
    # the section instead is silently undone", and a blanket inflected ban reds
    # exactly the sentence this group exists to protect.
    pmflat="$FIXTURE_BASE/pm-chat.flat.txt"
    tr '\n\t' '  ' < "$PM_CHAT" | tr -s ' ' > "$pmflat"
    assert_eq "T-5 PM-CHAT.md: instructs no deletion of a shipped section" \
        "0" "$(count_occurrences '(^|[^A-Za-z])([Dd]elete|[Rr]emove|[Dd]rop|[Ss]trip) the (entire |whole )?section' "$pmflat")"

    # Non-vacuity for the bans: the document must POSITIVELY teach the
    # suppression and say why, otherwise a document that says nothing passes.
    assert_eq "T-5 PM-CHAT.md: P-6 teaches the same-name Shape B suppression instead" \
        "1" "$(count_fixed '**same-name** Shape B pair' "$pmflat")"
    assert_eq "T-5 PM-CHAT.md: P-6 says why a deletion is wrong" \
        "1" "$(count_fixed 'silently undone' "$pmflat")"
fi

# ─────────────────────────────────────────────────────────────────────────
echo ""
echo "$passes passed, $fails failed"
[[ "$fails" -eq 0 ]] || exit 1
exit 0
