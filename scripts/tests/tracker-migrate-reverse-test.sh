#!/usr/bin/env bash
# scripts/tests/tracker-migrate-reverse-test.sh — offline test suite
# for V1 §6.5 reverse migration + V1 §6.6/§6.6.1 sidecar (BD-067).
#
# Groups:
#   1. Per-entry decoders — status/type/scope/severity/blockers/sections
#   2. Reconstruction — full Issue → v10 record round-trip
#   3. Mirror header strip — idempotency + presence/absence
#   4. End-to-end reverse — fixture issues → BACKLOG/STATUS/PLAN files
#      + sidecar; mode flip on `--disable`
#   5. Idempotency — second reverse produces byte-equal flat files
#   6. Doctor verb — basic checks
#   7. BD-111 retrofit — first-class blocked-by round-trip
#   8. BD-204 Mode-3 ops verbs — `pack tracker tree-rebuild` (tree-only
#      arm, gates, hand-edit overwrite proof) + the blocking
#      status-coherence comparator (blob is status truth; --force =
#      blob-wins) + the surface-neutralized silent-data-loss guard text

set -u

# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
# code exercised under the clamp (never set it in a live run).
export PACK_TRACKER_DEFERRAL_OVERRIDE=1

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
                echo '{"number":43,"title":"BD-002: Refactor bar","body":"<!-- pack-id: BD-002 -->\n<!-- template_version: bd-v11.0 -->\n<!-- pack-entry-body-gz64: @@BD002_BLOB@@ -->\n\n## Description\n\nRefactor.\n\n## File / Symbol\n\nscripts/bar.sh","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:unblocked"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/43"}'
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

# 1.1c BD-204 C-8 defect 1 (stateReason casing): the LIVE gh read-back
# carries GraphQL-enum casing — verbatim live evidence (2026-06-11):
#   {"number":21,"state":"CLOSED","stateReason":"NOT_PLANNED"}
# The decoder's lowercase matches hold ONLY because the provider
# boundary normalizes casing (`_gh_normalize_issue` in
# scripts/lib/tracker-provider-gh.sh). These legs pin the REAL chain —
# live-shape raw gh JSON → production normalizer → decoder — for all
# three closed arms (Cancelled / Deprecated-by-label / Resolved).
# Pre-fix, NOT_PLANNED fell through the `*` arm and decoded Resolved
# (the lossy-class reverse bug: BD-021/103/123 all read back as
# Resolved instead of Deprecated/Cancelled).
_live_np='{"number":21,"title":"BD-021: x","body":"","state":"CLOSED","stateReason":"NOT_PLANNED","labels":[],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/21"}'
_live_dep='{"number":23,"title":"BD-023: x","body":"","state":"CLOSED","stateReason":"NOT_PLANNED","labels":[{"name":"status:deprecated"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/23"}'
_live_comp='{"number":24,"title":"BD-024: x","body":"","state":"CLOSED","stateReason":"COMPLETED","labels":[],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/24"}'
assert_eq "1.1c live CLOSED+NOT_PLANNED → normalize → Cancelled" \
    "Cancelled" "$(_tmr_decode_status "$(printf '%s' "$_live_np" | _gh_normalize_issue)")"
assert_eq "1.1c live CLOSED+NOT_PLANNED + status:deprecated → normalize → Deprecated" \
    "Deprecated" "$(_tmr_decode_status "$(printf '%s' "$_live_dep" | _gh_normalize_issue)")"
assert_eq "1.1c live CLOSED+COMPLETED → normalize → Resolved" \
    "Resolved" "$(_tmr_decode_status "$(printf '%s' "$_live_comp" | _gh_normalize_issue)")"

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

# NIT-1 hermeticity (PACK-REVIEW-MODE3-OPS-COMMIT2): every successful
# tracker_migrate_reverse_reconstruct call below reaches
# _tmr_fetch_first_class_blocked_by (scripts/lib/tracker-migrate-reverse.sh),
# whose GH_REPO-absent fallback shells out to `gh repo view` — and whose
# follow-on GraphQL fetch would hit the REAL gh on a machine where that
# fallback succeeds. Wrap the whole group in the suite's fake-gh PATH
# pattern (the same _build_fake_gh stub Groups 4/5 use): `repo view`
# answers the fixture slug and the catch-all arm answers `gh api
# graphql` with empty output, so the fetch degrades to [] exactly as
# the offline baseline. No behavior-assertion changes.
FAKE_G2=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake-g2.XXXXXX"); _build_fake_gh "$FAKE_G2"
export PATH="$FAKE_G2:$PATH_SAVED"

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

# 2.1d BD-204 §3.3a (ii): the NORMALIZATION-TOLERANT divergence comparator.
# The blob is authoritative; the visible H2 is the advisory projection. On a
# direct GH edit of the H2 (not propagated to the blob), reverse FAILs loud.
# The comparator normalizes EXACTLY CRLF/CR→LF + per-line trailing-ws strip +
# single trailing newline — GH's documented body munging — so it neither
# false-positives an untouched-but-normalized body NOR false-negatives a real
# one-word content edit.
div_raw=$'**BD-079 — Divergence probe**\nType: TODO(version)\nStatus: Open\nFile/Symbol: scripts/probe.sh\nDescription: The quick brown fox.\n'
div_blob=$(printf '%s' "$div_raw" | _tmf_gz64_encode)

