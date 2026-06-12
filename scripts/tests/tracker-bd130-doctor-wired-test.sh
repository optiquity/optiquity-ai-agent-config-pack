#!/usr/bin/env bash
# scripts/tests/tracker-bd130-doctor-wired-test.sh — BD-130 wiring
# regression guard.
#
# BD-067 wired the `doctor` verb in scripts/pack-tracker.sh but did
# NOT source the lib that defines `tracker_doctor_run`. Empirically:
#
#     $ bash scripts/pack-tracker.sh doctor
#     scripts/pack-tracker.sh: line 165: tracker_doctor_run: \
#         command not found
#
# BD-130 fix: extracted the function body to
# scripts/lib/tracker-doctor.sh and added it to the source list of
# both scripts/pack-tracker.sh and scripts/tracker-migrate.sh.
#
# This test asserts:
#   1. `pack-tracker.sh doctor` against a scratch dir DOES NOT emit
#      "command not found".
#   2. `tracker-migrate.sh doctor` (legacy entry) ALSO does not.
#   3. The doctor output starts with the doctor-emitted banner
#      ("doctor: <repo>") rather than a shell error.
#   4. `scripts/lib/tracker-doctor.sh` exists and defines
#      `tracker_doctor_run` (so future refactors can't silently
#      remove the relocation).
#   5. The no-arg `pwd` fallback path works (Group 5 — N-4 close).
#   6. `--repo-root` rejects non-directory values via cmd_doctor's
#      validation block (Group 6 — N-5 close).
#   7. The defensive `declare -f` dependency probe (M-4 close)
#      catches the BD-130 failure mode under a future caller that
#      sources tracker-doctor.sh without first sourcing the
#      dependency libs (Group 7).
#
# Usage: bash scripts/tests/tracker-bd130-doctor-wired-test.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACK_TRACKER="$REPO_ROOT/scripts/pack-tracker.sh"
TRACKER_MIGRATE="$REPO_ROOT/scripts/tracker-migrate.sh"
DOCTOR_LIB="$REPO_ROOT/scripts/lib/tracker-doctor.sh"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  pass: %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  FAIL: %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "        %s\n" "$2"
}

assert_no_match() {
    local label="$1" needle="$2" haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        t_fail "$label" "unexpected substring '$needle' in output"
    else
        t_pass "$label"
    fi
}

assert_match() {
    local label="$1" needle="$2" haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        t_pass "$label"
    else
        t_fail "$label" "expected substring '$needle' missing from output"
    fi
}

# Scratch dir — empty, so doctor will emit warnings but should NOT
# emit "command not found" or any shell error before the banner.
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

echo "=== Group 1: scripts/lib/tracker-doctor.sh exists ==="
if [[ -f "$DOCTOR_LIB" ]]; then
    t_pass "1.1 lib file present at scripts/lib/tracker-doctor.sh"
else
    t_fail "1.1 lib file missing at $DOCTOR_LIB"
fi

if grep -q '^tracker_doctor_run()' "$DOCTOR_LIB" 2>/dev/null; then
    t_pass "1.2 lib defines tracker_doctor_run()"
else
    t_fail "1.2 lib does not define tracker_doctor_run()"
fi

echo "=== Group 2: pack-tracker.sh doctor wires the function ==="
out_pack=$(bash "$PACK_TRACKER" doctor --repo-root "$SCRATCH" 2>&1)
rc_pack=$?
assert_no_match "2.1 no 'command not found' in pack-tracker.sh doctor output" \
    "command not found" "$out_pack"
assert_match "2.2 pack-tracker.sh doctor emits 'doctor:' banner" \
    "doctor: $SCRATCH" "$out_pack"
# rc may be 0 or 1 depending on warnings; we only require that the
# doctor body executed (banner present, no shell error).

echo "=== Group 3: tracker-migrate.sh doctor wires the function ==="
out_migrate=$(bash "$TRACKER_MIGRATE" doctor --repo-root "$SCRATCH" 2>&1)
rc_migrate=$?
assert_no_match "3.1 no 'command not found' in tracker-migrate.sh doctor output" \
    "command not found" "$out_migrate"
