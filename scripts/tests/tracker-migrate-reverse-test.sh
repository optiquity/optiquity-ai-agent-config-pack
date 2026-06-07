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
assert_not_contains() { if [[ "$2" != *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' unexpectedly present"; fi; }

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

# BD-204 §3.3: the canonical fixture entry bodies (raw_body = lines 2..EOF of
# the per-entry file). The reverse pack emit now writes raw_body VERBATIM from
# the pack-entry-body-gz64 blob, so the fake-gh issues MUST carry the blob and
# the round-trip is byte-faithful. BD-001 is a NO-Blockers entry (proves the
# rewrite injects NO `Blockers: None` / `Resolved: n/a` lines — invariant 7).
FIX_BD001_RAWBODY=$'**BD-001 — Add foo to bar**\nType: TODO(version)\nStatus: Open\nFile/Symbol: scripts/foo.sh\nDescription: Implements foo on bar.\n'
FIX_BD002_RAWBODY=$'**BD-002 — Refactor bar**\nType: TODO(version)\nStatus: Unblocked\nBlockers: BD-001\nFile/Symbol: scripts/bar.sh\nDescription: Refactor.\n'
# Precompute the gz64 blobs via the PRODUCTION encoder (codec parity).
FIX_BD001_BLOB=$(printf '%s' "$FIX_BD001_RAWBODY" | _tmf_gz64_encode)
FIX_BD002_BLOB=$(printf '%s' "$FIX_BD002_RAWBODY" | _tmf_gz64_encode)

# Build a fake gh that handles both forward AND reverse paths:
# returns canned BD-001 / TD-010 / phase-3 view JSONs.
_build_fake_gh() {
    local bin="$1"
    # Quoted heredoc (no expansion); substitute the precomputed blob payloads
    # afterward via sed (the base64 alphabet contains no sed-special chars).
    cat > "$bin/gh" <<'FG'
#!/usr/bin/env bash
# Parse --label out of `issue list` flags (V1 §6.5 step 1 calls
# provider_list with bd-entry / td-entry / phase-epic filters).
label=""
for ((i=1; i<=$#; i++)); do
    if [[ "${!i}" == "--label" ]]; then
        j=$((i+1))
        label="${!j}"
        break
    fi
done
case "$1 $2" in
    "issue list")
        case "$label" in
            bd-entry)   echo '[{"number":42,"title":"BD-001: Add foo to bar","state":"OPEN","labels":[{"name":"bd-entry"}],"assignees":[],"milestone":null,"url":"http://x/42"},{"number":43,"title":"BD-002: Refactor bar","state":"OPEN","labels":[{"name":"bd-entry"}],"assignees":[],"milestone":null,"url":"http://x/43"}]' ;;
            td-entry)   echo '[{"number":55,"title":"TD-010: Document quux","state":"OPEN","labels":[{"name":"td-entry"}],"assignees":[],"milestone":null,"url":"http://x/55"}]' ;;
            phase-epic) echo '[{"number":58,"title":"Phase 3 — Foundations","state":"OPEN","labels":[{"name":"phase-epic"}],"assignees":[],"milestone":null,"url":"http://x/58"}]' ;;
            *)          echo '[]' ;;
        esac
        ;;
    "issue view")
        case "$3" in
            42)
                echo '{"number":42,"title":"BD-001: Add foo to bar","body":"<!-- pack-id: BD-001 -->\n<!-- template_version: bd-v11.0 -->\n<!-- pack-version: v11 -->\n<!-- pack-entry-body-gz64: @@BD001_BLOB@@ -->\n\n## Description\n\nImplements foo on bar.\n\n## File / Symbol\n\nscripts/foo.sh","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:open"},{"name":"type:feat"},{"name":"template:bd-v11.0"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/42"}'
                ;;
            43)
                echo '{"number":43,"title":"BD-002: Refactor bar","body":"<!-- pack-id: BD-002 -->\n<!-- template_version: bd-v11.0 -->\n<!-- pack-entry-body-gz64: @@BD002_BLOB@@ -->\n\n## Description\n\nRefactor.","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:unblocked"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/43"}'
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
    # Inject the precomputed gz64 blobs (base64 → no sed metacharacters).
    sed -i.bak "s|@@BD001_BLOB@@|$FIX_BD001_BLOB|; s|@@BD002_BLOB@@|$FIX_BD002_BLOB|" "$bin/gh"
    rm -f "$bin/gh.bak"
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
    # BD-175: pack-side test fixture needs pack-ops/ marker for the new
    # tracker_config_auto_surface canonical path (`[[ -d pack-ops ]]`).
    # Without it, surface auto-detect fails and the reverse emit lands
    # client-side at $repo/BACKLOG.md instead of $repo/pack-ops/BACKLOG.md.
    mkdir -p "$repo/pack-ops"
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
assert_eq "1.1 status:deferred → Deferred"   "Deferred"   "$(_tmr_decode_status '["status:deferred"]')"
assert_eq "1.1 status:resolved → Resolved"   "Resolved"   "$(_tmr_decode_status '["status:resolved"]')"
assert_eq "1.1 status:cancelled → Cancelled" "Cancelled"  "$(_tmr_decode_status '["status:cancelled"]')"
assert_eq "1.1 no status → Open default"     "Open"       "$(_tmr_decode_status '[]')"

