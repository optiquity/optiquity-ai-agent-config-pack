#!/usr/bin/env bash
# scripts/tests/test-migrate-v10-to-v11-gates.sh — BD-101 verification-gate
# tests for `scripts/migrate-v10-to-v11.sh`.
#
# Verifies the three new in-script gates introduced by BD-101:
#
#   Gate 1 — pre-migration dry-run summary (read-only)
#     1.1 PASS: clean dry-run; gate exits 0 with summary
#     1.2 FAIL: dispositions.tsv injected with unknown-classification
#     1.3 FAIL: state-dir contents corrupted (no report.md)
#
#   Gate 2 — post-Phase-A verification
#     2.1 PASS: post-apply; trinity addenda + help-fragments + relocations
#         + dispositions consistent
#     2.2 FAIL: trinity addenda missing (CLAUDE H2 marker stripped)
#     2.3 FAIL: HELP-FRAGMENT mismatched vs pack mirror
#     2.4 FAIL: relocated doc straggler at project root
#
#   Gate 3 — post-Phase-B verification (conditional on tracker mode)
#     3.1 SKIP: flat-file mode; gate exits 0 with `[INFO] skipped`
#     3.2 FAIL: tracker mode active, mapping malformed
#     3.3 PASS: tracker mode active, mapping + mirror green (doctor INFO)
#
#   Gate exit codes
#     4.1 Gate failure exit code 31 (EXIT_GATE_FAILED) is distinguishable
#         from stage failure exit codes (20..30)
#     4.2 Stage cap (30) is disjoint from gate code (31)
#     4.3 End-to-end --apply propagates rc=31 when Gate 2 fails (verified
#         via planted HELP-FRAGMENT.md drift in v10 fixture)
#
# These tests directly source the gate libs and helpers rather than
# round-tripping through the full migrator for every case — the BD-095
# dry-run suite + the BD-085 main migrate suite already cover the
# end-to-end orchestration; this suite focuses on per-gate semantics.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATE_SH="$REPO_ROOT/scripts/migrate-v10-to-v11.sh"
LIB_DIR="$REPO_ROOT/scripts/lib/migrate-v10-to-v11"