# 2.1d-i NO-FALSE-POSITIVE: an UNTOUCHED body whose H2 GitHub has merely
# normalized (CRLF line endings + per-line trailing spaces) MATCHES the blob.
# Build the H2 with REAL \r\n line endings + trailing spaces via $'...' (jq
# --arg does NOT interpret escapes, so the bytes must already be real).
div_h2_normalized=$'## Description\r\n\r\nThe quick brown fox.   \r\n\r\n## File / Symbol  \r\n\r\nscripts/probe.sh  '
div_issue_norm=$(jq -n --arg blob "$div_blob" --arg h2 "$div_h2_normalized" '{
  number: 79, id: "79",
  title: "BD-079: Divergence probe",
  body: ("<!-- pack-id: BD-079 -->\n<!-- pack-entry-body-gz64: " + $blob + " -->\n\n" + $h2),
  state: "open",
  labels: ["bd-entry","status:open"]
}')
div_norm_rc=0
div_norm_err=$(tracker_migrate_reverse_reconstruct "$div_issue_norm" '{}' 2>&1 1>/dev/null) || div_norm_rc=1
assert_eq "2.1d-i comparator MATCHES a CRLF+trailing-space-normalized body (no false-positive)" \
    "0" "$div_norm_rc"

# 2.1d-ii MISMATCH CAUGHT: a real ONE-WORD content edit to the visible H2
# (fox → cat) diverges from the blob → comparator FAILs loud (rc=1) with the
# `divergence:` message naming the issue + the divergent section. Real LF bytes.
div_h2_edited=$'## Description\n\nThe quick brown cat.\n\n## File / Symbol\n\nscripts/probe.sh'
div_issue_edit=$(jq -n --arg blob "$div_blob" --arg h2 "$div_h2_edited" '{
  number: 79, id: "79",
  title: "BD-079: Divergence probe",
  body: ("<!-- pack-id: BD-079 -->\n<!-- pack-entry-body-gz64: " + $blob + " -->\n\n" + $h2),
  state: "open",
  labels: ["bd-entry","status:open"]
}')
div_edit_err=$(tracker_migrate_reverse_reconstruct "$div_issue_edit" '{}' 2>&1 1>/dev/null); div_edit_rc=$?
assert_eq       "2.1d-ii comparator MISMATCHES a one-word content edit (caught, rc=1)" "1" "$div_edit_rc"
assert_contains "2.1d-ii divergence error names the issue + 'divergence:'" "$div_edit_err" "divergence: issue #79"
assert_contains "2.1d-ii divergence error names the divergent section"     "$div_edit_err" "Description"

# 2.1d-iii FORCE override: the SAME one-word-edit body with force=1 → blob-wins
# (rc=0, no abort) + a WARN surfaced. The blob is never mutated (the reverse
# proceeds with the authoritative blob content).
div_force_warn=$(tracker_migrate_reverse_reconstruct "$div_issue_edit" '{}' 1 2>&1 1>/dev/null); div_force_rc=$?
assert_eq       "2.1d-iii --force overrides divergence to blob-wins (rc=0)" "0" "$div_force_rc"
assert_contains "2.1d-iii --force surfaces a blob-wins WARN" "$div_force_warn" "blob wins"

# 2.1f BD-204 rehearsal run-3 Defect C: resolution-projection SYMMETRY for
# an UNRESOLVED entry (`Resolved: n/a`). The blob carries `Resolved: n/a`
# verbatim; the parser projects an EMPTY resolution; the composer's
# empty-omission rule emits NO `## Resolution` H2 — so a tracker-side
# recompose (the oracle's status-flip CRUD update: description + raw_body,
# empty resolution) must NOT diverge. Run 3 flagged exactly this phantom
# `(Resolution)` divergence on issue #4 (BD-904) and aborted the post-CRUD
# reverse (cascading the BD-908-missing / count / status-round-trip FAILs).
na_raw=$'**BD-080 — n/a resolution probe**\nType: TODO(version)\nStatus: Deferred\nBlockers: None\nUnblocks: None\nDescription: status flipped mid-cycle; unresolved entry.\nResolved: n/a\n'
na_body=$(tmf_compose_issue_body "BD-080" "status flipped mid-cycle; unresolved entry." "" "" "" "$na_raw")
# The composed body must NOT carry a phantom Resolution H2 (the projection
# side of the same symmetry rule, pinned at the composer output here).
assert_not_contains "2.1f composed body has NO phantom ## Resolution for 'Resolved: n/a'" \
    "$na_body" "## Resolution"
na_issue=$(jq -n --arg body "$na_body" '{
  number: 80, id: "80",
  title: "BD-080: n/a resolution probe",
  body: $body,
  state: "open",
  labels: ["bd-entry","status:deferred"]
}')
na_err=$(tracker_migrate_reverse_reconstruct "$na_issue" '{}' 2>&1 1>/dev/null); na_rc=$?
assert_eq "2.1f n/a-resolution entry does NOT flag divergence (rc=0; run-3 Defect C)" "0" "$na_rc"
assert_not_contains "2.1f no phantom '(Resolution)' divergence error" "$na_err" "divergence"
na_rec=$(tracker_migrate_reverse_reconstruct "$na_issue" '{}' 2>/dev/null)
assert_eq "2.1f status decodes Deferred (status-flip round-trips)" \
    "Deferred" "$(printf '%s' "$na_rec" | jq -r .status)"
na_got_raw=$(printf '%s' "$na_rec" | jq -j '.raw_body'; printf X); na_got_raw="${na_got_raw%X}"
assert_eq "2.1f blob raw_body (incl. 'Resolved: n/a' line) byte-faithful" "$na_raw" "$na_got_raw"

