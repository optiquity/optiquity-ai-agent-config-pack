#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-docs-groupings-conformance.sh —
# client-gate output asserts for the BD-189 groupings conformance leg
# (project-template/scripts/validate-docs.sh `_conf_check_grouping_entry`
# + `_conf_check_groupings_stream` + the A2 empty-Status close in
# `_conf_check_implplan_entry`).
#
# Pattern: the landed output-assert family
# (scripts/tests/test-validate-docs-target-coherence.sh) — stage a mktemp
# client tree with the REAL shipped gate + allowlist + the REAL shipped
# stream contracts (impl-plan + groupings), run the REAL gate, FILTER the
# output to the groupings conformance family, and assert each negative
# FAILS naming the file + the problem. Never whole-output equality: an
# isolated fixture tree legitimately trips out-of-scope axes.
#
# Coverage (the F4 negative battery + the GRP-000 probes + the two
# closes):
#   negatives — bad kind; dup member; descending order; min-2 (1 member,
#   no exception); stale exception; zero members (real grouping);
#   dangling member ref; part-ref member token (phase-2.Part-a); byte
#   grammar ×2 (double space after colon / trailing whitespace); header
#   spacing; back-pointer; field order; Entry-Type value; header↔filename
#   ID mismatch; free prose; blank line; missing trailing newline;
#   forbidden GROUPINGS.md; toc-sync ×3 (missing row / ghost row / no
#   _toc.md); mis-named GRP-0000.md; present-but-empty Status on a
#   phase-epic (A2); a member token RESOLVING to a phase-part entry (G-2
#   — the message directs to the parent phase); GRP-000 exclusivity /
#   exception-forbidden / pinned-Kind / pinned-title.
#   positives — populated valid tree (2 real groupings incl. a shared
#   member + a single-member-with-exception + a Target-carrying member +
#   a 1-member GRP-000 without the exception field); empty tree;
#   empty-member GRP-000.
#
# Usage:    bash scripts/tests/test-validate-docs-groupings-conformance.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GATE="$PACK_ROOT/project-template/scripts/validate-docs.sh"
ALLOWLIST="$PACK_ROOT/project-template/scripts/.docs-gate-allowlist.txt"
IP_RULES="$PACK_ROOT/project-template/docs/project/implementation-plan/_rules.md"
GRP_RULES="$PACK_ROOT/project-template/docs/project/groupings/_rules.md"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-vdocs-grp-conformance.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '%s\n' "$2" | sed 's/^/    /'
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

for f in "$GATE" "$ALLOWLIST" "$IP_RULES" "$GRP_RULES"; do
    if [[ ! -f "$f" ]]; then
        fail "required input present" "missing: $f"
    fi
done
if [[ $fails -gt 0 ]]; then
    echo "=== Results: $passes passed, $fails failed ==="
    exit 1
fi

# ── Builders ────────────────────────────────────────────────────────────
stage_tree() {
    local root="$1"
    mkdir -p "$root/docs/project/implementation-plan" \
             "$root/docs/project/groupings" "$root/scripts"
    cp "$IP_RULES" "$root/docs/project/implementation-plan/_rules.md"
    cp "$GRP_RULES" "$root/docs/project/groupings/_rules.md"
    cp "$GATE" "$root/scripts/validate-docs.sh"
    cp "$ALLOWLIST" "$root/scripts/.docs-gate-allowlist.txt"
    chmod +x "$root/scripts/validate-docs.sh"
}

# write_phase <root> <num> [status] [target|-] — an EMPTY status argument
# means present-but-empty (the ${3-…} unset-only default preserves it).
write_phase() {
    local root="$1" num="$2" status="${3-not-started}" target="${4--}"
    {
        printf '<!-- back -->\n## Phase %s — G%s\n\n' "$num" "$num"
        printf -- '- **Entry-Type**: phase-epic\n'
        printf -- '- **ID**: phase-%s\n' "$num"
        printf -- '- **Status**: %s\n' "$status"
        printf -- '- **Blockers**: none\n'
        printf -- '- **Unblocks**: none\n'
        printf -- '- **Goal**: g\n'
        printf -- '- **Prerequisite**: none\n'
        if [[ "$target" != "-" ]]; then
            printf -- '- **Target**: %s\n' "$target"
        fi
    } > "$root/docs/project/implementation-plan/phase-${num}.md"
}