assert_match "3.2 tracker-migrate.sh doctor emits 'doctor:' banner" \
    "doctor: $SCRATCH" "$out_migrate"

echo "=== Group 4: both dispatchers source tracker-doctor.sh ==="
if grep -q 'source "\$LIB_DIR/tracker-doctor.sh"' "$PACK_TRACKER"; then
    t_pass "4.1 pack-tracker.sh sources lib/tracker-doctor.sh"
else
    t_fail "4.1 pack-tracker.sh does NOT source lib/tracker-doctor.sh"
fi
if grep -q 'source "\$LIB_DIR/tracker-doctor.sh"' "$TRACKER_MIGRATE"; then
    t_pass "4.2 tracker-migrate.sh sources lib/tracker-doctor.sh"
else
    t_fail "4.2 tracker-migrate.sh does NOT source lib/tracker-doctor.sh"
fi

# ─────────────────────────────────────────────────────────────────
# Group 5: no-arg `pwd` fallback path (N-4 close)
# Exercises `[[ -z "$repo_root" ]] && repo_root="$(pwd)"` in both
# dispatchers' cmd_doctor; a refactor that lost the fallback would
# trip here instead of slipping past the wiring test.
# ─────────────────────────────────────────────────────────────────
echo "=== Group 5: no-arg pwd fallback ==="
out_pack_pwd=$(cd "$SCRATCH" && bash "$PACK_TRACKER" doctor 2>&1)
assert_no_match "5.1 no 'command not found' in no-arg pack-tracker.sh doctor" \
    "command not found" "$out_pack_pwd"
assert_match "5.2 no-arg pack-tracker.sh doctor banner names cwd" \
    "doctor: $SCRATCH" "$out_pack_pwd"

out_migrate_pwd=$(cd "$SCRATCH" && bash "$TRACKER_MIGRATE" doctor 2>&1)
assert_no_match "5.3 no 'command not found' in no-arg tracker-migrate.sh doctor" \
    "command not found" "$out_migrate_pwd"
assert_match "5.4 no-arg tracker-migrate.sh doctor banner names cwd" \
    "doctor: $SCRATCH" "$out_migrate_pwd"

# ─────────────────────────────────────────────────────────────────
# Group 6: --repo-root directory validation (N-5 close)
# Mirror cmd_update_templates' validation block; an invalid path
# should fail fast with the "validation" error class rather than
# falling through and producing nonsensical [WARN] lines.
# ─────────────────────────────────────────────────────────────────
echo "=== Group 6: --repo-root directory validation ==="
out_pack_bad=$(bash "$PACK_TRACKER" doctor --repo-root /does/not/exist 2>&1)
rc_pack_bad=$?
assert_match "6.1 pack-tracker.sh doctor rejects non-directory --repo-root" \
    "is not a directory" "$out_pack_bad"
if [[ "$rc_pack_bad" -ne 0 ]]; then
    t_pass "6.2 pack-tracker.sh doctor returns non-zero on invalid --repo-root"
else
    t_fail "6.2 pack-tracker.sh doctor returned 0 on invalid --repo-root"
fi

out_migrate_bad=$(bash "$TRACKER_MIGRATE" doctor --repo-root /does/not/exist 2>&1)
rc_migrate_bad=$?
assert_match "6.3 tracker-migrate.sh doctor rejects non-directory --repo-root" \
    "is not a directory" "$out_migrate_bad"
if [[ "$rc_migrate_bad" -ne 0 ]]; then
    t_pass "6.4 tracker-migrate.sh doctor returns non-zero on invalid --repo-root"
else
    t_fail "6.4 tracker-migrate.sh doctor returned 0 on invalid --repo-root"
fi

# ─────────────────────────────────────────────────────────────────
# Group 7: defensive dependency probe (M-4 close)
# Source tracker-doctor.sh in isolation (no tracker-config.sh,
# no tracker-provider*.sh) and verify the probe at the top of
# tracker_doctor_run produces a clear ERROR + MESSAGE pair and
# returns rc=2 — instead of the silent `command not found` failure
# that BD-130 was created to fix.
# ─────────────────────────────────────────────────────────────────
echo "=== Group 7: defensive dependency probe ==="
probe_out=$(bash -c "set +e; source '$DOCTOR_LIB'; tracker_doctor_run '$SCRATCH'; echo \"PROBE_RC=\$?\"" 2>&1)
assert_match "7.1 probe emits ERROR: tracker-doctor: missing dependency" \
    "ERROR: tracker-doctor: missing dependency:" "$probe_out"