# 2.1f-ii a REAL visible-H2 edit on the SAME n/a entry must STILL flag —
# the symmetry fix is no per-field carve-out: the comparator stays
# fail-loud on genuine divergence.
na_edit_body="${na_body/unresolved entry./EDITED entry.}"
na_edit_issue=$(jq -n --arg body "$na_edit_body" '{
  number: 81, id: "81",
  title: "BD-080: n/a resolution probe",
  body: $body,
  state: "open",
  labels: ["bd-entry","status:deferred"]
}')
na_edit_err=$(tracker_migrate_reverse_reconstruct "$na_edit_issue" '{}' 2>&1 1>/dev/null); na_edit_rc=$?
assert_eq       "2.1f-ii REAL H2 edit on the n/a entry STILL flags (rc=1)" "1" "$na_edit_rc"
assert_contains "2.1f-ii divergence names the issue" "$na_edit_err" "divergence: issue #81"
assert_contains "2.1f-ii divergence names the Description section" "$na_edit_err" "Description"

# 2.1e BD-204 §3.LF.3a — single-source BATCH MODE for the gz64 decode (Option B;
# design §4.6 (S) item 1). The C-4.6 deep guard pairs _tmf_gz64_encode_batch
# with _tmr_decode_body_blob_batch (ONE python3 over all N records, no per-entry
# spawn storm) — ONE shared codec that cannot drift from production (OQ-4).
# These tests prove BATCH-EQUIVALENCE: batch decode(N) == single-record decode
# applied N times, AND batch decode(batch encode(X)) == X byte-identical.

# _tmr_batch_frame / _tmr_batch_nth: the _TMF_BATCH length-prefixed framing
# helpers (arbitrary bytes safe), local to this suite.
_tmr_batch_frame() {
    python3 -c '
import sys
data = sys.stdin.buffer.read()
recs = data.split(b"\x00")
if recs and recs[-1] == b"":
    recs = recs[:-1]
w = sys.stdout.buffer
w.write(("%d\n" % len(recs)).encode("ascii"))
for r in recs:
    w.write(("%d\n" % len(r)).encode("ascii"))
    w.write(r)
'
}
_tmr_batch_nth() {
    python3 -c '
import sys
idx = int(sys.argv[1])
data = sys.stdin.buffer.read()
i = data.index(b"\n"); n = int(data[:i]); pos = i+1
got = []
for _ in range(n):
    j = data.index(b"\n", pos); L = int(data[pos:j]); pos = j+1
    got.append(data[pos:pos+L]); pos += L
sys.stdout.buffer.write(got[idx])
sys.stdout.buffer.write(b"X")
' "$1"
}

# 2.1e-i batch decode == single-record decode, applied N times (byte-identical).
# The single-record DECODE seam used by 2.1c extracts the marker then python-
# decodes; here we decode bare payloads directly (the guard's seam). Build 4
# payloads via _tmf_gz64_encode (single-record), decode each single + batch.
e_raw1=$'**BD-136 — decode**\nStatus: Open\ninterior ) fence ```\n'
e_raw2=$'simple\n'
e_raw3=$'**BD-204 — decode**\nResolved: #123 commit 08f7158\n'
e_raw4=$'trailing newlines\n\n\n'
e_p1=$(printf '%s' "$e_raw1" | _tmf_gz64_encode)
e_p2=$(printf '%s' "$e_raw2" | _tmf_gz64_encode)
e_p3=$(printf '%s' "$e_raw3" | _tmf_gz64_encode)
e_p4=$(printf '%s' "$e_raw4" | _tmf_gz64_encode)
# single-record decode (bare payload → raw bytes; sentinel preserves trailing \n)
sd1=$(printf '%s' "$e_p1" | python3 -c 'import sys,base64,gzip,io; sys.stdout.buffer.write(gzip.GzipFile(fileobj=io.BytesIO(base64.b64decode(sys.stdin.read().strip()))).read()); sys.stdout.buffer.write(b"X")'); sd1="${sd1%X}"
# batch decode over the 4 payloads
batch_dec=$(printf '%s\x00%s\x00%s\x00%s\x00' "$e_p1" "$e_p2" "$e_p3" "$e_p4" \
    | _tmr_batch_frame | _tmr_decode_body_blob_batch | base64)
bd0=$(printf '%s' "$batch_dec" | base64 -d | _tmr_batch_nth 0); bd0="${bd0%X}"
bd1=$(printf '%s' "$batch_dec" | base64 -d | _tmr_batch_nth 1); bd1="${bd1%X}"
bd2=$(printf '%s' "$batch_dec" | base64 -d | _tmr_batch_nth 2); bd2="${bd2%X}"
bd3=$(printf '%s' "$batch_dec" | base64 -d | _tmr_batch_nth 3); bd3="${bd3%X}"
assert_eq "2.1e-i batch decode rec0 == single-record decode" "$sd1" "$bd0"
# 2.1e-ii batch decode round-trips to the ORIGINAL raw_body byte-for-byte.
assert_eq "2.1e-ii batch decode(encode rec0)==original (BD-136 fixture)" "$e_raw1" "$bd0"
assert_eq "2.1e-ii batch decode(encode rec1)==original" "$e_raw2" "$bd1"
assert_eq "2.1e-ii batch decode(encode rec2)==original (BD-204 fixture)" "$e_raw3" "$bd2"
assert_eq "2.1e-ii batch decode(encode rec3)==original (trailing newlines)" "$e_raw4" "$bd3"