# write_part <root> <num> — a lightweight phase-part entry.
write_part() {
    local root="$1" num="$2"
    printf '<!-- back -->\n## Phase %s — Part\n\n- **Entry-Type**: phase-part\n' \
        "$num" > "$root/docs/project/implementation-plan/phase-${num}.md"
}

write_index() {
    local root="$1"; shift
    {
        printf '# Index — ordering — project-implementation-plan\n\n'
        printf '## Serial order\n\n'
        local n
        for n in "$@"; do
            printf -- '- [phase-%s](./phase-%s.md) — G%s\n' "$n" "$n" "$n"
        done
    } > "$root/docs/project/implementation-plan/_index.md"
}

# write_grp <root> <id> <kind> <members|"-"> [exception] [title]
# Emits the CLOSED serialization byte-exactly; members "-" = empty value.
write_grp() {
    local root="$1" gid="$2" kind="$3" members="$4"
    local exception="${5:-}" title="${6:-Sample $2}"
    {
        printf '<!-- per-entry source: docs/project/groupings/%s.md; contract: docs/project/groupings/_rules.md -->\n' "$gid"
        printf -- '**%s — %s**\n' "$gid" "$title"
        printf 'Entry-Type: grouping\n'
        printf 'Kind: %s\n' "$kind"
        if [[ "$members" == "-" ]]; then
            printf 'Member-phases:\n'
        else
            printf 'Member-phases: %s\n' "$members"
        fi
        if [[ -n "$exception" ]]; then
            printf 'Single-member exception: %s\n' "$exception"
        fi
    } > "$root/docs/project/groupings/${gid}.md"
}

# write_toc <root> <"GRP-NNN:count">...
write_toc() {
    local root="$1"; shift
    {
        printf '# Table of contents — project-groupings\n\n'
        printf '## unassigned\n\n'
        local row
        for row in "$@"; do
            printf -- '- %s — x (phases: %s)\n' "${row%%:*}" "${row##*:}"
        done
    } > "$root/docs/project/groupings/_toc.md"
}

run_gate() { bash "$1/scripts/validate-docs.sh" 2>&1; }

# The groupings conformance family (path-scoped; strips the printer
# indent).
grp_family() {
    printf '%s\n' "$1" \
        | grep -E 'docs/project/groupings/|GROUPINGS\.md' \
        | grep -F '[conformance]' | sed 's/^  - //'
}

expect_line() {
    # expect_line <label> <out> <fixed-needle>
    if printf '%s\n' "$2" | grep -qF "$3"; then
        pass "$1"
    else
        fail "$1" "wanted: $3
got:
$2"
    fi
}

expect_clean_family() {
    local fam
    fam="$(grp_family "$2")"
    if [[ -z "$fam" ]]; then
        pass "$1"
    else
        fail "$1" "$fam"
    fi
}

RD_G="docs/project/groupings"
RD_I="docs/project/implementation-plan"

echo "== BD-189 groupings conformance leg (family-filtered output asserts) =="

# ── Positives ───────────────────────────────────────────────────────────

# P1 — populated valid tree: 2 real groupings (shared member phase-2),
# a single-member-with-exception, a Target-carrying member, a 1-member
# GRP-000 WITHOUT the exception field.
R="$FIXTURE_BASE/p1"; stage_tree "$R"
for n in 1 2 3 4 5; do write_phase "$R" "$n"; done
write_phase "$R" 1 not-started current
write_index "$R" 1 2 3 4 5
write_grp "$R" GRP-000 unassigned "phase-5" "" "Ungrouped (declared)"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
write_grp "$R" GRP-002 shared-feature "phase-2, phase-3"
write_grp "$R" GRP-003 refactor-cluster "phase-4" "solo scope by design"
write_toc "$R" GRP-000:1 GRP-001:2 GRP-002:2 GRP-003:1
out="$(run_gate "$R")"
expect_clean_family "P1: populated valid tree (shared member + exception + Target + 1-member GRP-000, no exception field) — zero groupings-family lines" "$out"

# P2 — empty groupings tree (sidecars only, no _toc.md) → clean.
R="$FIXTURE_BASE/p2"; stage_tree "$R"
out="$(run_gate "$R")"
expect_clean_family "P2: empty groupings tree passes (no entries, no _toc.md needed)" "$out"

