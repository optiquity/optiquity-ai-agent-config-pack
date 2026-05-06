#!/usr/bin/env bash
# scripts/tests/tracker-migrate-reverse-test.sh — offline test suite
# for V1 §6.5 reverse migration + V1 §6.6/§6.6.1 sidecar (BD-067).
#
# Six groups:
#   1. Per-entry decoders — status/type/scope/severity/blockers/sections
#   2. Reconstruction — full Issue → v10 record round-trip
#   3. Mirror header strip — idempotency + presence/absence
#   4. End-to-end reverse — fixture issues → BACKLOG/STATUS/PLAN files
#      + sidecar; mode flip on `--disable`
#   5. Idempotency — second reverse produces byte-equal flat files
#   6. Doctor verb — basic checks

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
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-mirror.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-sidecar.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-reverse.sh"

PATH_SAVED="$PATH"

# Build a fake gh that handles both forward AND reverse paths:
# returns canned BD-001 / TD-010 / phase-3 view JSONs.
_build_fake_gh() {
    local bin="$1"
    cat > "$bin/gh" <<'FG'
#!/usr/bin/env bash
case "$1 $2" in
    "issue view")
        case "$3" in
            42)
                echo '{"number":42,"title":"BD-001: Add foo to bar","body":"<!-- pack-id: BD-001 -->\n<!-- template_version: bd-v11.0 -->\n<!-- pack-version: v11 -->\n\n## Description\n\nImplements foo on bar.\n\n## Context\n\nProject background.\n\n## File / Symbol\n\nscripts/foo.sh","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:open"},{"name":"type:feat"},{"name":"template:bd-v11.0"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/42"}'
                ;;
            43)
                echo '{"number":43,"title":"BD-002: Refactor bar","body":"<!-- pack-id: BD-002 -->\n<!-- template_version: bd-v11.0 -->\n\n## Description\n\nRefactor.","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:unblocked"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/43"}'
                ;;
            55)
                echo '{"number":55,"title":"TD-010: Document quux","body":"<!-- pack-id: TD-010 -->\n<!-- template_version: td-v11.0 -->\n\n## Description\n\nDoc gap.","state":"OPEN","stateReason":null,"labels":[{"name":"td-entry"},{"name":"status:open"},{"name":"scope:dependency"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/55"}'
                ;;
            58)
                echo '{"number":58,"title":"Phase 3 — Foundations","body":"<!-- pack-id: phase-3 -->\n<!-- template_version: phase-epic-v11.0 -->\n\n## Phase summary\n\nFoundations.","state":"OPEN","stateReason":null,"labels":[{"name":"phase-epic"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/58"}'
                ;;
        esac
        ;;
    "repo view") echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    *) ;;
esac
exit 0
FG
    chmod +x "$bin/gh"
}

_build_test_repo() {
    local repo="$1"
    cat > "$repo/tracker.toml" <<EOF
schema_version = 1
[backend]
name = "github"
repo = "fixture-org/fixture-repo"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
EOF
    mkdir -p "$repo/.pack-tracker"
    cat > "$repo/.pack-tracker/id-map.json" <<EOF
{
  "BD-001": {"id": "42", "url": "http://x/42"},
  "BD-002": {"id": "43", "url": "http://x/43"},
  "TD-010": {"id": "55", "url": "http://x/55"},
  "phase-3": {"id": "58", "url": "http://x/58"}
}
EOF
}

# ─────────────────────────────────────────────────────────────────
# Group 1: per-entry decoders
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: per-entry decoders ===\n"

assert_eq "1.1 status:open → Open"           "Open"       "$(_tmr_decode_status '["status:open"]')"
assert_eq "1.1 status:unblocked → Unblocked" "Unblocked"  "$(_tmr_decode_status '["status:unblocked"]')"
assert_eq "1.1 status:resolved → Resolved"   "Resolved"   "$(_tmr_decode_status '["status:resolved"]')"
assert_eq "1.1 status:cancelled → Cancelled" "Cancelled"  "$(_tmr_decode_status '["status:cancelled"]')"
assert_eq "1.1 no status → Open default"     "Open"       "$(_tmr_decode_status '[]')"

assert_eq "1.2 BD type"   "TODO(version)" "$(_tmr_decode_type "BD-001" '["bd-entry"]')"
assert_eq "1.2 TD TODO"   "TODO(scope)"   "$(_tmr_decode_type "TD-010" '["td-entry"]')"
assert_eq "1.2 TD KNOWN-GAP" "KNOWN GAP(scope)" "$(_tmr_decode_type "TD-010" '["td-entry","severity:critical"]')"

