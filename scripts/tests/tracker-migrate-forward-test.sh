#!/usr/bin/env bash
# scripts/tests/tracker-migrate-forward-test.sh — offline test suite
# for V1 §6.2 forward migration (BD-065).
#
# Three groups:
#   1. Parser correctness — fixture BACKLOG / IMPLEMENTATION-PLAN
#      parse to expected JSON shapes.
#   2. Helpers — mapping load/save, checkpoint write/read/clear,
#      issue-body composer, label set, mirror header.
#   3. Integration — end-to-end forward run against a temp repo with
#      a PATH-prepended fake `gh` that captures every gh invocation.
#      Asserts: right number of `issue create` calls; right title/body
#      shapes; mapping file populated correctly; second run is
#      idempotent (zero new creates).
#
# Usage: bash scripts/tests/tracker-migrate-forward-test.sh

set -u

# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
# code exercised under the clamp (never set it in a live run).
export PACK_TRACKER_DEFERRAL_OVERRIDE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-migrate"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' actual='$3'"; fi
}

assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' missing from: ${2:0:200}"; fi
}

# BD-134: keep test runtimes bounded — skip real backoff sleeps.
# The retry sweep is exercised in this suite (4.3) and in the
# dedicated tracker-bd134-close-retry-test.sh; both rely on env
# overrides to avoid 1s/2s/4s sleeps during CI. (Group 7 below is the
# BD-204 close-reason translation group, not a retry-sweep group.)
export TMF_CLOSE_RETRY_BACKOFF_SECS="0 0 0"

# Source all libs the same way tracker-migrate.sh does.
# shellcheck disable=SC1091
source "$LIB_DIR/per-entry/_lib.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/per-entry/decompose.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"

# ─────────────────────────────────────────────────────────────────
# BD-204 C-5 (C2a) — pack-tree seed helper
# ─────────────────────────────────────────────────────────────────
#
# The pack-surface forward read-side now enumerates the per-entry TREE
# under `/backlog/` (the no-monolith SSOT). The integration groups below
# therefore seed a BD-only per-entry tree into each test repo instead of
# `pack-ops/BACKLOG.md`. The pack backlog is BD-only by design (TD is the
# project namespace), so the seed filters the mixed fixture monolith to its
# BD-* entries, then decomposes them into one-entry-per-file tree files via
# the per-entry engine (the SAME `pack-backlog` regex the production read
# uses). NO `pack-ops/BACKLOG.md` monolith is written — under the
# no-monolith model there is none to read (fail-loud). The `pack-ops/`
# directory marker is still created so tracker_config_auto_surface returns
# "pack". (Group 1's parser tests still run tmf_parse_backlog directly on
# the mixed monolith fixture — that is the client-branch parser and is
# unaffected by the pack read-side repoint.)
#
# $1 = test repo root; $2 = path to a monolith fixture (mixed BD/TD ok)
_seed_pack_tree() {
    local repo="$1"
    local mono="$2"
    mkdir -p "$repo/pack-ops" "$repo/backlog"
    local bd_only
    bd_only=$(mktemp "${TMPDIR:-/tmp}/tmf-bdonly.XXXXXX")
    python3 - "$mono" > "$bd_only" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
blocks = re.split(r'\n---\n', text)
out = []
for b in blocks:
    if re.search(r'^\*\*BD-\d{3}', b.strip(), re.M):
        out.append(b.strip())
sys.stdout.write('\n\n---\n\n'.join(out) + '\n\n---\n')
PY
    per_entry_decompose "pack-backlog" "$bd_only" "$repo/backlog" >/dev/null
    rm -f "$bd_only"
}

# ─────────────────────────────────────────────────────────────────
# Group 1: parser correctness
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: parser correctness ===\n"

entries=$(tmf_parse_backlog "$FIXTURES/BACKLOG.md")
assert_eq "1.1 BACKLOG parses 5 entries" "5"        "$(printf '%s' "$entries" | jq 'length')"
assert_eq "1.1 entry[0].pack_id"          "BD-001"  "$(printf '%s' "$entries" | jq -r '.[0].pack_id')"
assert_eq "1.1 entry[0].status"           "Open"    "$(printf '%s' "$entries" | jq -r '.[0].status')"
assert_eq "1.1 entry[0].file_symbol"      "scripts/foo.sh" "$(printf '%s' "$entries" | jq -r '.[0].file_symbol')"
assert_contains "1.1 entry[0].description multi-line" \
    "$(printf '%s' "$entries" | jq -r '.[0].description')" "Multi-line continuation"
assert_eq "1.1 entry[1].blockers count=2" "2"      "$(printf '%s' "$entries" | jq '.[1].blockers | length')"
assert_eq "1.1 entry[1].blockers[0]"      "BD-001" "$(printf '%s' "$entries" | jq -r '.[1].blockers[0]')"
assert_eq "1.1 entry[1].blockers[1]"      "phase-1" "$(printf '%s' "$entries" | jq -r '.[1].blockers[1]')"
assert_eq "1.1 entry[2].status"           "Resolved" "$(printf '%s' "$entries" | jq -r '.[2].status')"
assert_contains "1.1 entry[2].resolution captures commit" \
    "$(printf '%s' "$entries" | jq -r '.[2].resolution')" "abc1234"
# BD-204 run-3 Defect C: the bare `Resolved: n/a` placeholder (unresolved
# entry; BD-001 in the fixture) parses to an EMPTY resolution, so the
# composer's empty-omission rule emits NO `## Resolution` H2 and the
# blob↔H2 divergence comparator expects none. Real resolution text
# (entry[2], asserted above) is untouched.
assert_eq "1.1 entry[0].resolution EMPTY for bare 'Resolved: n/a' (run-3 Defect C)" \
    "" "$(printf '%s' "$entries" | jq -r '.[0].resolution')"
assert_eq "1.1 entry[3].pack_id"          "TD-010"  "$(printf '%s' "$entries" | jq -r '.[3].pack_id')"
assert_eq "1.1 entry[4].status"           "Cancelled" "$(printf '%s' "$entries" | jq -r '.[4].status')"

phases=$(tmf_parse_implementation_plan "$FIXTURES/IMPLEMENTATION-PLAN.md")
assert_eq "1.2 plan parses 2 phases" "2" "$(printf '%s' "$phases" | jq 'length')"
assert_eq "1.2 phase[0].number"      "1" "$(printf '%s' "$phases" | jq -r '.[0].phase_number')"
assert_eq "1.2 phase[0].title"       "Foundations" "$(printf '%s' "$phases" | jq -r '.[0].title')"
assert_eq "1.2 phase[1].number"      "2" "$(printf '%s' "$phases" | jq -r '.[1].phase_number')"

# Empty / missing inputs surface typed errors.
err=$(tmf_parse_backlog "/no/such/BACKLOG.md" 2>&1 1>/dev/null) || true
assert_contains "1.3 missing BACKLOG → not-found" "$err" "ERROR: not-found"

# ─────────────────────────────────────────────────────────────────
# Group 2: helpers
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: helpers ===\n"

# 2.1 mapping load on missing file → empty object
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/tmf-test-helpers.XXXXXX")
m=$(tmf_mapping_load "$tmpdir/nope.json")
assert_eq "2.1 load missing → {}" "{}" "$(printf '%s' "$m" | jq -c .)"

# 2.2 set + get round-trip
m=$(tmf_mapping_set "$m" "BD-001" "42" "https://example/42")
m=$(tmf_mapping_set "$m" "TD-010" "99" "https://example/99")
assert_eq "2.2 mapping_get BD-001" "42" "$(tmf_mapping_get "$m" "BD-001")"
assert_eq "2.2 mapping_get TD-010" "99" "$(tmf_mapping_get "$m" "TD-010")"
if tmf_mapping_get "$m" "BD-999" >/dev/null 2>&1; then
    t_fail "2.2 missing key rc=1" "got rc=0"
else
    t_pass "2.2 missing key rc=1"
fi

# 2.3 save + reload round-trip
mfile="$tmpdir/id-map.json"
tmf_mapping_save "$mfile" "$m"
loaded=$(tmf_mapping_load "$mfile")
assert_eq "2.3 save/load round-trip BD-001 id" "42" "$(tmf_mapping_get "$loaded" "BD-001")"

# 2.4 checkpoint write + load + clear
ckp="$tmpdir/forward.checkpoint.json"
state=$(jq -n '{last_step: "step-4", completed_pack_ids: ["BD-001","BD-002"], timestamp: "2026-05-06T00:00:00Z"}')
tmf_checkpoint_write "$ckp" "$state"
loaded_ckp=$(tmf_checkpoint_load "$ckp")
assert_eq "2.4 checkpoint last_step"   "step-4" "$(printf '%s' "$loaded_ckp" | jq -r '.last_step')"
assert_eq "2.4 checkpoint completed_count" "2"  "$(printf '%s' "$loaded_ckp" | jq '.completed_pack_ids | length')"
tmf_checkpoint_clear "$ckp"
[[ ! -f "$ckp" ]] && t_pass "2.4 checkpoint cleared" || t_fail "2.4 checkpoint cleared"

# 2.5 issue-body composer
body=$(tmf_compose_issue_body "BD-001" "desc text" "ctx text" "" "")
assert_contains "2.5 body has pack-id marker"          "$body" "<!-- pack-id: BD-001 -->"
assert_contains "2.5 body has bd-v11.0 template_version" "$body" "<!-- template_version: bd-v11.0 -->"
assert_contains "2.5 body has pack-version: v11"       "$body" "<!-- pack-version: v11 -->"
assert_contains "2.5 body has Description section"     "$body" "## Description"
assert_contains "2.5 body has description text"        "$body" "desc text"
assert_contains "2.5 body has Context section"         "$body" "## Context"
if printf '%s' "$body" | grep -q "^## Resolution"; then
    t_fail "2.5 body Resolution absent when empty" "Resolution section unexpectedly present"
else
    t_pass "2.5 body Resolution absent when empty"
fi
# TD entries get td-v11.0 template_version
body_td=$(tmf_compose_issue_body "TD-010" "td desc" "" "" "")
assert_contains "2.5 td body has td-v11.0 marker" "$body_td" "<!-- template_version: td-v11.0 -->"
# Resolution section appears when resolution is non-empty
body_res=$(tmf_compose_issue_body "BD-003" "d" "" "fixed in abc" "")
assert_contains "2.5 body has Resolution section" "$body_res" "## Resolution"
assert_contains "2.5 body has resolution text"    "$body_res" "fixed in abc"
# File/Symbol section (Finding #3 fix) appears when non-empty
body_fs=$(tmf_compose_issue_body "BD-001" "d" "" "" "scripts/foo.sh")
assert_contains "2.5 body has File / Symbol section"   "$body_fs" "## File / Symbol"
assert_contains "2.5 body has file_symbol value"       "$body_fs" "scripts/foo.sh"
# File/Symbol omitted when empty
body_no_fs=$(tmf_compose_issue_body "BD-001" "d" "" "" "")
if printf '%s' "$body_no_fs" | grep -q "^## File / Symbol"; then
    t_fail "2.5 body File/Symbol absent when empty" "section unexpectedly present"
else
    t_pass "2.5 body File/Symbol absent when empty"
fi

# 2.6 label set composer
labels_open=$(_tmf_labels_for_entry '{"pack_id":"BD-001","status":"Open"}')
assert_eq "2.6 labels Open count=3"          "3"            "$(printf '%s' "$labels_open" | jq 'length')"
assert_contains "2.6 labels has bd-entry"    "$labels_open" '"bd-entry"'
assert_contains "2.6 labels has template:bd" "$labels_open" '"template:bd-v11.0"'
assert_contains "2.6 labels has status:open" "$labels_open" '"status:open"'
labels_resolved=$(_tmf_labels_for_entry '{"pack_id":"TD-010","status":"Resolved"}')
assert_contains "2.6 td-entry label"           "$labels_resolved" '"td-entry"'
assert_contains "2.6 status:resolved"          "$labels_resolved" '"status:resolved"'
# BD-204 DP-3 (C-5 carry-forward #1): a Deferred entry forward-encodes with
# the status:deferred label (NOT the status:open default). This is the
# FORWARD complement to the C-1 reverse-decode `status:deferred → Deferred`
# branch — without it, all 11 live Deferred entries would forward-encode as
# status:open and reverse-decode to Open, breaking the lossless round-trip.
labels_deferred=$(_tmf_labels_for_entry '{"pack_id":"BD-001","status":"Deferred"}')
assert_contains "2.6 status:deferred (DP-3 carry-forward #1)" "$labels_deferred" '"status:deferred"'
if printf '%s' "$labels_deferred" | grep -q '"status:open"'; then
    t_fail "2.6 Deferred does NOT fall through to status:open" "got status:open for a Deferred entry"
else
    t_pass "2.6 Deferred does NOT fall through to status:open"
fi

# ─────────────────────────────────────────────────────────────────
# 2.8 BD-204 §3.3 — verbatim-body-blob carrier (gz64 blob + size budget +
#     autolink neutralization). Codec PINNED to python3 (mtime=0).
# ─────────────────────────────────────────────────────────────────

# 2.8.1 the gz64 blob appears alongside the marker trio AND decodes verbatim.
bd204_raw=$'**BD-900 — Carrier fixture**\nType: TODO(version)\nStatus: Open\nDescription: line one\n\nan interior blank line and a paren ) and a fence ```\nResolved: n/a\n'
body_blob=$(tmf_compose_issue_body "BD-900" "line one" "" "" "" "$bd204_raw")
assert_contains "2.8.1 body has gz64 blob marker" "$body_blob" "<!-- pack-entry-body-gz64:"
# Extract + decode the blob; assert byte-identical to the source raw_body.
blob_payload=$(printf '%s' "$body_blob" | sed -nE 's/.*<!-- pack-entry-body-gz64:[[:space:]]*([A-Za-z0-9+/=]+)[[:space:]]*-->.*/\1/p' | head -1)
decoded_raw=$(printf '%s' "$blob_payload" | python3 -c 'import sys,base64,gzip,io; sys.stdout.buffer.write(gzip.GzipFile(fileobj=io.BytesIO(base64.b64decode(sys.stdin.read()))).read()); sys.stdout.buffer.write(b"X")')
decoded_raw="${decoded_raw%X}"
if [[ "$decoded_raw" == "$bd204_raw" ]]; then
    t_pass "2.8.1 gz64 blob decodes BYTE-IDENTICAL to raw_body (interior blank/paren/fence preserved)"