# 1.1b state-aware decode (Finding #4 fix): manually-closed issues
# without a status:* label decode from canonical state + state_reason.
manual_closed='{"state":"closed","state_reason":"completed","labels":[]}'
manual_cancelled='{"state":"closed","state_reason":"not_planned","labels":[]}'
manual_deprecated='{"state":"closed","state_reason":"not_planned","labels":["status:deprecated"]}'
manual_open='{"state":"open","labels":[]}'
manual_unblocked='{"state":"open","labels":["status:unblocked"]}'
assert_eq "1.1b state=closed completed → Resolved"   "Resolved"   "$(_tmr_decode_status "$manual_closed")"
assert_eq "1.1b state=closed not_planned → Cancelled" "Cancelled" "$(_tmr_decode_status "$manual_cancelled")"
assert_eq "1.1b state=closed + status:deprecated → Deprecated" "Deprecated" "$(_tmr_decode_status "$manual_deprecated")"
assert_eq "1.1b state=open no label → Open"          "Open"       "$(_tmr_decode_status "$manual_open")"
assert_eq "1.1b state=open status:unblocked → Unblocked" "Unblocked" "$(_tmr_decode_status "$manual_unblocked")"

assert_eq "1.2 BD type"   "TODO(version)" "$(_tmr_decode_type "BD-001" '["bd-entry"]')"
# v10 grammar (METHODOLOGY §988): Type: TODO(<scope>) — parenthetical
# is the scope label VALUE, falling back to the literal placeholder
# `scope` when no scope label exists (preserves v10 fixture round-trip).
assert_eq "1.2 TD TODO no scope label → fallback" \
    "TODO(scope)"        "$(_tmr_decode_type "TD-010" '["td-entry"]')"
assert_eq "1.2 TD TODO with scope:dependency → substituted" \
    "TODO(dependency)"   "$(_tmr_decode_type "TD-010" '["td-entry","scope:dependency"]')"
assert_eq "1.2 TD KNOWN GAP severity:critical → substituted" \
    "KNOWN GAP(critical)" "$(_tmr_decode_type "TD-010" '["td-entry","severity:critical"]')"

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

# 1.5c BD-108 review F4 — V3.3 §2 D-21: phase tasks (phase-N.M) are
# L2 entities and are NOT legal sub-issue parents. Only phase epics
# (phase-N) may appear in the sub-issue-parent channel of decoded
# Blockers. Pre-BD-108 used `pack_parent.startswith("phase-")` which
# would falsely admit a phase-task pack-id; BD-108 tightened the
# regex to `^phase-\d+$`. This regression test seeds a mapping
# containing a phase-task entry (phase-3.2 → "59") and passes "59"
# as the sub_issue_parent. The decoded Blockers must NOT include
# phase-3.2 — even though the gh-id reverse-lookup would resolve
# it. (Body-comment-marker channel admits the full set per V3.3
# §5.3, but that is a separate code path; this test isolates the
# sub-issue-parent restriction.)
mapping_d21='{"BD-001":{"id":"42"},"phase-3":{"id":"58"},"phase-3.2":{"id":"59"}}'
# Body has no Blocked-by markers, so the only Blockers source is the
# sub-issue parent channel. Without the D-21 regex tightening this
# would (incorrectly) yield ["phase-3.2"]; with the tightening the
# decoded list must be [].
d21_blockers=$(_tmr_decode_blockers "" "$mapping_d21" "59")
assert_eq "1.5c V3.3 D-21: phase-task pack-id NOT admitted as sub-issue parent (BD-108 F4)" \
    "[]" "$d21_blockers"
# Counterpoint: phase-3 (a phase epic) IS admitted as a sub-issue
# parent — confirms the regex tightening did not over-restrict.
d21_epic=$(_tmr_decode_blockers "" "$mapping_d21" "58")
assert_contains "1.5c V3.3 D-21: phase epic STILL admitted as sub-issue parent" \
    "$d21_epic" "phase-3"

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

# 2.1b BD-204 §3.3: a PRESENT-but-corrupt pack-entry-body-gz64 marker FAILs
# LOUD (never silent-empty). Feed a deliberately mangled base64 payload.
corrupt_issue=$(jq -n '{
  number: 77, id: "77",
  title: "BD-077: Corrupt blob",
  body: "<!-- pack-id: BD-077 -->\n<!-- pack-entry-body-gz64: NOTVALIDgzip== -->\n\n## Description\n\nx",
  state: "open",
  labels: ["bd-entry","status:open"]
}')
corrupt_err=$(tracker_migrate_reverse_reconstruct "$corrupt_issue" '{}' 2>&1); corrupt_rc=$?
assert_eq       "2.1b corrupt-blob reconstruct rc=1 (fail loud)" "1" "$corrupt_rc"
assert_contains "2.1b corrupt-blob error names issue + reason"   "$corrupt_err" "corrupt-blob: issue #77"
assert_contains "2.1b corrupt-blob error states never-empty"     "$corrupt_err" "NEVER emits an empty/partial entry body"