# P3 — GRP-000 with an EMPTY member value (legal-empty) → clean.
R="$FIXTURE_BASE/p3"; stage_tree "$R"
write_grp "$R" GRP-000 unassigned "-" "" "Ungrouped (declared)"
write_toc "$R" GRP-000:0
out="$(run_gate "$R")"
expect_clean_family "P3: empty-member GRP-000 passes (legal-empty; the contrast pair to N6)" "$out"

# ── Per-entry negatives (each on a minimal 2-phase base) ────────────────
neg_base() {
    local root="$1"
    stage_tree "$root"
    write_phase "$root" 1
    write_phase "$root" 2
    write_index "$root" 1 2
}

# N1 — bad kind.
R="$FIXTURE_BASE/n1"; neg_base "$R"
write_grp "$R" GRP-001 made-up "phase-1, phase-2"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N1: out-of-enum Kind FAILS naming file + value" "$out" \
    "$RD_G/GRP-001.md [conformance] Kind 'made-up' not in kind-enum"

# N2 — duplicate member.
R="$FIXTURE_BASE/n2"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-1"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N2: duplicate member FAILS" "$out" \
    "$RD_G/GRP-001.md [conformance] duplicate member in Member-phases"

# N3 — descending order.
R="$FIXTURE_BASE/n3"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-2, phase-1"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N3: descending member order FAILS" "$out" \
    "$RD_G/GRP-001.md [conformance] Member-phases must list members in canonical ascending"

# N4 — 1 member without the exception field (min-2).
R="$FIXTURE_BASE/n4"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1"
write_toc "$R" GRP-001:1
out="$(run_gate "$R")"
expect_line "N4: 1 member without the exception field FAILS (min-2 / IFF-1)" "$out" \
    "$RD_G/GRP-001.md [conformance] 1 member without 'Single-member exception'"

# N5 — stale exception (2 members + the field).
R="$FIXTURE_BASE/n5"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2" "stale rationale"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N5: stale exception FAILS (IFF-1 the other direction)" "$out" \
    "$RD_G/GRP-001.md [conformance] stale 'Single-member exception'"

# N6 — zero members on a REAL grouping.
R="$FIXTURE_BASE/n6"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "-"
write_toc "$R" GRP-001:0
out="$(run_gate "$R")"
expect_line "N6: zero members on a real grouping FAILS" "$out" \
    "$RD_G/GRP-001.md [conformance] zero members"

# N7 — dangling member ref.
R="$FIXTURE_BASE/n7"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-9"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N7: dangling member ref FAILS naming the member + the missing entry" "$out" \
    "$RD_G/GRP-001.md [conformance] dangling member ref phase-9 — no $RD_I/phase-9.md entry"

# N8 — part-ref member TOKEN (grammar violation, not resolution).
R="$FIXTURE_BASE/n8"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2.Part-a"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N8: a part-ref member token FAILS the closed member grammar" "$out" \
    "$RD_G/GRP-001.md [conformance] Member-phases token 'phase-2.Part-a' is not a phase-N member"

# N9 — byte grammar: double space after a field colon.
R="$FIXTURE_BASE/n9"; neg_base "$R"
write_grp "$R" GRP-001 " user-journey" "phase-1, phase-2"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N9: double space after the field colon FAILS (byte grammar)" "$out" \
    "$RD_G/GRP-001.md [conformance] 'Kind:' must be followed by exactly one space"

# N10 — byte grammar: trailing whitespace.
R="$FIXTURE_BASE/n10"; neg_base "$R"
write_grp "$R" GRP-001 "user-journey " "phase-1, phase-2"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N10: trailing whitespace FAILS (byte grammar)" "$out" \
    "$RD_G/GRP-001.md [conformance] trailing whitespace on line 4"

# N11 — header spacing (double space after the em-dash).
R="$FIXTURE_BASE/n11"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2" "" " Sample"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N11: non-canonical header spacing FAILS" "$out" \
    "$RD_G/GRP-001.md [conformance] header title spacing non-canonical"

# N12 — wrong back-pointer.
R="$FIXTURE_BASE/n12"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
sed 's/^<!-- per-entry source:.*$/<!-- back -->/' \
    "$R/docs/project/groupings/GRP-001.md" > "$R/tmp.$$" \
    && mv "$R/tmp.$$" "$R/docs/project/groupings/GRP-001.md"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N12: a wrong line-1 back-pointer FAILS" "$out" \
    "$RD_G/GRP-001.md [conformance] line 1 must be the back-pointer comment"