# 2.1e-iii ONE-codec proof: batch decode of a BATCH-ENCODED payload set ==
# the originals (the encode/decode batch seam C-4.6 depends on, end to end).
batch_enc_payloads=$(printf '%s\x00%s\x00%s\x00%s\x00' "$e_raw1" "$e_raw2" "$e_raw3" "$e_raw4" \
    | _tmr_batch_frame | _tmf_gz64_encode_batch | base64)
# Re-frame the batch-encoded payloads (already length-framed) directly into decode.
roundtrip_dec=$(printf '%s' "$batch_enc_payloads" | base64 -d | _tmr_decode_body_blob_batch | base64)
rd0=$(printf '%s' "$roundtrip_dec" | base64 -d | _tmr_batch_nth 0); rd0="${rd0%X}"
rd3=$(printf '%s' "$roundtrip_dec" | base64 -d | _tmr_batch_nth 3); rd3="${rd3%X}"
assert_eq "2.1e-iii batch encode→batch decode rec0 == original (shared codec)" "$e_raw1" "$rd0"
assert_eq "2.1e-iii batch encode→batch decode rec3 == original (shared codec)" "$e_raw4" "$rd3"

# 2.1e-iv ADDITIVE invariant — the single-record _tmr_decode_body_blob path is
# UNCHANGED (re-run the 2.1c reconstruct seam and confirm byte-faithful).
add_src=$'**BD-078 — additive**\nType: TODO(version)\nStatus: Open\nDescription: still works\n'
add_blob=$(printf '%s' "$add_src" | _tmf_gz64_encode)
add_issue=$(jq -n --arg blob "$add_blob" '{number:78,id:"78",title:"BD-078: additive",body:("<!-- pack-id: BD-078 -->\n<!-- pack-entry-body-gz64: " + $blob + " -->\n\n## Description\n\nstill works"),state:"open",labels:["bd-entry","status:open"]}')
add_rec=$(tracker_migrate_reverse_reconstruct "$add_issue" '{}')
add_got=$(printf '%s' "$add_rec" | jq -j '.raw_body'; printf X); add_got="${add_got%X}"
assert_eq "2.1e-iv single-record decode path byte-unchanged (additive)" "$add_src" "$add_got"

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

# End of the NIT-1 Group-2 hermetic wrap — restore the real PATH.
export PATH="$PATH_SAVED"
rm -rf "$FAKE_G2"

# ─────────────────────────────────────────────────────────────────
# Group 3: mirror header strip
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: mirror header strip ===\n"

# 3.1 header present → stripped cleanly
tmp=$(mktemp "${TMPDIR:-/tmp}/tmr-3.XXXXXX")
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
tmp=$(mktemp "${TMPDIR:-/tmp}/tmr-3b.XXXXXX")
echo "Just a body" > "$tmp"
before=$(cat "$tmp")
tracker_mirror_header_strip "$tmp"
after=$(cat "$tmp")
# Allow trailing-newline normalization.
assert_contains "3.2 no-header file body preserved" "$after" "Just a body"
rm -f "$tmp"

# 3.3 idempotent (strip twice → same as strip once)
tmp=$(mktemp "${TMPDIR:-/tmp}/tmr-3c.XXXXXX")
{ echo "<!--"; echo "  H"; echo "-->"; echo ""; echo "Body"; } > "$tmp"
tracker_mirror_header_strip "$tmp"
snap=$(cat "$tmp")
tracker_mirror_header_strip "$tmp"
snap2=$(cat "$tmp")
assert_eq "3.3 strip twice = strip once" "$snap" "$snap2"
rm -f "$tmp"

# 3.4 write+strip round-trip preserves body
tmp=$(mktemp "${TMPDIR:-/tmp}/tmr-3d.XXXXXX")
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

FAKE=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fakegh.XXXXXX")
_build_fake_gh "$FAKE"
REPO=$(mktemp -d "${TMPDIR:-/tmp}/tmr-repo.XXXXXX")
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
REPO_ATOMIC=$(mktemp -d "${TMPDIR:-/tmp}/tmr-atomic.XXXXXX"); _build_test_repo "$REPO_ATOMIC"
mkdir -p "$REPO_ATOMIC/backlog"
ORIGINAL_BODY=$'<!-- per-entry source: /backlog/BD-001.md; contract: /backlog/_rules.md -->\n**BD-001 — ORIGINAL**\nThis content must survive the failed disable.\n'
printf '%s' "$ORIGINAL_BODY" > "$REPO_ATOMIC/backlog/BD-001.md"
# Override _tmr_emit_status to simulate an emit failure (runs AFTER the
# tree emit, so the failure trips the atomicity gate → restore).
saved_emit=$(declare -f _tmr_emit_status)
_tmr_emit_status() { return 1; }

FAKE_ATOMIC=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake-atomic.XXXXXX"); _build_fake_gh "$FAKE_ATOMIC"
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
REPO_DATED=$(mktemp -d "${TMPDIR:-/tmp}/tmr-dated.XXXXXX"); _build_test_repo "$REPO_DATED"
mkdir -p "$REPO_DATED/.pack-tracker"
# Plant a fake older sidecar from yesterday.
touch "$REPO_DATED/.pack-tracker/reverse.sidecar.2025-01-01.md"
# Emit a current sidecar.
mapping_for_test=$(cat "$REPO_DATED/.pack-tracker/id-map.json" 2>/dev/null || echo '{}')
FAKE_DATED=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake-dated.XXXXXX"); _build_fake_gh "$FAKE_DATED"
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