# 2.1c BD-204 §3.3: a well-formed blob decodes to raw_body on the object,
# byte-faithful (the decode-identity invariant).
src_raw=$'**BD-078 — Blob decode**\nType: TODO(version)\nStatus: Open\nDescription: round trip me\n'
good_blob=$(printf '%s' "$src_raw" | _tmf_gz64_encode)
good_issue=$(jq -n --arg blob "$good_blob" '{
  number: 78, id: "78",
  title: "BD-078: Blob decode",
  body: ("<!-- pack-id: BD-078 -->\n<!-- pack-entry-body-gz64: " + $blob + " -->\n\n## Description\n\nround trip me"),
  state: "open",
  labels: ["bd-entry","status:open"]
}')
good_rec=$(tracker_migrate_reverse_reconstruct "$good_issue" '{}')
got_raw=$(printf '%s' "$good_rec" | jq -j '.raw_body'; printf X); got_raw="${got_raw%X}"
assert_eq "2.1c blob decodes to byte-faithful raw_body" "$src_raw" "$got_raw"

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

# BD-204 C-4: the PACK reverse emits the per-entry TREE (no monolith);
# PLAN/STATUS stay at root. The pack BACKLOG/CHANGELOG monoliths are NOT
# written (no-monolith / out-of-scope changelog).
[[ -f "$REPO/backlog/BD-001.md" ]]     && t_pass "4.1 per-entry tree emitted" || t_fail "4.1 per-entry tree emitted"
[[ -f "$REPO/backlog/_toc.md" ]]       && t_pass "4.1 _toc.md regenerated (DP-4)" || t_fail "4.1 _toc.md regenerated (DP-4)"
[[ -f "$REPO/IMPLEMENTATION-PLAN.md" ]] && t_pass "4.1 IMPLEMENTATION-PLAN.md emitted" || t_fail "4.1 IMPLEMENTATION-PLAN.md emitted"
[[ -f "$REPO/STATUS.md" ]]             && t_pass "4.1 STATUS.md emitted" || t_fail "4.1 STATUS.md emitted"
[[ ! -f "$REPO/pack-ops/BACKLOG.md" ]] && t_pass "4.1 no pack BACKLOG monolith written (no-monolith)" || t_fail "4.1 no pack BACKLOG monolith written (no-monolith)"
[[ ! -f "$REPO/pack-ops/CHANGELOG.md" ]] && t_pass "4.1 no pack CHANGELOG monolith written (out of scope)" || t_fail "4.1 no pack CHANGELOG monolith written (out of scope)"

# 4.2 tree content shape (concatenate the reconstructed entry files).
# BD-204 C-4 LOW-1 (PACK-REVIEW-BD-204-C4): the pack tree emit is filtered
# to the `pack-backlog` entry regex (`^BD-[0-9]+\.md$`, canonical per
# BD-211 — simplified from the former `^BD-[0-9]+[a-z]*\.md$`) — the SAME
# single source the backup set + `_toc.md` regen use — so the emit set ==
# the backup set == the `_toc.md` set by construction. On this MIXED fixture
# (BD-001, BD-002, TD-010 all reconstruct) only the `BD-*` ids are emitted to
# the pack tree; the `TD-010` id is NOT a pack-backlog entry and is skipped.
# (TD decode coverage is preserved by the Group 1 unit tests 1.2.)
backlog=$(cat "$REPO"/backlog/BD-*.md 2>/dev/null)
assert_contains "4.2 tree has BD-001 entry" "$backlog" "**BD-001 — Add foo to bar**"
assert_contains "4.2 tree has Status: Open" "$backlog" "Status: Open"
assert_contains "4.2 tree has File/Symbol"  "$backlog" "File/Symbol: scripts/foo.sh"
assert_contains "4.2 tree has Description"  "$backlog" "Description: Implements foo on bar."

# BD-204 §3.3 / §4.2: the pack emit writes raw_body VERBATIM from the blob.
# Assert the reconstructed BD-001.md (lines 2..EOF, back-pointer stripped) is
# BYTE-IDENTICAL to the canonical fixture raw_body — the byte-faithful leg.
recon_bd001=$(sed -n '2,$p' "$REPO/backlog/BD-001.md")
if [[ "$recon_bd001"$'\n' == "$FIX_BD001_RAWBODY" ]]; then
    t_pass "4.2 BD-001 reconstructed body is BYTE-IDENTICAL to source (verbatim emit)"
else
    t_fail "4.2 BD-001 reconstructed body is BYTE-IDENTICAL to source (verbatim emit)" \
        "recon='$recon_bd001'"
fi
# BD-204 §4.2 invariant 7: a NO-Blockers entry must NOT get injected
# `Blockers: None` / `Unblocks: None` / `Resolved: n/a` lines (the old emit's
# bug). The fixture BD-001 has no Blockers line and is not Resolved.
bd001_body=$(cat "$REPO/backlog/BD-001.md")
assert_not_contains "4.2 BD-001 no injected 'Blockers: None'"  "$bd001_body" "Blockers: None"
assert_not_contains "4.2 BD-001 no injected 'Unblocks: None'"  "$bd001_body" "Unblocks: None"
assert_not_contains "4.2 BD-001 no injected 'Resolved: n/a'"   "$bd001_body" "Resolved: n/a"
# LOW-1 negative assertions: a non-`BD-*` reconstructed id (TD-010) is NOT
# emitted to the pack tree, and no `backlog/TD-*.md` file is written — the
# emit set is provably the BD-only `pack-backlog` set.
[[ ! -f "$REPO/backlog/TD-010.md" ]] \
    && t_pass "4.2 TD-010 NOT emitted to pack tree (emit==backup==toc set)" \
    || t_fail "4.2 TD-010 NOT emitted to pack tree (emit==backup==toc set)"