assert_eq "1.3 scope decode"     "dependency" "$(_tmr_decode_scope    '["scope:dependency","other"]')"
assert_eq "1.3 severity decode"  "critical"   "$(_tmr_decode_severity '["severity:critical"]')"
assert_eq "1.3 missing scope"    ""           "$(_tmr_decode_scope    '["status:open"]')"

# 1.4 Section extraction.
body='<!-- pack-id: BD-001 -->

## Description

Section text here.
With multiple lines.

## Context

Background.

## File / Symbol

scripts/foo.sh'
desc=$(printf '%s' "$body" | _tmr_extract_section "Description")
ctx=$(printf  '%s' "$body" | _tmr_extract_section "Context")
fs=$(printf   '%s' "$body" | _tmr_extract_section "File / Symbol")
miss=$(printf '%s' "$body" | _tmr_extract_section "Resolution")
assert_contains "1.4 Description extracted" "$desc" "Section text here."
assert_contains "1.4 Description multi-line" "$desc" "With multiple lines."
assert_contains "1.4 Context extracted"     "$ctx"  "Background."
assert_contains "1.4 File/Symbol extracted" "$fs"   "scripts/foo.sh"
assert_eq       "1.4 missing section → empty" "" "$miss"

# 1.5 Blockers from sub-issue parent + comment markers.
mapping='{"BD-001":{"id":"42"},"BD-002":{"id":"43"},"phase-3":{"id":"58"}}'
body_with_blockers='## Description

Some text. Blocked by #43.'
blockers=$(_tmr_decode_blockers "$body_with_blockers" "$mapping" "58")
assert_contains "1.5 phase-3 sub-issue parent in blockers" "$blockers" "phase-3"
assert_contains "1.5 BD-002 comment marker in blockers"    "$blockers" "BD-002"
# 1.5b Empty-body blockers
empty_blockers=$(_tmr_decode_blockers "" "$mapping" "")
assert_eq "1.5 no blockers → []" "[]" "$empty_blockers"

# ─────────────────────────────────────────────────────────────────
# Group 2: reconstruction
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: reconstruction ===\n"

issue=$(jq -n '{
  number: 42, id: "42",
  title: "BD-001: Add foo to bar",
  body: "<!-- pack-id: BD-001 -->\n\n## Description\n\nImplements foo.\n\n## Context\n\nBackground.\n\n## File / Symbol\n\nscripts/foo.sh",
  state: "open",
  labels: ["bd-entry","status:open","type:feat"],
  parent: ""
}')
rec=$(tracker_migrate_reverse_reconstruct "$issue" '{}')
assert_eq "2.1 reconstruct pack_id"     "BD-001"           "$(printf '%s' "$rec" | jq -r .pack_id)"
assert_eq "2.1 reconstruct title clean" "Add foo to bar"   "$(printf '%s' "$rec" | jq -r .title)"
assert_eq "2.1 reconstruct status"      "Open"             "$(printf '%s' "$rec" | jq -r .status)"
assert_eq "2.1 reconstruct file_symbol" "scripts/foo.sh"   "$(printf '%s' "$rec" | jq -r .file_symbol)"
assert_contains "2.1 reconstruct description" "$(printf '%s' "$rec" | jq -r .description)" "Implements foo"
assert_contains "2.1 reconstruct context"     "$(printf '%s' "$rec" | jq -r .context)"     "Background"

# 2.2 Unblocks-inverse pass
entries='[
  {"pack_id":"BD-001","blockers":["BD-002"]},
  {"pack_id":"BD-002","blockers":["phase-3"]},
  {"pack_id":"BD-003","blockers":[]}
]'
out=$(printf '%s' "$entries" | _tmr_compute_unblocks)
ub_bd2=$(printf '%s' "$out" | jq -r '.[] | select(.pack_id=="BD-002") | .unblocks | join(",")')
ub_phase3_consumers=$(printf '%s' "$out" | jq -r '.[] | select(.pack_id=="BD-001") | .unblocks | length')
assert_eq "2.2 BD-002 unblocks BD-001" "BD-001" "$ub_bd2"
assert_eq "2.2 BD-001 unblocks 0"      "0"      "$ub_phase3_consumers"

# ─────────────────────────────────────────────────────────────────
# Group 3: mirror header strip
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: mirror header strip ===\n"

# 3.1 header present → stripped cleanly
tmp=$(mktemp -t tmr-3.XXXXXX)
{
    echo "<!--"
    echo "  Header line 1"
    echo "-->"
    echo ""
    echo "Body line 1"
    echo "Body line 2"
} > "$tmp"
tracker_mirror_header_strip "$tmp"
assert_eq "3.1 strip leaves only body line 1+2" "Body line 1" "$(head -n 1 "$tmp")"
[[ ! "$(head -n 1 "$tmp")" == "<!--" ]] && t_pass "3.1 header removed" || t_fail "3.1 header removed"
rm -f "$tmp"