REPO_OVR=$(mktemp -d "${TMPDIR:-/tmp}/tmr-ovr.XXXXXX"); _build_test_repo "$REPO_OVR"
mapping_ovr=$(cat "$REPO_OVR/.pack-tracker/id-map.json" 2>/dev/null || echo '{}')
FAKE_OVR=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake-ovr.XXXXXX"); _build_fake_gh "$FAKE_OVR"
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

FAKE=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake5.XXXXXX"); _build_fake_gh "$FAKE"
REPO=$(mktemp -d "${TMPDIR:-/tmp}/tmr-repo5.XXXXXX"); _build_test_repo "$REPO"

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
TQ_OUT=$(mktemp "${TMPDIR:-/tmp}/tmr-tq.XXXXXX")
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

REPO_DR=$(mktemp -d "${TMPDIR:-/tmp}/tmr-doctor.XXXXXX")
_build_test_repo "$REPO_DR"
mkdir -p "$REPO_DR/.github/ISSUE_TEMPLATE"
touch "$REPO_DR/.github/ISSUE_TEMPLATE/work-item.yml"

# BD-204 leg (h): the doctor's status-coherence advisory calls
# provider_list on tracker-mode pack fixtures — keep the suite hermetic
# by serving the fake gh for every Group 6 doctor invocation (zero live
# gh/network calls).
FAKE_DR=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake-doctor.XXXXXX"); _build_fake_gh "$FAKE_DR"
export PATH="$FAKE_DR:$PATH_SAVED"

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
REPO_BAD=$(mktemp -d "${TMPDIR:-/tmp}/tmr-doctor-bad.XXXXXX")
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
REPO_FRESH=$(mktemp -d "${TMPDIR:-/tmp}/tmr-doctor-fresh.XXXXXX")
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

# Restore the real PATH after the Group 6 fake-gh wrap.
export PATH="$PATH_SAVED"
rm -rf "$FAKE_DR"

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
FAKE_G7=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake-g7.XXXXXX")
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

# 7.3b BD-204 review F-1: the GH_REPO-preferred path strips the
# optional HOST/ prefix from the canonical [HOST/]OWNER/REPO export
# shape BEFORE the cut -d/ owner/name split — a verbatim host-prefixed
# value yielded owner=HOST, name=OWNER (GraphQL NOT_FOUND, swallowed
# best-effort → silent [] Blockers loss on GHE reverse migrations).
# The fake gh logs its argv and DIES on `repo view`, so this leg also
# proves the GH_REPO value (not the fallback) supplied the slug.
FAKE_G73B=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake-g73b.XXXXXX")
G73B_LOG="$FAKE_G73B/gh.log"
cat > "$FAKE_G73B/gh" <<FG73B
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$G73B_LOG"
case "\$1 \$2" in
    "repo view")   echo "fatal: not a git repository" >&2; exit 1 ;;
    "api graphql") cat "$G7_FIXTURE" ;;
    *)             ;;
esac
exit 0
FG73B
chmod +x "$FAKE_G73B/gh"
PATH="$FAKE_G73B:$PATH_SAVED"
export GH_REPO="github.example.com/fixture-org/fixture-repo"
g73b_edges=$(_tmr_fetch_first_class_blocked_by 42)
g73b_count=$(printf '%s' "$g73b_edges" | jq 'length' 2>/dev/null || echo 0)
assert_eq "7.3b host-prefixed GH_REPO: fetch parses 2 edges" "2" "$g73b_count"
g73b_query=$(grep "api graphql" "$G73B_LOG")
assert_contains     "7.3b owner split = fixture-org (HOST/ stripped)" \
    "$g73b_query" 'owner: "fixture-org"'
assert_contains     "7.3b name split = fixture-repo" \
    "$g73b_query" 'name: "fixture-repo"'
assert_not_contains "7.3b host must not leak into owner split" \
    "$g73b_query" 'owner: "github.example.com"'
# Plain owner/repo still works verbatim (one-slash shape is never
# inspected by the strip).
: > "$G73B_LOG"
export GH_REPO="fixture-org/fixture-repo"
g73b_edges=$(_tmr_fetch_first_class_blocked_by 42)
g73b_count=$(printf '%s' "$g73b_edges" | jq 'length' 2>/dev/null || echo 0)
assert_eq "7.3b plain GH_REPO: fetch parses 2 edges" "2" "$g73b_count"
g73b_query=$(grep "api graphql" "$G73B_LOG")
assert_contains "7.3b plain GH_REPO: owner split = fixture-org" \
    "$g73b_query" 'owner: "fixture-org"'
unset GH_REPO
PATH="$PATH_SAVED"
rm -rf "$FAKE_G73B"

# 7.4 fetch helper degrades to [] on missing/empty response.
FAKE_G74=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake-g74.XXXXXX")
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
FAKE_G75=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake-g75.XXXXXX")
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
FAKE_G76=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake-g76.XXXXXX")
cat > "$FAKE_G76/gh" <<'FG76'
#!/usr/bin/env bash
# Legacy-only fake gh: empty graphql response → fetch returns [];
# decoder falls through to body comment markers.
case "$1 $2" in
    "repo view")   echo "fixture-org/fixture-repo" ;;
    "api graphql") echo '{"data":{"repository":{"issue":{"blockedBy":{"nodes":[]}}}}}' ;;
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
# Group 8: BD-204 Mode-3 ops verbs — tree-rebuild + status coherence
#   (ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md §2/§3 + AMENDMENT-2
#    §B8 D2; PLAN-BD-204-MODE3-OPS-CONTRACT.md §5 legs 1/2/5/8/9)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 8: BD-204 Mode-3 ops verbs (tree-rebuild + status coherence) ===\n"