else
    t_fail "2.8.1 gz64 blob decodes BYTE-IDENTICAL to raw_body" "decoded differs"
fi

# 2.8.2 mtime=0 determinism: two composes of the same entry yield the same blob.
body_blob2=$(tmf_compose_issue_body "BD-900" "line one" "" "" "" "$bd204_raw")
blob2=$(printf '%s' "$body_blob2" | sed -nE 's/.*<!-- pack-entry-body-gz64:[[:space:]]*([A-Za-z0-9+/=]+)[[:space:]]*-->.*/\1/p' | head -1)
assert_eq "2.8.2 gz64 blob is deterministic (mtime=0)" "$blob_payload" "$blob2"

# 2.8.3 phase-style 4-arg compose emits NO blob marker (no raw_body source).
body_phase=$(tmf_compose_issue_body "phase-1" "Phase epic" "" "")
if printf '%s' "$body_phase" | grep -q "pack-entry-body-gz64"; then
    t_fail "2.8.3 4-arg compose omits blob marker" "blob unexpectedly present"
else
    t_pass "2.8.3 4-arg compose omits blob marker (DEFAULTED 6th param)"
fi

# 2.8.4 §3.3d autolink neutralization wraps the H2 PROJECTION trigger value in
#       an inline-code span (NO live autolink) AND the blob decodes verbatim.
tg_raw=$'**BD-901 — Autolink fixture**\nType: TODO(version)\nStatus: Open\nResolved: commit 08f7158 and #123 and @objc and https://x.test/y\n'
body_tg=$(tmf_compose_issue_body "BD-901" "see commit 08f7158 and #123 and @objc and https://x.test/y" "" "" "" "$tg_raw")
# The visible H2 Description value must be wrapped in a code span (backtick).
desc_proj=$(printf '%s' "$body_tg" | awk '/^## Description/{getline;getline;print;exit}')
assert_contains "2.8.4 H2 projection wraps trigger value in code span" "$desc_proj" '`'
# The blob still decodes to the verbatim original tokens.
tg_payload=$(printf '%s' "$body_tg" | sed -nE 's/.*<!-- pack-entry-body-gz64:[[:space:]]*([A-Za-z0-9+/=]+)[[:space:]]*-->.*/\1/p' | head -1)
tg_decoded=$(printf '%s' "$tg_payload" | python3 -c 'import sys,base64,gzip,io; sys.stdout.buffer.write(gzip.GzipFile(fileobj=io.BytesIO(base64.b64decode(sys.stdin.read()))).read()); sys.stdout.buffer.write(b"X")')
tg_decoded="${tg_decoded%X}"
assert_eq "2.8.4 blob decodes verbatim (autolink tokens untouched in blob)" "$tg_raw" "$tg_decoded"
assert_contains "2.8.4 blob carries the raw commit SHA verbatim" "$tg_decoded" "08f7158"

# 2.8.5 §3.3c SIZE BUDGET — a smaller-limit provider FAILs loud (never
#       truncates) above its bound; a within-budget entry passes. The stub
#       declares a 2,500-byte limit; with the 2,048-byte safety margin the
#       effective budget is ~452 bytes, so a large body overflows and a tiny
#       one fits (the limit > margin so the budget stays positive).
source "$REPO_ROOT/scripts/tests/fixtures/tracker-provider/stub-backend.sh"
tracker_provider_stub_capabilities() { echo '{"backend_name":"stub","body":{"limit":2500,"storage_format":"raw_text"},"rate_limits":{"min_write_interval_s":1}}'; }
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
big_raw=$(printf '**BD-902 — Big**\n'; for i in $(seq 1 60); do printf 'Description line %s padding padding padding padding padding padding\n' "$i"; done)
size_err=$(tmf_compose_issue_body "BD-902" "x" "" "" "" "$big_raw" 2>&1); size_rc=$?
assert_eq "2.8.5 over-budget compose rc=1 (fail loud)" "1" "$size_rc"
assert_contains "2.8.5 size-budget error names entry + byte count" "$size_err" "size-budget: entry BD-902"
assert_contains "2.8.5 size-budget error states never-truncate" "$size_err" "NEVER truncates"
small_out=$(tmf_compose_issue_body "BD-903" "x" "" "" "" $'**BD-903 — tiny**\nStatus: Open\n' 2>&1); small_rc=$?
assert_eq "2.8.5 within-budget compose rc=0" "0" "$small_rc"
assert_contains "2.8.5 within-budget body carries the blob" "$small_out" "pack-entry-body-gz64"

# 2.8.6 §3.3c a rich_text_normalizing backend FAILs loud (carrier needs raw_text).
tracker_provider_stub_capabilities() { echo '{"backend_name":"stub","body":{"limit":65536,"storage_format":"rich_text_normalizing"}}'; }
rt_err=$(tmf_compose_issue_body "BD-904" "x" "" "" "" $'**BD-904 — rt**\n' 2>&1); rt_rc=$?
assert_eq "2.8.6 rich_text backend compose rc=1" "1" "$rt_rc"
assert_contains "2.8.6 rich_text error requires raw_text" "$rt_err" "requires raw_text"
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE
# Restore the GH backend capabilities for the rest of the suite.
unset -f tracker_provider_stub_capabilities 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────
# 2.9 BD-204 §3.LF.3a — single-source BATCH MODE for the gz64 codec /
#     neutralizer / composer (Option B; design §4.6 (S)). The C-4.6 deep guard
#     calls these batch functions (ONE python3 over all N records) so its byte
#     leg shares the PRODUCTION codec (OQ-4 — no second copy can drift). These
#     tests prove BATCH-EQUIVALENCE: batch(N records) == single-record applied
#     N times, BYTE-IDENTICAL. The single-record path is verified UNCHANGED by
#     §2.8 above + the 211-entry round-trip (roundtrip test).
# ─────────────────────────────────────────────────────────────────

# _tmf_batch_frame: emit the _TMF_BATCH length-prefixed framing for a set of
# records passed as a NUL-delimited blob on stdin (so any byte — newline,
# paren, fence — survives). Output: "N\n"; then per record "L\n" + L bytes.
_tmf_batch_frame() {
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

# _tmf_batch_unframe_idx: read a _TMF_BATCH framed stream on stdin and print
# record $1 (0-based) raw bytes to stdout (no trailing sentinel issue — caller
# compares via files or $(...)+X).
_tmf_batch_nth() {
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

# 2.9.1 _tmf_gz64_encode batch == single-record applied N times (byte-identical).
b_r1=$'**BD-900 — Carrier**\nStatus: Open\ninterior blank\n\nparen ) fence ```\n'
b_r2=$'simple body\n'
b_r3=$'commit 08f7158 and #123 and @objc\n'
b_r4=$'trailing newlines body\n\n\n'
# single-record encodings
s_e1=$(printf '%s' "$b_r1" | _tmf_gz64_encode)
s_e2=$(printf '%s' "$b_r2" | _tmf_gz64_encode)
s_e3=$(printf '%s' "$b_r3" | _tmf_gz64_encode)
s_e4=$(printf '%s' "$b_r4" | _tmf_gz64_encode)
# batch encoding (NUL-delimit the 4 records, frame, run batch)
batch_enc_out=$(printf '%s\x00%s\x00%s\x00%s\x00' "$b_r1" "$b_r2" "$b_r3" "$b_r4" \
    | _tmf_batch_frame | _tmf_gz64_encode_batch | base64)
# decode the framed batch output and compare each record
be0=$(printf '%s' "$batch_enc_out" | base64 -d | _tmf_batch_nth 0); be0="${be0%X}"
be1=$(printf '%s' "$batch_enc_out" | base64 -d | _tmf_batch_nth 1); be1="${be1%X}"
be2=$(printf '%s' "$batch_enc_out" | base64 -d | _tmf_batch_nth 2); be2="${be2%X}"
be3=$(printf '%s' "$batch_enc_out" | base64 -d | _tmf_batch_nth 3); be3="${be3%X}"
assert_eq "2.9.1 gz64 batch rec0 == single-record" "$s_e1" "$be0"
assert_eq "2.9.1 gz64 batch rec1 == single-record" "$s_e2" "$be1"
assert_eq "2.9.1 gz64 batch rec2 == single-record" "$s_e3" "$be2"
assert_eq "2.9.1 gz64 batch rec3 == single-record (trailing newlines)" "$s_e4" "$be3"

# 2.9.2 _tmf_neutralize_autolinks batch == single-record applied N times.
n_v1='plain value no trigger'
n_v2='see #123 and commit 08f7158 here'
n_v3='a `code` span with @objc mention'
n_v4='http://x.test/y url trigger'
s_n1=$(printf '%s' "$n_v1" | _tmf_neutralize_autolinks)
s_n2=$(printf '%s' "$n_v2" | _tmf_neutralize_autolinks)
s_n3=$(printf '%s' "$n_v3" | _tmf_neutralize_autolinks)
s_n4=$(printf '%s' "$n_v4" | _tmf_neutralize_autolinks)
batch_neu=$(printf '%s\x00%s\x00%s\x00%s\x00' "$n_v1" "$n_v2" "$n_v3" "$n_v4" \
    | _tmf_batch_frame | _tmf_neutralize_autolinks_batch | base64)
bn0=$(printf '%s' "$batch_neu" | base64 -d | _tmf_batch_nth 0); bn0="${bn0%X}"
bn1=$(printf '%s' "$batch_neu" | base64 -d | _tmf_batch_nth 1); bn1="${bn1%X}"
bn2=$(printf '%s' "$batch_neu" | base64 -d | _tmf_batch_nth 2); bn2="${bn2%X}"
bn3=$(printf '%s' "$batch_neu" | base64 -d | _tmf_batch_nth 3); bn3="${bn3%X}"
assert_eq "2.9.2 neutralize batch rec0 == single-record (no trigger pass-through)" "$s_n1" "$bn0"
assert_eq "2.9.2 neutralize batch rec1 == single-record (#NNN + SHA trigger)" "$s_n2" "$bn1"
assert_eq "2.9.2 neutralize batch rec2 == single-record (backtick fence widen)" "$s_n3" "$bn2"
assert_eq "2.9.2 neutralize batch rec3 == single-record (URL trigger)" "$s_n4" "$bn3"

# 2.9.3 tmf_compose_issue_body batch == single-record applied N times. Each
# record is SIX length-framed fields: pack_id, description, context,
# resolution, file_symbol, raw_body. Uses the default GH provider (no live
# call; the size gate is skipped offline — within-budget bodies are identical).
c_raw1=$'**BD-136 — fixture**\nStatus: Open\ninterior ) fence ```\n'
c_raw3=$'**BD-204 — fixture**\nResolved: see #123 and commit 08f7158\n'
s_c1=$(tmf_compose_issue_body "BD-136" "line one" "" "" "" "$c_raw1")
s_c2=$(tmf_compose_issue_body "TD-010" "td desc" "ctx here" "" "scripts/foo.sh" $'**TD-010**\nbody\n')
s_c3=$(tmf_compose_issue_body "BD-204" "see commit 08f7158 and #123" "" "resolved in 08f7158" "" "$c_raw3")
s_c4=$(tmf_compose_issue_body "phase-1" "Phase epic" "" "" "" "")
# Build the 6-field-per-record framed batch input via python (NUL-safe).
compose_batch_out=$(python3 -c '
import sys
records = [
  ["BD-136", "line one", "", "", "", "**BD-136 — fixture**\nStatus: Open\ninterior ) fence ```\n"],
  ["TD-010", "td desc", "ctx here", "", "scripts/foo.sh", "**TD-010**\nbody\n"],
  ["BD-204", "see commit 08f7158 and #123", "", "resolved in 08f7158", "", "**BD-204 — fixture**\nResolved: see #123 and commit 08f7158\n"],
  ["phase-1", "Phase epic", "", "", "", ""],
]
w = sys.stdout.buffer
w.write(("%d\n" % len(records)).encode("ascii"))
for rec in records:
    for f in rec:
        fb = f.encode("utf-8")
        w.write(("%d\n" % len(fb)).encode("ascii"))
        w.write(fb)
' | tmf_compose_issue_body_batch | base64)
cb0=$(printf '%s' "$compose_batch_out" | base64 -d | _tmf_batch_nth 0); cb0="${cb0%X}"
cb1=$(printf '%s' "$compose_batch_out" | base64 -d | _tmf_batch_nth 1); cb1="${cb1%X}"
cb2=$(printf '%s' "$compose_batch_out" | base64 -d | _tmf_batch_nth 2); cb2="${cb2%X}"
cb3=$(printf '%s' "$compose_batch_out" | base64 -d | _tmf_batch_nth 3); cb3="${cb3%X}"
# single-record $(...) strips the one trailing \n; the batch payload retains it
# (printf '%s\n'). Compare with the trailing \n appended to the single capture.
assert_eq "2.9.3 compose batch rec0 == single-record (BD-136 + blob)"   "$s_c1"$'\n' "$cb0"
assert_eq "2.9.3 compose batch rec1 == single-record (TD + ctx + file)" "$s_c2"$'\n' "$cb1"
assert_eq "2.9.3 compose batch rec2 == single-record (BD-204 + resol)"  "$s_c3"$'\n' "$cb2"
assert_eq "2.9.3 compose batch rec3 == single-record (phase, no blob)"  "$s_c4"$'\n' "$cb3"

# 2.9.4 ADDITIVE invariant — the single-record _tmf_gz64_encode is UNCHANGED by
# the batch addendum (re-encode rec0 and confirm it still equals s_e1 above).
reverify_e1=$(printf '%s' "$b_r1" | _tmf_gz64_encode)
assert_eq "2.9.4 single-record _tmf_gz64_encode byte-unchanged (additive)" "$s_e1" "$reverify_e1"

# 2.8.7 §3.3d PACING — the create loop sleeps >= the min-write interval before
#       each create after the first (test seam: a counting fake sleep, no real
#       wall-clock wait).
PACE_LOG=$(mktemp "${TMPDIR:-/tmp}/tmf-pace-log.XXXXXX")
cat > "$REPO_ROOT/scripts/tests/.tmf-fake-sleep.$$" <<FSLEEP
#!/usr/bin/env bash
printf '%s\n' "\$1" >> "$PACE_LOG"
FSLEEP
chmod +x "$REPO_ROOT/scripts/tests/.tmf-fake-sleep.$$"
export TMF_PACING_SLEEP_CMD="$REPO_ROOT/scripts/tests/.tmf-fake-sleep.$$"
export TMF_PACING_INTERVAL_OVERRIDE=1
_TMF_CREATES_DONE=0
# First create: NOT paced.
_tmf_pace_before_create
[[ ! -s "$PACE_LOG" ]] && t_pass "2.8.7 first create is un-paced (no sleep)" || t_fail "2.8.7 first create is un-paced" "log=$(cat "$PACE_LOG")"
# After one create, the gate sleeps the interval.
_TMF_CREATES_DONE=1
_tmf_pace_before_create
paced=$(cat "$PACE_LOG")
assert_eq "2.8.7 second create sleeps >= interval (=1)" "1" "$paced"
rm -f "$PACE_LOG" "$REPO_ROOT/scripts/tests/.tmf-fake-sleep.$$"
unset TMF_PACING_SLEEP_CMD TMF_PACING_INTERVAL_OVERRIDE

# 2.8.8 §3.3d retry-after — on a simulated 429/secondary-rate-limit, the
#       backoff helper HONORS retry-after (backs off) rather than tight-retry.
BACKOFF_LOG=$(mktemp "${TMPDIR:-/tmp}/tmf-backoff-log.XXXXXX")
cat > "$REPO_ROOT/scripts/tests/.tmf-fake-sleep2.$$" <<FSLEEP2
#!/usr/bin/env bash
printf '%s\n' "\$1" >> "$BACKOFF_LOG"
FSLEEP2
chmod +x "$REPO_ROOT/scripts/tests/.tmf-fake-sleep2.$$"
export TMF_PACING_SLEEP_CMD="$REPO_ROOT/scripts/tests/.tmf-fake-sleep2.$$"
# A secondary-rate-limit error WITH a Retry-After hint → backoff returns 0
# (caller may retry) and sleeps the hinted seconds.
if _tmf_create_backoff "ERROR: rate-limit-secondary
Retry-After: 7"; then
    t_pass "2.8.8 backoff returns 0 (retry permitted) on rate-limit-secondary"
else
    t_fail "2.8.8 backoff returns 0 on rate-limit-secondary"
fi
assert_eq "2.8.8 backoff honors Retry-After hint (7s)" "7" "$(cat "$BACKOFF_LOG")"
# A non-pacing error → backoff returns 1 (caller aborts), no sleep.
: > "$BACKOFF_LOG"
if _tmf_create_backoff "ERROR: not-found"; then
    t_fail "2.8.8 backoff returns 1 on non-pacing error"
else
    t_pass "2.8.8 backoff returns 1 (abort) on a non-pacing error"
fi
[[ ! -s "$BACKOFF_LOG" ]] && t_pass "2.8.8 no backoff sleep on a non-pacing error" || t_fail "2.8.8 no sleep on non-pacing error"
rm -f "$BACKOFF_LOG" "$REPO_ROOT/scripts/tests/.tmf-fake-sleep2.$$"
unset TMF_PACING_SLEEP_CMD

# 2.7 mirror header
header=$(tmf_mirror_header "test-org/test-repo")
assert_contains "2.7 header opens with comment"     "$header" "<!--"
assert_contains "2.7 header names tracker mode"     "$header" "read-only mirror"
assert_contains "2.7 header includes backend slug"  "$header" "test-org/test-repo"
assert_contains "2.7 header has ISO timestamp"      "$header" "Last regenerated"
assert_contains "2.7 header closes comment"         "$header" "-->"

rm -rf "$tmpdir"

# ─────────────────────────────────────────────────────────────────
# Group 3: integration (PATH-prepended fake gh)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: integration with fake gh ===\n"

# Set up a fake-gh bin dir + log file. The fake gh records each
# invocation and can be programmed via env vars to return canned
# stdout for `gh issue list` / `gh issue create` etc.
FAKE_BIN=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin.XXXXXX")
GH_LOG=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog.XXXXXX")
ISSUE_COUNTER_FILE=$(mktemp "${TMPDIR:-/tmp}/tmf-counter.XXXXXX")
# BD-132 F-7: track which issue numbers have been closed so the
# `issue list --state closed --label X` poll (Part 1 stabilization)
# returns a count that grows as `issue close` is called. This lets
# the close-stabilization helper see the closes propagate, which is
# what its label-scoped poll measures on a real repo.
CLOSED_IDS_FILE=$(mktemp "${TMPDIR:-/tmp}/tmf-closed.XXXXXX")
: > "$CLOSED_IDS_FILE"
echo "100" > "$ISSUE_COUNTER_FILE"

cat > "$FAKE_BIN/gh" <<FAKEGH
#!/usr/bin/env bash
# Fake gh for tracker-migrate-forward tests. Captures every invocation
# in \$FAKE_GH_LOG. Returns canned content per subcommand.
printf '%s\n' "\$*" >> "$GH_LOG"

case "\$1 \$2" in
    "issue create")
        # Increment counter and emit the synthesized URL.
        counter=\$(cat "$ISSUE_COUNTER_FILE")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_FILE"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        # BD-204: enforce the REAL gh CLI close-reason vocabulary
        # {completed|not planned|duplicate} — reject anything else with
        # a nonzero exit, like the real CLI ("not planned" takes a
        # SPACE; the interface token not_planned must never reach gh).
        _cr=""; _cp=""
        for _ca in "\$@"; do
            [[ "\$_cp" == "--reason" || "\$_cp" == "-r" ]] && _cr="\$_ca"
            _cp="\$_ca"
        done
        if [[ -n "\$_cr" ]]; then
            case "\$_cr" in
                completed|"not planned"|duplicate) ;;
                *)
                    echo "fake-gh: invalid --reason '\$_cr' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                    exit 1
                    ;;
            esac
        fi
        # Track the closed id so the stabilization poll (BD-132 F-7)
        # can see it reflected in subsequent \`issue list --state
        # closed --label …\` calls. The id is the 3rd positional arg.
        printf '%s\n' "\$3" >> "$CLOSED_IDS_FILE"
        ;;
    "issue reopen"|"issue edit"|"issue comment")
        # No stdout needed for these — caller doesn't parse.
        ;;
    "search issues")
        # Default: empty result set (no marker found upstream).
        # Forces all entries down the create path.
        echo '[]'
        ;;
    "issue list")
        # BD-132 F-7: when the caller is the close-stabilization
        # poll (state=closed scoped to an entry-label), reflect the
        # tracked closed ids. For all other list calls (open
        # rosters, search, etc.) keep the legacy empty-array
        # response so the rest of the test suite is unaffected.
        want_closed=0
        for arg in "\$@"; do
            [[ "\$arg" == "closed" ]] && want_closed=1
        done
        if [[ "\$want_closed" == "1" ]]; then
            python3 - <<PY