# N13 — field order violation (Kind before Entry-Type).
R="$FIXTURE_BASE/n13"; neg_base "$R"
{
    printf '<!-- per-entry source: docs/project/groupings/GRP-001.md; contract: docs/project/groupings/_rules.md -->\n'
    printf -- '**GRP-001 — Sample GRP-001**\n'
    printf 'Kind: user-journey\n'
    printf 'Entry-Type: grouping\n'
    printf 'Member-phases: phase-1, phase-2\n'
} > "$R/docs/project/groupings/GRP-001.md"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N13: declared field-order violation FAILS" "$out" \
    "$RD_G/GRP-001.md [conformance] field order violates the declared field-order"

# N14 — Entry-Type value mismatch.
R="$FIXTURE_BASE/n14"; neg_base "$R"
{
    printf '<!-- per-entry source: docs/project/groupings/GRP-001.md; contract: docs/project/groupings/_rules.md -->\n'
    printf -- '**GRP-001 — Sample GRP-001**\n'
    printf 'Entry-Type: td\n'
    printf 'Kind: user-journey\n'
    printf 'Member-phases: phase-1, phase-2\n'
} > "$R/docs/project/groupings/GRP-001.md"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N14: an Entry-Type value mismatch FAILS" "$out" \
    "$RD_G/GRP-001.md [conformance] Entry-Type 'td' != schema entry-type 'grouping'"

# N15 — header ID != filename ID.
R="$FIXTURE_BASE/n15"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
sed 's/^\*\*GRP-001 /**GRP-002 /' \
    "$R/docs/project/groupings/GRP-001.md" > "$R/tmp.$$" \
    && mv "$R/tmp.$$" "$R/docs/project/groupings/GRP-001.md"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N15: header↔filename ID mismatch FAILS" "$out" \
    "$RD_G/GRP-001.md [conformance] header ID GRP-002 != filename ID GRP-001"

# N16 — free-floating prose line.
R="$FIXTURE_BASE/n16"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
printf 'Some free prose here.\n' >> "$R/docs/project/groupings/GRP-001.md"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N16: a free-floating prose line FAILS (closed serialization)" "$out" \
    "is not an admitted 'Field: value' line"

# N17 — blank line inside the serialization.
R="$FIXTURE_BASE/n17"; neg_base "$R"
{
    printf '<!-- per-entry source: docs/project/groupings/GRP-001.md; contract: docs/project/groupings/_rules.md -->\n'
    printf -- '**GRP-001 — Sample GRP-001**\n'
    printf 'Entry-Type: grouping\n'
    printf '\n'
    printf 'Kind: user-journey\n'
    printf 'Member-phases: phase-1, phase-2\n'
} > "$R/docs/project/groupings/GRP-001.md"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N17: a blank line inside the entry FAILS" "$out" \
    "$RD_G/GRP-001.md [conformance] blank line at line 4"

# N18 — missing trailing newline.
R="$FIXTURE_BASE/n18"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
printf '%s' "$(cat "$R/docs/project/groupings/GRP-001.md")" \
    > "$R/docs/project/groupings/GRP-001.md"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N18: a missing trailing newline FAILS (byte grammar)" "$out" \
    "$RD_G/GRP-001.md [conformance] file must end with a single trailing newline"

# N19 — forbidden GROUPINGS.md monolith.
R="$FIXTURE_BASE/n19"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
write_toc "$R" GRP-001:2
printf '# mono\n' > "$R/docs/project/GROUPINGS.md"
out="$(run_gate "$R")"
expect_line "N19: a reintroduced GROUPINGS.md monolith FAILS" "$out" \
    "docs/project/GROUPINGS.md [conformance] FORBIDDEN monolith mirror present"

# N20 — toc-sync: entry present, row missing.
R="$FIXTURE_BASE/n20"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
write_toc "$R"
out="$(run_gate "$R")"
expect_line "N20: toc-sync missing-row drift FAILS" "$out" \
    "$RD_G/_toc.md [conformance] missing entry GRP-001"

# N21 — toc-sync: ghost row (no entry file).
R="$FIXTURE_BASE/n21"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
write_toc "$R" GRP-001:2 GRP-002:2
out="$(run_gate "$R")"
expect_line "N21: toc-sync ghost-row drift FAILS" "$out" \
    "$RD_G/_toc.md [conformance] lists GRP-002 with no GRP-002.md entry file"

