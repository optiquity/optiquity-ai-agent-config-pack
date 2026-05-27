#!/usr/bin/env bash
# scripts/tests/test-issue-forms.sh — offline structural test suite for
# the issue-template form family (BD-063).
#
# Verifies, for both surfaces (pack-root and project-template):
#   1. All three forms (work-item.yml, inbound.yml, config.yml) parse
#      as valid YAML and load to a dict.
#   2. work-item.yml structure: title format, labels (incl. template:work-item-v11.0),
#      body block presence, wi-type dropdown's 4 options, phase-task fields
#      present, blockers help text mentions phase-N / phase-N.M, trailing
#      markdown trio (pack-id PENDING + template_version + pack-version).
#   3. inbound.yml structure: labels, in-category dropdown's 7 options,
#      trailing markdown trio with template_version: inbound-v11.0.
#   4. config.yml: blank_issues_enabled false; contact_links present.
#   5. Cross-surface invariants: forms have identical schema-relevant
#      fields except for namespace examples (BD vs TD).
#
# Usage: bash scripts/tests/test-issue-forms.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

# Read a value from a YAML file via a Python expression on `data`.
# Usage: yq_get <yaml-path> <python-expr-using-data>
yq_get() {
    local path="$1"
    local expr="$2"
    python3 -c "
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]).read())
print($expr)
" "$path"
}

raw_file() { cat "$1"; }

assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' actual='$3'"; fi
}

assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' not in (first 200): ${2:0:200}"; fi
}

# ─────────────────────────────────────────────────────────────────
# Group 1: All forms parse as YAML
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: YAML parses on both surfaces ===\n"

for surface in ".github" "project-template/.github"; do
    for filename in work-item.yml inbound.yml config.yml; do
        path="$REPO_ROOT/$surface/ISSUE_TEMPLATE/$filename"
        if python3 -c "import yaml; yaml.safe_load(open('$path'))" 2>/dev/null; then
            t_pass "$surface/ISSUE_TEMPLATE/$filename parses"
        else
            t_fail "$surface/ISSUE_TEMPLATE/$filename parse failure"
        fi
    done
done

# ─────────────────────────────────────────────────────────────────
# Group 2: work-item.yml structure (run for both surfaces)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: work-item.yml structure ===\n"

check_workitem() {
    local label="$1"
    local path="$2"
    # Optional 3rd arg: surface kind. "pack" (default) admits the `bd`
    # wi-type option; "project" does NOT — per BD-193 boundary cleanup,
    # BD entries are pack-internal and client projects use TD.
    local surface_kind="${3:-pack}"

    assert_eq "$label name has 'work item'" "True" \
        "$(yq_get "$path" "'work item' in data['name'].lower()")"

    labels=$(yq_get "$path" "sorted(data.get('labels', []))")
    assert_contains "$label labels include work-item"        "$labels" "'work-item'"
    assert_contains "$label labels include needs-triage"     "$labels" "'needs-triage'"
    assert_contains "$label labels include template:work-item-v11.0" "$labels" "'template:work-item-v11.0'"

    options=$(yq_get "$path" "[b['attributes']['options'] for b in data['body'] if b.get('type')=='dropdown' and b.get('id')=='wi-type'][0]")
    if [[ "$surface_kind" == "pack" ]]; then
        assert_contains "$label wi-type has bd"                "$options" "'bd'"
    else
        # Project-side MUST NOT admit `bd` (BD-193 F2.d).
        if [[ "$options" == *"'bd'"* ]]; then
            t_fail "$label wi-type must NOT have bd (project-side)" \
                "options='$options' contains 'bd' — BD entries are pack-internal"
        else
            t_pass "$label wi-type correctly omits bd (project-side)"
        fi
    fi
    assert_contains "$label wi-type has td"                    "$options" "'td'"
    assert_contains "$label wi-type has phase-epic-skeleton"   "$options" "'phase-epic-skeleton'"
    assert_contains "$label wi-type has phase-task-skeleton"   "$options" "'phase-task-skeleton'"

    for fid in wi-task-title wi-problem-goal-success wi-files wi-definition-of-done wi-dependencies; do
        present=$(yq_get "$path" "any(b.get('id')=='$fid' for b in data['body'])")
        assert_eq "$label phase-task field $fid present" "True" "$present"
    done

    blockers_desc=$(yq_get "$path" "[b['attributes']['description'] for b in data['body'] if b.get('id')=='wi-blockers'][0]")
    assert_contains "$label wi-blockers description names phase-N"   "$blockers_desc" "phase-N"
    assert_contains "$label wi-blockers description names phase-N.M" "$blockers_desc" "phase-N.M"

    raw=$(raw_file "$path")
    assert_contains "$label HTML-comment pack-id: PENDING"             "$raw" "<!-- pack-id: PENDING -->"
    assert_contains "$label HTML-comment template_version 2-digit"     "$raw" "<!-- template_version: work-item-v11.0 -->"
    assert_contains "$label HTML-comment pack-version: v11"            "$raw" "<!-- pack-version: v11 -->"
}