assert_not_contains "4.2 tree body carries no TD-010 entry" \
    "$backlog" "**TD-010 — Document quux**"

# 4.3 STATUS reports counts
status_md=$(cat "$REPO/STATUS.md")
assert_contains "4.3 STATUS phase line"     "$status_md" "Phase 3 — Foundations"
assert_contains "4.3 STATUS Open count"     "$status_md" "Open: 3"

# 4.4 BD-204 C-4 / DP-2: NO sidecar on the pack reverse (the carrier is
# the form family + the Issue body; the sidecar file is dropped). The
# tracker-sidecar.sh module stays dormant (its direct-API tests live in
# 4.7b / 4.8 below — the module is not deleted), but the reverse
# orchestrator no longer EMITS a sidecar on the pack surface.
sidecar=$(ls "$REPO/.pack-tracker/reverse.sidecar."*.md 2>/dev/null | head -n 1)
[[ -z "$sidecar" ]] && t_pass "4.4 NO sidecar on pack reverse (DP-2 dropped)" \
    || t_fail "4.4 NO sidecar on pack reverse (DP-2 dropped)" "unexpected: $sidecar"

# 4.5 BD-204 C-4: each tree entry's line 1 is the per-entry back-pointer
# (not a mirror header). Verify on BD-001.
first_line=$(head -n 1 "$REPO/backlog/BD-001.md")
[[ "$first_line" == "<!-- per-entry source: /backlog/BD-001.md;"* ]] \
    && t_pass "4.5 tree entry line-1 is the per-entry back-pointer" \
    || t_fail "4.5 tree entry line-1 is the per-entry back-pointer" "got: $first_line"

# 4.6 last_reverse_run set; mode not flipped (no --disable).
assert_contains "4.6 tracker.toml has last_reverse_run" \
    "$(cat "$REPO/tracker.toml")" "last_reverse_run = \""
assert_eq "4.6 mode still tracker" "tracker" "$(tracker_config_get "$REPO/tracker.toml" mode.state)"

# 4.7 With --disable flag, mode flips to flat-file.
# BD-132: pass force=1 to bypass race-detection (mapping freshness)
# in this fixture-time test; the freshness threshold is a guard for
# real init→disable races, not for unit-test fixtures created seconds
# before the disable call.
export PATH="$FAKE:$PATH_SAVED"
tracker_migrate_reverse_run "$REPO" 0 1 0 1 >/dev/null 2>&1
export PATH="$PATH_SAVED"
assert_eq "4.7 mode flipped to flat-file via --disable" "flat-file" \
    "$(tracker_config_get "$REPO/tracker.toml" mode.state)"

# 4.7-atomic Disable atomicity (PACK-REVIEW-BD066-068 #3 fix):
# simulate an emit failure mid-disable; expect (a) flat files
# restored from backup, (b) mode NOT flipped, (c) partial-write error.
# BD-204 C-4 (§3.3 T8): the pack backup/restore set is the /backlog/*.md
# TREE (pe_list_entry_files), so plant a recognizable original tree entry
# and verify it is restored after the failed emit.
REPO_ATOMIC=$(mktemp -d -t tmr-atomic.XXXXXX); _build_test_repo "$REPO_ATOMIC"
mkdir -p "$REPO_ATOMIC/backlog"
ORIGINAL_BODY=$'<!-- per-entry source: /backlog/BD-001.md; contract: /backlog/_rules.md -->\n**BD-001 — ORIGINAL**\nThis content must survive the failed disable.\n'
printf '%s' "$ORIGINAL_BODY" > "$REPO_ATOMIC/backlog/BD-001.md"
# Override _tmr_emit_status to simulate an emit failure (runs AFTER the
# tree emit, so the failure trips the atomicity gate → restore).
saved_emit=$(declare -f _tmr_emit_status)
_tmr_emit_status() { return 1; }

FAKE_ATOMIC=$(mktemp -d -t tmr-fake-atomic.XXXXXX); _build_fake_gh "$FAKE_ATOMIC"
export PATH="$FAKE_ATOMIC:$PATH_SAVED"
# BD-132: force=1 bypasses race-detection so we exercise the
# emit-failure atomicity path (the original purpose of this test).
err=$(tracker_migrate_reverse_run "$REPO_ATOMIC" 0 1 0 1 2>&1) || true
export PATH="$PATH_SAVED"

# Restore the real function so subsequent tests aren't affected.
eval "$saved_emit"

assert_contains "4.7-atomic emit-failure surfaces partial-write" "$err" "ERROR: partial-write"
assert_contains "4.7-atomic message names flat files restored"   "$err" "files restored from backup"
# Mode NOT flipped.
mode_after=$(tracker_config_get "$REPO_ATOMIC/tracker.toml" mode.state)
assert_eq "4.7-atomic mode NOT flipped on emit failure" "tracker" "$mode_after"
# Tree entry restored. Compare via byte-equality on disk (avoids the
# trailing-newline trim that command substitution does).
if cmp -s <(printf '%s' "$ORIGINAL_BODY") "$REPO_ATOMIC/backlog/BD-001.md"; then
    t_pass "4.7-atomic tree entry restored to original (byte-equal)"
else
    t_fail "4.7-atomic tree entry restored to original (byte-equal)" \
        "actual: $(cat "$REPO_ATOMIC/backlog/BD-001.md" | head -c 200)"