import json
ids = []
try:
    with open("$CLOSED_IDS_FILE") as f:
        for line in f:
            line = line.strip()
            if line:
                ids.append(line)
except FileNotFoundError:
    pass
print(json.dumps([{"number": int(i)} for i in ids]))
PY
        else
            echo '[]'
        fi
        ;;
    "issue view")
        # Return labels-empty / assignees-empty payload.
        echo '{"labels":[], "assignees":[]}'
        ;;
    "repo view")
        echo '{"nameWithOwner":"fixture-org/fixture-repo"}'
        ;;
    "api graphql")
        echo '{}'
        ;;
    "extension list")
        echo ""
        ;;
    *)
        # Unhandled — return success with empty stdout.
        ;;
esac
exit 0
FAKEGH
chmod +x "$FAKE_BIN/gh"
export PATH="$FAKE_BIN:$PATH"

if [[ "$(command -v gh)" != "$FAKE_BIN/gh" ]]; then
    printf "FATAL: PATH not properly prepended (got %s)\n" "$(command -v gh)" >&2
    exit 2
fi

# Build a temp repo seeded from the fixtures.
# BD-204 C-5 (C2a): seed the BD-only per-entry tree (no monolith).
TEST_REPO=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo.XXXXXX")
_seed_pack_tree "$TEST_REPO" "$FIXTURES/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml"          "$TEST_REPO/tracker.toml"

# Override the dispatcher to keep pointing at github (the stub fixture
# tracker.toml has backend.name=stub, but we want the gh backend for
# this test since we have a PATH-mocked gh).
export _TRACKER_PROVIDER_BACKEND_OVERRIDE="github"

# 3.1 first run creates issues.
output=$(tracker_migrate_forward_run "$TEST_REPO" 0 0 2>&1)
rc=$?
assert_eq "3.1 first run rc=0" "0" "$rc"
# BD-204 C-5 (C2a): the pack tree is BD-only — the mixed fixture's BD-* set
# is {BD-001, BD-002, BD-003} (TD-010/TD-011 are the project namespace, not
# pack-backlog entries). So the pack forward parses 3 entries.
assert_contains "3.1 reports 3 entries"  "$output" "parsed 3 BACKLOG entries"
assert_contains "3.1 reports 2 phases"   "$output" "2 phase(s)"
assert_contains "3.1 reports complete"   "$output" "forward: complete"

# 3.2 fake gh log captured `issue create` per entry + per phase.
n_creates=$(grep -c "^issue create " "$GH_LOG" || true)
# 3 BD entries + 2 phase epics = 5 creates expected.
assert_eq "3.2 issue create called 5 times (3 entries + 2 phases)" "5" "$n_creates"

# 3.3 fake gh log captured ≥1 `issue close` (BD-003 Resolved — the only
# closed-state entry in the BD-only set; TD-011 Cancelled was a TD, dropped).
n_closes=$(grep -c "^issue close " "$GH_LOG" || true)
[[ "$n_closes" -ge 1 ]] && t_pass "3.3 issue close called for resolved entry (count=$n_closes)" \
    || t_fail "3.3 issue close" "expected ≥1, got $n_closes"

# 3.4 mapping file written.
mfile="$TEST_REPO/.pack-tracker/id-map.json"
[[ -f "$mfile" ]] && t_pass "3.4 mapping file written" \
    || t_fail "3.4 mapping file written" "missing $mfile"
n_mapped=$(jq 'length' "$mfile")
# 3 BD entries + 2 phases = 5 mapping entries.
assert_eq "3.4 mapping has 5 entries" "5" "$n_mapped"

# 3.5 mapping has the expected pack ids (BD-only tree + phase epics).
for pid in BD-001 BD-002 BD-003 phase-1 phase-2; do
    if jq -e --arg k "$pid" 'has($k)' "$mfile" >/dev/null; then
        t_pass "3.5 mapping has $pid"
    else
        t_fail "3.5 mapping has $pid" "missing"
    fi
done

# 3.5b BATCH-17 F1: step 7 / 7b now route through
# tracker_links_create_blocked_by, which persists every successful
# blocked-by edge to the cycle-graph store at
# .pack-tracker/links-graph.json. BD-002 has `Blockers: BD-001, phase-1`
# in the fixture. The phase-1 token routes to the v10 sub-issue-parent
# arm (NOT a blocked-by edge), so only BD-001 lands in the store as a
# blocked-by edge. Without F1, the store would not exist at all on
# initial migration.
store_path="$TEST_REPO/.pack-tracker/links-graph.json"
if [[ -f "$store_path" ]]; then
    t_pass "3.5b F1: cycle-graph store created at $store_path"
    n_edges=$(jq '.edges | length' "$store_path" 2>/dev/null || echo 0)
    if [[ "$n_edges" -ge 1 ]]; then
        t_pass "3.5b F1: cycle-graph store has ≥1 blocked-by edge (BD-002 → BD-001)"
    else
        t_fail "3.5b F1: cycle-graph store has ≥1 blocked-by edge (BD-002 → BD-001)" \
            "n_edges=$n_edges"
    fi
    # BD-002 → BD-001 edge present?
    if jq -e '.edges[] | select(.source == "BD-002" and .target == "BD-001" and .kind == "blocked-by")' \
        "$store_path" >/dev/null 2>&1; then
        t_pass "3.5b F1: cycle-graph store has BD-002 blocked-by BD-001 edge"
    else
        t_fail "3.5b F1: cycle-graph store has BD-002 blocked-by BD-001 edge" \
            "edges: $(jq -c '.edges' "$store_path" 2>/dev/null)"
    fi
else
    t_fail "3.5b F1: cycle-graph store created at $store_path" \
        "missing (was forward migration's blocked-by orchestrator wired?)"
fi

# 3.6 BD-204 C-5 (C2b RETIRE pack): the pack forward retires Step-10 — under
# the no-monolith SSOT model NO `pack-ops/BACKLOG.md` mirror is regenerated
# (regenerating one would VIOLATE the fail-loud / no-mirror standard and trip
# validate-pack Check 32′). The tree IS the mirror, regenerated by the
# reverse/regen path (C-4), not by a forward mirror-write.
[[ ! -f "$TEST_REPO/pack-ops/BACKLOG.md" ]] \
    && t_pass "3.6 pack forward writes NO pack-ops/BACKLOG.md monolith (Step-10 retired)" \
    || t_fail "3.6 pack forward writes NO pack-ops/BACKLOG.md monolith (Step-10 retired)" \
        "unexpected monolith regenerated by forward"

# 3.7 tracker.toml updated with last_forward_run.
assert_contains "3.7 tracker.toml has last_forward_run" \
    "$(cat "$TEST_REPO/tracker.toml")" "last_forward_run = \""

# 3.7b forward run flips migration.forward_complete = false → true
# per V1 §3.2 D-5; the fixture starts at false (mirroring `init` output)
# so this assertion proves the production code path emits the flip.
assert_contains "3.7b tracker.toml flips forward_complete=true" \
    "$(cat "$TEST_REPO/tracker.toml")" "forward_complete = true"

# 3.7c integration: tracker_mode resolves to "tracker" after a successful
# init→forward sequence (V1 §3.2 detection). Closes Finding #1 + #10
# from PACK-REVIEW-CUMULATIVE-V11: every prior fixture hard-coded
# forward_complete = true, so no test exercised the production flip.
mode_after=$(tracker_mode "$TEST_REPO/tracker.toml")
assert_eq "3.7c tracker_mode resolves to tracker" "tracker" "$mode_after"

# 3.8 idempotency: second run produces 0 new creates.
> "$GH_LOG"
output2=$(tracker_migrate_forward_run "$TEST_REPO" 0 0 2>&1)
rc2=$?
assert_eq "3.8 second run rc=0" "0" "$rc2"
n_creates_2=$(grep -c "^issue create " "$GH_LOG" || true)
assert_eq "3.8 second run: 0 new creates" "0" "$n_creates_2"
# Mapping file count unchanged.
n_mapped_2=$(jq 'length' "$mfile")
assert_eq "3.8 mapping count unchanged" "$n_mapped" "$n_mapped_2"