PACK_TRACKER_SH="$REPO_ROOT/scripts/pack-tracker.sh"

# 8.1 (plan leg 1) tree-rebuild happy path: tree files + _toc.md
# regenerated; last_tree_regen stamped; mode.state UNCHANGED; NO
# STATUS.md / IMPLEMENTATION-PLAN.md at the fixture root; no monolith.
FAKE8=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake8.XXXXXX"); _build_fake_gh "$FAKE8"
REPO8=$(mktemp -d "${TMPDIR:-/tmp}/tmr-repo8.XXXXXX"); _build_test_repo "$REPO8"
export PATH="$FAKE8:$PATH_SAVED"
out8=$(bash "$PACK_TRACKER_SH" tree-rebuild --repo-root "$REPO8" 2>&1)
rc8=$?
export PATH="$PATH_SAVED"
assert_eq       "8.1 tree-rebuild rc=0"                       "0" "$rc8"
assert_contains "8.1 reports tree-rebuild complete"           "$out8" "tree-rebuild: complete"
[[ -f "$REPO8/backlog/BD-001.md" ]] && t_pass "8.1 tree entry materialized" || t_fail "8.1 tree entry materialized"
[[ -f "$REPO8/backlog/_toc.md" ]]   && t_pass "8.1 _toc.md regenerated (DP-4 by construction)" || t_fail "8.1 _toc.md regenerated (DP-4 by construction)"
[[ ! -f "$REPO8/STATUS.md" ]] \
    && t_pass "8.1 NO STATUS.md deposited at fixture root (tree-only)" \
    || t_fail "8.1 NO STATUS.md deposited at fixture root (tree-only)"
[[ ! -f "$REPO8/IMPLEMENTATION-PLAN.md" ]] \
    && t_pass "8.1 NO IMPLEMENTATION-PLAN.md deposited at fixture root (tree-only)" \
    || t_fail "8.1 NO IMPLEMENTATION-PLAN.md deposited at fixture root (tree-only)"
[[ ! -f "$REPO8/pack-ops/BACKLOG.md" ]] \
    && t_pass "8.1 no monolith written (Check 32-prime shape)" \
    || t_fail "8.1 no monolith written (Check 32-prime shape)"
assert_contains "8.1 last_tree_regen stamped in tracker.toml" \
    "$(cat "$REPO8/tracker.toml")" 'last_tree_regen = "'
assert_eq "8.1 mode.state UNCHANGED (no flip)" "tracker" \
    "$(tracker_config_get "$REPO8/tracker.toml" mode.state)"

# 8.2 (plan leg 8) hand-edit overwrite proof — the contract's teeth:
# hand-edit a tree file in tracker mode, run tree-rebuild, hand-edit
# GONE (one-way write proven by test, not prose). The file returns to
# byte-identity with the pre-edit regenerated content.
pre_edit_snapshot=$(cat "$REPO8/backlog/BD-001.md")
printf 'HAND-EDIT SENTINEL — this line must be clobbered\n' >> "$REPO8/backlog/BD-001.md"
grep -q "HAND-EDIT SENTINEL" "$REPO8/backlog/BD-001.md" \
    && t_pass "8.2 hand-edit landed on disk (precondition)" \
    || t_fail "8.2 hand-edit landed on disk (precondition)"
export PATH="$FAKE8:$PATH_SAVED"
bash "$PACK_TRACKER_SH" tree-rebuild --repo-root "$REPO8" >/dev/null 2>&1
rc82=$?
export PATH="$PATH_SAVED"
assert_eq "8.2 second tree-rebuild rc=0" "0" "$rc82"
if grep -q "HAND-EDIT SENTINEL" "$REPO8/backlog/BD-001.md"; then
    t_fail "8.2 hand-edit OVERWRITTEN WITHOUT DETECTION (one-way write)" "sentinel survived"
else
    t_pass "8.2 hand-edit OVERWRITTEN WITHOUT DETECTION (one-way write)"
fi
assert_eq "8.2 regenerated file byte-equal to pre-edit content" \
    "$pre_edit_snapshot" "$(cat "$REPO8/backlog/BD-001.md")"

# 8.3 (plan leg 2) flat-file-mode refusal (fail-loud message asserted).
python3 - "$REPO8/tracker.toml" <<'PYEOF'
import re, sys
p = sys.argv[1]
text = open(p).read()
text = text.replace('state = "tracker"', 'state = "flat-file"')
open(p, "w").write(text)
PYEOF
out83=$(bash "$PACK_TRACKER_SH" tree-rebuild --repo-root "$REPO8" 2>&1)
rc83=$?
[[ "$rc83" -ne 0 ]] \
    && t_pass "8.3 flat-file mode → tree-rebuild refuses (rc!=0)" \
    || t_fail "8.3 flat-file mode → tree-rebuild refuses (rc!=0)" "rc=$rc83"
assert_contains "8.3 refusal is typed validation"      "$out83" "ERROR: validation"
assert_contains "8.3 refusal names not-in-tracker-mode" "$out83" "not in tracker mode"
assert_contains "8.3 refusal names the flat-file SSOT" "$out83" "the per-entry tree is the SSOT in flat-file mode"
rm -rf "$FAKE8" "$REPO8"