# N22 — toc-sync: entries present, NO _toc.md at all.
R="$FIXTURE_BASE/n22"; neg_base "$R"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
out="$(run_gate "$R")"
expect_line "N22: entries with no _toc.md FAIL (the stream's sole readable index)" "$out" \
    "$RD_G/_toc.md [conformance] missing — the groupings stream has 1 entry/entries"

# N23 — mis-named GRP-0000.md (tightened numbering).
R="$FIXTURE_BASE/n23"; neg_base "$R"
write_grp "$R" GRP-0000 user-journey "phase-1, phase-2"
out="$(run_gate "$R")"
expect_line "N23: GRP-0000.md FAILS as a mis-named grouping entry (never SKIP)" "$out" \
    "$RD_G/GRP-0000.md [conformance] mis-named grouping entry"

# N24 — the A2 close: present-but-empty Status on a phase-epic.
R="$FIXTURE_BASE/n24"; stage_tree "$R"
write_phase "$R" 1 ""
write_index "$R" 1
out="$(run_gate "$R")"
expect_line "N24: present-but-empty Status on a phase-epic FAILS (the A2 close)" "$out" \
    "$RD_I/phase-1.md [conformance] Status present but empty"

# N25 — the G-2 close: a member token RESOLVING to a phase-part entry.
R="$FIXTURE_BASE/n25"; stage_tree "$R"
write_phase "$R" 1
write_part "$R" 2
write_index "$R" 1 2
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
write_toc "$R" GRP-001:2
out="$(run_gate "$R")"
expect_line "N25: a part-typed member FAILS same-class-as-dangling, naming the member file" "$out" \
    "$RD_G/GRP-001.md [conformance] member phase-2 resolves to a phase-part entry ($RD_I/phase-2.md)"
expect_line "N25b: the part-member message directs to the parent phase (containment)" "$out" \
    "parts inherit membership by containment; list the parent phase instead"

# ── GRP-000 reserved-branch probes ──────────────────────────────────────

# N26 — exclusivity: a phase in GRP-000 AND a real grouping.
R="$FIXTURE_BASE/n26"; neg_base "$R"
write_grp "$R" GRP-000 unassigned "phase-1" "" "Ungrouped (declared)"
write_grp "$R" GRP-001 user-journey "phase-1, phase-2"
write_toc "$R" GRP-000:1 GRP-001:2
out="$(run_gate "$R")"
expect_line "N26: GRP-000 exclusivity violation FAILS naming the phase + both files" "$out" \
    "$RD_G/GRP-000.md [conformance] exclusivity violation — phase-1 is declared ungrouped in $RD_G/GRP-000.md AND is a member of $RD_G/GRP-001.md"

# N27 — the exception field on GRP-000 (forbidden at ANY count).
R="$FIXTURE_BASE/n27"; neg_base "$R"
write_grp "$R" GRP-000 unassigned "phase-1" "never legal" "Ungrouped (declared)"
write_toc "$R" GRP-000:1
out="$(run_gate "$R")"
expect_line "N27: the exception field on GRP-000 FAILS at any member count" "$out" \
    "$RD_G/GRP-000.md [conformance] 'Single-member exception' is FORBIDDEN on GRP-000"

# N28 — non-unassigned Kind on GRP-000.
R="$FIXTURE_BASE/n28"; neg_base "$R"
write_grp "$R" GRP-000 user-journey "phase-1" "" "Ungrouped (declared)"
write_toc "$R" GRP-000:1
out="$(run_gate "$R")"
expect_line "N28: a non-unassigned Kind on GRP-000 FAILS (pinned)" "$out" \
    "$RD_G/GRP-000.md [conformance] GRP-000 Kind is pinned to 'unassigned'"

# N29 — wrong pinned title on GRP-000.
R="$FIXTURE_BASE/n29"; neg_base "$R"
write_grp "$R" GRP-000 unassigned "phase-1" "" "Wrong Title"
write_toc "$R" GRP-000:1
out="$(run_gate "$R")"
expect_line "N29: a wrong GRP-000 title FAILS (pinned bytes)" "$out" \
    "$RD_G/GRP-000.md [conformance] GRP-000 title is pinned"

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