fi
# Backup dir cleaned up after restore.
[[ ! -d "$REPO_ATOMIC/.pack-tracker/disable-backup" ]] \
    && t_pass "4.7-atomic backup dir cleaned up after restore" \
    || t_fail "4.7-atomic backup dir cleaned up after restore"
rm -rf "$REPO_ATOMIC" "$FAKE_ATOMIC"

# 4.7b Sidecar dated-filename stability (PACK-REVIEW-BD066-068 #12 fix):
# emitting a second sidecar removes any prior date file so disk
# state stays bounded.
REPO_DATED=$(mktemp -d -t tmr-dated.XXXXXX); _build_test_repo "$REPO_DATED"
mkdir -p "$REPO_DATED/.pack-tracker"
# Plant a fake older sidecar from yesterday.
touch "$REPO_DATED/.pack-tracker/reverse.sidecar.2025-01-01.md"
# Emit a current sidecar.
mapping_for_test=$(cat "$REPO_DATED/.pack-tracker/id-map.json" 2>/dev/null || echo '{}')
FAKE_DATED=$(mktemp -d -t tmr-fake-dated.XXXXXX); _build_fake_gh "$FAKE_DATED"
export PATH="$FAKE_DATED:$PATH_SAVED"
tracker_sidecar_emit "$REPO_DATED" "$mapping_for_test" 0 >/dev/null 2>&1
export PATH="$PATH_SAVED"
# Older sidecar removed.
[[ ! -f "$REPO_DATED/.pack-tracker/reverse.sidecar.2025-01-01.md" ]] \
    && t_pass "4.7b older dated sidecar cleaned up" \
    || t_fail "4.7b older dated sidecar cleaned up" "fake 2025-01-01 file still present"
# Current sidecar written.
n_sidecars=$(ls "$REPO_DATED/.pack-tracker/"reverse.sidecar.*.md 2>/dev/null | wc -l | tr -d ' ')
assert_eq "4.7b exactly one sidecar after emit" "1" "$n_sidecars"
rm -rf "$REPO_DATED" "$FAKE_DATED"

# 4.8 Sidecar extension hooks (PACK-REVIEW-BD062-069-071 #8 fix):
# overriding _tmsc_reactions_for_entry changes sidecar output.
# BD-204 C-4: the pack reverse no longer EMITS a sidecar (DP-2 dropped),
# so this exercises the dormant tracker-sidecar.sh module via a DIRECT
# tracker_sidecar_emit call (matching 4.7b) instead of the orchestrator —
# the module is dormant, not deleted, so its hook contract stays covered.
saved_hook=$(declare -f _tmsc_reactions_for_entry)
_tmsc_reactions_for_entry() {
    echo "👍 5  ❤️ 2  (overridden for test)"
}

REPO_OVR=$(mktemp -d -t tmr-ovr.XXXXXX); _build_test_repo "$REPO_OVR"
mapping_ovr=$(cat "$REPO_OVR/.pack-tracker/id-map.json" 2>/dev/null || echo '{}')
FAKE_OVR=$(mktemp -d -t tmr-fake-ovr.XXXXXX); _build_fake_gh "$FAKE_OVR"
export PATH="$FAKE_OVR:$PATH_SAVED"
tracker_sidecar_emit "$REPO_OVR" "$mapping_ovr" 0 >/dev/null 2>&1
export PATH="$PATH_SAVED"
sidecar_ovr=$(ls "$REPO_OVR/.pack-tracker/reverse.sidecar."*.md 2>/dev/null | head -n 1)
assert_contains "4.8 reactions hook override emits custom text" \
    "$(cat "$sidecar_ovr")" "overridden for test"
# And the default reactions placeholder is gone.
if grep -q "reactions fetch not implemented" "$sidecar_ovr"; then
    t_fail "4.8 default reactions text replaced" "default still present"
else
    t_pass "4.8 default reactions text replaced"
fi

# Restore default hook so subsequent tests are unaffected.
eval "$saved_hook"
rm -rf "$REPO_OVR" "$FAKE_OVR"

rm -rf "$FAKE" "$REPO"

# ─────────────────────────────────────────────────────────────────
# Group 5: idempotency (second reverse → byte-equal)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: idempotency ===\n"

FAKE=$(mktemp -d -t tmr-fake5.XXXXXX); _build_fake_gh "$FAKE"
REPO=$(mktemp -d -t tmr-repo5.XXXXXX); _build_test_repo "$REPO"

export PATH="$FAKE:$PATH_SAVED"
tracker_migrate_reverse_run "$REPO" >/dev/null 2>&1
# BD-204 C-4: the pack reverse emits the per-entry tree; assert the
# tree (concatenated) + STATUS.md are byte-equal across runs.
backlog1=$(cat "$REPO"/backlog/BD-*.md "$REPO/backlog/_toc.md" 2>/dev/null)
status1=$(cat  "$REPO/STATUS.md")
sleep 1
tracker_migrate_reverse_run "$REPO" >/dev/null 2>&1
backlog2=$(cat "$REPO"/backlog/BD-*.md "$REPO/backlog/_toc.md" 2>/dev/null)
status2=$(cat  "$REPO/STATUS.md")
export PATH="$PATH_SAVED"

