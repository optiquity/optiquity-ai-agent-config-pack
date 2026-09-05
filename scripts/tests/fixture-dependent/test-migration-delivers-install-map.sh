#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/fixture-dependent/test-migration-delivers-install-map.sh —
# the migration acceptance sweep: a v10 client built from the v10 tag,
# migrated by the current pack, must end with EVERY declared install-map path
# delivered.
#
# A migration that reports success while leaving a declared file at the
# previous version's bytes, or never creating one, is the defect class this
# test exists for. The sweep reproduces what a client sees: after the
# migration, every destination the install map declares (explicit + family
# rows, on either axis) is classified against pack v11 bytes and pack v10
# bytes:
#     v11-current  — byte-identical to the pack source (delivered)
#     customized   — neither v10 nor v11 bytes (must be a file the client edited)
#     V10-STALE    — still the previous version's bytes (NOT delivered)
#     ABSENT       — no file (a defect unless the client deleted it at v10)
# PASS means zero V10-STALE, ABSENT == exactly the set the client deleted,
# every customized row is an edited file, and no retired skill directory
# survives in any per-CLI home.
#
# Fixture: `test-fixtures/v10-realistic-ot` (built by the v10 tag's own
# init-project.sh, so every pack-shipped file starts as a v10 blob — the
# provenance regime is asserted, not assumed), materialised into a sandbox by
# `build.sh --for-contract migration`. On top of it the test adds a customised
# Xcode script pair (an edited-file control) and deletes two pack files a v10
# install created (an honored-deletion control, one S3 manifest row + one S5
# map row).
#
# Hashing is BATCHED — one `git ls-tree` for v10 blobs, one `git hash-object
# --stdin-paths` for the pack sources, one for the client files — never a
# subprocess per row (ci-check-runtime-compounding). After the real sweep the
# classifier and the leftover scan are proven to bite with planted controls —
# two planted sweep rows and three re-planted retired paths (a directory, a
# DANGLING symlink, a directory — one per home, so the control spans the
# scan's home x object-type matrix) — each driven through the SAME function
# the real leg uses (a control that re-tests its own setup proves nothing).
# No row COUNT is asserted anywhere: counts are fixture-dependent; 3.1
# asserts the sweep covered exactly the destination set the map declares, and
# 4.5 asserts the recorded retirements are exactly the paths present before.
#
# Usage:    bash scripts/tests/fixture-dependent/test-migration-delivers-install-map.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts/tests/fixture-dependent/ → pack root is three levels up.
PACK_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_SH="$PACK_ROOT/test-fixtures/build.sh"
MIGRATE_SH="$PACK_ROOT/scripts/migrate-v10-to-v11.sh"
V10_TAG="${V10_TAG:-v10}"

require_fixture() {
    local name="${1:?require_fixture: missing <name>}"
    local fx="$PACK_ROOT/test-fixtures/$name"
    if [[ ! -d "$fx" || ! -f "$fx/.git/HEAD" ]]; then
        printf 'ERROR: %s requires test-fixtures/%s/ but it does not exist or is not a built fixture.\n' \
            "$(basename "${BASH_SOURCE[0]}")" "$name" >&2
        printf '       Build it with: bash test-fixtures/build.sh --name %s\n' "$name" >&2
        exit 3
    fi
}
require_fixture v10-realistic-ot

passes=0
fails=0
pass() { printf '  pass: %s\n' "$1"; passes=$((passes + 1)); }
fail() {
    printf '  FAIL: %s\n' "$1" >&2
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2" >&2
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3" >&2
    fails=$((fails + 1))
}
assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then pass "$label"; else fail "$label" "$expected" "$actual"; fi
}

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-migration-delivers.XXXXXX")"
SANDBOX="$(bash "$BUILD_SH" --for-contract migration)" \
    || { printf 'ERROR: failed to materialize the migration sandbox\n' >&2; exit 2; }
trap '[[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"; rm -rf "$WORK"' EXIT