assert_match "7.2 probe emits MESSAGE with calling-convention hint" \
    "source tracker-config.sh" "$probe_out"
assert_match "7.3 probe returns rc=2 (calling-convention failure)" \
    "PROBE_RC=2" "$probe_out"
assert_no_match "7.4 probe does NOT emit raw 'command not found'" \
    "command not found" "$probe_out"

# ─────────────────────────────────────────────────────────────────
# Group 8: pack-surface freshness reads the /backlog tree, NOT the
# deleted pack monolith (BD-204 C-6 / C7b REPOINT).
# The pack monolith pack-ops/BACKLOG.md is DELETED (BD-203 no-mirror
# SSOT). The doctor's pack-surface freshness check (d) must map to the
# /backlog per-entry tree's regen index (_toc.md) and must NEVER read
# pack-ops/BACKLOG.md. We source the lib + its deps directly and run
# tracker_doctor_run against a pack fixture that holds the tree AND a
# stale monolith sentinel; the doctor must report on the tree and must
# NOT surface the monolith.
# ─────────────────────────────────────────────────────────────────
echo "=== Group 8: pack-surface freshness reads /backlog tree (C-6) ==="
LIB_DIR="$REPO_ROOT/scripts/lib"
PACK_FIX="$(mktemp -d)"
trap 'rm -rf "$SCRATCH" "$PACK_FIX"' EXIT
# Pack surface marker.
touch "$PACK_FIX/PACK-CHAT.md"
# Per-entry tree + regen index (the SSOT).
mkdir -p "$PACK_FIX/backlog"
cat > "$PACK_FIX/backlog/BD-001.md" <<'EOF'
<!-- per-entry source: backlog/BD-001.md; contract: backlog/_rules.md -->
**BD-001 — Seed entry**
Status: Open
EOF
cat > "$PACK_FIX/backlog/_toc.md" <<'EOF'
# Backlog index
- BD-001 — Seed entry (Open)
EOF
# Stale monolith sentinel — must NEVER be read by the pack-surface
# freshness check.
mkdir -p "$PACK_FIX/pack-ops"
cat > "$PACK_FIX/pack-ops/BACKLOG.md" <<'EOF'
<!--
STALE PACK MONOLITH — must never be read by doctor (BD-203 deleted it).
-->
EOF