assert_eq "5.1 tree byte-equal across runs" "$backlog1" "$backlog2"
assert_eq "5.1 STATUS.md byte-equal across runs"  "$status1"  "$status2"
rm -rf "$FAKE" "$REPO"

# 5.2 Triple-quote in body content does not crash _tmr_emit_backlog
# (regression: PACK-REVIEW-BD066-068 Finding #13 — pre-fix the
# helpers embedded jq-emitted JSON into Python triple-quoted strings
# which terminate early on `"""` payload). Fixed by passing JSON via
# temp file. The JSON value below contains an *escaped* triple-quote
# so the JSON itself is valid; the description text the user wrote
# is the literal three-character sequence `"""`.
TQ_OUT=$(mktemp -t tmr-tq.XXXXXX)
entries_with_tq=$(jq -nc '[{
    pack_id: "BD-001",
    title: "Triple quote test",
    type: "TODO(version)",
    status: "Open",
    blockers: [],
    unblocks: [],
    file_symbol: "",
    description: "User wrote a \"\"\" block here.",
    context: "",
    resolution: "",
    scope: "",
    severity: ""
}]')
if _tmr_emit_backlog "$entries_with_tq" "x/y" "$TQ_OUT" 2>/dev/null; then
    t_pass "5.2 _tmr_emit_backlog handles triple-quote in body"
else
    t_fail "5.2 _tmr_emit_backlog handles triple-quote in body" "rc != 0"
fi
if [[ -s "$TQ_OUT" ]] && grep -q "Triple quote test" "$TQ_OUT"; then
    t_pass "5.2 emitted file contains the triple-quoted entry"
else
    t_fail "5.2 emitted file contains the triple-quoted entry" "missing or empty"
fi
# And the literal ``` block survived through to the markdown output.
if grep -q '"""' "$TQ_OUT"; then
    t_pass "5.2 emitted file preserves the literal triple-quote text"
else
    t_fail "5.2 emitted file preserves the literal triple-quote text" "no \"\"\" found"
fi
rm -f "$TQ_OUT"

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
assert_contains "6.1 doctor reports OK on templates"      "$output" ".github/ISSUE_TEMPLATE present"
# F4: capability-cache refresh sub-surface (V2 §22.1).
# First run on a fresh repo populates the cache.
assert_contains "6.1a doctor populates capability cache"  "$output" "capability cache absent; populating"
[[ -f "$REPO_DR/.pack-tracker/capabilities.json" ]] \
    && t_pass "6.1a capability cache file written" \
    || t_fail "6.1a capability cache file written" "missing"
# Second run on the same repo finds the cache and reports OK.
output2=$(bash "$REPO_ROOT/scripts/tracker-migrate.sh" doctor --repo-root "$REPO_DR" 2>&1)
assert_contains "6.1a doctor reports OK on cached capabilities" \
    "$output2" "[OK]   capability cache current"
# Tampering with the cache surfaces a schema-reshape signal.
# Per BD-130 retro N-1: the schema-reshape line was demoted from
# WARN to INFO because the same invocation auto-heals the cache by
# rewriting capabilities.json with the freshly-re-probed value.
# Emitting WARN-and-rc=1 on an already-healed condition falsely
# failed CI gates on `pack tracker doctor`'s exit code. The signal
# itself is preserved in the message so operators still notice it.
echo '{}' > "$REPO_DR/.pack-tracker/capabilities.json"
output3=$(bash "$REPO_ROOT/scripts/tracker-migrate.sh" doctor --repo-root "$REPO_DR" 2>&1)
assert_contains "6.1a doctor surfaces schema-reshape on capability diff (INFO; auto-healed)" \
    "$output3" "[INFO] capability cache differed from re-probe (schema-reshape; cache auto-refreshed)"
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
# F9 verification: the WARN line names a recovery verb (V3 §27.1 Layer 2).
assert_contains "6.2 WARN line names recovery verb"     "$output" "→ Run:"
rm -rf "$REPO_BAD"

# 6.3 doctor template-version freshness check (PACK-REVIEW-BD062-069-071
# Finding #7 fix). Build a repo whose form-level template_version
# matches an empty manifest → reports "current".
REPO_FRESH=$(mktemp -d -t tmr-doctor-fresh.XXXXXX)
_build_test_repo "$REPO_FRESH"
mkdir -p "$REPO_FRESH/.github/ISSUE_TEMPLATE"
cat > "$REPO_FRESH/.github/ISSUE_TEMPLATE/work-item.yml" <<'EOF'
name: x
description: x
body:
  - type: markdown
    attributes:
      value: |
        <!-- template_version: work-item-v11.0 -->
EOF
cat > "$REPO_FRESH/.github/ISSUE_TEMPLATE/inbound.yml" <<'EOF'
name: x
description: x
body:
  - type: markdown
    attributes:
      value: |
        <!-- template_version: inbound-v11.0 -->
EOF

output=$(bash "$REPO_ROOT/scripts/tracker-migrate.sh" doctor --repo-root "$REPO_FRESH" 2>&1)
assert_contains "6.3 doctor reports template-version freshness check" \
    "$output" "template-version freshness:"
assert_contains "6.3 doctor reports work-item version"  "$output" "work-item=work-item-v11.0"
assert_contains "6.3 doctor reports inbound version"    "$output" "inbound=inbound-v11.0"
# Empty production manifest → reports "0 transitions (current)".
assert_contains "6.3 doctor reports empty manifest"     "$output" "0 transitions (current)"
rm -rf "$REPO_FRESH"