# ── 0. Provenance regime: the sandbox's pack files ARE v10 blobs ───────────
echo "== 0. provenance regime (v10-realistic-ot = v10 tag install) =="
b10=$(git -C "$PACK_ROOT" rev-parse "${V10_TAG}:project-template/agent-run.sh")
bcl=$(git hash-object "$SANDBOX/agent-run.sh")
assert_eq "0.1 agent-run.sh in the sandbox is the v10 pack blob (regime: BASE = tag ${V10_TAG})" "$b10" "$bcl"
[[ -f "$SANDBOX/.mcp.json.example" && ! -f "$SANDBOX/.mcp.json" ]] \
    && pass "0.2 v10 install laid down .mcp.json.example and never .mcp.json" \
    || fail "0.2 sandbox shape unexpected for .mcp.json / .mcp.json.example"
retired=$(comm -23 \
    <(git -C "$PACK_ROOT" ls-tree -r --name-only "$V10_TAG" -- project-template/skills/ \
        | sed -n 's#^project-template/skills/\([^/]*\)/SKILL\.md$#\1#p' | sort -u) \
    <(git -C "$PACK_ROOT" ls-files -- 'project-template/skills/*/SKILL.md' \
        | sed -n 's#^project-template/skills/\([^/]*\)/SKILL\.md$#\1#p' | sort -u))
[[ -n "$retired" ]] \
    && pass "0.3 retired-skill set derived from the ${V10_TAG}-vs-HEAD pool inventory is non-empty ($(printf '%s' "$retired" | tr '\n' ' '))" \
    || fail "0.3 retired-skill set is EMPTY — the leftover leg could not bite"
# The retired paths present BEFORE migration, over the SAME three homes and
# the SAME predicate leftover_scan uses (a directory OR a symlink, dangling
# or not); 4.5 asserts the recorded set equals this set.
pre_dirs=""
for r in $retired; do for h in .claude .codex .agents; do
    [[ -d "$SANDBOX/$h/skills/$r" || -L "$SANDBOX/$h/skills/$r" ]] && pre_dirs="$pre_dirs $h/skills/$r"
done; done
pre_dirs="${pre_dirs# }"
pre_leftover=$(printf '%s\n' $pre_dirs | grep -c .)
[[ "$pre_leftover" -gt 0 ]] \
    && pass "0.4 sandbox carries $pre_leftover retired skill dir(s) before migration (the leftover leg has something to catch)" \
    || fail "0.4 sandbox carries no retired skill dir — the leftover leg is vacuous"

# ── 1. Client edits + deletions on top of the fixture ──────────────────────
echo "== 1. client edits (edited-file control) + deletions (honored-deletion control) =="
for f in scripts/test-swift.sh scripts/validate-swift.sh; do
    sed -i.bak -e 's/^XCODE_SCHEME=""/XCODE_SCHEME="FixtureApp"/' \
               -e 's/^XCODE_DESTINATION=""/XCODE_DESTINATION="platform=macOS"/' "$SANDBOX/$f"
    rm -f "$SANDBOX/$f.bak"
done
grep -q 'XCODE_SCHEME="FixtureApp"' "$SANDBOX/scripts/test-swift.sh" \
    && pass "1.1 Xcode script customization anchor present" \
    || fail "1.1 Xcode script customization did not apply"
# Files the client edited (fixture customizations + this test's edits): the
# only rows allowed to classify `customized`.
EDITED="CLAUDE.md AGENTS.md GEMINI.md .codex/config.toml scripts/test-swift.sh scripts/validate-swift.sh"
# Two rows a v10 install DID create, deleted by the client: one S3 manifest
# row (.codex/config.toml.example) and one S5 map-derived row
# (docs/pack/prompts/architect.md). Both must stay deleted.
EXPECT_DELETED=".codex/config.toml.example docs/pack/prompts/architect.md"
for d in $EXPECT_DELETED; do
    [[ -f "$SANDBOX/$d" ]] && pass "1.2 $d exists in the v10 sandbox before deletion (control)" \
                           || fail "1.2 $d absent in the v10 sandbox — the deletion control is vacuous"
    rm -f "$SANDBOX/$d"
done
git -C "$SANDBOX" add -A >/dev/null 2>&1
git -C "$SANDBOX" -c user.name=fixture -c user.email=fixture@example.com commit -q -m "client edits + deletions" >/dev/null 2>&1