# 3.2 no-header → file unchanged
tmp=$(mktemp -t tmr-3b.XXXXXX)
echo "Just a body" > "$tmp"
before=$(cat "$tmp")
tracker_mirror_header_strip "$tmp"
after=$(cat "$tmp")
# Allow trailing-newline normalization.
assert_contains "3.2 no-header file body preserved" "$after" "Just a body"
rm -f "$tmp"

# 3.3 idempotent (strip twice → same as strip once)
tmp=$(mktemp -t tmr-3c.XXXXXX)
{ echo "<!--"; echo "  H"; echo "-->"; echo ""; echo "Body"; } > "$tmp"
tracker_mirror_header_strip "$tmp"
snap=$(cat "$tmp")
tracker_mirror_header_strip "$tmp"
snap2=$(cat "$tmp")
assert_eq "3.3 strip twice = strip once" "$snap" "$snap2"
rm -f "$tmp"

# 3.4 write+strip round-trip preserves body
tmp=$(mktemp -t tmr-3d.XXXXXX)
echo "Original body" > "$tmp"
tracker_mirror_header_write "$tmp" "x/y"
tracker_mirror_header_strip "$tmp"
final=$(cat "$tmp")
assert_eq "3.4 write+strip round-trip" "Original body" "$(printf '%s' "$final" | head -n 1)"
rm -f "$tmp"

# ─────────────────────────────────────────────────────────────────
# Group 4: end-to-end reverse
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: end-to-end reverse ===\n"

FAKE=$(mktemp -d -t tmr-fakegh.XXXXXX)
_build_fake_gh "$FAKE"
REPO=$(mktemp -d -t tmr-repo.XXXXXX)
_build_test_repo "$REPO"

export PATH="$FAKE:$PATH_SAVED"
output=$(tracker_migrate_reverse_run "$REPO" 2>&1)
rc=$?
export PATH="$PATH_SAVED"

assert_eq       "4.1 reverse rc=0"          "0" "$rc"
assert_contains "4.1 reports 3 entries"     "$output" "reconstructed 3 BACKLOG entries"
assert_contains "4.1 reports 1 phase epic"  "$output" "1 phase epic"
assert_contains "4.1 reports complete"      "$output" "reverse: complete"

[[ -f "$REPO/BACKLOG.md" ]]            && t_pass "4.1 BACKLOG.md emitted" || t_fail "4.1 BACKLOG.md emitted"
[[ -f "$REPO/IMPLEMENTATION_PLAN.md" ]] && t_pass "4.1 IMPLEMENTATION_PLAN.md emitted" || t_fail "4.1 IMPLEMENTATION_PLAN.md emitted"
[[ -f "$REPO/STATUS.md" ]]             && t_pass "4.1 STATUS.md emitted" || t_fail "4.1 STATUS.md emitted"
[[ -f "$REPO/CHANGELOG.md" ]]          && t_pass "4.1 CHANGELOG.md emitted" || t_fail "4.1 CHANGELOG.md emitted"

# 4.2 BACKLOG.md content shape
backlog=$(cat "$REPO/BACKLOG.md")
assert_contains "4.2 BACKLOG has BD-001 entry" "$backlog" "**BD-001 — Add foo to bar**"
assert_contains "4.2 BACKLOG has TD-010 entry" "$backlog" "**TD-010 — Document quux**"
assert_contains "4.2 BACKLOG has Status: Open" "$backlog" "Status: Open"
assert_contains "4.2 BACKLOG has File/Symbol"  "$backlog" "File/Symbol: scripts/foo.sh"
assert_contains "4.2 BACKLOG has Description"  "$backlog" "Description: Implements foo on bar."

# 4.3 STATUS reports counts
status_md=$(cat "$REPO/STATUS.md")
assert_contains "4.3 STATUS phase line"     "$status_md" "Phase 3 — Foundations"
assert_contains "4.3 STATUS Open count"     "$status_md" "Open: 3"

# 4.4 Sidecar emitted
sidecar=$(ls "$REPO/.pack-tracker/reverse.sidecar."*.md 2>/dev/null | head -n 1)
[[ -n "$sidecar" && -f "$sidecar" ]] && t_pass "4.4 sidecar file present" || t_fail "4.4 sidecar file present" "missing"
sidecar_content=$(cat "$sidecar")
assert_contains "4.4 sidecar has BD-001 section"   "$sidecar_content" "## BD-001 (gh #42)"
assert_contains "4.4 sidecar has phase-3 section"  "$sidecar_content" "## phase-3 (gh #58)"
assert_contains "4.4 sidecar has extra_fields"     "$sidecar_content" "### extra_fields"
assert_contains "4.4 sidecar has reactions block"  "$sidecar_content" "### reactions"
assert_contains "4.4 sidecar empty extra_fields at v11.0" "$sidecar_content" "empty at v11.0"