# 3.9 dry-run mode: parser runs, no creates.
> "$GH_LOG"
TEST_REPO2=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo-dry.XXXXXX")
_seed_pack_tree "$TEST_REPO2" "$FIXTURES/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO2/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml" "$TEST_REPO2/tracker.toml"
output3=$(tracker_migrate_forward_run "$TEST_REPO2" 1 0 2>&1)
rc3=$?
assert_eq "3.9 dry-run rc=0"           "0" "$rc3"
assert_contains "3.9 dry-run prints summary" "$output3" "parsed 3 BACKLOG entries"
assert_contains "3.9 dry-run stops after parse" "$output3" "stopping after parse"
n_creates_3=$(grep -c "^issue create " "$GH_LOG" || true)
assert_eq "3.9 dry-run: 0 creates" "0" "$n_creates_3"
[[ ! -d "$TEST_REPO2/.pack-tracker" ]] && t_pass "3.9 dry-run: no .pack-tracker dir created" \
    || t_fail "3.9 dry-run: no .pack-tracker dir created"

# 3.10 status subcommand reports the V2 §22.1 8-field surface.
status_out=$(tracker_migrate_status_report "$TEST_REPO" 2>&1)
assert_contains "3.10 status reports tracker mode"        "$status_out" "tracker mode:"
assert_contains "3.10 status reports backend"             "$status_out" "backend:"
assert_contains "3.10 status reports repo"                "$status_out" "repo:"
assert_contains "3.10 status reports mapping count"       "$status_out" "mapping count:"
assert_contains "3.10 status reports mapping freshness"   "$status_out" "mapping freshness:"
assert_contains "3.10 status reports mirror freshness"    "$status_out" "mirror freshness:"
assert_contains "3.10 status reports template freshness"  "$status_out" "template freshness:"
assert_contains "3.10 status reports last forward run"    "$status_out" "last forward run:"
assert_contains "3.10 status reports last reverse run"    "$status_out" "last reverse run:"

# 3.10b BD-204 C-6-FIX1 (F-1): on the PACK surface the "mirror freshness"
# line reads the `/backlog/_toc.md` tree regen index (DP-4), NOT the
# DELETED `pack-ops/BACKLOG.md` monolith. Plant a `_toc.md` (tree regen
# index) AND a STALE `pack-ops/BACKLOG.md` sentinel; assert the status
# line reflects the tree's mtime and NEVER consults the deleted monolith.
TEST_REPO_ST=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo-status.XXXXXX")
_seed_pack_tree "$TEST_REPO_ST" "$FIXTURES/BACKLOG.md"   # pack-ops/ marker → pack surface
cp "$FIXTURES/tracker.toml" "$TEST_REPO_ST/tracker.toml"
printf '# Backlog index\n\n- BD-001\n' > "$TEST_REPO_ST/backlog/_toc.md"
# BD-219 CI-fix: portable file-mtime → ISO-8601 UTC. `date -r FILE` is a
# BSD-vs-GNU flag-semantics hazard (BSD `-r` historically expects epoch
# seconds, not a file); python3 yields the byte-identical UTC string on both
# platforms (matches the production `date -r … -u` output on the GNU CI runner).
toc_mtime_st=$(MTIME_FILE="$TEST_REPO_ST/backlog/_toc.md" python3 -c \
    'import os,datetime; print(datetime.datetime.fromtimestamp(int(os.path.getmtime(os.environ["MTIME_FILE"])), datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))' \
    2>/dev/null || echo "")
# Stale monolith sentinel: if the pack branch ever read it, the V1 §6.3
# `<!--` header would make mirror_age its mtime / "(no mirror header)".
printf '<!-- STALE MONOLITH SENTINEL -->\n**BD-001 — should never be read**\n' \
    > "$TEST_REPO_ST/pack-ops/BACKLOG.md"
status_out_st=$(tracker_migrate_status_report "$TEST_REPO_ST" 2>&1)
mirror_line_st=$(printf '%s\n' "$status_out_st" | grep '^mirror freshness:')
# Positive: pack mirror-freshness == the /backlog/_toc.md mtime.
assert_contains "3.10b pack mirror freshness reads /backlog/_toc.md mtime" \
    "$mirror_line_st" "$toc_mtime_st"
# Negative (defensive): the stale monolith is NEVER consulted — neither
# its path nor any monolith-header artifact appears in the mirror line.
if printf '%s' "$status_out_st" | grep -q 'pack-ops/BACKLOG.md'; then
    t_fail "3.10b pack status never names pack-ops/BACKLOG.md" "found pack-ops/BACKLOG.md in status output"
else
    t_pass "3.10b pack status never names pack-ops/BACKLOG.md"
fi
if printf '%s' "$mirror_line_st" | grep -q '(no mirror header)'; then
    t_fail "3.10b pack status never inspects the monolith header" "got '(no mirror header)' — the deleted monolith was consulted"
else
    t_pass "3.10b pack status never inspects the monolith header"
fi
rm -rf "$TEST_REPO_ST"

# 3.11 missing tracker.toml: forward fails with typed error. (Only the
# pack-ops/ surface marker is needed — forward errors at the tracker.toml
# check before any entry read, so no tree seed is required.)
TEST_REPO3=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo-noconf.XXXXXX")
mkdir -p "$TEST_REPO3/pack-ops"
err=$(tracker_migrate_forward_run "$TEST_REPO3" 0 0 2>&1) || true
assert_contains "3.11 missing tracker.toml → validation" "$err" "ERROR: validation"
assert_contains "3.11 error mentions pack tracker init" "$err" "pack tracker init"

# ─────────────────────────────────────────────────────────────────
# Group 4: review-fix verifications
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: review-fix verifications ===\n"

# 4.1 Mirror-header idempotency (Finding #2): three consecutive runs
# of _tmf_regen_mirror against a clean-body fixture produce byte-equal
# files modulo the "Last regenerated" timestamp line.
mtmp=$(mktemp "${TMPDIR:-/tmp}/tmf-mirror-idem.XXXXXX")
printf 'Some BACKLOG body content.\nLine two.\n' > "$mtmp"
_tmf_regen_mirror "$mtmp" "test-org/test-repo"
snap1=$(grep -v "Last regenerated:" "$mtmp")
_tmf_regen_mirror "$mtmp" "test-org/test-repo"
snap2=$(grep -v "Last regenerated:" "$mtmp")
_tmf_regen_mirror "$mtmp" "test-org/test-repo"
snap3=$(grep -v "Last regenerated:" "$mtmp")
assert_eq "4.1 mirror regen run-2 ≡ run-1 (modulo timestamp)" "$snap1" "$snap2"
assert_eq "4.1 mirror regen run-3 ≡ run-1 (modulo timestamp)" "$snap1" "$snap3"
# Body content survives all three runs.
assert_contains "4.1 body line preserved across runs" "$snap1" "Some BACKLOG body content."
rm -f "$mtmp"

# 4.2 File/Symbol round-trip (Finding #3): an entry with File/Symbol
# set ships through to the issue body. Use the parser+composer chain
# directly (the fixture BACKLOG.md has File/Symbol on every entry).
entries_for_fs=$(tmf_parse_backlog "$FIXTURES/BACKLOG.md")
entry_bd1=$(printf '%s' "$entries_for_fs" | jq -c '.[0]')
fs_value=$(printf '%s' "$entry_bd1" | jq -r '.file_symbol')
assert_eq "4.2 parser captures file_symbol BD-001" "scripts/foo.sh" "$fs_value"
desc_bd1=$(printf '%s' "$entry_bd1" | jq -r '.description')
ctx_bd1=$(printf  '%s' "$entry_bd1" | jq -r '.context')
res_bd1=$(printf  '%s' "$entry_bd1" | jq -r '.resolution')
body_bd1=$(tmf_compose_issue_body "BD-001" "$desc_bd1" "$ctx_bd1" "$res_bd1" "$fs_value")
assert_contains "4.2 composed body has File / Symbol heading" "$body_bd1" "## File / Symbol"
assert_contains "4.2 composed body has scripts/foo.sh"        "$body_bd1" "scripts/foo.sh"
# BD-204 run-3 Defect C: BD-001 carries the bare `Resolved: n/a`
# placeholder, so the parse→compose chain emits NO `## Resolution` H2
# (pre-fix it emitted a phantom `## Resolution\n\nn/a` section).
# (This suite has no assert_not_contains helper — use the same grep
# idiom as the 2.5 "Resolution absent when empty" leg.)
if printf '%s' "$body_bd1" | grep -q "^## Resolution"; then
    t_fail "4.2 composed body has NO ## Resolution for bare 'Resolved: n/a' (run-3 Defect C)" \
        "phantom Resolution section present"
else
    t_pass "4.2 composed body has NO ## Resolution for bare 'Resolved: n/a' (run-3 Defect C)"
fi

# 4.3 Partial-write surfacing (Finding #5): fake gh that fails on
# `issue close` produces an end-of-run partial-write typed error.
FAKE_BIN_PF=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-pf.XXXXXX")
GH_LOG_PF=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-pf.XXXXXX")
ISSUE_COUNTER_PF=$(mktemp "${TMPDIR:-/tmp}/tmf-counter-pf.XXXXXX")
echo "200" > "$ISSUE_COUNTER_PF"

cat > "$FAKE_BIN_PF/gh" <<FAKEGH_PF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_PF"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_PF")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_PF"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        echo "HTTP 422: cannot close issue" >&2
        exit 1
        ;;
    "issue comment")          ;;
    "issue edit")             ;;
    "search issues")          echo '[]' ;;
    "issue list")             echo '[]' ;;
    "issue view")             echo '{"labels":[], "assignees":[]}' ;;
    "repo view")              echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")            echo '{}' ;;
    "extension list")         echo "" ;;
    *)                        ;;
esac
exit 0
FAKEGH_PF
chmod +x "$FAKE_BIN_PF/gh"

# Run forward with fake-gh that fails on close. Expect rc=1 + partial-write.
TEST_REPO_PF=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo-pf.XXXXXX")
_seed_pack_tree "$TEST_REPO_PF" "$FIXTURES/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_PF/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml" "$TEST_REPO_PF/tracker.toml"

PATH_SAVED="$PATH"
export PATH="$FAKE_BIN_PF:$PATH_SAVED"
# `|| true` would mask the non-zero rc we are testing for. Without it
# and without `set -e`, the assignment's rc propagates to $?.
output_pf=$(tracker_migrate_forward_run "$TEST_REPO_PF" 0 0 2>&1)
rc_pf=$?
export PATH="$PATH_SAVED"

assert_eq "4.3 partial-failure run rc=1"             "1" "$rc_pf"
assert_contains "4.3 surfaces ERROR: partial-write"  "$output_pf" "ERROR: partial-write"
assert_contains "4.3 partial-write names step-8 close" "$output_pf" "step-8 close"
assert_contains "4.3 partial-write next-step verb"   "$output_pf" "→ Run: see resume options"

# Mapping file IS persisted even on partial failure (Finding #7 fix).
mfile_pf="$TEST_REPO_PF/.pack-tracker/id-map.json"
[[ -f "$mfile_pf" ]] && t_pass "4.3 mapping persisted on partial failure" \
    || t_fail "4.3 mapping persisted on partial failure" "missing $mfile_pf"

# BD-131: a partial-CLOSE failure (creates all succeeded, closes
# failed) MUST still flip migration.forward_complete = true. The
# create surface is the strong signal for `tracker_mode()`; close
# failures are best-effort and surfaced via the partial-write typed
# error above. Treating partial closes as forward_incomplete would
# silently route downstream tooling to flat-file mode after an
# otherwise successful migration — defeating the opt-in.
assert_contains "4.3 BD-131 forward_complete=true after partial-close (creates clean)" \
    "$(cat "$TEST_REPO_PF/tracker.toml")" "forward_complete = true"

rm -rf "$FAKE_BIN_PF" "$GH_LOG_PF" "$ISSUE_COUNTER_PF" "$TEST_REPO_PF"

# 4.4 Body-marker recovery (Findings #1 + #8): fake gh that returns
# a search hit AND a matching body marker for BD-001 → BD-065 should
# treat the entry as recovered (registered in mapping, not re-created).
FAKE_BIN_REC=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-rec.XXXXXX")
GH_LOG_REC=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-rec.XXXXXX")
ISSUE_COUNTER_REC=$(mktemp "${TMPDIR:-/tmp}/tmf-counter-rec.XXXXXX")
# BD-132 F-7: track closed ids so the stabilization poll sees them.
CLOSED_IDS_REC=$(mktemp "${TMPDIR:-/tmp}/tmf-closed-rec.XXXXXX")
: > "$CLOSED_IDS_REC"
echo "300" > "$ISSUE_COUNTER_REC"

cat > "$FAKE_BIN_REC/gh" <<'FAKEGH_REC'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "@@GH_LOG@@"

# Special-case BD-001 recovery: search returns a hit, view returns
# matching body marker. Match on substring of "$*" so quote-fragility
# in case patterns is avoided.
all="$*"
case "$all" in
    *"search issues"*"BD-001:"*)
        # Raw `gh search issues --json ...` shape: an array of objects.
        # Provider's normalizer wraps it into the {items, next_cursor} envelope.
        echo '[{"number":555,"title":"BD-001: Add foo","url":"https://github.com/fixture-org/fixture-repo/issues/555","state":"OPEN","labels":[]}]'
        exit 0
        ;;
    *"issue view 555"*)
        # Raw `gh issue view 555 --json ...` shape (flat object).
        # Body contains the matching pack-id marker → recovery succeeds.
        printf '%s\n' '{"number":555,"title":"BD-001: Add foo","body":"<!-- pack-id: BD-001 -->\n<!-- template_version: bd-v11.0 -->","state":"OPEN","stateReason":null,"labels":[],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"https://github.com/fixture-org/fixture-repo/issues/555"}'
        exit 0
        ;;
esac

case "$1 $2" in
    "issue create")
        counter=$(cat "@@COUNTER@@")
        next=$((counter + 1))
        echo "$next" > "@@COUNTER@@"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "$next"
        ;;
    "issue close")
        # BD-204: enforce the REAL gh CLI close-reason vocabulary
        # {completed|not planned|duplicate} — nonzero exit otherwise.
        _cr=""; _cp=""
        for _ca in "$@"; do
            [[ "$_cp" == "--reason" || "$_cp" == "-r" ]] && _cr="$_ca"
            _cp="$_ca"
        done
        if [[ -n "$_cr" ]]; then
            case "$_cr" in
                completed|"not planned"|duplicate) ;;
                *)
                    echo "fake-gh: invalid --reason '$_cr' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                    exit 1
                    ;;
            esac
        fi
        # BD-132 F-7: track the closed id for stabilization poll visibility.
        printf '%s\n' "$3" >> "@@CLOSED_IDS@@"
        ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues")    echo '[]' ;;
    "issue list")
        # BD-132 F-7: stabilization poll asks for state=closed,label=...
        want_closed=0
        for arg in "$@"; do
            [[ "$arg" == "closed" ]] && want_closed=1
        done
        if [[ "$want_closed" == "1" ]]; then
            python3 - <<PY