# 8.4 (plan leg 9) client-surface refusal names BD-207. A client-shaped
# repo (docs/pack/ marker, NO pack-ops/) auto-detects surface=client;
# tree_only is pack-surface-only at v11.0.
REPO84=$(mktemp -d "${TMPDIR:-/tmp}/tmr-repo84.XXXXXX")
mkdir -p "$REPO84/docs/pack"
cat > "$REPO84/docs/pack/tracker.toml" <<'EOF'
schema_version = 1
[backend]
name = "github"
repo = "fixture-org/fixture-repo"
[mode]
state = "tracker"
[id_namespace]
prefix = "TD"
[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
EOF
out84=$(bash "$PACK_TRACKER_SH" tree-rebuild --repo-root "$REPO84" 2>&1)
rc84=$?
[[ "$rc84" -ne 0 ]] \
    && t_pass "8.4 client surface → tree-rebuild refuses (rc!=0)" \
    || t_fail "8.4 client surface → tree-rebuild refuses (rc!=0)" "rc=$rc84"
assert_contains "8.4 refusal names pack-surface-only"  "$out84" "pack surface only at v11.0"
assert_contains "8.4 refusal names BD-207"             "$out84" "BD-207"
# Engine-seam guard (defensive double of the verb gate): a DIRECT
# engine call with tree_only=1 on the client surface also refuses.
out84b=$(tracker_migrate_reverse_run "$REPO84" 0 0 0 0 1 2>&1)
rc84b=$?
[[ "$rc84b" -ne 0 ]] \
    && t_pass "8.4 engine seam: direct tree_only=1 call on client surface refuses" \
    || t_fail "8.4 engine seam: direct tree_only=1 call on client surface refuses" "rc=$rc84b"
assert_contains "8.4 engine-seam refusal names BD-207" "$out84b" "BD-207"
rm -rf "$REPO84"

# 8.5 (plan leg 5) status-coherence comparator — blob is status truth.
# Unit legs first: blob Status vs projection mismatch fails loud;
# --force = blob-wins (WARN, rc=0); matching pair passes; no-Status
# blob skips (field-faithful contract).
div_raw=$'**BD-001 — Add foo to bar**\nType: TODO(version)\nStatus: Resolved\nDescription: x.\n'
err85=$(_tmr_check_status_coherence "$div_raw" "Open" 42 "BD-001" 0 2>&1 1>/dev/null)
rc85=$?
[[ "$rc85" -ne 0 ]] \
    && t_pass "8.5 unit: divergent blob/projection Status fails loud (rc!=0)" \
    || t_fail "8.5 unit: divergent blob/projection Status fails loud (rc!=0)" "rc=$rc85"
assert_contains "8.5 unit: error names the pack-id"        "$err85" "BD-001"
assert_contains "8.5 unit: error names BOTH values"        "$err85" "'Open'"
assert_contains "8.5 unit: error names the blob value"     "$err85" "'Resolved'"
assert_contains "8.5 unit: error names the recovery verb"  "$err85" "pack tracker edit --status Resolved"
warn85=$(_tmr_check_status_coherence "$div_raw" "Open" 42 "BD-001" 1 2>&1 1>/dev/null)
rc85f=$?
assert_eq       "8.5 unit: --force = blob-wins (rc=0)"     "0" "$rc85f"
assert_contains "8.5 unit: --force override is WARNed, never silent" "$warn85" "blob wins"
rc85m=0
_tmr_check_status_coherence "$div_raw" "Resolved" 42 "BD-001" 0 >/dev/null 2>&1 || rc85m=1
assert_eq "8.5 unit: matching blob/projection passes" "0" "$rc85m"
rc85n=0
_tmr_check_status_coherence $'**BD-001 — X**\nType: TODO(version)\nDescription: no status field.\n' "Open" 42 "BD-001" 0 >/dev/null 2>&1 || rc85n=1
assert_eq "8.5 unit: blob without a Status line skips (field-faithful)" "0" "$rc85n"

# 8.5 e2e: a divergent issue blocks tree-rebuild; --force lets the
# blob's Status reach the tree file. Custom single-issue fixture:
# labels/state project Open, blob says Status: Resolved.
DIV_RAWBODY=$'**BD-001 — Add foo to bar**\nType: TODO(version)\nStatus: Resolved\nFile/Symbol: scripts/foo.sh\nDescription: Implements foo on bar.\n'
DIV_BLOB=$(printf '%s' "$DIV_RAWBODY" | _tmf_gz64_encode)
FAKE85=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake85.XXXXXX")
cat > "$FAKE85/gh" <<'FG85'
#!/usr/bin/env bash
label=""
for ((i=1; i<=$#; i++)); do
    if [[ "${!i}" == "--label" ]]; then
        j=$((i+1)); label="${!j}"; break
    fi
done
case "$1 $2" in
    "issue list")
        case "$label" in
            bd-entry) echo '[{"number":42,"title":"BD-001: Add foo to bar","state":"OPEN","labels":[{"name":"bd-entry"}],"assignees":[],"milestone":null,"url":"http://x/42"}]' ;;
            *)        echo '[]' ;;
        esac
        ;;
    "issue view")
        echo '{"number":42,"title":"BD-001: Add foo to bar","body":"<!-- pack-id: BD-001 -->\n<!-- template_version: bd-v11.0 -->\n<!-- pack-version: v11 -->\n<!-- pack-entry-body-gz64: @@DIV_BLOB@@ -->\n\n## Description\n\nImplements foo on bar.\n\n## File / Symbol\n\nscripts/foo.sh","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:open"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/42"}'
        ;;
    "repo view") echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    *) ;;