# ── 2. Migrate (bare → auto dry-run + apply; resolve the pause; resume) ────
echo "== 2. migrate =="
LOG="$WORK/migrate.log"
PACK="$PACK_ROOT" bash "$MIGRATE_SH" --no-interactive "$SANDBOX" > "$LOG" 2>&1; rc1=$?
assert_eq "2.1 --apply (bare, auto dry-run) rc" "0" "$rc1"
state_dir="$SANDBOX/.pack-migrate-v10-to-v11"
paused="$state_dir/sentinels/stage-S3.paused"
# The pre-resume dispositions carry the S3 rows; --resume re-initialises
# the file, so snapshot it now for the S3-row assertions below.
cp "$state_dir/dispositions.tsv" "$WORK/dispositions-s3.tsv" 2>/dev/null || : > "$WORK/dispositions-s3.tsv"
rc2=0
if [[ -f "$paused" ]]; then
    n=0
    while IFS= read -r s; do [[ -n "$s" ]] || continue; touch "${s}.resolved"; n=$((n + 1)); done < "$paused"
    pass "2.2 apply paused on $n sidecar(s) (trinity fills) — resolved via .resolved"
    PACK="$PACK_ROOT" bash "$MIGRATE_SH" --resume "$SANDBOX" >> "$LOG" 2>&1; rc2=$?
    assert_eq "2.3 --resume rc" "0" "$rc2"
else
    pass "2.2 apply completed without a pause"
fi
grep -q 'Gate 2 PASS' "$LOG" && pass "2.4 Gate 2 PASS in the log" || fail "2.4 Gate 2 PASS missing from the log" "" "$(grep -E 'Gate 2|FAIL' "$LOG" | head -5)"

# ── 3. The sweep ───────────────────────────────────────────────────────────
echo "== 3. sweep every declared install-map path =="
# One line per DECLARED destination: `<class> <dest> <src>`. Rows on either
# axis are swept (union, deduped by destination), so a row declared for one
# path but not the other is still checked.
sweep() {
    local client="$1"
    local rows v10blobs v11hash chash present
    rows=$(
        # shellcheck disable=SC1091
        . "$PACK_ROOT/scripts/lib/install-map.sh"
        export INSTALL_MAP_PACK="$PACK_ROOT"
        { install_map_dispatch_set cmd_update; install_map_dispatch_set migrate; } \
            | awk -F: '{print $1 "\t" $2}' | sort -u -t"$(printf '\t')" -k2,2
    )
    v10blobs=$(git -C "$PACK_ROOT" ls-tree -r "$V10_TAG" -- project-template supporting-docs \
        | awk '{print $4 "\t" $3}')
    v11hash=$(printf '%s\n' "$rows" | cut -f1 | sed "s#^#$PACK_ROOT/#" \
        | git hash-object --stdin-paths | paste -d"$(printf '\t')" <(printf '%s\n' "$rows" | cut -f1) -)
    present=$(printf '%s\n' "$rows" | cut -f2 | while IFS= read -r d; do
        [[ -f "$client/$d" ]] && printf '%s\n' "$d"; done)
    chash=""
    if [[ -n "$present" ]]; then
        chash=$(printf '%s\n' "$present" | sed "s#^#$client/#" | git hash-object --stdin-paths \
            | paste -d"$(printf '\t')" <(printf '%s\n' "$present") -)
    fi
    awk -F'\t' '
        FILENAME==ARGV[1] { v10[$1]=$2; next }
        FILENAME==ARGV[2] { v11[$1]=$2; next }
        FILENAME==ARGV[3] { cl[$1]=$2; next }
        NF >= 2 {
            src=$1; dest=$2
            if (!(dest in cl))                            c="ABSENT"
            else if (cl[dest]==v11[src])                  c="v11-current"
            else if ((src in v10) && cl[dest]==v10[src])  c="V10-STALE"
            else                                          c="customized"
            printf "%s %s %s\n", c, dest, src
        }' <(printf '%s\n' "$v10blobs") <(printf '%s\n' "$v11hash") <(printf '%s\n' "$chash") <(printf '%s\n' "$rows")
}
# Retired skill paths still present in any per-CLI home of `$1` — a
# directory, or a symlink whether live or DANGLING (`-e` follows a link and
# cannot see a dangling one, the shape a client who linked a skill across
# homes is left with when the target copy is retired first) — as one line of
# space-separated `<home>/skills/<name>` entries, empty when none.
# Leg 4.4 AND control 5.4 call THIS function, so the control exercises the
# detection the leg relies on rather than re-testing its own `mkdir`.
leftover_scan() {
    local client="$1" r h out=""
    for r in $retired; do for h in .claude .codex .agents; do
        [[ -e "$client/$h/skills/$r" || -L "$client/$h/skills/$r" ]] && out="$out $h/skills/$r"
    done; done
    printf '%s' "$out"
}
SWEEP="$WORK/sweep.txt"
sweep "$SANDBOX" > "$SWEEP"
total=$(wc -l < "$SWEEP" | tr -d ' ')
stale=$(grep -c '^V10-STALE ' "$SWEEP"); absent=$(grep -c '^ABSENT ' "$SWEEP")
cust=$(grep -c '^customized ' "$SWEEP"); cur=$(grep -c '^v11-current ' "$SWEEP")
printf '  swept %s declared paths: v11-current=%s customized=%s V10-STALE=%s ABSENT=%s\n' "$total" "$cur" "$cust" "$stale" "$absent"
# 3.1 is a PROPERTY, never a row count: the sweep classified EXACTLY the
# destination set the map declares on either axis — none dropped by the
# join, none invented. Row counts are fixture-dependent, and a fixed floor
# cannot see a silently dropped family.
declared=$(
    # shellcheck disable=SC1091
    . "$PACK_ROOT/scripts/lib/install-map.sh"
    export INSTALL_MAP_PACK="$PACK_ROOT"
    { install_map_dispatch_set cmd_update; install_map_dispatch_set migrate; } | cut -d: -f2 | sort -u
)
n_declared=$(printf '%s\n' "$declared" | grep -c .)
swept_dests=$(awk '{print $2}' "$SWEEP" | sort -u)
if [[ "$n_declared" -gt 0 && "$swept_dests" == "$declared" ]]; then
    pass "3.1 sweep covered exactly the $n_declared destination(s) the install map declares (none dropped, none invented)"