import json
ids = []
try:
    with open("@@CLOSED_IDS@@") as f:
        for line in f:
            line = line.strip()
            if line:
                ids.append(line)
except FileNotFoundError:
    pass
print(json.dumps([{"number": int(i)} for i in ids]))
PY
        else
            echo '[]'
        fi
        ;;
    "issue view")       echo '{"labels":[], "assignees":[]}' ;;
    "repo view")        echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")      echo '{}' ;;
    "extension list")   echo "" ;;
    *)                  ;;
esac
exit 0
FAKEGH_REC
# Substitute placeholders to avoid heredoc-quoting headaches.
sed -i.bak \
    -e "s|@@GH_LOG@@|$GH_LOG_REC|g" \
    -e "s|@@COUNTER@@|$ISSUE_COUNTER_REC|g" \
    -e "s|@@CLOSED_IDS@@|$CLOSED_IDS_REC|g" \
    "$FAKE_BIN_REC/gh"
rm -f "$FAKE_BIN_REC/gh.bak"
chmod +x "$FAKE_BIN_REC/gh"

TEST_REPO_REC=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo-rec.XXXXXX")
_seed_pack_tree "$TEST_REPO_REC" "$FIXTURES/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_REC/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml" "$TEST_REPO_REC/tracker.toml"

export PATH="$FAKE_BIN_REC:$PATH_SAVED"
output_rec=$(tracker_migrate_forward_run "$TEST_REPO_REC" 0 0 2>&1)
rc_rec=$?
export PATH="$PATH_SAVED"

assert_eq "4.4 recovery run rc=0" "0" "$rc_rec"
# Mapping should have BD-001 with id=555 (recovered, not freshly created).
mfile_rec="$TEST_REPO_REC/.pack-tracker/id-map.json"
[[ -f "$mfile_rec" ]] || t_fail "4.4 mapping file written" "missing"
bd1_id=$(jq -r '.["BD-001"].id' "$mfile_rec")
assert_eq "4.4 BD-001 mapped to recovered id 555 (not a new create)" "555" "$bd1_id"
# Output reports recovered counter.
assert_contains "4.4 output reports recovered" "$output_rec" "recovered:"

rm -rf "$FAKE_BIN_REC" "$GH_LOG_REC" "$ISSUE_COUNTER_REC" "$CLOSED_IDS_REC" "$TEST_REPO_REC"

# 4.5 --mirror-only flag (BD-065 review fix #10) on the PACK surface.
# BD-204 C-6 / POQ-1 (C5 review F-2): the pack monolith
# pack-ops/BACKLOG.md is DELETED (BD-203 no-mirror SSOT) — there is NO
# forward mirror to rebuild on the pack surface. The pack branch must
# FAIL LOUD (typed validation error) rather than reading/regenerating a
# deleted monolith. The per-entry tree under /backlog/ is the SSOT,
# regenerated by the reverse/regen path (NOT a forward mirror-rebuild).
GH_LOG_MO=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-mo.XXXXXX")
FAKE_BIN_MO=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-mo.XXXXXX")
cat > "$FAKE_BIN_MO/gh" <<FAKE_GH_MO
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_MO"
exit 0
FAKE_GH_MO
chmod +x "$FAKE_BIN_MO/gh"

TEST_REPO_MO=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo-mo.XXXXXX")
mkdir -p "$TEST_REPO_MO/pack-ops"   # surface marker → pack
# Seed the per-entry tree (the pack SSOT). NO pack-ops/BACKLOG.md
# monolith — it is deleted under BD-203.
mkdir -p "$TEST_REPO_MO/backlog"
cat > "$TEST_REPO_MO/backlog/BD-001.md" <<'EOF'
<!-- per-entry source: backlog/BD-001.md; contract: backlog/_rules.md -->
**BD-001 — Seed entry**
Status: Open
EOF
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_MO/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml"          "$TEST_REPO_MO/tracker.toml"

export PATH="$FAKE_BIN_MO:$PATH_SAVED"
output_mo=$(tracker_migrate_forward_run "$TEST_REPO_MO" 0 0 1 2>&1)
rc_mo=$?
export PATH="$PATH_SAVED"

# Pack branch fails loud: non-zero rc + typed validation error.
[[ "$rc_mo" -ne 0 ]] \
    && t_pass "4.5 --mirror-only on pack surface returns non-zero (fail-loud)" \
    || t_fail "4.5 --mirror-only on pack surface returns non-zero (fail-loud)" "rc=$rc_mo"
assert_contains "4.5 --mirror-only pack error is typed validation" "$output_mo" "ERROR: validation"
assert_contains "4.5 --mirror-only pack error names no-mirror SSOT" "$output_mo" "not applicable on the no-mirror pack surface"
# BD-204 Mode-3 ops contract §2 ride-along (a) (plan leg 3): the
# fail-loud message now NAMES the replacement verb.
assert_contains "4.5 --mirror-only pack error names tree-rebuild" "$output_mo" "pack tracker tree-rebuild"
# NO monolith regenerated — the pack branch never writes pack-ops/BACKLOG.md.
[[ ! -f "$TEST_REPO_MO/pack-ops/BACKLOG.md" ]] \
    && t_pass "4.5 --mirror-only writes NO pack-ops/BACKLOG.md monolith" \
    || t_fail "4.5 --mirror-only writes NO pack-ops/BACKLOG.md monolith"
# Zero gh calls: the short-circuit errors before touching the tracker.
n_gh_calls=$(wc -l < "$GH_LOG_MO" | tr -d ' ')
assert_eq "4.5 --mirror-only invokes 0 gh calls" "0" "$n_gh_calls"
# No mapping file written.
[[ ! -f "$TEST_REPO_MO/.pack-tracker/id-map.json" ]] \
    && t_pass "4.5 --mirror-only writes no id-map.json" \
    || t_fail "4.5 --mirror-only writes no id-map.json"

rm -rf "$FAKE_BIN_MO" "$GH_LOG_MO" "$TEST_REPO_MO"

# 4.5b CLIENT-surface --mirror-only regression (BD-204 Mode-3 ops
# contract, plan leg 4): the client arm is UNTOUCHED by the pack
# tree-rebuild work — `mirror-rebuild` still legitimately refreshes the
# client BACKLOG.md mirror header (rc=0, header written, body
# preserved). BD-207 owns the client repoint.
GH_LOG_MOC=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-moc.XXXXXX")
FAKE_BIN_MOC=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-moc.XXXXXX")
cat > "$FAKE_BIN_MOC/gh" <<FAKE_GH_MOC
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_MOC"
exit 0
FAKE_GH_MOC
chmod +x "$FAKE_BIN_MOC/gh"

TEST_REPO_MOC=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo-moc.XXXXXX")
mkdir -p "$TEST_REPO_MOC/docs/pack"   # surface marker → client (no pack-ops/)
cp "$FIXTURES/tracker.toml" "$TEST_REPO_MOC/docs/pack/tracker.toml"
printf '# BACKLOG\n\n**TD-001 — Client seed entry**\nStatus: Open\n' > "$TEST_REPO_MOC/BACKLOG.md"

export PATH="$FAKE_BIN_MOC:$PATH_SAVED"
output_moc=$(tracker_migrate_forward_run "$TEST_REPO_MOC" 0 0 1 2>&1)
rc_moc=$?
export PATH="$PATH_SAVED"

assert_eq       "4.5b client --mirror-only rc=0 (regression)" "0" "$rc_moc"
assert_contains "4.5b client --mirror-only refreshes the mirror header" \
    "$output_moc" "BACKLOG.md mirror header refreshed"
head_moc=$(head -n 1 "$TEST_REPO_MOC/BACKLOG.md")
assert_eq "4.5b client BACKLOG.md gains the read-only mirror header" "<!--" "$head_moc"
grep -q "TD-001 — Client seed entry" "$TEST_REPO_MOC/BACKLOG.md" \
    && t_pass "4.5b client BACKLOG.md body preserved under the header" \
    || t_fail "4.5b client BACKLOG.md body preserved under the header"

rm -rf "$FAKE_BIN_MOC" "$GH_LOG_MOC" "$TEST_REPO_MOC"

# 4.6 Checkpoint cadence integration test (PACK-REVIEW-BD065 Finding
# #6 closure). Lower TMF_CHECKPOINT_INTERVAL=2 against the BD-only tree
# (3 BD entries): expect a checkpoint write after entry 2, and the
# checkpoint cleared after the post-loop step 11.
FAKE_BIN_CP=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-cp.XXXXXX")
GH_LOG_CP=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-cp.XXXXXX")
ISSUE_COUNTER_CP=$(mktemp "${TMPDIR:-/tmp}/tmf-counter-cp.XXXXXX")
# BD-132 F-7: track closed ids so the stabilization poll sees them.
CLOSED_IDS_CP=$(mktemp "${TMPDIR:-/tmp}/tmf-closed-cp.XXXXXX")
: > "$CLOSED_IDS_CP"
echo "300" > "$ISSUE_COUNTER_CP"

cat > "$FAKE_BIN_CP/gh" <<FAKEGH_CP
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_CP"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_CP")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_CP"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        # BD-204: enforce the REAL gh CLI close-reason vocabulary
        # {completed|not planned|duplicate} — nonzero exit otherwise.
        _cr=""; _cp=""
        for _ca in "\$@"; do
            [[ "\$_cp" == "--reason" || "\$_cp" == "-r" ]] && _cr="\$_ca"
            _cp="\$_ca"
        done
        if [[ -n "\$_cr" ]]; then
            case "\$_cr" in
                completed|"not planned"|duplicate) ;;
                *)
                    echo "fake-gh: invalid --reason '\$_cr' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                    exit 1
                    ;;
            esac
        fi
        # BD-132 F-7: track closed id for stabilization poll.
        printf '%s\n' "\$3" >> "$CLOSED_IDS_CP"
        ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues") echo '[]' ;;
    "issue list")
        # BD-132 F-7: state=closed poll → return tracked ids.
        want_closed=0
        for arg in "\$@"; do
            [[ "\$arg" == "closed" ]] && want_closed=1
        done
        if [[ "\$want_closed" == "1" ]]; then
            python3 - <<PY
import json
ids = []
try:
    with open("$CLOSED_IDS_CP") as f:
        for line in f:
            line = line.strip()
            if line:
                ids.append(line)
except FileNotFoundError:
    pass
print(json.dumps([{"number": int(i)} for i in ids]))
PY
        else
            echo '[]'
        fi
        ;;
    "issue view")    echo '{"labels":[], "assignees":[]}' ;;
    "repo view")     echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")   echo '{}' ;;
    "extension list") echo "" ;;
    *)               ;;
esac
exit 0
FAKEGH_CP
chmod +x "$FAKE_BIN_CP/gh"

TEST_REPO_CP=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo-cp.XXXXXX")
_seed_pack_tree "$TEST_REPO_CP" "$FIXTURES/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_CP/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml"          "$TEST_REPO_CP/tracker.toml"

# Override the cadence and run forward. Re-source the lib because
# TMF_CHECKPOINT_INTERVAL is read at source-time when env-overridable.
export TMF_CHECKPOINT_INTERVAL=2
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"

export PATH="$FAKE_BIN_CP:$PATH_SAVED"
output_cp=$(tracker_migrate_forward_run "$TEST_REPO_CP" 0 0 0 2>&1)
rc_cp=$?
export PATH="$PATH_SAVED"
unset TMF_CHECKPOINT_INTERVAL
# Re-source lib to restore default cadence for any later tests.
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"

assert_eq "4.6 forward with cadence=2 rc=0" "0" "$rc_cp"
# Checkpoint file is cleared at end-of-run (step 11), but mid-run
# writes were performed. The mapping file should reflect all 3 BD
# entries + 2 phases.
mfile_cp="$TEST_REPO_CP/.pack-tracker/id-map.json"
[[ -f "$mfile_cp" ]] && t_pass "4.6 mapping file written" \
    || t_fail "4.6 mapping file written"
n_mapped_cp=$(jq 'length' "$mfile_cp")
assert_eq "4.6 mapping has 5 entries" "5" "$n_mapped_cp"
# Checkpoint should be cleared after success.
ckp_cp="$TEST_REPO_CP/.pack-tracker/forward.checkpoint.json"
[[ ! -f "$ckp_cp" ]] && t_pass "4.6 checkpoint cleared after success" \
    || t_fail "4.6 checkpoint cleared after success"

rm -rf "$FAKE_BIN_CP" "$GH_LOG_CP" "$ISSUE_COUNTER_CP" "$CLOSED_IDS_CP" "$TEST_REPO_CP"

# Cleanup of Group 3 globals.
rm -rf "$FAKE_BIN" "$GH_LOG" "$ISSUE_COUNTER_FILE" "$CLOSED_IDS_FILE" "$TEST_REPO" "$TEST_REPO2" "$TEST_REPO3"

# ─────────────────────────────────────────────────────────────────
# Group 5: BD-131 forward_complete write semantics
# ─────────────────────────────────────────────────────────────────
#
# BD-131 (D-4) — clean forward must flip
# `tracker.toml [migration].forward_complete = true` so V1 §3.2
# `tracker_mode()` resolves to "tracker". Partial-create failures
# must leave the flag at "false" so downstream tooling stays on
# flat-file until the operator re-runs init to complete the create
# surface.
#
# Group 4.3 already covers the partial-CLOSE path (creates clean,
# closes fail) — that one MUST flip to true (asserted above).
# Group 5 covers:
#   5.1 — direct writer round-trip with both "true" and "false"
#   5.2 — _tmf_verify_forward_complete read-back helper
#   5.3 — partial-CREATE failure → forward_complete stays "false"
#         (full integration: fake gh fails on the 4th `issue create`)

printf "\n=== Group 5: BD-131 forward_complete write semantics ===\n"

# 5.1 _tmf_update_tracker_toml round-trip.
TOML_RT=$(mktemp -d "${TMPDIR:-/tmp}/tmf-bd131-rt.XXXXXX")
cat > "$TOML_RT/tracker.toml" <<'TOML'
schema_version = 1