esac
exit 0
FG85
sed -i.bak "s|@@DIV_BLOB@@|$DIV_BLOB|" "$FAKE85/gh"
rm -f "$FAKE85/gh.bak"
chmod +x "$FAKE85/gh"
REPO85=$(mktemp -d "${TMPDIR:-/tmp}/tmr-repo85.XXXXXX")
cat > "$REPO85/tracker.toml" <<'EOF'
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
mkdir -p "$REPO85/pack-ops" "$REPO85/.pack-tracker"
printf '{ "BD-001": {"id": "42", "url": "http://x/42"} }\n' > "$REPO85/.pack-tracker/id-map.json"
export PATH="$FAKE85:$PATH_SAVED"
out85=$(bash "$PACK_TRACKER_SH" tree-rebuild --repo-root "$REPO85" 2>&1)
rc85e=$?
export PATH="$PATH_SAVED"
[[ "$rc85e" -ne 0 ]] \
    && t_pass "8.5 e2e: divergent issue blocks tree-rebuild (rc!=0)" \
    || t_fail "8.5 e2e: divergent issue blocks tree-rebuild (rc!=0)" "rc=$rc85e"
assert_contains "8.5 e2e: failure names status-coherence" "$out85" "status-coherence"
assert_contains "8.5 e2e: failure lists the pack-id"      "$out85" "BD-001"
[[ ! -f "$REPO85/backlog/BD-001.md" ]] \
    && t_pass "8.5 e2e: blocked rebuild wrote no tree file" \
    || t_fail "8.5 e2e: blocked rebuild wrote no tree file"
export PATH="$FAKE85:$PATH_SAVED"
out85f=$(bash "$PACK_TRACKER_SH" tree-rebuild --repo-root "$REPO85" --force 2>&1)
rc85ef=$?
export PATH="$PATH_SAVED"
assert_eq "8.5 e2e: --force rc=0 (blob-wins)" "0" "$rc85ef"
assert_contains "8.5 e2e: --force override surfaces a WARN" "$out85f" "blob wins"
if grep -q "^Status: Resolved$" "$REPO85/backlog/BD-001.md" 2>/dev/null; then
    t_pass "8.5 e2e: the blob's Status: Resolved reached the tree file"
else
    t_fail "8.5 e2e: the blob's Status: Resolved reached the tree file" \
        "got: $(grep '^Status:' "$REPO85/backlog/BD-001.md" 2>/dev/null)"
fi
rm -rf "$FAKE85" "$REPO85"

# 8.6 surface-neutralized silent-data-loss guard text (BD-204 ride-along
# (b)): the pack surface reconstructs the TREE, not BACKLOG.md — the
# guard message is surface-neutral. Static pin on the lib (mirrors the
# bd130 suite's grep-leg pattern).
if grep -q "Reconstructing the flat-file state now would drop" "$LIB_DIR/tracker-migrate-reverse.sh"; then
    t_pass "8.6 guard message is surface-neutralized"
else
    t_fail "8.6 guard message is surface-neutralized" "new wording missing"
fi
if grep -q "Reconstructing BACKLOG.md now would drop" "$LIB_DIR/tracker-migrate-reverse.sh"; then
    t_fail "8.6 old BACKLOG.md guard wording removed" "old wording still present"
else
    t_pass "8.6 old BACKLOG.md guard wording removed"
fi

# 8.7 SHOULD-2 (PACK-REVIEW-MODE3-OPS-COMMIT2) fail-loud emit gate: a
# PACK emit failure on the non-flip tree-rebuild arm must (a) NOT stamp
# [migration].last_tree_regen, (b) NOT print the success summary,
# (c) return rc!=0. Direct engine call (the 8.4 engine-seam pattern)
# with _tmr_emit_pack_tree overridden to fail — the exact
# `|| emit_failed=1` seam in tracker_migrate_reverse_run, exercised
# deterministically (no disk-failure simulation); the override is
# scoped to the command-substitution subshell and never leaks.
FAKE87=$(mktemp -d "${TMPDIR:-/tmp}/tmr-fake87.XXXXXX"); _build_fake_gh "$FAKE87"
REPO87=$(mktemp -d "${TMPDIR:-/tmp}/tmr-repo87.XXXXXX"); _build_test_repo "$REPO87"
export PATH="$FAKE87:$PATH_SAVED"
out87=$(
    _tmr_emit_pack_tree() { echo "SIMULATED EMIT FAILURE (8.7)" >&2; return 1; }
    tracker_migrate_reverse_run "$REPO87" 0 0 0 0 1 2>&1
)
rc87=$?
export PATH="$PATH_SAVED"
[[ "$rc87" -ne 0 ]] \
    && t_pass "8.7 emit failure → tree-rebuild rc!=0 (fail loud)" \
    || t_fail "8.7 emit failure → tree-rebuild rc!=0 (fail loud)" "rc=$rc87"
assert_not_contains "8.7 emit failure → NO success summary" "$out87" "tree-rebuild: complete"
assert_contains "8.7 emit failure → typed partial-write error"     "$out87" "ERROR: partial-write"
assert_contains "8.7 emit failure → names the failed emit step"    "$out87" "tree-rebuild: emit step failed"
assert_contains "8.7 emit failure → states the stamp was withheld" "$out87" "last_tree_regen NOT stamped"
assert_not_contains "8.7 emit failure → last_tree_regen NOT stamped in tracker.toml" \
    "$(cat "$REPO87/tracker.toml")" "last_tree_regen"
rm -rf "$FAKE87" "$REPO87"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