else
    fail "3.1 swept destination set differs from the map's declared set" \
         "$n_declared declared destination(s)" \
         "$(printf '%s\n' "$swept_dests" | grep -c .) swept; set difference: $(comm -3 <(printf '%s\n' "$declared") <(printf '%s\n' "$swept_dests") | tr -d '\t' | head -5 | tr '\n' ' ')"
fi
if [[ "$stale" -eq 0 ]]; then
    pass "3.2 zero V10-STALE — every declared path the client kept is at pack v11 bytes"
else
    fail "3.2 $stale declared path(s) still at v10 bytes after migration" "" "$(grep '^V10-STALE ' "$SWEEP")"
fi
absent_set=$(grep '^ABSENT ' "$SWEEP" | awk '{print $2}' | sort | tr '\n' ' ' | sed 's/ $//')
expect_sorted=$(printf '%s\n' $EXPECT_DELETED | sort | tr '\n' ' ' | sed 's/ $//')
if [[ "$absent_set" == "$expect_sorted" ]]; then
    pass "3.3 ABSENT set is exactly the client's deletions ($expect_sorted) — nothing else missing, deletions honored"
else
    fail "3.3 ABSENT set differs from the client's deletions" "$expect_sorted" "$absent_set"
fi
bad_cust=""
while read -r _c d _s; do
    case " $EDITED " in *" $d "*) ;; *) bad_cust="$bad_cust $d" ;; esac
done < <(grep '^customized ' "$SWEEP")
if [[ -z "$bad_cust" ]]; then
    pass "3.4 every customized row ($cust) is a file the client edited"
else
    fail "3.4 customized rows that the client did NOT edit" "" "$bad_cust"
fi
for f in scripts/test-swift.sh scripts/validate-swift.sh; do
    grep -q "^customized $f " "$SWEEP" \
        && pass "3.5 $f classified customized (edit preserved through migration)" \
        || fail "3.5 $f not classified customized" "" "$(grep " $f " "$SWEEP")"
done
grep -q '^v11-current agent-run.sh ' "$SWEEP" \
    && pass "3.6 agent-run.sh delivered at pack v11 bytes" \
    || fail "3.6 agent-run.sh not v11-current" "" "$(grep ' agent-run.sh ' "$SWEEP")"