doctor8_out=$(bash -c '
  set +e
  LIB_DIR="'"$LIB_DIR"'"
  source "$LIB_DIR/tracker-errors.sh"
  source "$LIB_DIR/tracker-config.sh"
  source "$LIB_DIR/tracker-provider.sh"
  source "$LIB_DIR/tracker-provider-gh.sh"
  source "$LIB_DIR/template-version.sh" 2>/dev/null
  source "$LIB_DIR/template-translations.sh" 2>/dev/null
  source "$LIB_DIR/tracker-doctor.sh"
  tracker_doctor_run "'"$PACK_FIX"'"
' 2>&1)

assert_match "8.1 pack doctor reports the /backlog tree regen index" \
    "/backlog" "$doctor8_out"
assert_no_match "8.2 pack doctor does NOT report a BACKLOG.md mirror line" \
    "BACKLOG.md mirror" "$doctor8_out"
assert_no_match "8.3 pack doctor does NOT report a BACKLOG.md mirror header" \
    "BACKLOG.md has read-only mirror header" "$doctor8_out"
assert_no_match "8.4 pack doctor emits no 'command not found'" \
    "command not found" "$doctor8_out"

# ─────────────────────────────────────────────────────────────────
# Group 9: BD-204 Mode-3 ops contract §4.1 — leg (d) freshness-key
# repoint + leg (h) status-coherence advisory (PLAN §5 leg 7).
# All offline: a fake gh on PATH serves the pack-owned issue list;
# the divergent issue's blob is encoded with the PRODUCTION
# `_tmf_gz64_encode` codec (no codec reproduction).
# ─────────────────────────────────────────────────────────────────
echo "=== Group 9: BD-204 doctor leg (d) repoint + leg (h) coherence ==="

DR9="$(mktemp -d)"
FAKE9="$(mktemp -d)"
trap 'rm -rf "$SCRATCH" "$PACK_FIX" "$DR9" "$FAKE9"' EXIT
mkdir -p "$DR9/pack-ops" "$DR9/backlog" "$DR9/.pack-tracker"
cat > "$DR9/backlog/_toc.md" <<'EOF'
# Backlog index
- BD-001 — Seed entry (Open)
EOF
printf '{ "BD-001": {"id": "42", "url": "http://x/42"} }\n' > "$DR9/.pack-tracker/id-map.json"

# tracker.toml writer: $1 = extra [migration] key lines (may be empty).
_dr9_write_cfg() {
    cat > "$DR9/tracker.toml" <<EOF
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
$1
EOF
}

# Divergent fixture issue: labels/state project Open; the blob's
# Status: line says Resolved. Blob via the production encoder.
DR9_RAW=$'**BD-001 — Seed entry**\nType: TODO(version)\nStatus: Resolved\nDescription: Divergent fixture.\n'
DR9_BLOB=$(DR9_RAW="$DR9_RAW" bash -c '
  set +e
  source "'"$LIB_DIR"'/tracker-errors.sh"
  source "'"$LIB_DIR"'/tracker-config.sh"
  source "'"$LIB_DIR"'/tracker-provider.sh"
  source "'"$LIB_DIR"'/tracker-provider-gh.sh"
  source "'"$LIB_DIR"'/tracker-migrate-forward.sh"
  printf "%s" "$DR9_RAW" | _tmf_gz64_encode
')
cat > "$FAKE9/gh" <<'FG9'
#!/usr/bin/env bash
# Args log for leg 9.4b (full-coverage --limit assertion); ${0%/*}
# resolves to this stub's own FAKE9 dir.
echo "GH9: $*" >> "${0%/*}/calls.log"
case "$1 $2" in
    "issue list")
        echo '[{"number":42,"title":"BD-001: Seed entry","body":"<!-- pack-id: BD-001 -->\n<!-- pack-entry-body-gz64: @@DR9_BLOB@@ -->\n\n## Description\n\nDivergent fixture.","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:open"}],"assignees":[],"milestone":null,"url":"http://x/42"}]'
        ;;
    "repo view") echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    *) ;;
esac
exit 0
FG9
sed -i.bak "s|@@DR9_BLOB@@|$DR9_BLOB|" "$FAKE9/gh"
rm -f "$FAKE9/gh.bak"
chmod +x "$FAKE9/gh"
PATH_SAVED9="$PATH"

# 9.1 absent-keys tolerance: neither freshness key set → INFO, not WARN.
_dr9_write_cfg ""
export PATH="$FAKE9:$PATH_SAVED9"
out91=$(bash "$TRACKER_MIGRATE" doctor --repo-root "$DR9" 2>&1)
export PATH="$PATH_SAVED9"
assert_match "9.1 absent freshness keys → INFO (tolerated)" \
    "[INFO] tree-freshness keys absent" "$out91"
assert_no_match "9.1 absent freshness keys → no stale-tree WARN" \
    "tree is stale relative to tracker writes" "$out91"

# 9.2 stale tree: last_tracker_write > last_tree_regen → WARN naming
# the recovery verb.
_dr9_write_cfg 'last_tracker_write = "2026-06-12T10:00:00Z"
last_tree_regen = "2026-06-12T09:00:00Z"'
export PATH="$FAKE9:$PATH_SAVED9"
out92=$(bash "$TRACKER_MIGRATE" doctor --repo-root "$DR9" 2>&1)
rc92=$?
export PATH="$PATH_SAVED9"
assert_match "9.2 stale tree → WARN" \
    "[WARN] tree is stale relative to tracker writes" "$out92"
assert_match "9.2 stale-tree WARN names the recovery verb" \
    "→ Run: pack tracker tree-rebuild" "$out92"