# 4.5 No mirror header (V1 §6.5 step 8: stripped after reverse).
first_line=$(head -n 1 "$REPO/BACKLOG.md")
[[ "$first_line" != "<!--" ]] && t_pass "4.5 no mirror header on reverse output" \
    || t_fail "4.5 no mirror header on reverse output"

# 4.6 last_reverse_run set; mode not flipped (no --disable).
assert_contains "4.6 tracker.toml has last_reverse_run" \
    "$(cat "$REPO/tracker.toml")" "last_reverse_run = \""
assert_eq "4.6 mode still tracker" "tracker" "$(tracker_config_get "$REPO/tracker.toml" mode.state)"

# 4.7 With --disable flag, mode flips to flat-file.
export PATH="$FAKE:$PATH_SAVED"
tracker_migrate_reverse_run "$REPO" 0 1 0 >/dev/null 2>&1
export PATH="$PATH_SAVED"
assert_eq "4.7 mode flipped to flat-file via --disable" "flat-file" \
    "$(tracker_config_get "$REPO/tracker.toml" mode.state)"

rm -rf "$FAKE" "$REPO"

# ─────────────────────────────────────────────────────────────────
# Group 5: idempotency (second reverse → byte-equal)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: idempotency ===\n"

FAKE=$(mktemp -d -t tmr-fake5.XXXXXX); _build_fake_gh "$FAKE"
REPO=$(mktemp -d -t tmr-repo5.XXXXXX); _build_test_repo "$REPO"

export PATH="$FAKE:$PATH_SAVED"
tracker_migrate_reverse_run "$REPO" >/dev/null 2>&1
backlog1=$(cat "$REPO/BACKLOG.md")
status1=$(cat  "$REPO/STATUS.md")
sleep 1
tracker_migrate_reverse_run "$REPO" >/dev/null 2>&1
backlog2=$(cat "$REPO/BACKLOG.md")
status2=$(cat  "$REPO/STATUS.md")
export PATH="$PATH_SAVED"

assert_eq "5.1 BACKLOG.md byte-equal across runs" "$backlog1" "$backlog2"
assert_eq "5.1 STATUS.md byte-equal across runs"  "$status1"  "$status2"
rm -rf "$FAKE" "$REPO"

# ─────────────────────────────────────────────────────────────────
# Group 6: doctor verb
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 6: doctor verb ===\n"

REPO_DR=$(mktemp -d -t tmr-doctor.XXXXXX)
_build_test_repo "$REPO_DR"
mkdir -p "$REPO_DR/.github/ISSUE_TEMPLATE"
touch "$REPO_DR/.github/ISSUE_TEMPLATE/work-item.yml"

# Source the doctor function (defined in scripts/tracker-migrate.sh).
# We can't source the dispatcher itself (it has set -euo pipefail and
# main "$@" at end), so define a stand-alone here matching the impl.
# Easiest: invoke via the script.
output=$(bash "$REPO_ROOT/scripts/tracker-migrate.sh" doctor --repo-root "$REPO_DR" 2>&1)
assert_contains "6.1 doctor reports OK on tracker.toml"   "$output" "[OK]   tracker.toml schema_version supported"
assert_contains "6.1 doctor reports OK on mapping file"   "$output" "[OK]   mapping file is valid JSON"
assert_contains "6.1 doctor reports OK on pack-ids"       "$output" "[OK]   all mapping pack-ids are well-shaped"
assert_contains "6.1 doctor reports OK on templates"      "$output" "[OK]   .github/ISSUE_TEMPLATE present"
rm -rf "$REPO_DR"

# 6.2 doctor surfaces malformed pack-id
REPO_BAD=$(mktemp -d -t tmr-doctor-bad.XXXXXX)
_build_test_repo "$REPO_BAD"
mkdir -p "$REPO_BAD/.github/ISSUE_TEMPLATE"
touch "$REPO_BAD/.github/ISSUE_TEMPLATE/work-item.yml"
# Inject a bad pack-id key into the mapping.
jq '. + {"weird-id": {"id":"99","url":"x"}}' "$REPO_BAD/.pack-tracker/id-map.json" > "$REPO_BAD/.pack-tracker/_tmp.json"
mv "$REPO_BAD/.pack-tracker/_tmp.json" "$REPO_BAD/.pack-tracker/id-map.json"

output=$(bash "$REPO_ROOT/scripts/tracker-migrate.sh" doctor --repo-root "$REPO_BAD" 2>&1)
rc=$?
assert_contains "6.2 doctor warns on malformed pack-id" "$output" "[WARN] mapping has malformed pack-ids"
assert_eq       "6.2 doctor returns rc=1 on warnings"   "1" "$rc"
rm -rf "$REPO_BAD"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