PASSED=0
FAILED=0
t_pass() { echo -e "  \033[32mPASS\033[0m $1"; PASSED=$((PASSED + 1)); }
t_fail() { echo -e "  \033[31mFAIL\033[0m $1${2:+ — $2}"; FAILED=$((FAILED + 1)); }
assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' got='$3'"; fi
}
assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "expected to contain '$3'"; fi
}
assert_not_contains() {
    if [[ "$2" != *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "expected NOT to contain '$3'"; fi
}

# Source the framework + gate libs into THIS shell so we can call them
# directly with synthetic fixtures (Group 1/2/3 unit-test style).
# `say`/`info`/etc come from migrator-core.sh; gate libs need them.
export MIGRATOR_FROM_VERSION="v10"
export MIGRATOR_TO_VERSION="v11"
export MIGRATOR_BASELINE_TAG="v10"
export MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update")

# Required hook stubs so migrator-core's contract check is satisfied
# when sourced (we do not call `migrator_run`, but the file declares
# `set -euo pipefail` only inside `migrator_run` — fine).
migrator_manifest() { :; }
migrator_directory_sweeps() { :; }
migrator_relocations() { :; }
migrator_artifact_installs() { :; }
migrator_post_report_hook() { :; }

# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib/migrator-core.sh"
# shellcheck source=/dev/null
. "$LIB_DIR/checkpoint.sh"
# shellcheck source=/dev/null
. "$LIB_DIR/gate-1-dry-run-summary.sh"
# shellcheck source=/dev/null
. "$LIB_DIR/gate-2-phase-a-verify.sh"
# shellcheck source=/dev/null
. "$LIB_DIR/gate-3-phase-b-verify.sh"

# Shared fixture builder — minimal v10-shaped target identical to the
# BD-095 dry-run test fixture.
make_v10_target() {
    local d
    d=$(mktemp -d -t migrate10-bd101.XXXXXX)
    git init -q "$d" >/dev/null
    git -C "$d" config user.email "test@example.com"
    git -C "$d" config user.name  "Test"
    mkdir -p "$d/.claude" "$d/docs/pack" "$d/.codex" "$d/.gemini"
    git -C "$REPO_ROOT" show v10:project-template/CLAUDE.md > "$d/CLAUDE.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/AGENTS.md > "$d/AGENTS.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/GEMINI.md > "$d/GEMINI.md" 2>/dev/null
    git -C "$d" add -A >/dev/null
    git -C "$d" commit -q -m "v10 initial state" 2>/dev/null
    printf '%s\n' "$d"
}

# Build a synthetic state-dir with a minimal valid dispositions.tsv +
# report.md so Gate 1 has something to inspect without driving the
# whole migrator.
make_state_dir() {
    local d
    d=$(mktemp -d -t gate1-state.XXXXXX)
    cat > "$d/dispositions.tsv" <<'EOF'
unchanged-pack	trinity	CLAUDE.md	none	-	-	-
pack-update-applied	trinity	AGENTS.md	copied	-	-	-
merged-with-customization	trinity	GEMINI.md	preserved	-	-	kept project edits
EOF
    cat > "$d/report.md" <<'EOF'
# Migration report
test fixture
EOF
    printf '%s\n' "$d"
}

# ─────────────────────────────────────────────────────────────────────────
# Group 1 — Gate 1 (pre-migration dry-run summary)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Gate 1 (pre-migration dry-run summary) ===\n"

# 1.1 PASS: clean dispositions + report present.
SD=$(make_state_dir)
out=$(migrate_v10_to_v11_gate1_run "$SD" 2>&1) ; rc=$?
assert_eq "1.1 Gate 1 PASS rc=0" "0" "$rc"
assert_contains "1.1 Gate 1 PASS banner" "$out" "Gate 1 PASS"
assert_contains "1.1 Gate 1 OK dispositions" "$out" "[OK]   dispositions"
rm -rf "$SD"

# 1.2 FAIL: inject an unknown-classification row.
SD=$(make_state_dir)
printf 'unknown-classification\tgeneric\tweird.md\tnone\t-\t-\t-\n' >> "$SD/dispositions.tsv"
out=$(migrate_v10_to_v11_gate1_run "$SD" 2>&1) ; rc=$?
assert_eq "1.2 Gate 1 FAIL rc=31" "31" "$rc"
assert_contains "1.2 Gate 1 names unknown-classification" "$out" "unknown-classification"
assert_contains "1.2 Gate 1 FAIL banner" "$out" "Gate 1 FAIL"
rm -rf "$SD"

# 1.3 FAIL: missing report.md.
SD=$(make_state_dir)
rm -f "$SD/report.md"
out=$(migrate_v10_to_v11_gate1_run "$SD" 2>&1) ; rc=$?
assert_eq "1.3 Gate 1 FAIL rc=31 (no report)" "31" "$rc"
assert_contains "1.3 Gate 1 names report.md" "$out" "report.md not rendered"
rm -rf "$SD"

# 1.4 PASS with conflicts INFO line (conflicts are not a Gate 1 fail —
# they are the whole point of the two-phase pause-and-resume workflow).
SD=$(make_state_dir)
printf 'customization-detected-needs-reconciliation\ttrinity\tCLAUDE.md\tsidecar\tCLAUDE.md.v10-customized\t-\tnotes\n' \
    >> "$SD/dispositions.tsv"
out=$(migrate_v10_to_v11_gate1_run "$SD" 2>&1) ; rc=$?
assert_eq "1.4 Gate 1 PASS with conflicts rc=0" "0" "$rc"
assert_contains "1.4 Gate 1 reports conflict count" "$out" "1 file(s) will need reconciliation"
rm -rf "$SD"

# 1.5 (BD-101 retro fix MINOR-1) Row count excludes the `# disposition...`
# header line. `make_state_dir` writes 3 data rows (no header at top) —
# the [OK] line should report `3 row(s)`, not `4 row(s)`.
SD=$(make_state_dir)
# Prepend the `# disposition` header so the TSV resembles what
# customization_preserve_init writes.
{ printf '# disposition\tclass\trel_path\taction\tsidecar\tdiff\tnotes\n'; cat "$SD/dispositions.tsv"; } > "$SD/dispositions.tsv.new"
mv "$SD/dispositions.tsv.new" "$SD/dispositions.tsv"
out=$(migrate_v10_to_v11_gate1_run "$SD" 2>&1) ; rc=$?
assert_eq "1.5 Gate 1 PASS with header+3 data rows rc=0" "0" "$rc"
assert_contains "1.5 Gate 1 reports 3 row(s) (header excluded)" "$out" "3 row(s), no unknown-classification"
assert_not_contains "1.5 Gate 1 NOT 4 row(s) (would mean header counted)" "$out" "4 row(s), no unknown-classification"
rm -rf "$SD"

# 1.6 (BD-101 retro fix MINOR-1) Header-only TSV reports 0 row(s), not 1.
SD=$(make_state_dir)
printf '# disposition\tclass\trel_path\taction\tsidecar\tdiff\tnotes\n' > "$SD/dispositions.tsv"
out=$(migrate_v10_to_v11_gate1_run "$SD" 2>&1) ; rc=$?
assert_eq "1.6 Gate 1 PASS header-only TSV rc=0" "0" "$rc"
assert_contains "1.6 Gate 1 reports 0 row(s) for header-only TSV" "$out" "0 row(s), no unknown-classification"
rm -rf "$SD"

# 1.7 (BD-101 retro fix MINOR-2) Dispositions check is SKIPPED in resume
# mode. We simulate resume by setting _MIGRATOR_MODE=resume and verify
# the gate's [INFO] dispositions: skipped line appears (and the row
# count message does NOT appear).
SD=$(make_state_dir)
saved_mode="${_MIGRATOR_MODE:-}"
_MIGRATOR_MODE="resume"
out=$(migrate_v10_to_v11_gate1_run "$SD" 2>&1) ; rc=$?
_MIGRATOR_MODE="$saved_mode"
assert_eq "1.7 Gate 1 PASS in resume mode rc=0" "0" "$rc"
assert_contains "1.7 Gate 1 dispositions: skipped (resume mode)" "$out" "[INFO] dispositions: skipped"
assert_not_contains "1.7 Gate 1 no [OK] dispositions in resume" "$out" "[OK]   dispositions:"
rm -rf "$SD"

# ─────────────────────────────────────────────────────────────────────────
# Group 2 — Gate 2 (post-Phase-A verification)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Gate 2 (post-Phase-A verification) ===\n"

# 2.1 PASS: full successful --apply produces a tree that satisfies all
#     Gate 2 checks. We DO NOT re-invoke the migrator (apply.sh wraps
#     the gate into post_report_hook which would `exit` on FAIL); we
#     drive the migrator end-to-end via PACK + --dry-run + --apply,
#     then call the gate directly to inspect its output.
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/tmp/bd101-apply.log 2>&1 ; apply_rc=$?
assert_eq "2.0 setup --apply rc=0" "0" "$apply_rc"

SD="$T/.pack-migrate-v10-to-v11"
out=$(PACK="$REPO_ROOT" \
    migrate_v10_to_v11_gate2_run "$T" "$SD" "$REPO_ROOT" 2>&1) ; rc=$?
assert_eq "2.1 Gate 2 PASS rc=0" "0" "$rc"
assert_contains "2.1 Gate 2 OK trinity"        "$out" "[OK]   trinity"
assert_contains "2.1 Gate 2 OK help-fragments" "$out" "[OK]   help-fragments"
assert_contains "2.1 Gate 2 OK relocations"    "$out" "[OK]   relocations"
assert_contains "2.1 Gate 2 OK dispositions"   "$out" "[OK]   dispositions"
assert_contains "2.1 Gate 2 OK validate-pack"  "$out" "[OK]   validate-pack"
assert_contains "2.1 Gate 2 PASS banner"       "$out" "Gate 2 PASS"
rm -rf "$T"

# 2.2 FAIL: trinity addenda stripped.
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/dev/null 2>&1
SD="$T/.pack-migrate-v10-to-v11"
# Strip the addenda H2 from CLAUDE.md.
grep -v -E '^## (Project memory|Project addenda)' "$T/CLAUDE.md" > "$T/CLAUDE.md.tmp"
mv "$T/CLAUDE.md.tmp" "$T/CLAUDE.md"
out=$(PACK="$REPO_ROOT" \
    migrate_v10_to_v11_gate2_run "$T" "$SD" "$REPO_ROOT" 2>&1) ; rc=$?
assert_eq "2.2 Gate 2 FAIL trinity rc=31" "31" "$rc"
assert_contains "2.2 Gate 2 names trinity" "$out" "[FAIL] trinity"
rm -rf "$T"

# 2.3 FAIL: HELP-FRAGMENT mismatched vs pack mirror.
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/dev/null 2>&1
SD="$T/.pack-migrate-v10-to-v11"
echo "## drift" >> "$T/docs/pack/HELP-FRAGMENT.md"
out=$(PACK="$REPO_ROOT" \
    migrate_v10_to_v11_gate2_run "$T" "$SD" "$REPO_ROOT" 2>&1) ; rc=$?
assert_eq "2.3 Gate 2 FAIL help-fragment rc=31" "31" "$rc"
assert_contains "2.3 Gate 2 names help-fragments" "$out" "[FAIL] help-fragments"
assert_contains "2.3 Gate 2 names HELP-FRAGMENT" "$out" "HELP-FRAGMENT.md differs"
rm -rf "$T"

# 2.4 FAIL: relocated-doc straggler at project root.
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/dev/null 2>&1
SD="$T/.pack-migrate-v10-to-v11"
# Plant a legacy METHODOLOGY.md back at the root.
echo "# stale methodology" > "$T/METHODOLOGY.md"
out=$(PACK="$REPO_ROOT" \
    migrate_v10_to_v11_gate2_run "$T" "$SD" "$REPO_ROOT" 2>&1) ; rc=$?
assert_eq "2.4 Gate 2 FAIL relocations rc=31" "31" "$rc"
assert_contains "2.4 Gate 2 names relocations" "$out" "[FAIL] relocations"
assert_contains "2.4 Gate 2 names METHODOLOGY" "$out" "METHODOLOGY.md still at project root"
rm -rf "$T"

# 2.5 (BD-101 retro fix MINOR-3) FAIL: orphan *.v10-customized sidecar
# at project root. After a successful --apply, plant a sidecar that
# escaped the resume.sh precondition list and verify Gate 2 catches it.
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/dev/null 2>&1
SD="$T/.pack-migrate-v10-to-v11"
# Plant an orphan sidecar that the gate's new check should observe.
echo "# orphan sidecar content" > "$T/orphan-doc.v10-customized"
out=$(PACK="$REPO_ROOT" \
    migrate_v10_to_v11_gate2_run "$T" "$SD" "$REPO_ROOT" 2>&1) ; rc=$?
assert_eq "2.5 Gate 2 FAIL orphan-sidecar rc=31" "31" "$rc"
assert_contains "2.5 Gate 2 names sidecars FAIL" "$out" "[FAIL] sidecars"
assert_contains "2.5 Gate 2 names the orphan file" "$out" "orphan-doc.v10-customized"
rm -rf "$T"

# 2.6 (BD-101 retro fix MINOR-3) PASS: clean tree (no orphan sidecars)
# satisfies the new check.
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/dev/null 2>&1
SD="$T/.pack-migrate-v10-to-v11"
out=$(PACK="$REPO_ROOT" \
    migrate_v10_to_v11_gate2_run "$T" "$SD" "$REPO_ROOT" 2>&1) ; rc=$?
assert_eq "2.6 Gate 2 PASS no-orphan-sidecars rc=0" "0" "$rc"
assert_contains "2.6 Gate 2 OK sidecars (no orphans)" "$out" "[OK]   sidecars: no orphan"
rm -rf "$T"

# 2.7 (BD-101 retro fix MAJOR-1) Gate 2 FAIL recovery banner uses the
# corrected v10→v11 rsync recipe rather than the broken
# `restore-from-backup.sh` reference. Force a Gate 2 failure (planted
# trinity strip), capture banner, assert content.
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/dev/null 2>&1
SD="$T/.pack-migrate-v10-to-v11"
grep -v -E '^## (Project memory|Project addenda)' "$T/CLAUDE.md" > "$T/CLAUDE.md.tmp"
mv "$T/CLAUDE.md.tmp" "$T/CLAUDE.md"
out=$(PACK="$REPO_ROOT" \
    migrate_v10_to_v11_gate2_run "$T" "$SD" "$REPO_ROOT" 2>&1) ; rc=$?
assert_eq "2.7 Gate 2 FAIL banner exit rc=31" "31" "$rc"
# Banner SHOULD reference the rsync-based recovery + the v10→v11 backup dir.
assert_contains "2.7 Gate 2 banner mentions rsync recipe" "$out" "rsync -a --delete"
assert_contains "2.7 Gate 2 banner names v10→v11 backup dir" "$out" ".pack-migrate-v10-to-v11-backup/"
assert_contains "2.7 Gate 2 banner notes legacy script does not apply" "$out" "LEGACY"
# Banner SHOULD NOT invoke restore-from-backup.sh as the recovery command.
# (It MAY mention the script by name in a "do not use this — it is for
# v9.3→v10" disclaimer, so we use a tighter check looking for the
# bare invocation pattern.)
assert_not_contains "2.7 Gate 2 banner does NOT invoke restore-from-backup.sh" "$out" "bash \$PACK/scripts/restore-from-backup.sh"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 3 — Gate 3 (post-Phase-B verification, conditional)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 3: Gate 3 (post-Phase-B verification) ===\n"

# 3.1 SKIP: flat-file mode (no tracker.toml).
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/dev/null 2>&1
out=$(PACK="$REPO_ROOT" \
    migrate_v10_to_v11_gate3_run "$T" "$REPO_ROOT" 2>&1) ; rc=$?
assert_eq "3.1 Gate 3 SKIP rc=0 (flat-file mode)" "0" "$rc"
assert_contains "3.1 Gate 3 says skipped"     "$out" "[INFO] tracker: skipped"
assert_contains "3.1 Gate 3 SKIP banner"      "$out" "Gate 3 SKIP"
assert_not_contains "3.1 Gate 3 no doctor"    "$out" "[OK]   doctor"
rm -rf "$T"

# 3.2 FAIL: synthesize tracker mode + malformed mapping.
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/dev/null 2>&1
# Plant a tracker.toml that signals tracker mode active. Use the
# minimal grep-fallback shape so checkpoint_tracker_mode_active
# accepts it even when tracker-config.sh would refuse to parse.
cat > "$T/tracker.toml" <<'EOF'
schema_version = "1"
[mode]
state = "tracker"
[backend]
name = "github"
repo = "test/test"
[id_namespace]
prefix = "BD"
[migration]
mapping_file = ".pack-tracker/id-map.json"
forward_complete = true
last_forward_run = "2024-01-01T00:00:00Z"
EOF
mkdir -p "$T/.pack-tracker"
# Malformed JSON.
echo '{not valid json' > "$T/.pack-tracker/id-map.json"
out=$(PACK="$REPO_ROOT" \
    migrate_v10_to_v11_gate3_run "$T" "$REPO_ROOT" 2>&1) ; rc=$?
assert_eq "3.2 Gate 3 FAIL mapping rc=31" "31" "$rc"
assert_contains "3.2 Gate 3 names mapping" "$out" "[FAIL] mapping"
rm -rf "$T"

# 3.3 PASS path: tracker mode active, mapping good. The doctor check
#     may fail in CI without `gh` installed, so we accept either PASS
#     (rc=0) or a controlled FAIL whose only failure is the doctor
#     line. Test asserts mapping + mirror checks pass regardless.
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/dev/null 2>&1
cat > "$T/tracker.toml" <<'EOF'
schema_version = "1"
[mode]
state = "tracker"
[backend]
name = "github"
repo = "test/test"
[id_namespace]
prefix = "BD"
[migration]
mapping_file = ".pack-tracker/id-map.json"
forward_complete = true
last_forward_run = "2020-01-01T00:00:00Z"
EOF
mkdir -p "$T/.pack-tracker"
echo '{"BD-001": 1, "BD-002": 2}' > "$T/.pack-tracker/id-map.json"
# Add the BACKLOG mirror header so the freshness check has something
# to validate.
{
    echo '<!--'
    echo 'mirror header'
    echo '-->'
    echo '# BACKLOG'
} > "$T/BACKLOG.md"
# Make the BACKLOG mtime newer than last_forward_run.
touch "$T/BACKLOG.md"

out=$(PACK="$REPO_ROOT" \
    migrate_v10_to_v11_gate3_run "$T" "$REPO_ROOT" 2>&1) ; rc=$?
# Mapping + mirror MUST pass. Doctor may pass or fail depending on
# environment (`gh` present, etc.).
assert_contains "3.3 Gate 3 OK mapping" "$out" "[OK]   mapping"
assert_contains "3.3 Gate 3 OK mirror"  "$out" "[OK]   mirror"
# Either PASS or doctor-only FAIL is acceptable.
if (( rc == 0 )); then
    t_pass "3.3 Gate 3 PASS rc=0 (doctor green)"
else
    if [[ "$out" == *"[FAIL] doctor"* ]]; then
        t_pass "3.3 Gate 3 doctor-only FAIL accepted (env-dependent)"
    else
        t_fail "3.3 Gate 3 unexpected FAIL: rc=$rc, output above"
    fi
fi
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 4 — Gate exit-code distinguishability
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 4: Gate exit codes are distinguishable from stage codes ===\n"

# 4.1 EXIT_GATE_FAILED is 31 (above the 20..30 stage range cap).
assert_eq "4.1 EXIT_GATE_FAILED constant" "31" "$EXIT_GATE_FAILED"

# 4.2 Stage failure exit codes (20..30 by formula) do not collide with 31.
#     migrator-core.sh fail_stage caps at 30; 31 is the first free slot.
assert_eq "4.2 stage cap is 30, gate is 31 — disjoint" "ok" \
    "$(if (( EXIT_GATE_FAILED > 30 )); then echo ok; else echo collision; fi)"

# 4.3 End-to-end: --apply that fails Gate 2 surfaces rc=31 (verified by
#     forcing a Gate 2 failure mid-apply). We do this by planting a
#     custom HELP-FRAGMENT.md inside the v10 fixture BEFORE --dry-run.
#     S5's artifact-install honors the `! -f` guard and keeps our custom
#     copy; Gate 2's help-fragments check then observes the byte-mismatch
#     against the pack mirror and FAILs, propagating EXIT_GATE_FAILED=31
#     through the apply.sh post_report_hook wrapper.
#
#     Why HELP-FRAGMENT.md (not trinity)? The v10 customization-surface
#     fingerprint covers trinity but NOT docs/pack/HELP-FRAGMENT.md, so
#     planting the file does not invalidate the dry-run fingerprint
#     (--apply's freshness check still passes). This gives us a clean
#     end-to-end path through dispatch + S5 + S6 + Gate 2 without
#     mid-flight hook injection.
T=$(make_v10_target)
mkdir -p "$T/docs/pack"
printf '# CUSTOM HELP FRAGMENT — DRIFT FOR GATE 2 TEST\n' \
    > "$T/docs/pack/HELP-FRAGMENT.md"
git -C "$T" add -A >/dev/null
git -C "$T" commit -q -m "plant drifted HELP-FRAGMENT.md" 2>/dev/null
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
# Now run --apply. S5 keeps our custom HELP-FRAGMENT. Gate 2 fires from
# inside post_report_hook, observes the help-fragment byte-mismatch,
# and apply.sh exits with EXIT_GATE_FAILED.
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" 2>&1) ; rc=$?
assert_eq "4.3 --apply exit code on Gate 2 FAIL" "31" "$rc"
assert_contains "4.3 output names Gate 2"           "$out" "Gate 2 FAIL"
assert_contains "4.3 output names help-fragments"   "$out" "[FAIL] help-fragments"
assert_contains "4.3 output names HELP-FRAGMENT.md" "$out" "HELP-FRAGMENT.md differs"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 5 — checkpoint_check_mapping_integrity (NIT-2 jq integer tightening)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 5: mapping integrity rejects non-integer numerics (NIT-2) ===\n"

if ! command -v jq >/dev/null 2>&1; then
    echo "  [skip] jq not on PATH; mapping-integer tests require jq"
else
    # 5.1 PASS: all-integer mapping.
    T=$(mktemp -d -t bd101-map-good.XXXXXX)
    mkdir -p "$T/.pack-tracker"
    echo '{"BD-001": 1, "BD-002": 5, "BD-003": 99}' > "$T/.pack-tracker/id-map.json"
    out=$(checkpoint_check_mapping_integrity "$T" 2>&1) ; rc=$?
    assert_eq "5.1 mapping all-int rc=0" "0" "$rc"
    assert_contains "5.1 mapping all-int [OK] line" "$out" "[OK]   mapping: 3 entries"
    rm -rf "$T"

    # 5.2 FAIL: float value (3.14) — pre-fix the bare predicate accepts
    # this; the tightened predicate rejects it because floor(3.14) != 3.14.
    T=$(mktemp -d -t bd101-map-float.XXXXXX)
    mkdir -p "$T/.pack-tracker"
    echo '{"BD-001": 3.14, "BD-002": 5}' > "$T/.pack-tracker/id-map.json"
    out=$(checkpoint_check_mapping_integrity "$T" 2>&1) ; rc=$?
    assert_eq "5.2 mapping float-value rc=1" "1" "$rc"
    assert_contains "5.2 mapping FAIL non-positive-integer" "$out" "[FAIL] mapping"
    assert_contains "5.2 mapping names BD-001 (the float)" "$out" "BD-001"
    rm -rf "$T"

    # 5.3 FAIL: zero (boundary) — must be rejected (positive only).
    T=$(mktemp -d -t bd101-map-zero.XXXXXX)
    mkdir -p "$T/.pack-tracker"
    echo '{"BD-001": 0, "BD-002": 5}' > "$T/.pack-tracker/id-map.json"
    out=$(checkpoint_check_mapping_integrity "$T" 2>&1) ; rc=$?
    assert_eq "5.3 mapping zero-value rc=1" "1" "$rc"
    assert_contains "5.3 mapping FAIL zero" "$out" "[FAIL] mapping"
    rm -rf "$T"
fi

# ─────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASSED"
printf "Failed: %d\n" "$FAILED"
if [[ "$FAILED" -eq 0 ]]; then
    echo "All BD-101 gate tests passed."
    exit 0
fi
exit 1