grep -q '^v11-current .mcp.json ' "$SWEEP" \
    && pass "3.7 .mcp.json created at pack v11 bytes (v10 shipped only the example)" \
    || fail "3.7 .mcp.json not v11-current" "" "$(grep ' .mcp.json ' "$SWEEP")"
src_mode=$(git -C "$PACK_ROOT" ls-files -s project-template/agent-run.sh | cut -c1-6)
[[ "$src_mode" == "100755" && -x "$SANDBOX/agent-run.sh" ]] \
    && pass "3.8 agent-run.sh executable in the client, matching its pack source mode ($src_mode)" \
    || fail "3.8 agent-run.sh mode mismatch" "source $src_mode + executable" "$(ls -l "$SANDBOX/agent-run.sh" | cut -c1-10)"

# ── 4. Dispositions: the clean add, the honored deletions, the retirements ─
echo "== 4. dispositions =="
if awk -F'\t' '$3 == ".mcp.json" && $1 == "pack-update-applied" { f=1 } END { exit f ? 0 : 1 }' "$WORK/dispositions-s3.tsv"; then
    pass "4.1 .mcp.json recorded pack-update-applied (clean add, not an honored deletion)"
else
    fail "4.1 .mcp.json disposition wrong" "pack-update-applied" "$(awk -F'\t' '$3 == ".mcp.json"' "$WORK/dispositions-s3.tsv")"
fi
if awk -F'\t' '$3 == ".codex/config.toml.example" && $1 == "project-deleted-pack-kept" { f=1 } END { exit f ? 0 : 1 }' "$WORK/dispositions-s3.tsv"; then
    pass "4.2 deleted S3 row .codex/config.toml.example recorded project-deleted-pack-kept"
else
    fail "4.2 .codex/config.toml.example disposition wrong" "project-deleted-pack-kept" "$(awk -F'\t' '$3 == ".codex/config.toml.example"' "$WORK/dispositions-s3.tsv")"
fi
if awk -F'\t' '$3 == "docs/pack/prompts/architect.md" && $1 == "project-deleted-pack-kept" { f=1 } END { exit f ? 0 : 1 }' "$state_dir/dispositions.tsv"; then
    pass "4.3 deleted S5 row docs/pack/prompts/architect.md recorded project-deleted-pack-kept"
else
    fail "4.3 docs/pack/prompts/architect.md disposition wrong" "project-deleted-pack-kept" "$(awk -F'\t' '$3 == "docs/pack/prompts/architect.md"' "$state_dir/dispositions.tsv")"
fi
leftover=$(leftover_scan "$SANDBOX")
[[ -z "$leftover" ]] \
    && pass "4.4 no retired skill directory survives in .claude/.codex/.agents" \
    || fail "4.4 retired skill directory left behind" "" "$leftover"
# 4.5 is a SET property, never a floor: the retired paths the dispositions
# record (a `<home>/skills/<name>` prefix on a removed-by-design row — a
# file row, an empty-dir row, or a symlink row) are EXACTLY the paths that
# were present before migration (0.4). A missing home reds it; so does a
# spurious one.
rt_dirs=""
for r in $retired; do for h in .claude .codex .agents; do
    if awk -F'\t' -v p="$h/skills/$r" '$1 == "removed-by-design" && ($3 == p || index($3, p "/") == 1) { f=1 } END { exit f ? 0 : 1 }' "$state_dir/dispositions.tsv"; then
        rt_dirs="$rt_dirs $h/skills/$r"
    fi
done; done
rt_dirs="${rt_dirs# }"
if [[ -n "$pre_dirs" && "$rt_dirs" == "$pre_dirs" ]]; then
    pass "4.5 removed-by-design rows recorded for exactly the retired path(s) present before migration ($pre_dirs)"
else
    fail "4.5 recorded retired-path set differs from the set present before migration" "$pre_dirs" "$rt_dirs"
fi
grep -q '^## Files retired by pack' "$state_dir/report.md" \
    && pass "4.6 report.md lists the retirements under 'Files retired by pack'" \
    || fail "4.6 report.md has no 'Files retired by pack' section"