# ─────────────────────────────────────────────────────────────────
# Group 7: BD-111 retrofit — first-class blocked-by round-trip
#   (PACK-REVIEW-BD-111 F1; scope-extension second pass 2026-05-15)
#
# After BD-111 the forward writer routes `provider_link blocked-by`
# to a first-class `addBlockedBy` GraphQL edge; the body comment
# marker "Blocked by #N" is no longer written. Without this Group's
# coverage, the reverse decoder would silently lose Blockers for
# post-BD-111 issues. Group 7 verifies:
#   7.1 — _tmr_decode_blockers consumes a non-empty first_class_edges
#         JSON array (arg 4) and emits the expected pack-ids.
#   7.2 — De-dup: an upstream that appears in both the first-class
#         edge list AND a body comment marker contributes one entry
#         (first-class wins by source order).
#   7.3 — _tmr_fetch_first_class_blocked_by parses a well-formed
#         GraphQL response into a JSON array of issue numbers.
#   7.4 — End-to-end: tracker_migrate_reverse_reconstruct against an
#         extended fake-gh that serves first-class edges → the
#         reconstructed Blockers field contains the expected pack-id.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 7: BD-111 retrofit — first-class blocked-by ===\n"

# 7.1 first-class edges only (no body marker, no sub-issue parent)
mapping_g7='{"BD-001":{"id":"42"},"BD-002":{"id":"43"},"BD-003":{"id":"55"},"phase-3":{"id":"58"}}'
g71_blockers=$(_tmr_decode_blockers "" "$mapping_g7" "" '[43, 55]')
assert_contains "7.1 first-class edge BD-002 in blockers"      "$g71_blockers" "BD-002"
assert_contains "7.1 first-class edge BD-003 in blockers"      "$g71_blockers" "BD-003"
# Order: GH numeric source order preserved → BD-002 (gh=43) before BD-003 (gh=55).
g71_first=$(printf '%s' "$g71_blockers" | jq -r '.[0]')
assert_eq "7.1 first-class source order: BD-002 first" "BD-002" "$g71_first"

# 7.2 mixed environment: same upstream appears in both first-class
# AND comment marker → one entry only. First-class wins by source
# order (it's processed before the comment-marker pass in the decoder).
body_g72='## Description

Some text. Blocked by #43.'
g72_blockers=$(_tmr_decode_blockers "$body_g72" "$mapping_g7" "" '[43]')
g72_count=$(printf '%s' "$g72_blockers" | jq 'length')
assert_eq "7.2 de-dup: BD-002 appears once across both sources" "1" "$g72_count"
assert_contains "7.2 de-dup: BD-002 in blockers"                "$g72_blockers" "BD-002"

# 7.2b mixed environment: first-class edge for BD-002 + comment marker
# for BD-003 → both appear, in deterministic order (first-class first).
body_g72b='## Description

Some text. Blocked by #55.'
g72b_blockers=$(_tmr_decode_blockers "$body_g72b" "$mapping_g7" "" '[43]')
g72b_count=$(printf '%s' "$g72b_blockers" | jq 'length')
assert_eq "7.2b mixed: 2 distinct upstreams"                    "2" "$g72b_count"
g72b_first=$(printf  '%s' "$g72b_blockers" | jq -r '.[0]')
g72b_second=$(printf '%s' "$g72b_blockers" | jq -r '.[1]')
assert_eq "7.2b mixed: first-class BD-002 first"                "BD-002" "$g72b_first"
assert_eq "7.2b mixed: comment-marker BD-003 second"            "BD-003" "$g72b_second"

# 7.2c legacy-only path (no first-class edges) still works (BD-060
# era — backward-compat sentinel; mirrors existing 1.5 assertion).
body_g72c='## Description

Some text. Blocked by #43.'
g72c_blockers=$(_tmr_decode_blockers "$body_g72c" "$mapping_g7" "" '[]')
assert_contains "7.2c legacy-only: BD-002 still extracted" "$g72c_blockers" "BD-002"

# 7.3 _tmr_fetch_first_class_blocked_by parses a fake GraphQL response.
# Build a fake gh that returns the BD-111 fixture content for `api graphql`.
FAKE_G7=$(mktemp -d -t tmr-fake-g7.XXXXXX)
G7_FIXTURE="$REPO_ROOT/scripts/tests/fixtures/tracker-provider/gh-list-blocked-by.json"
[[ -f "$G7_FIXTURE" ]] || { echo "FATAL: gh-list-blocked-by.json fixture missing"; exit 2; }
cat > "$FAKE_G7/gh" <<FG7
#!/usr/bin/env bash
# Group 7 fake gh: serve owner/repo on \`repo view\`, fixture on
# \`api graphql\`. Anything else → empty.
case "\$1 \$2" in
    "repo view")   echo "fixture-org/fixture-repo" ;;
    "api graphql") cat "$G7_FIXTURE" ;;
    *)             ;;
