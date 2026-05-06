#!/usr/bin/env bash
# scripts/tests/template-version-test.sh — D-18 dual-carrier
# read/reconcile tests (BD-069).
#
# Three groups:
#   1. Body-marker reader — extracts template_version from issue body
#   2. Label reader — extracts template_version from labels (string
#      array or object array shapes)
#   3. Reconcile — both agree, mismatch, missing, both empty
#   4. Path helpers — extract version dir; compose archive path

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }
assert_eq()       { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }
assert_contains() { if [[ "$2" == *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' missing"; fi; }

# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/template-version.sh"

# ─────────────────────────────────────────────────────────────────
# Group 1: body-marker reader
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: body-marker reader ===\n"

issue_bd='{"body":"<!-- pack-id: BD-001 -->\n<!-- template_version: bd-v11.0 -->\n<!-- pack-version: v11 -->\n\n## Description"}'
issue_td='{"body":"<!-- template_version: td-v11.0 -->"}'
issue_phase='{"body":"<!-- template_version: phase-task-v11.2 -->"}'
issue_no_marker='{"body":"## Description\n\nNo marker here."}'
issue_no_body='{"body":""}'
issue_malformed='{"body":"<!-- template_version: --><!-- second -->"}'

assert_eq "1.1 BD body marker → bd-v11.0"        "bd-v11.0"          "$(template_version_read_body "$issue_bd")"
assert_eq "1.1 TD body marker → td-v11.0"        "td-v11.0"          "$(template_version_read_body "$issue_td")"
assert_eq "1.1 phase-task body marker"           "phase-task-v11.2"  "$(template_version_read_body "$issue_phase")"
assert_eq "1.1 no marker → empty"                ""                  "$(template_version_read_body "$issue_no_marker")"
assert_eq "1.1 empty body → empty"               ""                  "$(template_version_read_body "$issue_no_body")"

# ─────────────────────────────────────────────────────────────────
# Group 2: label reader
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: label reader ===\n"

# String array shape (canonical Issue post-normalization).
labels_str='["bd-entry","template:bd-v11.0","status:open"]'
labels_str_td='["td-entry","template:td-v11.0"]'
labels_str_phase='["phase-task","phase-3","template:phase-task-v11.2"]'
labels_str_none='["bd-entry","status:open"]'
labels_str_first='["template:bd-v11.0","template:bd-v11.1"]'   # first wins

# Object array shape (raw gh issue view).
labels_obj='[{"name":"bd-entry"},{"name":"template:td-v11.0"}]'

assert_eq "2.1 string-array template:bd-v11.0"      "bd-v11.0"          "$(template_version_read_label "$labels_str")"
assert_eq "2.1 string-array template:td-v11.0"      "td-v11.0"          "$(template_version_read_label "$labels_str_td")"
assert_eq "2.1 string-array phase-task-v11.2"       "phase-task-v11.2"  "$(template_version_read_label "$labels_str_phase")"
assert_eq "2.1 no template label → empty"           ""                  "$(template_version_read_label "$labels_str_none")"
assert_eq "2.1 first template:* wins"               "bd-v11.0"          "$(template_version_read_label "$labels_str_first")"
assert_eq "2.2 object-array template:td-v11.0"      "td-v11.0"          "$(template_version_read_label "$labels_obj")"

# Empty / malformed inputs return empty without error.
assert_eq "2.3 empty array → empty"                 ""                  "$(template_version_read_label '[]')"
assert_eq "2.3 not-an-array → empty"                ""                  "$(template_version_read_label '"not an array"')"

# ─────────────────────────────────────────────────────────────────
# Group 3: reconcile
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: reconcile ===\n"

# 3.1 both agree → return canonical
assert_eq "3.1 both agree → bd-v11.0" "bd-v11.0" "$(template_version_reconcile "bd-v11.0" "bd-v11.0")"

# 3.2 mismatch → typed validation error, rc=1
err=$(template_version_reconcile "bd-v11.0" "bd-v11.1" 2>&1 1>/dev/null) || true
assert_contains "3.2 mismatch → ERROR: validation"  "$err" "ERROR: validation"
assert_contains "3.2 message names body version"    "$err" "bd-v11.0"
assert_contains "3.2 message names label version"   "$err" "bd-v11.1"
assert_contains "3.2 verb-line points at update-templates" "$err" "update-templates"

# 3.3 body missing → use label, warn on stderr
out=$(template_version_reconcile "" "bd-v11.0" 2>/dev/null)
err=$(template_version_reconcile "" "bd-v11.0" 2>&1 1>/dev/null)
assert_eq       "3.3 body missing → returns label" "bd-v11.0"   "$out"
assert_contains "3.3 body missing → warns"          "$err"       "WARN"

# 3.4 label missing → use body, warn on stderr
out=$(template_version_reconcile "bd-v11.0" "" 2>/dev/null)
err=$(template_version_reconcile "bd-v11.0" "" 2>&1 1>/dev/null)
assert_eq       "3.4 label missing → returns body" "bd-v11.0"   "$out"
assert_contains "3.4 label missing → warns"        "$err"       "WARN"

# 3.5 both missing → empty + rc=0
out=$(template_version_reconcile "" "" 2>/dev/null)
rc=$?
assert_eq "3.5 both missing → empty" ""  "$out"
assert_eq "3.5 both missing → rc=0"  "0" "$rc"

# ─────────────────────────────────────────────────────────────────
# Group 4: path helpers
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: path helpers ===\n"

assert_eq "4.1 bd-v11.0 → v11.0"           "v11.0"  "$(template_version_extract_version_dir "bd-v11.0")"
assert_eq "4.1 td-v11.0 → v11.0"           "v11.0"  "$(template_version_extract_version_dir "td-v11.0")"
assert_eq "4.1 phase-task-v11.2 → v11.2"   "v11.2"  "$(template_version_extract_version_dir "phase-task-v11.2")"
assert_eq "4.1 phase-epic-v12.5 → v12.5"   "v12.5"  "$(template_version_extract_version_dir "phase-epic-v12.5")"
assert_eq "4.1 malformed → empty"          ""        "$(template_version_extract_version_dir "no-version-suffix")"

# 4.2 archive path composition
expected="maintenance-docs/v11-research/templates-archive/v11.0/bd-v11.0/SCHEMA.md"
assert_eq "4.2 archive path bd-v11.0" "$expected" "$(template_version_archive_path "bd-v11.0")"
expected2="maintenance-docs/v11-research/templates-archive/v11.2/phase-task-v11.2/SCHEMA.md"
assert_eq "4.2 archive path phase-task-v11.2" "$expected2" "$(template_version_archive_path "phase-task-v11.2")"

# 4.3 Verify the archive path the sidecar now emits matches the
# real archive layout for v11.0 (BD-064 ships those SCHEMA.md files).
real_v11_0_paths=(
    "$REPO_ROOT/$(template_version_archive_path "bd-v11.0")"
    "$REPO_ROOT/$(template_version_archive_path "td-v11.0")"
    "$REPO_ROOT/$(template_version_archive_path "phase-epic-v11.0")"
    "$REPO_ROOT/$(template_version_archive_path "phase-task-v11.0")"
    "$REPO_ROOT/$(template_version_archive_path "inbound-v11.0")"
)
for p in "${real_v11_0_paths[@]}"; do
    if [[ -f "$p" ]]; then
        t_pass "4.3 archive path resolves to existing file: $(basename "$(dirname "$p")")"
    else
        t_fail "4.3 archive path resolves to existing file" "missing: $p"
    fi
done

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
