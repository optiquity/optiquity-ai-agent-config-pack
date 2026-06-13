#!/usr/bin/env bash
# scripts/tests/test-tracker-promote-direct.sh — direct-close wrapper
# tests (BD-107; V3.3 §3.2). Verifies the wrapper emits the expected
# JSON shape and writes NO promotion labels and NO new entities.
#
# Coverage groups:
#   1. Direct-close wrapper happy path
#       1.1 emits outcome="direct-close"
#       1.2 promotion_labels = [] (V3.3 §3.2)
#       1.3 new_entity = null (V3.3 §3.2)
#       1.4 resolution_text uses today's UTC date
#       1.5 default note used when none supplied
#       1.6 explicit note honoured
#   2. Direct-close wrapper validation
#       2.1 invalid TD shape rejected
#       2.2 BD-NNN rejected (only TDs promote per V3.3 §3)
#   3. v10 lifecycle preservation (no labels, no entity, no sidecar)
#       3.1 wrapper does NOT call provider_create
#       3.2 wrapper does NOT call provider_set_labels
#       3.3 wrapper does NOT call provider_link
#       3.4 sidecar in repo unchanged after direct-close call
#   4. Verb dispatcher (pack-td.sh resolve)
#       4.1 dispatcher routes to tracker_promote_direct_close
#       4.2 --note flag forwarded
#   5. Path 3 forbidden invariants (corpus-wide grep)
#       5.1 no `tracker_labels_folded_into` constructor anywhere
#       5.2 no `--fold-into` arg in pack-td.sh
#       5.3 no `folded-into:` label written by direct-close JSON
#       5.4 dispatcher rejects `pack td promote --fold-into=...`
#
# Usage: bash scripts/tests/test-tracker-promote-direct.sh

set -u

# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
# code exercised under the clamp (never set it in a live run).
export PACK_TRACKER_DEFERRAL_OVERRIDE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-promote"
PROV_FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-provider"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq()       { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }
assert_contains() { if [[ "$2" == *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' missing"; fi; }
assert_not_contains() { if [[ "$2" != *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' unexpectedly present"; fi; }

# Source libs.
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-labels.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-cycle-check.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-links.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-mirror.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-phase-task.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-promote.sh"
# Stub backend for verifying NO provider calls happen.
# shellcheck disable=SC1091
source "$PROV_FIXTURES/stub-backend.sh"
# Override _stub_record to write side-channel file.
_stub_record() {
    STUB_CALLS="$STUB_CALLS|$*"
    if [[ -n "${STUB_LOG_FILE:-}" ]]; then
        printf '|%s\n' "$*" >> "$STUB_LOG_FILE"
    fi
}

SCRATCH=$(mktemp -d -t tprdc.XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT

# ─────────────────────────────────────────────────────────────────
# Group 1: direct-close wrapper happy path
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: direct-close wrapper happy path ===\n"

result=$(tracker_promote_direct_close "TD-031" 2>/dev/null)

# 1.1 outcome marker
assert_eq "1.1 outcome=direct-close"  "direct-close" "$(printf '%s' "$result" | jq -r '.outcome')"
assert_eq "1.1 td_id captured"        "TD-031"       "$(printf '%s' "$result" | jq -r '.td_id')"

# 1.2/1.3 V3.3 §3.2 invariants
prom_labels=$(printf '%s' "$result" | jq -c '.promotion_labels')
assert_eq "1.2 promotion_labels = []"  "[]"  "$prom_labels"

new_entity=$(printf '%s' "$result" | jq -r '.new_entity')
assert_eq "1.3 new_entity = null"  "null"  "$new_entity"

# 1.4 resolution_text dated today
today=$(date -u '+%Y-%m-%d')
res_text=$(printf '%s' "$result" | jq -r '.resolution_text')
assert_contains "1.4 resolution_text dated today (UTC)"  "$res_text"  "$today"
assert_contains "1.4 resolution_text labelled completed" "$res_text"  "completed"

# 1.5 default note
assert_contains "1.5 default note 'completed inline'" "$res_text" "completed inline"

# 1.6 explicit note honoured
result_note=$(tracker_promote_direct_close "TD-029" "fixed in batch 17" 2>/dev/null)
assert_contains "1.6 explicit note honoured" \
    "$(printf '%s' "$result_note" | jq -r '.resolution_text')" \
    "fixed in batch 17"
assert_eq "1.6 note field captured" "fixed in batch 17" \
    "$(printf '%s' "$result_note" | jq -r '.note')"

# Bonus: v10 lifecycle pointer text included
assert_contains "1.x v10 lifecycle pointer in JSON" \
    "$(printf '%s' "$result" | jq -r '.v10_lifecycle')" \
    "Procedure 4"

# ─────────────────────────────────────────────────────────────────
# Group 2: direct-close wrapper validation
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: direct-close wrapper validation ===\n"

if tracker_promote_direct_close "garbage" 2>/dev/null; then
    t_fail "2.1 invalid TD shape rejected" "expected rc=1; got rc=0"
else
    t_pass "2.1 invalid TD shape rejected"
fi

if tracker_promote_direct_close "BD-029" 2>/dev/null; then
    t_fail "2.2 BD-NNN rejected (only TDs promote)" "expected rc=1; got rc=0"
else
    t_pass "2.2 BD-NNN rejected (only TDs promote)"
fi

if tracker_promote_direct_close "" 2>/dev/null; then
    t_fail "2.x empty TD id rejected" "expected rc=1; got rc=0"
else
    t_pass "2.x empty TD id rejected"
fi

# ─────────────────────────────────────────────────────────────────
# Group 3: v10 lifecycle preservation (no labels, no entity)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: v10 lifecycle preservation (no labels, no entity) ===\n"

# Set up a minimal worktree with a sidecar file. After direct-close,
# the sidecar SHOULD be byte-identical (V3.3 §3.2: "no new entity, no
# promotion labels"). And no provider calls should fire.
wt="$SCRATCH/g3"
mkdir -p "$wt/.pack-tracker"
echo '{"original":"sidecar-content"}' > "$wt/.pack-tracker/sidecar.json"
cp "$FIXTURES/BACKLOG.md" "$wt/BACKLOG.md"
sidecar_sha_before=$(shasum -a 256 "$wt/.pack-tracker/sidecar.json" | cut -d' ' -f1)
backlog_sha_before=$(shasum -a 256 "$wt/BACKLOG.md" | cut -d' ' -f1)

export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
G3_STUB="$SCRATCH/g3-stub.log"
: > "$G3_STUB"
export STUB_LOG_FILE="$G3_STUB"
tracker_promote_direct_close "TD-031" "small fix inline" >/dev/null 2>&1
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE STUB_LOG_FILE

# 3.1/3.2/3.3 NO provider calls
if grep -qE '^\|create' "$G3_STUB"; then
    t_fail "3.1 wrapper does NOT call provider_create" \
        "found: $(grep -E '^\|create' "$G3_STUB" | head -1)"
else
    t_pass "3.1 wrapper does NOT call provider_create"
fi
if grep -qE '^\|set_labels' "$G3_STUB"; then
    t_fail "3.2 wrapper does NOT call provider_set_labels" \
        "found: $(grep -E '^\|set_labels' "$G3_STUB" | head -1)"
else
    t_pass "3.2 wrapper does NOT call provider_set_labels"
fi
if grep -qE '^\|link' "$G3_STUB"; then
    t_fail "3.3 wrapper does NOT call provider_link"
else
    t_pass "3.3 wrapper does NOT call provider_link"
fi
if grep -qE '^\|close' "$G3_STUB"; then
    t_fail "3.x wrapper does NOT call provider_close"
else
    t_pass "3.x wrapper does NOT call provider_close (delegated to v10 lifecycle)"
fi

# 3.4 sidecar + BACKLOG unchanged
sidecar_sha_after=$(shasum -a 256 "$wt/.pack-tracker/sidecar.json" | cut -d' ' -f1)
backlog_sha_after=$(shasum -a 256 "$wt/BACKLOG.md" | cut -d' ' -f1)
assert_eq "3.4 sidecar SHA-256 byte-identical after direct-close" \
    "$sidecar_sha_before" "$sidecar_sha_after"
assert_eq "3.4 BACKLOG SHA-256 byte-identical after direct-close" \
    "$backlog_sha_before" "$backlog_sha_after"

# ─────────────────────────────────────────────────────────────────
# Group 4: verb dispatcher (pack-td.sh resolve)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: verb dispatcher (pack-td.sh resolve) ===\n"

DISPATCHER="$REPO_ROOT/scripts/pack-td.sh"

out=$("$DISPATCHER" resolve TD-031 2>/dev/null)
assert_eq "4.1 dispatcher routes resolve → direct-close outcome" \
    "direct-close" "$(printf '%s' "$out" | jq -r '.outcome')"
assert_eq "4.1 dispatcher td_id"  "TD-031"  "$(printf '%s' "$out" | jq -r '.td_id')"

# 4.2 --note flag forwarded
out_note=$("$DISPATCHER" resolve TD-031 --note "completed in PR #42" 2>/dev/null)
assert_contains "4.2 --note flag forwarded" \
    "$(printf '%s' "$out_note" | jq -r '.resolution_text')" \
    "completed in PR #42"

# Also: dispatcher resolve --help works
help_out=$("$DISPATCHER" resolve --help 2>&1)
assert_contains "4.x resolve --help prints manifest" "$help_out" "Direct close"

# Resolve without TD id → typed error
err=$("$DISPATCHER" resolve 2>&1) || true
assert_contains "4.x resolve without TD id → typed error" "$err" "ERROR: validation"

# ─────────────────────────────────────────────────────────────────
# Group 5: Path 3 forbidden invariants
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: Path 3 forbidden invariants ===\n"

# 5.1 no tracker_labels_folded_into helper exists
if declare -f tracker_labels_folded_into >/dev/null 2>&1; then
    t_fail "5.1 NO folded-into helper" \
        "tracker_labels_folded_into is defined; V3.3 §3 line 27 forbids this"
else
    t_pass "5.1 NO folded-into helper (Path 3 forbidden per V3.3 §3 line 27)"
fi

# 5.2 no --fold-into arg in pack-td.sh source as a wired branch. The
# rejection stanza (case "--fold-into=*|--fold-into)" → tracker_error_emit
# + return 1) IS allowed and expected — it surfaces the typed error
# when a user invokes the forbidden Path 3 verb. We verify by
# inspecting the rejection-block contents (must call tracker_error_emit
# AND return non-zero). If the rejection block is intact, this is the
# correct invariant.
if grep -nE 'fold-into' "$REPO_ROOT/scripts/pack-td.sh" >/dev/null; then
    # Verify the rejection stanza contains tracker_error_emit naming
    # Path 3 forbidden. python-grep across the stanza body.
    rejection_count=$(python3 - <<'PYEOF'
import re
with open("/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/pack-td.sh") as f:
    src = f.read()
# Find the case branch handling --fold-into. The line opens with
# `--fold-into=*|--fold-into)` followed by the rejection body and `;;`.
# Search for the CASE-LABEL line specifically (must start with optional
# whitespace then `--fold-into=`).
m = re.search(
    r"^\s*--fold-into=\*\|--fold-into\)(.*?);;",
    src, re.DOTALL | re.MULTILINE,
)
if m and "tracker_error_emit" in m.group(1) and "Path 3 forbidden" in m.group(1):
    print("1")
else:
    print("0")
PYEOF
)
    if [[ "$rejection_count" == "1" ]]; then
        t_pass "5.2 --fold-into in pack-td.sh present only as typed-error rejection (not wired)"
    else
        t_fail "5.2 --fold-into appears as a wired branch in pack-td.sh"
    fi
else
    t_pass "5.2 NO --fold-into arg in pack-td.sh"
fi

# 5.3 direct-close JSON output has no folded-into anywhere
result=$(tracker_promote_direct_close "TD-031" 2>/dev/null)
assert_not_contains "5.3 direct-close JSON has no folded-into" "$result" "folded-into"

# 5.4 dispatcher rejects pack td promote --fold-into=...
err=$("$DISPATCHER" promote --fold-into=phase-3.2 TD-031 2>&1) || true
assert_contains "5.4 dispatcher rejects --fold-into" "$err" "ERROR: validation"
assert_contains "5.4 dispatcher names Path 3 forbidden" "$err" "Path 3 forbidden"

# 5.5 corpus-wide: no folded-into label written anywhere in the new
# orchestrator's source. Allowed: comments documenting the
# prohibition. Disallowed: function definitions or label literals
# (i.e. lines that would actually emit the label, not lines explaining
# it doesn't exist). We strip comment lines (anything beginning with
# whitespace + `#`) before the grep.
non_comment_hits=$(grep -nE 'folded-into:' \
    "$LIB_DIR/tracker-promote.sh" "$REPO_ROOT/scripts/pack-td.sh" \
    2>/dev/null \
    | grep -vE '(^|:)[0-9]+:[[:space:]]*#' \
    || true)
if [[ -z "$non_comment_hits" ]]; then
    t_pass "5.5 grep: no 'folded-into:' label literal in new code (comments OK)"
else
    t_fail "5.5 grep: no 'folded-into:' label literal in new code (comments OK)" \
        "$non_comment_hits"
fi

# 5.6 corpus-wide: no inline `(from TD-NNN)` body marker emitted by
# the formatter (the V3.2 Path 3 prose form). Comments referencing
# this prohibition are permitted; what's forbidden is an actual
# emitter that writes that text into a body. Strip comment lines.
non_comment_hits=$(grep -nE '\(from TD-' \
    "$LIB_DIR/tracker-promote.sh" 2>/dev/null \
    | grep -vE '(^|:)[0-9]+:[[:space:]]*#' \
    || true)
if [[ -z "$non_comment_hits" ]]; then
    t_pass "5.6 grep: no V3.2 '(from TD-NNN)' body marker (Path 3 prose form)"
else
    t_fail "5.6 grep: no V3.2 '(from TD-NNN)' body marker (Path 3 prose form)" \
        "$non_comment_hits"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
exit "$FAIL"