esac
exit 0
FG7
chmod +x "$FAKE_G7/gh"
PATH="$FAKE_G7:$PATH_SAVED"
unset GH_REPO   # force the fallback to gh repo view
g73_edges=$(_tmr_fetch_first_class_blocked_by 42)
g73_count=$(printf '%s' "$g73_edges" | jq 'length' 2>/dev/null || echo 0)
assert_eq "7.3 fetch parses 2 first-class edges" "2" "$g73_count"
g73_first=$(printf  '%s' "$g73_edges" | jq -r '.[0]')
g73_second=$(printf '%s' "$g73_edges" | jq -r '.[1]')
assert_eq "7.3 first edge number=43"  "43" "$g73_first"
assert_eq "7.3 second edge number=55" "55" "$g73_second"
PATH="$PATH_SAVED"
rm -rf "$FAKE_G7"

# 7.4 fetch helper degrades to [] on missing/empty response.
FAKE_G74=$(mktemp -d -t tmr-fake-g74.XXXXXX)
cat > "$FAKE_G74/gh" <<'FG74'
#!/usr/bin/env bash
# Empty stdout + nonzero exit on api graphql → fetch must return [].
case "$1 $2" in
    "repo view")   echo "fixture-org/fixture-repo" ;;
    "api graphql") exit 1 ;;
    *) ;;
esac
exit 0
FG74
chmod +x "$FAKE_G74/gh"
PATH="$FAKE_G74:$PATH_SAVED"
g74_edges=$(_tmr_fetch_first_class_blocked_by 42 2>/dev/null)
assert_eq "7.4 fetch swallows graphql error → []" "[]" "$g74_edges"
PATH="$PATH_SAVED"
rm -rf "$FAKE_G74"

# 7.5 end-to-end: tracker_migrate_reverse_reconstruct fetches first-
# class edges and folds them into the Blockers field. We construct
# an issue JSON inline (number=42, body has no comment marker), set
# up a fake gh that serves the fixture for `api graphql`, and assert
# the reconstructed entry's blockers list contains BD-002 + BD-003.
FAKE_G75=$(mktemp -d -t tmr-fake-g75.XXXXXX)
cat > "$FAKE_G75/gh" <<FG75
#!/usr/bin/env bash
# End-to-end fake gh for Group 7.5: serve fixture on api graphql,
# owner/repo on repo view, empty for everything else (the
# reconstruct path doesn't make any other gh calls beyond what
# _tmr_fetch_first_class_blocked_by does — provider_get etc. are
# bypassed because we hand it the issue JSON directly).
case "\$1 \$2" in
    "repo view")   echo "fixture-org/fixture-repo" ;;
    "api graphql") cat "$G7_FIXTURE" ;;
    *)             ;;
esac
exit 0
FG75
chmod +x "$FAKE_G75/gh"
PATH="$FAKE_G75:$PATH_SAVED"

issue_g75='{"number":"42","title":"BD-001: foo","body":"<!-- pack-id: BD-001 -->\n\n## Description\n\nfoo.","state":"open","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:open"}],"assignees":[],"milestone":null,"parent":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/42"}'
mapping_g75='{"BD-001":{"id":"42"},"BD-002":{"id":"43"},"BD-003":{"id":"55"}}'
rec_g75=$(tracker_migrate_reverse_reconstruct "$issue_g75" "$mapping_g75")
g75_blockers=$(printf '%s' "$rec_g75" | jq -c '.blockers')
assert_contains "7.5 end-to-end: BD-002 in reconstructed blockers" "$g75_blockers" "BD-002"
assert_contains "7.5 end-to-end: BD-003 in reconstructed blockers" "$g75_blockers" "BD-003"
g75_count=$(printf '%s' "$g75_blockers" | jq 'length')
assert_eq "7.5 end-to-end: exactly 2 blockers from first-class edges" "2" "$g75_count"
PATH="$PATH_SAVED"
rm -rf "$FAKE_G75"

# 7.6 backward-compat: legacy-only environment (fake gh returns no
# first-class edges) still reconstructs Blockers from body comment
# markers. Confirms the BD-111 retrofit is additive, not replacing.
FAKE_G76=$(mktemp -d -t tmr-fake-g76.XXXXXX)
cat > "$FAKE_G76/gh" <<'FG76'
#!/usr/bin/env bash
# Legacy-only fake gh: empty graphql response → fetch returns [];
# decoder falls through to body comment markers.
case "$1 $2" in
    "repo view")   echo "fixture-org/fixture-repo" ;;
    "api graphql") echo '{"data":{"repository":{"issue":{"blockedByIssues":{"nodes":[]}}}}}' ;;
    *) ;;
esac
exit 0
FG76
chmod +x "$FAKE_G76/gh"
PATH="$FAKE_G76:$PATH_SAVED"

issue_g76='{"number":"42","title":"BD-001: foo","body":"<!-- pack-id: BD-001 -->\n\n## Description\n\nfoo. Blocked by #43.","state":"open","stateReason":null,"labels":[{"name":"bd-entry"}],"assignees":[],"milestone":null,"parent":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/42"}'
mapping_g76='{"BD-001":{"id":"42"},"BD-002":{"id":"43"}}'
rec_g76=$(tracker_migrate_reverse_reconstruct "$issue_g76" "$mapping_g76")
g76_blockers=$(printf '%s' "$rec_g76" | jq -c '.blockers')
assert_contains "7.6 legacy-only: BD-002 from body marker" "$g76_blockers" "BD-002"
g76_count=$(printf '%s' "$g76_blockers" | jq 'length')
assert_eq "7.6 legacy-only: exactly 1 blocker (no first-class)" "1" "$g76_count"
PATH="$PATH_SAVED"
rm -rf "$FAKE_G76"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