# ── 5. Controls: the sweep classifier BITES ────────────────────────────────
echo "== 5. controls (planted defects must be flagged; then removed) =="
git -C "$PACK_ROOT" show "${V10_TAG}:project-template/agent-run.sh" > "$SANDBOX/agent-run.sh"
mv "$SANDBOX/.mcp.json" "$WORK/mcp.keep"
first_retired=$(printf '%s\n' "$retired" | head -1)
# Three retired-path shapes, one per home, so the control spans the scan's
# home x object-type matrix: a real directory in .claude, a DANGLING
# relative symlink in .codex (its target is under the .gemini/ home S5b moved
# away — the shape a client who linked across homes is left with), a real
# directory in .agents. The link's danglingness is asserted so that cell is
# not vacuous.
mkdir -p "$SANDBOX/.claude/skills/$first_retired" "$SANDBOX/.agents/skills/$first_retired" "$SANDBOX/.codex/skills"
ln -s "../../.gemini/skills/$first_retired" "$SANDBOX/.codex/skills/$first_retired"
[[ -L "$SANDBOX/.codex/skills/$first_retired" && ! -e "$SANDBOX/.codex/skills/$first_retired" ]] \
    && pass "5.0 control setup: .codex/skills/$first_retired is a DANGLING symlink (-L and not -e)" \
    || fail "5.0 control setup: the planted .codex link is not dangling — the symlink cell would be vacuous"
ctrl=$(sweep "$SANDBOX")
printf '%s\n' "$ctrl" | grep -q '^V10-STALE agent-run.sh ' \
    && pass "5.1 control: planted v10 agent-run.sh is flagged V10-STALE" \
    || fail "5.1 control: planted v10 agent-run.sh NOT flagged" "" "$(printf '%s\n' "$ctrl" | grep ' agent-run.sh ')"
printf '%s\n' "$ctrl" | grep -q '^ABSENT .mcp.json ' \
    && pass "5.2 control: removed .mcp.json is flagged ABSENT" \
    || fail "5.2 control: removed .mcp.json NOT flagged"
[[ "$(printf '%s\n' "$ctrl" | grep -c '^V10-STALE ')" -eq 1 ]] \
    && pass "5.3 control: exactly ONE V10-STALE row (the planted one) — no collateral" \
    || fail "5.3 control: V10-STALE count != 1" "1" "$(printf '%s\n' "$ctrl" | grep -c '^V10-STALE ')"
# 5.4 drives the SAME scan leg 4.4 uses; a control that only re-tested the
# `mkdir` above would pass with the scan disabled.
ctrl_left=$(leftover_scan "$SANDBOX")
ctrl_expect=" .claude/skills/$first_retired .codex/skills/$first_retired .agents/skills/$first_retired"
[[ "$ctrl_left" == "$ctrl_expect" ]] \
    && pass "5.4 control: leftover_scan flags all three planted shapes — real dir (.claude), dangling symlink (.codex), real dir (.agents)" \
    || fail "5.4 control: leftover_scan did NOT flag every planted shape" "'$ctrl_expect'" "'$ctrl_left'"
# Restore.
cp "$PACK_ROOT/project-template/agent-run.sh" "$SANDBOX/agent-run.sh"
mv "$WORK/mcp.keep" "$SANDBOX/.mcp.json"
rm -rf "$SANDBOX/.claude/skills/$first_retired" "$SANDBOX/.agents/skills/$first_retired"
rm -f "$SANDBOX/.codex/skills/$first_retired"
post=$(sweep "$SANDBOX")
post_stale=$(printf '%s\n' "$post" | grep -c '^V10-STALE ')
post_absent=$(printf '%s\n' "$post" | grep -c '^ABSENT ')
n_deleted=$(printf '%s\n' $EXPECT_DELETED | grep -c .)
post_left=$(leftover_scan "$SANDBOX")
[[ "$post_stale" -eq 0 && "$post_absent" -eq "$n_deleted" && -z "$post_left" ]] \
    && pass "5.5 controls removed: sweep back to zero V10-STALE and the $n_deleted honored deletions; leftover_scan empty again" \
    || fail "5.5 sweep / leftover_scan did not return to the clean state after removing the controls" \
            "stale=0 absent=$n_deleted leftover=''" "stale=$post_stale absent=$post_absent leftover='$post_left'"

# ── Summary ────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