[backend]
name = "github"
repo = "fixture-org/fixture-repo"

[mode]
state = "tracker"

[id_namespace]
prefix = "BD"

[migration]
forward_complete = false
mapping_file = ".pack-tracker/id-map.json"
TOML

_tmf_update_tracker_toml "$TOML_RT/tracker.toml" "true"
assert_contains "5.1 writer with 'true' flips forward_complete=true" \
    "$(cat "$TOML_RT/tracker.toml")" "forward_complete = true"
assert_contains "5.1 writer with 'true' adds last_forward_run" \
    "$(cat "$TOML_RT/tracker.toml")" "last_forward_run = \""

_tmf_update_tracker_toml "$TOML_RT/tracker.toml" "false"
assert_contains "5.1 writer with 'false' sets forward_complete=false" \
    "$(cat "$TOML_RT/tracker.toml")" "forward_complete = false"

# 5.1b default arg is "true" (preserves pre-BD-131 behavior at any
# call site that omits the second arg).
cat > "$TOML_RT/tracker.toml" <<'TOML'
schema_version = 1
[backend]
name = "github"
repo = "x/y"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = false
TOML
_tmf_update_tracker_toml "$TOML_RT/tracker.toml"
assert_contains "5.1b writer omitted-arg defaults to 'true'" \
    "$(cat "$TOML_RT/tracker.toml")" "forward_complete = true"

# 5.1c writer rejects unexpected values (defensive — out-of-schema
# strings would break tracker_mode() resolution downstream).
cat > "$TOML_RT/tracker.toml" <<'TOML'
schema_version = 1
[migration]
forward_complete = false
TOML
err_5_1c=$(_tmf_update_tracker_toml "$TOML_RT/tracker.toml" "yes" 2>&1) || true
assert_contains "5.1c writer rejects unexpected value with stderr WARN" \
    "$err_5_1c" "refusing to write unexpected forward_complete value"
assert_contains "5.1c rejected write leaves forward_complete unchanged" \
    "$(cat "$TOML_RT/tracker.toml")" "forward_complete = false"

rm -rf "$TOML_RT"

# 5.2 _tmf_verify_forward_complete helper.
TOML_VF=$(mktemp -d "${TMPDIR:-/tmp}/tmf-bd131-vf.XXXXXX")
cat > "$TOML_VF/tracker.toml" <<'TOML'
schema_version = 1
[backend]
name = "github"
repo = "x/y"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
TOML
_tmf_verify_forward_complete "$TOML_VF/tracker.toml" "true"
assert_eq "5.2 verify match → rc=0" "0" "$?"

vf_err=$(_tmf_verify_forward_complete "$TOML_VF/tracker.toml" "false" 2>&1)
vf_rc=$?
assert_eq "5.2 verify mismatch → rc=1" "1" "$vf_rc"
assert_contains "5.2 verify mismatch emits stderr WARN" \
    "$vf_err" "read-back mismatch"

# 5.2b verify is a no-op (returns 0) when cfg is missing — it's a
# best-effort safety net, not a hard precondition.
_tmf_verify_forward_complete "/no/such/file.toml" "true"
assert_eq "5.2b verify on missing cfg → rc=0 (no-op)" "0" "$?"

rm -rf "$TOML_VF"

# 5.3 Partial-CREATE failure: fake gh fails on the 4th `issue
# create`. Forward should early-return rc=1 BEFORE step 11, so
# tracker.toml's forward_complete remains at the init-time "false".
# Per BD-131 semantics the create surface is the strong signal —
# a partial create means the mapping does not cover every entry,
# so downstream `tracker_mode()` MUST keep resolving to flat-file.
FAKE_BIN_C=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-c.XXXXXX")
GH_LOG_C=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-c.XXXXXX")
ISSUE_COUNTER_C=$(mktemp "${TMPDIR:-/tmp}/tmf-counter-c.XXXXXX")
echo "0" > "$ISSUE_COUNTER_C"

cat > "$FAKE_BIN_C/gh" <<FAKEGH_C
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_C"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_C")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_C"
        # Fail on the 2nd create — the BD-only tree has 3 BD entries, so
        # failing on the 2nd entry create fails mid-entry-loop, exercising
        # the BD-131 creation_ok=0 branch via the tmf provider_create
        # early-return (a partial-CREATE, not a partial-close).
        if [[ "\$next" == "2" ]]; then
            echo "HTTP 422: validation failed" >&2
            exit 1
        fi
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        # BD-204: enforce the REAL gh CLI close-reason vocabulary
        # {completed|not planned|duplicate} — nonzero exit otherwise.
        _cr=""; _cp=""
        for _ca in "\$@"; do
            [[ "\$_cp" == "--reason" || "\$_cp" == "-r" ]] && _cr="\$_ca"
            _cp="\$_ca"
        done
        if [[ -n "\$_cr" ]]; then
            case "\$_cr" in
                completed|"not planned"|duplicate) ;;
                *)
                    echo "fake-gh: invalid --reason '\$_cr' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                    exit 1
                    ;;
            esac
        fi
        ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues")         echo '[]' ;;
    "issue list")            echo '[]' ;;
    "issue view")            echo '{"labels":[], "assignees":[]}' ;;
    "repo view")             echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")           echo '{}' ;;
    "extension list")        echo "" ;;
    *)                       ;;
esac
exit 0
FAKEGH_C
chmod +x "$FAKE_BIN_C/gh"

TEST_REPO_C=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo-c.XXXXXX")
_seed_pack_tree "$TEST_REPO_C" "$FIXTURES/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_C/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml"          "$TEST_REPO_C/tracker.toml"

# Confirm the fixture starts at forward_complete = false (so a
# false flag at end-of-test is meaningful: it proves the writer
# did not flip on partial-create, NOT that the writer never ran).
assert_contains "5.3 fixture starts forward_complete=false" \
    "$(cat "$TEST_REPO_C/tracker.toml")" "forward_complete = false"

PATH_SAVED_C="$PATH"
export PATH="$FAKE_BIN_C:$PATH_SAVED_C"
output_c=$(tracker_migrate_forward_run "$TEST_REPO_C" 0 0 2>&1)
rc_c=$?
export PATH="$PATH_SAVED_C"

# Forward should fail with the propagated provider_create error
# (early-return at the create site — step 11 never runs).
assert_eq "5.3 partial-create run rc=1" "1" "$rc_c"

# Retro F5: confirm the orchestrator surfaces the propagated
# provider_create error rather than swallowing it. The fake gh emits
# "HTTP 422: validation failed" on the 4th create; mirror 4.3's
# output assertions so the captured stderr has at least one
# load-bearing pin.
assert_contains "5.3 partial-create run surfaces propagated provider_create error" \
    "$output_c" "validation failed"

# tracker.toml MUST still read forward_complete = false so
# tracker_mode() keeps resolving to flat-file (V1 §3.2). This is
# the BD-131 contract: partial creates MUST NOT silently route
# downstream tooling to tracker mode against an incomplete map.
assert_contains "5.3 BD-131 forward_complete stays 'false' on partial-create" \
    "$(cat "$TEST_REPO_C/tracker.toml")" "forward_complete = false"

# Mapping file SHOULD have the partial set (entries created before
# the failure) — Finding #7's per-create save invariant.
mfile_c="$TEST_REPO_C/.pack-tracker/id-map.json"
[[ -f "$mfile_c" ]] && t_pass "5.3 partial-create mapping persisted (resume seed)" \
    || t_fail "5.3 partial-create mapping persisted (resume seed)" "missing $mfile_c"

rm -rf "$FAKE_BIN_C" "$GH_LOG_C" "$ISSUE_COUNTER_C" "$TEST_REPO_C"

# 5.4 BD-131 retro F1 — resume-then-completes flips forward_complete
# to "true". The resume path is the documented recovery verb for the
# `forward_complete = false` state 5.3 introduced. This test pins down
# the orchestrator-level invariant end-to-end:
#
#   Phase 1 — partial-create run leaves the create surface incomplete:
#     - Override TMF_CHECKPOINT_INTERVAL=2 so a checkpoint is written
#       after the 2nd entry (the default 25 would never write because
#       the failure happens before idx % 25 == 0).
#     - Use a fake gh that fails on the 4th `issue create`.
#     - Assert rc=1 + forward_complete still "false" + checkpoint
#       file present (resume seed).
#
#   Phase 2 — resume run completes the surface:
#     - Re-use the same TEST_REPO so the partial mapping +
#       checkpoint carry forward.
#     - Swap to a fake gh that succeeds on every operation.
#     - Run `tracker_migrate_forward_run "$REPO" 0 1` (resume=1).
#     - Assert rc=0 (no partial-write) + forward_complete = "true"
#       on disk + last_forward_run line written + tracker_mode() now
#       resolves to "tracker".
#
# A future refactor that quietly regresses the resume path's
# interaction with `creation_ok` (e.g. resetting it to 0 inside the
# resume skip arm, or rebuilding completed_pack_ids from the mapping
# without re-driving step 11) would fail this test immediately.

FAKE_BIN_R1=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-r1.XXXXXX")
GH_LOG_R1=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-r1.XXXXXX")
ISSUE_COUNTER_R1=$(mktemp "${TMPDIR:-/tmp}/tmf-counter-r1.XXXXXX")
echo "0" > "$ISSUE_COUNTER_R1"

# Phase 1 fake gh: fails on the 3rd `issue create`. With the BD-only tree
# (3 BD entries) and cadence=2, a checkpoint is written after entry 2; the
# 3rd entry create then fails, leaving 2 created + a checkpoint (the resume
# seed). Splitting the fake into two binaries (R1 = fail-on-3rd, R2 =
# always-succeed) makes the swap explicit between the partial and resume
# runs.
cat > "$FAKE_BIN_R1/gh" <<FAKEGH_R1
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_R1"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_R1")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_R1"
        if [[ "\$next" == "3" ]]; then
            echo "HTTP 422: validation failed" >&2
            exit 1
        fi
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        # BD-204: enforce the REAL gh CLI close-reason vocabulary
        # {completed|not planned|duplicate} — nonzero exit otherwise.
        _cr=""; _cp=""
        for _ca in "\$@"; do
            [[ "\$_cp" == "--reason" || "\$_cp" == "-r" ]] && _cr="\$_ca"
            _cp="\$_ca"
        done
        if [[ -n "\$_cr" ]]; then
            case "\$_cr" in
                completed|"not planned"|duplicate) ;;
                *)
                    echo "fake-gh: invalid --reason '\$_cr' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                    exit 1
                    ;;
            esac
        fi
        ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues")         echo '[]' ;;
    "issue list")            echo '[]' ;;
    "issue view")            echo '{"labels":[], "assignees":[]}' ;;
    "repo view")             echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")           echo '{}' ;;
    "extension list")        echo "" ;;
    *)                       ;;
esac
exit 0
FAKEGH_R1
chmod +x "$FAKE_BIN_R1/gh"

TEST_REPO_R=$(mktemp -d "${TMPDIR:-/tmp}/tmf-repo-r.XXXXXX")
_seed_pack_tree "$TEST_REPO_R" "$FIXTURES/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_R/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml"           "$TEST_REPO_R/tracker.toml"

# Override checkpoint cadence so phase 1 writes a checkpoint that
# phase 2's resume can consume. Re-source the lib because the
# constant is read at source-time.
export TMF_CHECKPOINT_INTERVAL=2
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"

# ── Phase 1 — partial-create run ─────────────────────────────────
PATH_SAVED_R="$PATH"
export PATH="$FAKE_BIN_R1:$PATH_SAVED_R"
output_r1=$(tracker_migrate_forward_run "$TEST_REPO_R" 0 0 2>&1)
rc_r1=$?
export PATH="$PATH_SAVED_R"

assert_eq "5.4 phase-1 partial-create run rc=1" "1" "$rc_r1"
assert_contains "5.4 phase-1 forward_complete stays 'false'" \
    "$(cat "$TEST_REPO_R/tracker.toml")" "forward_complete = false"
ckp_r="$TEST_REPO_R/.pack-tracker/forward.checkpoint.json"
[[ -f "$ckp_r" ]] && t_pass "5.4 phase-1 checkpoint persisted (resume seed)" \
    || t_fail "5.4 phase-1 checkpoint persisted (resume seed)" "missing $ckp_r"

# Sanity: tracker_mode() must resolve to flat-file at this point
# even though [mode].state = "tracker" (the fixture sets it). This
# is the V1 §3.2 / D-5 contract that BD-131 enforces.
mode_after_partial=$(tracker_mode "$TEST_REPO_R/tracker.toml")
assert_eq "5.4 phase-1 tracker_mode() → flat-file" "flat-file" "$mode_after_partial"

# ── Phase 2 — swap to all-success fake gh and resume ─────────────
FAKE_BIN_R2=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-r2.XXXXXX")
GH_LOG_R2=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-r2.XXXXXX")
ISSUE_COUNTER_R2=$(mktemp "${TMPDIR:-/tmp}/tmf-counter-r2.XXXXXX")
# BD-132 F-7: track closed ids so the stabilization poll sees them
# (the fixture has a Resolved entry, so step 8 closes will fire and
# step 8.5 will poll for state=closed).
CLOSED_IDS_R2=$(mktemp "${TMPDIR:-/tmp}/tmf-closed-r2.XXXXXX")
: > "$CLOSED_IDS_R2"
# Continue the gh-id sequence past where phase 1 stopped (2 entries
# created → next id is 3) so the resume's new creates do not collide
# with the partial mapping. Phase 1's 3rd attempt failed; phase 2 must
# satisfy the 3rd BD entry + 2 phase epics = 3 more creates.
echo "2" > "$ISSUE_COUNTER_R2"

cat > "$FAKE_BIN_R2/gh" <<FAKEGH_R2
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_R2"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_R2")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_R2"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        # BD-204: enforce the REAL gh CLI close-reason vocabulary
        # {completed|not planned|duplicate} — nonzero exit otherwise.
        _cr=""; _cp=""
        for _ca in "\$@"; do
            [[ "\$_cp" == "--reason" || "\$_cp" == "-r" ]] && _cr="\$_ca"
            _cp="\$_ca"
        done
        if [[ -n "\$_cr" ]]; then
            case "\$_cr" in
                completed|"not planned"|duplicate) ;;
                *)
                    echo "fake-gh: invalid --reason '\$_cr' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                    exit 1
                    ;;
            esac
        fi
        printf '%s\n' "\$3" >> "$CLOSED_IDS_R2"
        ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues")         echo '[]' ;;
    "issue list")
        want_closed=0
        for arg in "\$@"; do
            [[ "\$arg" == "closed" ]] && want_closed=1
        done
        if [[ "\$want_closed" == "1" ]]; then
            python3 - <<PY