check_workitem "pack-root work-item.yml"        "$REPO_ROOT/.github/ISSUE_TEMPLATE/work-item.yml"                  "pack"
check_workitem "project-template work-item.yml" "$REPO_ROOT/project-template/.github/ISSUE_TEMPLATE/work-item.yml" "project"

# ─────────────────────────────────────────────────────────────────
# Group 3: inbound.yml structure
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: inbound.yml structure ===\n"

check_inbound() {
    local label="$1"
    local path="$2"

    labels=$(yq_get "$path" "sorted(data.get('labels', []))")
    assert_contains "$label labels include inbound"                 "$labels" "'inbound'"
    assert_contains "$label labels include needs-triage"            "$labels" "'needs-triage'"
    assert_contains "$label labels include template:inbound-v11.0"  "$labels" "'template:inbound-v11.0'"

    options=$(yq_get "$path" "[b['attributes']['options'] for b in data['body'] if b.get('type')=='dropdown' and b.get('id')=='in-category'][0]")
    for opt in bug feature-request \
               pack-feedback-workflow pack-feedback-prompt pack-feedback-agent-perf \
               pack-feedback-friction pack-feedback-open-question; do
        assert_contains "$label in-category has $opt" "$options" "'$opt'"
    done

    required_obs=$(yq_get "$path" "[b.get('validations',{}).get('required',False) for b in data['body'] if b.get('id')=='in-observation'][0]")
    assert_eq "$label in-observation required" "True" "$required_obs"

    raw=$(raw_file "$path")
    assert_contains "$label HTML-comment pack-id: PENDING"          "$raw" "<!-- pack-id: PENDING -->"
    assert_contains "$label HTML-comment template_version inbound"  "$raw" "<!-- template_version: inbound-v11.0 -->"
    assert_contains "$label HTML-comment pack-version: v11"         "$raw" "<!-- pack-version: v11 -->"
}

check_inbound "pack-root inbound.yml"        "$REPO_ROOT/.github/ISSUE_TEMPLATE/inbound.yml"
check_inbound "project-template inbound.yml" "$REPO_ROOT/project-template/.github/ISSUE_TEMPLATE/inbound.yml"

# ─────────────────────────────────────────────────────────────────
# Group 4: config.yml structure
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: config.yml structure ===\n"

check_config() {
    local label="$1"
    local path="$2"
    bie=$(yq_get "$path" "data.get('blank_issues_enabled')")
    assert_eq "$label blank_issues_enabled = False" "False" "$bie"
    cl=$(yq_get "$path" "len(data.get('contact_links', [])) >= 1")
    assert_eq "$label contact_links has at least 1 entry" "True" "$cl"
}

check_config "pack-root config.yml"        "$REPO_ROOT/.github/ISSUE_TEMPLATE/config.yml"
check_config "project-template config.yml" "$REPO_ROOT/project-template/.github/ISSUE_TEMPLATE/config.yml"

# ─────────────────────────────────────────────────────────────────
# Group 5: cross-surface invariants
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: cross-surface invariants ===\n"

pack_opts=$(yq_get "$REPO_ROOT/.github/ISSUE_TEMPLATE/work-item.yml" \
    "sorted([b['attributes']['options'] for b in data['body'] if b.get('id')=='wi-type'][0])")
proj_opts=$(yq_get "$REPO_ROOT/project-template/.github/ISSUE_TEMPLATE/work-item.yml" \
    "sorted([b['attributes']['options'] for b in data['body'] if b.get('id')=='wi-type'][0])")
# Per BD-193 F2.d: pack-side admits `bd`, project-side does NOT. The
# project-side options must be exactly the pack-side options minus `bd`.
expected_proj_opts=$(python3 -c "
import sys
pack=$pack_opts
print(sorted([o for o in pack if o != 'bd']))
")
assert_eq "5.1 wi-type options pack admits bd vs project omits bd" \
    "$expected_proj_opts" "$proj_opts"

pack_cats=$(yq_get "$REPO_ROOT/.github/ISSUE_TEMPLATE/inbound.yml" \
    "sorted([b['attributes']['options'] for b in data['body'] if b.get('id')=='in-category'][0])")
proj_cats=$(yq_get "$REPO_ROOT/project-template/.github/ISSUE_TEMPLATE/inbound.yml" \
    "sorted([b['attributes']['options'] for b in data['body'] if b.get('id')=='in-category'][0])")
assert_eq "5.2 in-category options identical across surfaces" "$pack_cats" "$proj_cats"

pack_title=$(yq_get "$REPO_ROOT/.github/ISSUE_TEMPLATE/work-item.yml" "data.get('title', '')")
proj_title=$(yq_get "$REPO_ROOT/project-template/.github/ISSUE_TEMPLATE/work-item.yml" "data.get('title', '')")
assert_contains "5.3 pack-root title uses BD- namespace"        "$pack_title" "BD-NNN"
assert_contains "5.3 project-template title uses TD- namespace" "$proj_title" "TD-NNN"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