if [[ "$rc92" -ne 0 ]]; then
    t_pass "9.2 doctor rc=1 on stale-tree WARN"
else
    t_fail "9.2 doctor rc=1 on stale-tree WARN" "rc=0"
fi

# 9.3 fresh tree: last_tree_regen >= last_tracker_write → OK.
_dr9_write_cfg 'last_tracker_write = "2026-06-12T09:00:00Z"
last_tree_regen = "2026-06-12T10:00:00Z"'
export PATH="$FAKE9:$PATH_SAVED9"
out93=$(bash "$TRACKER_MIGRATE" doctor --repo-root "$DR9" 2>&1)
export PATH="$PATH_SAVED9"
assert_match "9.3 fresh tree → OK regen-current line" \
    "/backlog tree regen is current" "$out93"
assert_no_match "9.3 fresh tree → no stale-tree WARN" \
    "tree is stale relative to tracker writes" "$out93"

# 9.4 leg (h): the mocked divergent issue (projection Open vs blob
# Status: Resolved) → status-coherence WARN naming the recovery verb.
# (Same cfg as 9.3 — coherence is independent of the freshness keys.)
assert_match "9.4 status-coherence WARN fires on the divergent issue" \
    "[WARN] status-coherence: BD-001" "$out93"
assert_match "9.4 coherence WARN names blob-truth values" \
    "'Open' != blob Status: 'Resolved'" "$out93"
assert_match "9.4 coherence WARN names the recovery verb" \
    "→ Run: pack tracker edit --status Resolved" "$out93"

# 9.4b SHOULD-1 (PACK-REVIEW-MODE3-OPS-COMMIT2): the leg-(h) read is
# FULL-COVERAGE — the doctor must request the 1000-item default limit
# (the old fixed `100` cap silently covered ~47% of the 213 live pack
# entries). Asserted against the fake-gh args log from the 9.3/9.4 run.
assert_match "9.4b leg (h) provider_list requests the full-coverage limit (--limit 1000)" \
    "--limit 1000 --label bd-entry --state all" \
    "$(cat "$FAKE9/calls.log" 2>/dev/null)"

# 9.4c SHOULD-1 saturation guard: a read that returns exactly the
# requested limit may have truncated → loud WARN (rc=1), never a
# silent sample. Force saturation deterministically by shrinking the
# limit to 1 via the TRACKER_DOCTOR_COH_LIMIT env seam — the fake gh
# returns exactly 1 issue, so items returned == limit.
export PATH="$FAKE9:$PATH_SAVED9"
out94c=$(TRACKER_DOCTOR_COH_LIMIT=1 bash "$TRACKER_MIGRATE" doctor --repo-root "$DR9" 2>&1)
rc94c=$?
export PATH="$PATH_SAVED9"
assert_match "9.4c saturated read → loud truncation WARN" \
    "[WARN] status-coherence: provider_list read SATURATED at the 1-item limit" "$out94c"
assert_match "9.4c saturation WARN names the recovery seam" \
    "TRACKER_DOCTOR_COH_LIMIT" "$out94c"
if [[ "$rc94c" -ne 0 ]]; then
    t_pass "9.4c doctor rc=1 on saturation WARN"
else
    t_fail "9.4c doctor rc=1 on saturation WARN" "rc=0"
fi

# 9.5 leg (h) INFO-skip in flat-file mode (GH Issues ignored).
python3 - "$DR9/tracker.toml" <<'PYEOF'
import sys
p = sys.argv[1]
text = open(p).read().replace('state = "tracker"', 'state = "flat-file"')
open(p, "w").write(text)
PYEOF
export PATH="$FAKE9:$PATH_SAVED9"
out95=$(bash "$TRACKER_MIGRATE" doctor --repo-root "$DR9" 2>&1)
export PATH="$PATH_SAVED9"
assert_match "9.5 flat-file mode → coherence advisory INFO-skipped" \
    "[INFO] status-coherence advisory skipped (flat-file mode" "$out95"
assert_no_match "9.5 flat-file mode → no coherence WARN" \
    "[WARN] status-coherence" "$out95"

echo
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