import json
ids = []
try:
    with open("$CLOSED_IDS_R2") as f:
        for line in f:
            line = line.strip()
            if line:
                ids.append(line)
except FileNotFoundError:
    pass
print(json.dumps([{"number": int(i)} for i in ids]))
PY
        else
            echo '[]'
        fi
        ;;
    "issue view")            echo '{"labels":[], "assignees":[]}' ;;
    "repo view")             echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")           echo '{}' ;;
    "extension list")        echo "" ;;
    *)                       ;;
esac
exit 0
FAKEGH_R2
chmod +x "$FAKE_BIN_R2/gh"

export PATH="$FAKE_BIN_R2:$PATH_SAVED_R"
output_r2=$(tracker_migrate_forward_run "$TEST_REPO_R" 0 1 2>&1)
rc_r2=$?
export PATH="$PATH_SAVED_R"

# Restore default checkpoint cadence for any later groups.
unset TMF_CHECKPOINT_INTERVAL
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"

# Resume must succeed end-to-end (no partial-write surface).
assert_eq "5.4 phase-2 resume run rc=0" "0" "$rc_r2"

# This is the load-bearing assertion: the orchestrator-level invariant
# (creation_ok=1 → step 11 writes "true") must hold across the
# resume → completes path. A future regression that flips
# creation_ok to 0 inside the resume skip arm — or rebuilds
# completed_pack_ids without driving step 11 — would fail here.
assert_contains "5.4 BD-131 phase-2 resume flips forward_complete to 'true'" \
    "$(cat "$TEST_REPO_R/tracker.toml")" "forward_complete = true"

# last_forward_run must have been written by step 11 (the partial
# run never reached step 11, so the absence-then-presence flip is a
# clean signal that step 11 ran on resume).
assert_contains "5.4 phase-2 resume writes last_forward_run" \
    "$(cat "$TEST_REPO_R/tracker.toml")" "last_forward_run = \""

# Composition check: tracker_mode() now resolves to "tracker" — the
# user-visible recovery contract for BD-131.
mode_after_resume=$(tracker_mode "$TEST_REPO_R/tracker.toml")
assert_eq "5.4 phase-2 tracker_mode() → tracker" "tracker" "$mode_after_resume"

# Checkpoint must be cleared after the successful resume (V1 §6.2
# step 11 cleanup; PACK-REVIEW-BD065 Finding #6 + BD-132 F-4
# stabilization-conditional clear). With our all-success fake gh,
# stabilization succeeds → checkpoint cleared.
[[ ! -f "$ckp_r" ]] && t_pass "5.4 phase-2 checkpoint cleared after resume success" \
    || t_fail "5.4 phase-2 checkpoint cleared after resume success" "$ckp_r still present"

# Mapping must be complete: 3 BD entries + 2 phase epics = 5 ids.
mfile_r="$TEST_REPO_R/.pack-tracker/id-map.json"
n_mapped_r=$(jq 'length' "$mfile_r")
assert_eq "5.4 phase-2 mapping has 5 entries (3 BD + 2 phases)" \
    "5" "$n_mapped_r"

rm -rf "$FAKE_BIN_R1" "$GH_LOG_R1" "$ISSUE_COUNTER_R1" \
       "$FAKE_BIN_R2" "$GH_LOG_R2" "$ISSUE_COUNTER_R2" \
       "$CLOSED_IDS_R2" "$TEST_REPO_R"

# ─────────────────────────────────────────────────────────────────
# Group 6: BD-108 cross-entity link routing (review F3)
# ─────────────────────────────────────────────────────────────────
#
# BD-108 review F3 (per IMPLEMENTATION-REPORT-BD-108-FIX): the forward
# orchestrator gained two new BD-108 paths that were unit-tested in
# `test-tracker-links.sh` (orchestration layer) but not exercised
# end-to-end at the migrator level:
#
#   (a) step 6+7 case-statement routing — a BACKLOG entry with
#       `Blockers: phase-N.M` must route to `provider_link blocked-by`
#       (which routes to the first-class `addBlockedBy` GraphQL
#       mutation per BD-111), NOT to `provider_sub_issue_create` (the
#       v10 phase-N sub-issue parent path).
#   (b) new step 7b — when an IMPLEMENTATION-PLAN.md contains a
#       phase-task `Dependencies` bullet, the orchestrator parses it
#       via `tracker_phase_task_parse` and replays each dependency as
#       a `provider_link blocked-by` call.
#
# Both paths are exercised here against the same fake-gh + integration
# pattern Group 3 uses, but with a self-contained mini-fixture so the
# pre-existing entry counts (5 BD/TD + 2 phase) stay intact.

printf "\n=== Group 6: BD-108 cross-entity link routing (review F3) ===\n"

# Mini-fixture repo with one BACKLOG entry that has `Blockers:
# phase-3.2` and an IMPLEMENTATION-PLAN with a Dependencies bullet.
TEST_REPO_BD108=$(mktemp -d "${TMPDIR:-/tmp}/tmf-bd108.XXXXXX")
mkdir -p "$TEST_REPO_BD108/pack-ops"   # surface marker → pack
mkdir -p "$TEST_REPO_BD108/backlog"    # BD-204 C-5: per-entry tree (no monolith)
BD108_MONO=$(mktemp "${TMPDIR:-/tmp}/tmf-bd108-mono.XXXXXX")
FAKE_BIN_BD108=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-bd108.XXXXXX")
GH_LOG_BD108=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-bd108.XXXXXX")
ISSUE_COUNTER_BD108=$(mktemp "${TMPDIR:-/tmp}/tmf-counter-bd108.XXXXXX")
echo "0" > "$ISSUE_COUNTER_BD108"

# Two BACKLOG entries:
#   - BD-501: blocked by phase-3.2 (the BD-108 routing target)
#   - BD-502: blocked by phase-3 (the v10 sub-issue-parent path; included
#     so the test can prove the case statement routes the two cases
#     differently against the SAME fake-gh log).
# Three phases (1, 2, 3) so the id-map carries phase-3 for the
# sub-issue-parent path. phase-3.2 is NOT created at v11.0 (phase-task
# creation is a future BD; documented limitation 10.2 of the BD-108
# IMPLEMENTATION-REPORT) — so the phase-3.2 Blocker reaches the case
# statement but tmf_mapping_get returns empty, surfacing the routing
# decision via the partial_failures path.
# BD-204 C-5 (C2a): write the mini-fixture to a temp monolith, then
# decompose it into the BD-only per-entry tree the pack forward reads.
cat > "$BD108_MONO" <<'BACKLOG'
# BACKLOG

**BD-501 — Phase-task blocker entry (BD-108 routing target)**
Type: TODO(version)
Status: Open
Blockers: phase-3.2
Unblocks: None
File/Symbol: scripts/foo.sh
Description: BD-108 F3 routing fixture.
Resolved: n/a

---

**BD-502 — Phase-epic blocker entry (v10 sub-issue parent path)**
Type: TODO(version)
Status: Open
Blockers: phase-3
Unblocks: None
File/Symbol: scripts/bar.sh
Description: Counterpoint to BD-501 — proves case statement
  routes phase-N differently than phase-N.M.
Resolved: n/a

---
BACKLOG
per_entry_decompose "pack-backlog" "$BD108_MONO" "$TEST_REPO_BD108/backlog" >/dev/null

cat > "$TEST_REPO_BD108/IMPLEMENTATION-PLAN.md" <<'PLAN'
# IMPLEMENTATION PLAN

## Phases

### Phase 1 — Foundations

Lay the foundations.

### Phase 2 — Polish

Polish for v1.

### Phase 3 — Cross-entity dependencies

Phase epic for BD-065 (V3.3 §6.4): the H3 form is what the BD-065
forward parser recognizes for phase-epic creation.

## Phase 3 — Cross-entity dependencies

The H2 form is what the BD-106 phase-task parser recognizes as the
phase context for `#### N.M — Title` task headings below.

### Tasks
#### 3.1 — Schema bootstrap
- **Problem / Goal / Success**: define the initial schema.
- **Files created/modified**: schemas/v11.json
- **Definition of done**: schema-validate PASS.
- **Dependencies**:
  - phase-3.2 (must complete migration scaffold first)
  - TD-029
PLAN

cat > "$TEST_REPO_BD108/tracker.toml" <<'TOML'
schema_version = 1

[backend]
name = "stub"
repo = "fixture-org/fixture-repo"

[mode]
state = "tracker"

[id_namespace]
prefix = "BD"

[migration]
forward_complete = false
mapping_file = ".pack-tracker/id-map.json"
TOML

# Reuse the same fake-gh shape as Group 3 — captures every call to
# the log file. F3-specific assertions inspect the log for the
# routing-decision fingerprints.
cat > "$FAKE_BIN_BD108/gh" <<FAKEGH_BD108
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_BD108"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_BD108")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_BD108"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        # BD-204: enforce the REAL gh CLI close-reason vocabulary
        # {completed|not planned|duplicate} — nonzero exit otherwise.
        # (No closed-status entry in this mini-fixture; the guard keeps
        # every close stub in this suite vocabulary-strict.)
        _cr=""; _cp=""
        for _ca in "\$@"; do
            [[ "\$_cp" == "--reason" || "\$_cp" == "-r" ]] && _cr="\$_ca"
            _cp="\$_ca"
        done
        if [[ -n "\$_cr" ]]; then
            case "\$_cr" in
                completed|"not planned"|duplicate) ;;
                *)
                    echo "fake-gh: invalid --reason '\$_cr' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                    exit 1
                    ;;
            esac
        fi
        ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues") echo '[]' ;;
    "issue list")    echo '[]' ;;
    "issue view")    echo '{"labels":[], "assignees":[]}' ;;
    "repo view")     echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")   echo '{}' ;;
    "extension list") echo "" ;;
    *)               ;;
esac
exit 0
FAKEGH_BD108
chmod +x "$FAKE_BIN_BD108/gh"

# Ensure the github backend is selected (the mini-fixture's tracker.toml
# uses the "stub" backend, but we need the gh backend so the fake gh
# captures the routing fingerprint).
export _TRACKER_PROVIDER_BACKEND_OVERRIDE="github"

PATH_SAVED_BD108="$PATH"
export PATH="$FAKE_BIN_BD108:$PATH_SAVED_BD108"
output_bd108=$(tracker_migrate_forward_run "$TEST_REPO_BD108" 0 0 2>&1)
rc_bd108=$?
export PATH="$PATH_SAVED_BD108"

# rc=1 is the expected outcome here because the v11.0 fixture
# deliberately exercises step 7b's "phase-task source not in id-map"
# branch (phase-task creation is a future BD per BD-108 §10.2),
# which surfaces as a partial-write — see assertion 6.3 below.
# A clean rc=0 would mean step 7b silently swallowed the gap, which
# is the regression F10 fixed.
assert_eq "6.1 BD-108 mini-fixture forward rc=1 (partial-write expected)" "1" "$rc_bd108"
assert_contains "6.1 partial-write surfaces ERROR: partial-write" \
    "$output_bd108" "ERROR: partial-write"

# (F3-a) The phase-3.2 Blocker on BD-501 must reach the case statement.
# Because phase-3.2 is not in the id-map (no phase-task creation at
# v11.0), tmf_mapping_get returns empty — the case-statement arm
# proceeds without invoking provider_link. The routing decision is
# observable via the partial_failures log: the phase-N.M arm does NOT
# emit a "step-6 sub_issue_create: BD-501 -> phase-3.2" entry (which
# would indicate the v10 path was taken). Instead, the new
# phase-N.M arm runs and produces no log line for the missing target
# (silent skip — distinct from sub_issue_create's failure log).
#
# We assert the absence of the v10-path failure marker for BD-501 →
# phase-3.2. If the BD-108 case-statement reorder were reverted, the
# v10 phase-N arm would catch phase-3.2 and write
# "step-6 sub_issue_create: BD-501 -> phase-3.2" to partial_failures
# (which surfaces in the run output via the typed partial-write
# error block).
if [[ "$output_bd108" != *"step-6 sub_issue_create: BD-501 -> phase-3.2"* ]]; then
    t_pass "6.2 phase-3.2 Blocker NOT routed to sub_issue_create (BD-108 F3a)"
else
    t_fail "6.2 phase-3.2 Blocker NOT routed to sub_issue_create (BD-108 F3a)" \
        "v10 phase-N arm caught phase-3.2 — case-statement order regression"
fi

# (F3-b) Step 7b runs when IMPLEMENTATION-PLAN.md has a Dependencies
# bullet. Because phase-3.1 (the task carrying the Dependencies bullet)
# is NOT in the id-map at v11.0, the source-not-in-id-map branch fires.
# The marker line in partial_failures is "step-7b phase-task source
# not in id-map: phase-3.1". This proves step 7b's parser ran and the
# replay loop attempted resolution — the BD-108 IMPLEMENTATION-REPORT
# documented this as the v11.0 limitation (10.2).
assert_contains "6.3 step 7b runs and surfaces phase-task source gap (BD-108 F3b)" \
    "$output_bd108" "step-7b phase-task source not in id-map: phase-3.1"

# (F3-cleanup) The v10 path for phase-3 (BD-502) MUST still fire
# sub_issue_create — proves the case-statement reorder did not
# regress the existing v10 routing.
n_sub_issue_calls=$(grep -c "issue edit\|sub-issue\|/sub_issues" "$GH_LOG_BD108" 2>/dev/null || true)
# The github backend uses `gh api graphql` (or REST sub-issue
# endpoint) for sub-issue create — depending on the backend version.
# Either way, BD-502's phase-3 Blocker should route to a sub-issue
# create attempt against phase-3's gh id; the fake gh's log captures
# the api graphql call. We rely on the integration log having at
# least one api-graphql or sub-issue invocation as proxy for the
# v10 path firing for BD-502 → phase-3.
n_api_graphql=$(grep -c "^api graphql" "$GH_LOG_BD108" 2>/dev/null || true)
[[ "$n_api_graphql" -ge 1 ]] && t_pass "6.4 v10 phase-N Blocker still routes via api graphql (sub-issue path intact)" \
    || t_fail "6.4 v10 phase-N Blocker still routes via api graphql (sub-issue path intact)" \
       "expected ≥1 api-graphql call for BD-502 → phase-3 sub-issue; got $n_api_graphql"

unset _TRACKER_PROVIDER_BACKEND_OVERRIDE
rm -rf "$FAKE_BIN_BD108" "$GH_LOG_BD108" "$ISSUE_COUNTER_BD108" "$TEST_REPO_BD108" "$BD108_MONO"

# ─────────────────────────────────────────────────────────────────
# Group 7: BD-204 close-reason CLI-boundary translation (C-8 live flip)
# ─────────────────────────────────────────────────────────────────
#
# The C-8 live flip (2026-06-11) failed ALL FIVE Deprecated/Cancelled
# closes (BD-021/022/023/103/123) 3x each: tracker_provider_gh_close
# passed the provider INTERFACE token `not_planned` straight to
# `gh issue close --reason`, whose real vocabulary is
# {completed|not planned|duplicate} — "not planned" takes a SPACE.
# Every mock accepted any reason string, so the drift never failed
# offline; the live-oracle fixture had no Deprecated/Cancelled entry,
# so it never failed live either. This group pins the END-TO-END
# forward path: a Deprecated entry AND a Cancelled entry must reach
# the gh CLI as `--reason not planned` (the translated form), against
# a fake gh that — like every close stub in this suite now — REJECTS
# any reason outside the real CLI vocabulary.

printf "\n=== Group 7: BD-204 close-reason CLI-boundary translation ===\n"

TEST_REPO_CR=$(mktemp -d "${TMPDIR:-/tmp}/tmf-closereason.XXXXXX")
mkdir -p "$TEST_REPO_CR/pack-ops"   # surface marker → pack
mkdir -p "$TEST_REPO_CR/backlog"    # per-entry tree (no monolith)
CR_MONO=$(mktemp "${TMPDIR:-/tmp}/tmf-cr-mono.XXXXXX")
FAKE_BIN_CR=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-cr.XXXXXX")
GH_LOG_CR=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-cr.XXXXXX")
ISSUE_COUNTER_CR=$(mktemp "${TMPDIR:-/tmp}/tmf-counter-cr.XXXXXX")
CLOSED_IDS_CR=$(mktemp "${TMPDIR:-/tmp}/tmf-closed-cr.XXXXXX")
: > "$CLOSED_IDS_CR"
echo "600" > "$ISSUE_COUNTER_CR"

cat > "$CR_MONO" <<'BACKLOG'
# BACKLOG

**BD-601 — Deprecated close-reason entry**
Type: TODO(version)
Status: Deprecated
Blockers: None
Unblocks: None
File/Symbol: scripts/foo.sh
Description: Deprecated entry — step 8 must close it with the interface
  reason not_planned, translated to the gh CLI form at the boundary.
Resolved: n/a

---

**BD-602 — Cancelled close-reason entry**
Type: TODO(version)
Status: Cancelled
Blockers: None
Unblocks: None
File/Symbol: scripts/bar.sh
Description: Cancelled entry — same not_planned interface reason, same
  CLI translation as the Deprecated row (DP-3).
Resolved: n/a

---
BACKLOG
per_entry_decompose "pack-backlog" "$CR_MONO" "$TEST_REPO_CR/backlog" >/dev/null

cat > "$TEST_REPO_CR/IMPLEMENTATION-PLAN.md" <<'PLAN'
# IMPLEMENTATION PLAN
PLAN
cp "$FIXTURES/tracker.toml" "$TEST_REPO_CR/tracker.toml"

# Vocabulary-enforcing fake gh: same shape as Group 3 (create counter,
# closed-id tracking for the BD-132 stabilization poll), with the
# BD-204 close-reason guard.
cat > "$FAKE_BIN_CR/gh" <<FAKEGH_CR
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_CR"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_CR")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_CR"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        # BD-204: enforce the REAL gh CLI close-reason vocabulary
        # {completed|not planned|duplicate} — nonzero exit otherwise.
        _cr=""; _cp=""
        for _ca in "\$@"; do
            [[ "\$_cp" == "--reason" || "\$_cp" == "-r" ]] && _cr="\$_ca"
            _cp="\$_ca"
        done
        if [[ -n "\$_cr" ]]; then
            case "\$_cr" in
                completed|"not planned"|duplicate) ;;
                *)
                    echo "fake-gh: invalid --reason '\$_cr' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                    exit 1
                    ;;
            esac
        fi
        printf '%s\n' "\$3" >> "$CLOSED_IDS_CR"
        ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues") echo '[]' ;;
    "issue list")
        # BD-132 F-7: state=closed poll → return tracked ids.
        want_closed=0
        for arg in "\$@"; do
            [[ "\$arg" == "closed" ]] && want_closed=1
        done
        if [[ "\$want_closed" == "1" ]]; then
            python3 - <<PY
import json
ids = []
try:
    with open("$CLOSED_IDS_CR") as f:
        for line in f:
            line = line.strip()
            if line:
                ids.append(line)
except FileNotFoundError:
    pass
print(json.dumps([{"number": int(i)} for i in ids]))
PY
        else
            echo '[]'
        fi
        ;;
    "issue view")    echo '{"labels":[], "assignees":[]}' ;;
    "repo view")     echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")   echo '{}' ;;
    "extension list") echo "" ;;
    *)               ;;
esac
exit 0
FAKEGH_CR
chmod +x "$FAKE_BIN_CR/gh"

export _TRACKER_PROVIDER_BACKEND_OVERRIDE="github"
PATH_SAVED_CR="$PATH"
export PATH="$FAKE_BIN_CR:$PATH_SAVED_CR"
output_cr=$(tracker_migrate_forward_run "$TEST_REPO_CR" 0 0 2>&1)
rc_cr=$?
export PATH="$PATH_SAVED_CR"
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE

# 7.1 the run completes clean: both closes were ACCEPTED by the
# vocabulary-enforcing fake (pre-fix this run died partial-write with
# both closes failing 3x — exactly the C-8 live-flip shape).
assert_eq "7.1 forward over Deprecated+Cancelled fixture rc=0" "0" "$rc_cr"
# (This suite has no assert_not_contains helper — same grep idiom as 4.2.)
if [[ "$output_cr" == *"ERROR: partial-write"* ]]; then
    t_fail "7.1 no partial-write (closes accepted by the vocabulary-enforcing fake)" \
        "partial-write surfaced: ${output_cr:0:200}"
else
    t_pass "7.1 no partial-write (closes accepted by the vocabulary-enforcing fake)"
fi
assert_contains "7.1 summary reports both entries closed" "$output_cr" "closed:     2"

# 7.2 BOTH closes reach the gh CLI in the TRANSLATED form. The create
# counter starts at 600 and the tree enumerates BD-601 then BD-602, so
# the gh ids are 601 and 602 deterministically.
log_cr=$(cat "$GH_LOG_CR")
assert_contains "7.2 Deprecated close reaches gh as --reason not planned" \
    "$log_cr" "issue close 601 --reason not planned"
assert_contains "7.2 Cancelled close reaches gh as --reason not planned" \
    "$log_cr" "issue close 602 --reason not planned"
n_translated=$(grep -c -- "--reason not planned" "$GH_LOG_CR" || true)
assert_eq "7.2 exactly 2 translated close invocations" "2" "$n_translated"

# 7.3 the interface token never leaks through to the CLI.
if grep -q -- "--reason not_planned" "$GH_LOG_CR"; then
    t_fail "7.3 interface token not_planned must NOT reach the gh CLI" \
        "$(grep -- '--reason' "$GH_LOG_CR" | head -2 | tr '\n' ' ')"
else
    t_pass "7.3 interface token not_planned does not reach the gh CLI"
fi

rm -rf "$FAKE_BIN_CR" "$GH_LOG_CR" "$ISSUE_COUNTER_CR" "$CLOSED_IDS_CR" \
       "$TEST_REPO_CR" "$CR_MONO"

# ─────────────────────────────────────────────────────────────────
# Group 8: BD-204 C-8 defect 2 — Blockers-cycle pre-pass (fail loud
# BEFORE any provider call)
# ─────────────────────────────────────────────────────────────────
#
# The live C-8 flip carried a mutual block (BD-094 `Blockers: BD-088,
# BD-095, BD-085` + BD-095 `Blockers: BD-085, BD-088, BD-094`). The
# BD-108 per-edge cycle check refused the second edge pre-call on
# every run, but the step-7 arms swallowed the typed error, so each
# run ended partial-write with only the bare unactionable line
# `step-7 link blocked-by: BD-095 -> BD-094` — retried verbatim 3x.
# This group pins the END-TO-END contract of the parse-time pre-pass
# (tmf_blockers_cycle_precheck): a forward run over the same 2-cycle
# topology fails LOUD — naming both IDs and the full cycle path —
# with ZERO provider calls (no issue create, no link mutation), on
# both the real run and `--dry-run`.

printf "\n=== Group 8: BD-204 C-8 Blockers-cycle pre-pass ===\n"

TEST_REPO_CY=$(mktemp -d "${TMPDIR:-/tmp}/tmf-cycle.XXXXXX")
mkdir -p "$TEST_REPO_CY/pack-ops"   # surface marker → pack
mkdir -p "$TEST_REPO_CY/backlog"    # per-entry tree (no monolith)
CY_MONO=$(mktemp "${TMPDIR:-/tmp}/tmf-cy-mono.XXXXXX")
FAKE_BIN_CY=$(mktemp -d "${TMPDIR:-/tmp}/tmf-fakebin-cy.XXXXXX")
GH_LOG_CY=$(mktemp "${TMPDIR:-/tmp}/tmf-ghlog-cy.XXXXXX")

# The BD-094/BD-095 mutual-block topology, renumbered: BD-701 and
# BD-702 mutually blocked, both sharing the non-cyclic blocker BD-703
# (mirrors BD-085/BD-088 in the live data).
cat > "$CY_MONO" <<'BACKLOG'
# BACKLOG

**BD-701 — Mutual-block half A (live BD-094 shape)**
Type: TODO(version)
Status: Open
Blockers: BD-703, BD-702
Unblocks: None
File/Symbol: scripts/foo.sh
Description: Mutually blocked with BD-702 — the live C-8 2-cycle.
Resolved: n/a

---

**BD-702 — Mutual-block half B (live BD-095 shape)**
Type: TODO(version)
Status: Open
Blockers: BD-703, BD-701
Unblocks: None
File/Symbol: scripts/bar.sh
Description: Mutually blocked with BD-701 — the live C-8 2-cycle.
Resolved: n/a

---

**BD-703 — Shared non-cyclic blocker (live BD-085/BD-088 shape)**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: scripts/baz.sh
Description: Upstream of both halves; not part of the cycle.
Resolved: n/a

---
BACKLOG
per_entry_decompose "pack-backlog" "$CY_MONO" "$TEST_REPO_CY/backlog" >/dev/null

cat > "$TEST_REPO_CY/IMPLEMENTATION-PLAN.md" <<'PLAN'
# IMPLEMENTATION PLAN
PLAN
cp "$FIXTURES/tracker.toml" "$TEST_REPO_CY/tracker.toml"

# Logging-only fake gh: every invocation is a provider-call witness.
# The pre-pass contract is that the log stays EMPTY.
cat > "$FAKE_BIN_CY/gh" <<FAKEGH_CY
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_CY"
case "\$1 \$2" in
    "search issues"|"issue list") echo '[]' ;;
    "issue view")    echo '{"labels":[], "assignees":[]}' ;;
    "repo view")     echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")   echo '{}' ;;
    "extension list") echo "" ;;
    *)               ;;
esac
exit 0
FAKEGH_CY
chmod +x "$FAKE_BIN_CY/gh"

export _TRACKER_PROVIDER_BACKEND_OVERRIDE="github"
PATH_SAVED_CY="$PATH"
export PATH="$FAKE_BIN_CY:$PATH_SAVED_CY"
output_cy=$(tracker_migrate_forward_run "$TEST_REPO_CY" 0 0 2>&1)
rc_cy=$?
output_cy_dry=$(tracker_migrate_forward_run "$TEST_REPO_CY" 1 0 2>&1)
rc_cy_dry=$?
export PATH="$PATH_SAVED_CY"
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE

# 8.1 the run fails loud (rc=1) with a typed validation error.
assert_eq "8.1 forward over 2-cycle fixture rc=1 (loud pre-call refusal)" "1" "$rc_cy"
assert_contains "8.1 loud refusal is a typed validation error" \
    "$output_cy" "ERROR: validation"
assert_contains "8.1 refusal names the Blockers data-cycle cause" \
    "$output_cy" "Blockers data contains dependency cycle"

# 8.2 the refusal names BOTH IDs and the FULL cycle path.
assert_contains "8.2 refusal names the cycle path (both IDs, closed loop)" \
    "$output_cy" "cycle path: BD-701 -> BD-702 -> BD-701"

# 8.3 ZERO provider calls — no create, no link mutation, nothing. The
# pre-pass runs before step 1, so the gh log must be byte-empty.
if [[ ! -s "$GH_LOG_CY" ]]; then
    t_pass "8.3 NO provider call before the refusal (gh log empty)"
else
    t_fail "8.3 NO provider call before the refusal (gh log empty)" \
        "gh log: $(head -3 "$GH_LOG_CY" | tr '\n' ' ')"
fi
# No mapping file / cycle store either (nothing mutated on disk).
[[ ! -f "$TEST_REPO_CY/.pack-tracker/id-map.json" ]] \
    && t_pass "8.3 no id-map written (run refused pre-mutation)" \
    || t_fail "8.3 no id-map written (run refused pre-mutation)"

# 8.4 --dry-run catches the same cycle (tree-level check before any
# live run) with the same loud message.
assert_eq "8.4 --dry-run over 2-cycle fixture rc=1" "1" "$rc_cy_dry"
assert_contains "8.4 --dry-run names the cycle path" \
    "$output_cy_dry" "cycle path: BD-701 -> BD-702 -> BD-701"

# 8.5 the legacy swallowed shape is GONE: the refusal must NOT surface
# as a bare step-7 partial-failure line (the pre-fix C-8 symptom).
if [[ "$output_cy" != *"step-7 link blocked-by"* ]]; then
    t_pass "8.5 refusal is NOT the swallowed step-7 partial-failure shape"
else
    t_fail "8.5 refusal is NOT the swallowed step-7 partial-failure shape" \
        "${output_cy:0:200}"
fi

rm -rf "$FAKE_BIN_CY" "$GH_LOG_CY" "$TEST_REPO_CY" "$CY_MONO"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
