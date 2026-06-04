#!/usr/bin/env bash
# scripts/tests/test-per-entry.sh — test suite for the BD-164 per-entry
# split helpers (scripts/lib/per-entry/).
#
# Test cases (per integration parent §18.2 #1):
#   1. Round-trip identity: decompose(mirror) → tree;
#      regenerate(tree) → mirror'; mirror == mirror' byte-identical.
#   2. Empty-tree behavior: regenerate over empty stream produces a
#      mirror sourced from _intro.md only (no entries).
#   3. Supporting-file admission: `_quotas.md` (unknown) is SKIP;
#      `_v8-resolved-archive.md` (known) is emitted.
#   4. Divergence-warning routing: interactive vs non-interactive
#      paths exercised via PE_FORCE_OVERWRITE_MIRROR + non-TTY stdin.
#
# Plus structural / per-helper unit cases:
#   5. Determinism: multiple regenerations of same input yield
#      byte-identical output.
#   6. Idempotency (decompose): running decompose twice on the same
#      input is a no-op the second time.
#   7. Back-pointer add/strip: line-1 HTML comment added by decompose,
#      stripped by mirror generator (preserves byte-additive invariant).
#   8. Stream-shape coverage: pack-backlog (BD-NNN) AND pack-changelog
#      (vN.M) decompose+regenerate round-trip.
#   9. _rules.md runtime read: helper reads supporting-file basename
#      list at runtime; unknown basenames SKIPPED.
#  10. Bash 3.2 compatibility smoke: helpers source cleanly under
#      `bash --norc -c`.
#
# Usage: bash scripts/tests/test-per-entry.sh
# Exit:  0 if all PASS; 1 on any FAIL.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib/per-entry"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' actual='$3'"; fi
}

assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' missing from: ${2:0:200}"; fi
}

assert_byte_identical() {
    # $1 = label, $2 = path A, $3 = path B
    if cmp -s "$2" "$3"; then t_pass "$1"
    else
        t_fail "$1" "files differ: $2 vs $3"
        diff "$2" "$3" 2>&1 | head -20 | sed 's/^/         /' >&2 || true
    fi
}

# Source the helpers (same load order as a consumer would use).
# shellcheck disable=SC1091
. "$LIB_DIR/_lib.sh"
# shellcheck disable=SC1091
. "$LIB_DIR/decompose.sh"
# shellcheck disable=SC1091
. "$LIB_DIR/mirror-generate.sh"
# shellcheck disable=SC1091
. "$LIB_DIR/toc-regenerate.sh"

# Track per-test scratch dirs for cleanup.
SCRATCH_ROOT=$(mktemp -d -t per-entry-tests.XXXXXX)
trap 'rm -rf "$SCRATCH_ROOT"' EXIT INT TERM

# ─────────────────────────────────────────────────────────────────
# Fixture helpers
# ─────────────────────────────────────────────────────────────────

# Build a synthetic pack-backlog mirror (3 entries + intro + v8 archive).
# $1 = output file path
fixture_pack_backlog_mirror() {
    cat >"$1" <<'EOF'
# Backlog

All planned improvements to the AI Agent Config Pack are tracked here.

---

## Active — v11 Scope

The v11.0 implementation surface.

---

**BD-100 — Sample first entry**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: `scripts/example.sh`
Description: First sample entry. Single-line description.

---

**BD-101 — Sample second entry**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: BD-100
File/Symbol: `scripts/another.sh`
Description: Second sample entry with multiple lines:
  - Line one
  - Line two
  - Line three
Resolved: 2026-05-13 — sample resolution narrative.

---

**BD-102 — Sample third entry, deferred**
Type: TODO(version)
Status: Deferred
Blockers: v12.0
Unblocks: None
File/Symbol: n/a
Description: Deferred to a later version.

---

## Resolved — v8 (March 2026)

Legacy v8 historical block — frozen.

- v8.0 — Initial release (2026-03-01).
- v8.1 — Bugfix release (2026-03-15).
EOF
}

# Build the synthetic intro (the preamble lines that the mirror
# generator emits before entries).
# $1 = output _intro.md path
fixture_pack_backlog_intro() {
    cat >"$1" <<'EOF'
# Backlog

All planned improvements to the AI Agent Config Pack are tracked here.

---

## Active — v11 Scope

The v11.0 implementation surface.
EOF
}

# Build the synthetic _v8 archive (the trailing frozen-historical block).
# $1 = output _v8-resolved-archive.md path
fixture_pack_backlog_v8_archive() {
    cat >"$1" <<'EOF'
## Resolved — v8 (March 2026)

Legacy v8 historical block — frozen.

- v8.0 — Initial release (2026-03-01).
- v8.1 — Bugfix release (2026-03-15).
EOF
}

# Build the synthetic _rules.md declaring supporting files.
# $1 = output _rules.md path
fixture_pack_backlog_rules() {
    cat >"$1" <<'EOF'
# Per-stream contract — pack-backlog

Stream identity: pack-backlog
Filename convention: ^BD-\d+\.md$
Entry contract: see ARCHITECTURE-V3.1-DELTA.md §3 A2
Lifecycle states: Open, Resolved, Deferred, Cancelled, Deprecated
Write authority: PACK-CHAT.md (Pack Chat) + METHODOLOGY.md Part 7

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
- `_v8-resolved-archive.md`
EOF
}

# Build a minimal pack-changelog monolith (BD-203 per-release shape: two
# `## vN` releases — v11 carries nested `### vN.M` + a `### New` block
# that must ride inside the v11.md entry; v7 is H2-only).
# $1 = output file path
fixture_pack_changelog_mirror() {
    cat >"$1" <<'EOF'
# Changelog

All notable changes to the AI Agent Config Pack are documented here.

---

## v11 — May 2026

### v11.0 — Initial v11 release

- Sample bullet one.
- Sample bullet two.

### New

- Nested subsection bullet.

## v7 — January 2025

- Legacy H2-only release (no nested H3).
EOF
}

# ─────────────────────────────────────────────────────────────────
# Group 1: stream-shape lookups (sanity)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: stream-shape lookups ===\n"

# BD-203: pack-stream mirror-filename asserts removed — under the
# no-mirror model the pack monoliths are deleted; the per-entry tree +
# `_toc.md` is the SOLE SSOT. The `mirror` attribute is retained only as
# a constant (deletion-target reference); it is no longer a live mirror
# path, so asserting it as a pack deliverable is wrong-model. Project
# streams DO still use mirror-generate (pending BD-206) — keep 1.3–1.5.
assert_eq "1.3 project-backlog mirror filename" "docs/project/BACKLOG.md" "$(pe_canonical_mirror_for_stream project-backlog)"
assert_eq "1.4 project-implementation-plan mirror filename" "docs/project/IMPLEMENTATION-PLAN.md" "$(pe_canonical_mirror_for_stream project-implementation-plan)"
assert_eq "1.5 project-changelog mirror filename" "docs/project/CHANGELOG.md" "$(pe_canonical_mirror_for_stream project-changelog)"
# BD-203 A4: pack-backlog entry regex admits the suffix form.
assert_eq "1.6 pack-backlog entry regex"  "^BD-[0-9]+[a-z]*\.md$" "$(pe_entry_regex_for_stream pack-backlog)"
assert_eq "1.7 project-backlog entry regex" "^TD-[0-9]+\.md$" "$(pe_entry_regex_for_stream project-backlog)"
assert_eq "1.8 pack-backlog known supporting includes _v8-resolved-archive.md" \
    "yes" "$(pe_supporting_files_known_for_stream pack-backlog | grep -q '_v8-resolved-archive.md' && echo yes || echo no)"
assert_eq "1.9 project-changelog known supporting includes _format.md" \
    "yes" "$(pe_supporting_files_known_for_stream project-changelog | grep -q '_format.md' && echo yes || echo no)"

# pe_stream_for_path walks the trailing path suffix.
TMP_DIR1=$(mktemp -d -t pe-pathlookup.XXXXXX)
mkdir -p "$TMP_DIR1/backlog"
mkdir -p "$TMP_DIR1/docs/project/changelog"
assert_eq "1.10 pe_stream_for_path resolves pack-backlog suffix" "pack-backlog" "$(pe_stream_for_path "$TMP_DIR1/backlog")"
assert_eq "1.11 pe_stream_for_path resolves project-changelog suffix" "project-changelog" "$(pe_stream_for_path "$TMP_DIR1/docs/project/changelog")"
rm -rf "$TMP_DIR1"

# ─────────────────────────────────────────────────────────────────
# Group 2: back-pointer add / strip (Addendum #2 §2)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: back-pointer add / strip ===\n"

# Compose: pack-backlog BD-100 → '<!-- per-entry source: /backlog/BD-100.md; contract: /backlog/_rules.md -->'
EXPECT_BP='<!-- per-entry source: /backlog/BD-100.md; contract: /backlog/_rules.md -->'
ACTUAL_BP=$(pe_backpointer_line pack-backlog BD-100)
assert_eq "2.1 pack-backlog back-pointer line shape" "$EXPECT_BP" "$ACTUAL_BP"

# project-side uses the project-relative path (no leading slash).
EXPECT_BP_TD='<!-- per-entry source: docs/project/backlog/TD-001.md; contract: docs/project/backlog/_rules.md -->'
ACTUAL_BP_TD=$(pe_backpointer_line project-backlog TD-001)
assert_eq "2.2 project-backlog back-pointer line shape" "$EXPECT_BP_TD" "$ACTUAL_BP_TD"

# Strip is idempotent + only removes a line-1 match.
TMP_BP=$(mktemp -t pe-bp.XXXXXX)
{
    echo '<!-- per-entry source: /backlog/BD-100.md; contract: /backlog/_rules.md -->'
    echo '**BD-100 — Sample**'
    echo 'Type: TODO(version)'
} >"$TMP_BP"
STRIPPED=$(pe_strip_backpointer_stdin <"$TMP_BP")
assert_eq "2.3 strip removes line-1 back-pointer" "**BD-100 — Sample**
Type: TODO(version)" "$STRIPPED"
# Strip on a file WITHOUT a back-pointer is a no-op.
TMP_BP2=$(mktemp -t pe-bp2.XXXXXX)
{
    echo '**BD-100 — Sample**'
    echo 'Type: TODO(version)'
} >"$TMP_BP2"
STRIPPED2=$(pe_strip_backpointer_stdin <"$TMP_BP2")
assert_eq "2.4 strip on file without back-pointer is no-op" "**BD-100 — Sample**
Type: TODO(version)" "$STRIPPED2"
rm -f "$TMP_BP" "$TMP_BP2"

# ─────────────────────────────────────────────────────────────────
# Group 3: round-trip identity (decompose → regenerate)
# ─────────────────────────────────────────────────────────────────
#
# Verifies the byte-additive invariant per integration parent §7.3:
# decompose(mirror) → per-entry tree; regenerate(tree) → mirror';
# mirror == mirror' byte-identical.

printf "\n=== Group 3: pack-backlog round-trip identity ===\n"

PB_ROOT="$SCRATCH_ROOT/pack-backlog-roundtrip"
PB_DIR="$PB_ROOT/backlog"
mkdir -p "$PB_DIR"

# Build the input mirror.
fixture_pack_backlog_mirror "$PB_ROOT/BACKLOG.md"

# Set up the per-entry tree directory with intro + _v8 archive +
# _rules.md so the mirror generator can re-emit the byte-identical
# mirror. (The decompose helper does NOT write supporting files;
# that is BD-167's job. For the round-trip test we pre-populate
# them — same as the post-migration state will be.)
fixture_pack_backlog_intro "$PB_DIR/_intro.md"
fixture_pack_backlog_v8_archive "$PB_DIR/_v8-resolved-archive.md"
fixture_pack_backlog_rules "$PB_DIR/_rules.md"

# Save a baseline copy of the mirror for byte-identity comparison.
cp "$PB_ROOT/BACKLOG.md" "$PB_ROOT/BACKLOG.md.baseline"

# Decompose.
per_entry_decompose pack-backlog "$PB_ROOT/BACKLOG.md" "$PB_DIR" 2>/dev/null

# Verify per-entry files exist.
assert_eq "3.1 BD-100.md exists" "yes" "$([[ -f "$PB_DIR/BD-100.md" ]] && echo yes || echo no)"
assert_eq "3.2 BD-101.md exists" "yes" "$([[ -f "$PB_DIR/BD-101.md" ]] && echo yes || echo no)"
assert_eq "3.3 BD-102.md exists" "yes" "$([[ -f "$PB_DIR/BD-102.md" ]] && echo yes || echo no)"

# Verify back-pointer present on line 1 of every per-entry file.
LINE1_BD100=$(head -n 1 "$PB_DIR/BD-100.md")
assert_eq "3.4 BD-100.md line 1 is back-pointer" \
    '<!-- per-entry source: /backlog/BD-100.md; contract: /backlog/_rules.md -->' \
    "$LINE1_BD100"

# Verify line 2 is the bold-header (byte-identical span starts here).
LINE2_BD100=$(sed -n '2p' "$PB_DIR/BD-100.md")
assert_eq "3.5 BD-100.md line 2 is the bold-header (byte-identical span anchor)" \
    "**BD-100 — Sample first entry**" \
    "$LINE2_BD100"

# Verify byte-identical span: tail +2 of BD-100.md should appear in the original mirror.
TAIL_BD100=$(tail -n +2 "$PB_DIR/BD-100.md")
ORIG_BD100=$(awk '/^\*\*BD-100 —/,/^Description: First sample entry. Single-line description.$/' "$PB_ROOT/BACKLOG.md.baseline")
assert_eq "3.6 BD-100.md tail+2 matches original BD-100 span" "$ORIG_BD100" "$TAIL_BD100"

# Now regenerate the mirror from the per-entry tree.
# Force overwrite since the original mirror is on disk (we want to
# verify byte-identity of the regenerated content vs the baseline).
PE_FORCE_OVERWRITE_MIRROR=1 \
    per_entry_regenerate_mirror pack-backlog "$PB_DIR" "$PB_ROOT/BACKLOG.md" 2>/dev/null

# Compare regenerated mirror against the baseline.
assert_byte_identical "3.7 round-trip byte-identity (mirror == mirror')" \
    "$PB_ROOT/BACKLOG.md.baseline" \
    "$PB_ROOT/BACKLOG.md"

# ─────────────────────────────────────────────────────────────────
# Group 4: idempotency (decompose twice == decompose once)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: idempotency ===\n"

# Take a snapshot of every per-entry file's content + mtime hash.
SNAP_DIR=$(mktemp -d -t pe-snap.XXXXXX)
cp "$PB_DIR/BD-100.md" "$SNAP_DIR/BD-100.md"
cp "$PB_DIR/BD-101.md" "$SNAP_DIR/BD-101.md"
cp "$PB_DIR/BD-102.md" "$SNAP_DIR/BD-102.md"

# Decompose again.
per_entry_decompose pack-backlog "$PB_ROOT/BACKLOG.md" "$PB_DIR" 2>/dev/null

assert_byte_identical "4.1 decompose twice → BD-100 byte-identical" "$SNAP_DIR/BD-100.md" "$PB_DIR/BD-100.md"
assert_byte_identical "4.2 decompose twice → BD-101 byte-identical" "$SNAP_DIR/BD-101.md" "$PB_DIR/BD-101.md"
assert_byte_identical "4.3 decompose twice → BD-102 byte-identical" "$SNAP_DIR/BD-102.md" "$PB_DIR/BD-102.md"

rm -rf "$SNAP_DIR"

# ─────────────────────────────────────────────────────────────────
# Group 5: determinism (regenerate multiple times yields identical output)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: determinism ===\n"

# Snapshot the regenerated mirror.
cp "$PB_ROOT/BACKLOG.md" "$PB_ROOT/BACKLOG.md.snap1"
PE_FORCE_OVERWRITE_MIRROR=1 \
    per_entry_regenerate_mirror pack-backlog "$PB_DIR" "$PB_ROOT/BACKLOG.md" 2>/dev/null
cp "$PB_ROOT/BACKLOG.md" "$PB_ROOT/BACKLOG.md.snap2"
PE_FORCE_OVERWRITE_MIRROR=1 \
    per_entry_regenerate_mirror pack-backlog "$PB_DIR" "$PB_ROOT/BACKLOG.md" 2>/dev/null
cp "$PB_ROOT/BACKLOG.md" "$PB_ROOT/BACKLOG.md.snap3"

assert_byte_identical "5.1 regenerate snap1 == snap2" "$PB_ROOT/BACKLOG.md.snap1" "$PB_ROOT/BACKLOG.md.snap2"
assert_byte_identical "5.2 regenerate snap2 == snap3" "$PB_ROOT/BACKLOG.md.snap2" "$PB_ROOT/BACKLOG.md.snap3"

# ─────────────────────────────────────────────────────────────────
# Group 6: empty-tree behavior
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 6: empty-tree mirror ===\n"

ET_ROOT="$SCRATCH_ROOT/empty-tree"
ET_DIR="$ET_ROOT/backlog"
mkdir -p "$ET_DIR"
fixture_pack_backlog_intro "$ET_DIR/_intro.md"
fixture_pack_backlog_rules "$ET_DIR/_rules.md"
# No entry files. No _v8 archive.

per_entry_regenerate_mirror pack-backlog "$ET_DIR" "$ET_ROOT/BACKLOG.md" 2>/dev/null

# The mirror should contain the intro content and nothing else
# (no entries, no v8 archive since the file isn't present).
EMPTY_OUT=$(cat "$ET_ROOT/BACKLOG.md")
assert_contains "6.1 empty-tree mirror contains intro preamble" \
    "$EMPTY_OUT" "All planned improvements"
assert_eq "6.2 empty-tree mirror does NOT contain BD- entries" \
    "no" "$(printf '%s' "$EMPTY_OUT" | grep -q '^\*\*BD-' && echo yes || echo no)"

# ─────────────────────────────────────────────────────────────────
# Group 7: supporting-file admission (`_quotas.md` SKIP, `_v8-resolved-archive.md` emitted)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 7: supporting-file admission ===\n"

SF_ROOT="$SCRATCH_ROOT/supporting-files"
SF_DIR="$SF_ROOT/backlog"
mkdir -p "$SF_DIR"
fixture_pack_backlog_intro "$SF_DIR/_intro.md"
fixture_pack_backlog_v8_archive "$SF_DIR/_v8-resolved-archive.md"

# _rules.md ADMITS an unknown supporting file `_quotas.md` plus the
# known _v8-resolved-archive.md. The helpers should SKIP the unknown
# basename per integration parent §7.5 final paragraph.
cat >"$SF_DIR/_rules.md" <<'EOF'
# Per-stream contract — pack-backlog (extended for test 7)

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
- `_v8-resolved-archive.md`
- `_quotas.md`
EOF

# Add a (synthetic) _quotas.md to the directory; the helpers should
# ignore it because it's not in the hard-coded known list.
echo "## Quotas (synthetic — should NOT appear in mirror)" >"$SF_DIR/_quotas.md"

# Verify the effective list intersects (admitted ∩ known) and excludes _quotas.md.
EFFECTIVE=$(pe_supporting_files_effective pack-backlog "$SF_DIR")
assert_eq "7.1 effective set excludes unknown _quotas.md" \
    "no" "$(printf '%s' "$EFFECTIVE" | tr ' ' '\n' | grep -Fxq '_quotas.md' && echo yes || echo no)"
assert_eq "7.2 effective set includes known _v8-resolved-archive.md" \
    "yes" "$(printf '%s' "$EFFECTIVE" | tr ' ' '\n' | grep -Fxq '_v8-resolved-archive.md' && echo yes || echo no)"

# Regenerate; the mirror should contain v8 archive content but NOT _quotas.md content.
per_entry_regenerate_mirror pack-backlog "$SF_DIR" "$SF_ROOT/BACKLOG.md" 2>/dev/null
SF_MIRROR_OUT=$(cat "$SF_ROOT/BACKLOG.md")
assert_contains "7.3 mirror contains v8 archive content" "$SF_MIRROR_OUT" "Resolved — v8 (March 2026)"
assert_eq "7.4 mirror does NOT contain _quotas.md content" \
    "no" "$(printf '%s' "$SF_MIRROR_OUT" | grep -q 'Quotas (synthetic' && echo yes || echo no)"

# ─────────────────────────────────────────────────────────────────
# Group 8: divergence-warning routing (interactive vs non-interactive)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 8: divergence-warning routing ===\n"

DW_ROOT="$SCRATCH_ROOT/divergence"
DW_DIR="$DW_ROOT/backlog"
mkdir -p "$DW_DIR"
fixture_pack_backlog_intro "$DW_DIR/_intro.md"
fixture_pack_backlog_v8_archive "$DW_DIR/_v8-resolved-archive.md"
fixture_pack_backlog_rules "$DW_DIR/_rules.md"

# Build a baseline mirror via the regenerator (so we know the
# regenerator's output is on disk — no divergence).
per_entry_regenerate_mirror pack-backlog "$DW_DIR" "$DW_ROOT/BACKLOG.md" 2>/dev/null

# Hand-edit the mirror to introduce divergence.
{
    cat "$DW_ROOT/BACKLOG.md"
    echo "<!-- intentional hand-edit to introduce divergence -->"
} >"$DW_ROOT/BACKLOG.md.edited"
mv "$DW_ROOT/BACKLOG.md.edited" "$DW_ROOT/BACKLOG.md"

# 8.1 — Non-interactive (no TTY) without --force: divergence warning
# emitted to stderr, returns non-zero exit, mirror unchanged.
DW_BEFORE_SHA=$(shasum -a 256 "$DW_ROOT/BACKLOG.md" | awk '{print $1}')
DW_RC=0
DW_STDERR=$(per_entry_regenerate_mirror pack-backlog "$DW_DIR" "$DW_ROOT/BACKLOG.md" </dev/null 2>&1) || DW_RC=$?
DW_AFTER_SHA=$(shasum -a 256 "$DW_ROOT/BACKLOG.md" | awk '{print $1}')

if [[ "$DW_RC" -ne 0 ]]; then t_pass "8.1 non-interactive divergence returns non-zero exit (rc=$DW_RC)"
else t_fail "8.1 non-interactive divergence returns non-zero exit" "rc=$DW_RC; expected non-zero"; fi
assert_contains "8.2 non-interactive divergence emits warning to stderr" "$DW_STDERR" "divergence"
assert_eq "8.3 non-interactive divergence DOES NOT modify on-disk mirror" "$DW_BEFORE_SHA" "$DW_AFTER_SHA"
assert_contains "8.4 warning names --force-overwrite-mirror as the override" "$DW_STDERR" "force-overwrite-mirror"

# 8.5 — PE_FORCE_OVERWRITE_MIRROR=1 bypasses the block: regenerates +
# warns to stderr (audit-trail per Addendum #2 §4.5).
DW_FORCE_RC=0
DW_FORCE_STDERR=$(PE_FORCE_OVERWRITE_MIRROR=1 \
    per_entry_regenerate_mirror pack-backlog "$DW_DIR" "$DW_ROOT/BACKLOG.md" </dev/null 2>&1) || DW_FORCE_RC=$?
DW_AFTER_FORCE_SHA=$(shasum -a 256 "$DW_ROOT/BACKLOG.md" | awk '{print $1}')

if [[ "$DW_FORCE_RC" -eq 0 ]]; then t_pass "8.5 force-overwrite returns 0"
else t_fail "8.5 force-overwrite returns 0" "rc=$DW_FORCE_RC; expected 0"; fi
assert_contains "8.6 force-overwrite emits audit-trail warning" "$DW_FORCE_STDERR" "PE_FORCE_OVERWRITE_MIRROR=1"
# Mirror SHA changed (the regenerator overwrote the hand-edit).
if [[ "$DW_AFTER_FORCE_SHA" != "$DW_BEFORE_SHA" ]]; then t_pass "8.7 force-overwrite did modify on-disk mirror"
else t_fail "8.7 force-overwrite did modify on-disk mirror" "SHA unchanged"; fi

# 8.8 — Idempotent regenerate (no divergence): no warning, no overwrite needed.
NOOP_RC=0
NOOP_STDERR=$(per_entry_regenerate_mirror pack-backlog "$DW_DIR" "$DW_ROOT/BACKLOG.md" </dev/null 2>&1) || NOOP_RC=$?
if [[ "$NOOP_RC" -eq 0 ]]; then t_pass "8.8 no-divergence regenerate returns 0"
else t_fail "8.8 no-divergence regenerate returns 0" "rc=$NOOP_RC; stderr=$NOOP_STDERR"; fi
assert_eq "8.9 no-divergence regenerate emits NO warning" "" "$NOOP_STDERR"

# ─────────────────────────────────────────────────────────────────
# Group 9: TOC regeneration
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 9: TOC regeneration ===\n"

per_entry_regenerate_toc pack-backlog "$PB_DIR" 2>/dev/null
[[ -f "$PB_DIR/_toc.md" ]] && t_pass "9.1 _toc.md created" || t_fail "9.1 _toc.md created"

TOC_OUT=$(cat "$PB_DIR/_toc.md")
assert_contains "9.2 _toc.md contains 'Table of contents — pack-backlog' header" "$TOC_OUT" "Table of contents — pack-backlog"
assert_contains "9.3 _toc.md contains 'Open' status group" "$TOC_OUT" "## Open"
assert_contains "9.4 _toc.md contains 'Resolved' status group" "$TOC_OUT" "## Resolved"
assert_contains "9.5 _toc.md contains 'Deferred' status group" "$TOC_OUT" "## Deferred"
assert_contains "9.6 _toc.md links BD-100 entry" "$TOC_OUT" "[BD-100](./BD-100.md)"
assert_contains "9.7 _toc.md links BD-101 entry" "$TOC_OUT" "[BD-101](./BD-101.md)"

# Determinism + idempotency: regenerate twice → byte-identical TOC.
cp "$PB_DIR/_toc.md" "$PB_ROOT/_toc.md.snap1"
per_entry_regenerate_toc pack-backlog "$PB_DIR" 2>/dev/null
assert_byte_identical "9.8 TOC regeneration is byte-deterministic" "$PB_ROOT/_toc.md.snap1" "$PB_DIR/_toc.md"

# ─────────────────────────────────────────────────────────────────
# Group 10: pack-changelog per-release decompose (BD-203 CHANGE 2)
# ─────────────────────────────────────────────────────────────────
#
# BD-203 retires the pack mirror round-trip: the per-entry tree is the
# SOLE SSOT. This group verifies the per-RELEASE granularity (one
# `vN.md` per `## vN` H2) — the entry body is the ENTIRE H2 block, so
# nested `### vN.M` / `### New` subsections ride INSIDE the release file
# (no data loss), and H2-only releases (v7) are preserved.

printf "\n=== Group 10: pack-changelog per-release decompose (BD-203 CHANGE 2) ===\n"

PC_ROOT="$SCRATCH_ROOT/pack-changelog-per-release"
PC_DIR="$PC_ROOT/changelog"
mkdir -p "$PC_DIR"

fixture_pack_changelog_mirror "$PC_ROOT/CHANGELOG.md"

cat >"$PC_DIR/_rules.md" <<'EOF'
# Per-stream contract — pack-changelog

The per-entry tree (+ `_toc.md`) is the SOLE source of truth and
readable form. There is no monolithic mirror.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
EOF

per_entry_decompose pack-changelog "$PC_ROOT/CHANGELOG.md" "$PC_DIR" 2>/dev/null

# Per-release granularity: one file per `## vN` (NOT per `### vN.M`).
[[ -f "$PC_DIR/v11.md" ]] && t_pass "10.1 v11.md exists (per-release)" || t_fail "10.1 v11.md exists (per-release)"
[[ -f "$PC_DIR/v7.md" ]] && t_pass "10.2 v7.md exists (H2-only release preserved)" || t_fail "10.2 v7.md exists (H2-only release preserved)"
# No per-point-release files under the new granularity.
[[ -f "$PC_DIR/v11.0.md" ]] && t_fail "10.2b no per-point-release v11.0.md" "should not exist under per-release granularity" \
    || t_pass "10.2b no per-point-release v11.0.md (per-release granularity)"

# Verify back-pointer + first-header invariant (the H2 line is the
# byte-identical span anchor for the release file).
LINE1_V11=$(head -n 1 "$PC_DIR/v11.md")
assert_eq "10.3 v11.md line 1 is back-pointer" \
    '<!-- per-entry source: /changelog/v11.md; contract: /changelog/_rules.md -->' \
    "$LINE1_V11"

# Nested subsections preserved verbatim inside the release entry.
V11_BODY=$(cat "$PC_DIR/v11.md")
assert_contains "10.3a v11.md preserves nested '### v11.0' subsection" "$V11_BODY" "### v11.0 — Initial v11 release"
assert_contains "10.3b v11.md preserves nested '### New' subsection" "$V11_BODY" "### New"

# TOC regeneration coverage for changelog (groups by major version).
per_entry_regenerate_toc pack-changelog "$PC_DIR" 2>/dev/null
PC_TOC=$(cat "$PC_DIR/_toc.md")
assert_contains "10.4 changelog _toc.md groups by major version v11" "$PC_TOC" "## v11"
assert_contains "10.5 changelog _toc.md links v11 release entry" "$PC_TOC" "[v11](./v11.md)"
assert_contains "10.6 changelog _toc.md links v7 release entry" "$PC_TOC" "[v7](./v7.md)"

# ─────────────────────────────────────────────────────────────────
# Group 11: bash 3.2 compatibility smoke
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 11: bash 3.2 compatibility smoke ===\n"

# bash --norc -c "source helper" should succeed without unbound-var
# errors (we don't use `set -u` in the helpers because some shared
# patterns rely on parameter-existence checks).
SMOKE_RC=0
bash --norc -c ". $LIB_DIR/_lib.sh && . $LIB_DIR/decompose.sh && . $LIB_DIR/mirror-generate.sh && . $LIB_DIR/toc-regenerate.sh" 2>/dev/null || SMOKE_RC=$?
if [[ "$SMOKE_RC" -eq 0 ]]; then t_pass "11.1 helpers source cleanly under bash --norc"
else t_fail "11.1 helpers source cleanly under bash --norc" "rc=$SMOKE_RC"; fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "PASS: %d\n" "$PASS"
printf "FAIL: %d\n" "$FAIL"

if [[ "$FAIL" -eq 0 ]]; then
    printf "\nAll per-entry tests PASSED (%d/%d).\n" "$PASS" "$((PASS+FAIL))"
    exit 0
else
    printf "\n%d/%d per-entry tests FAILED.\n" "$FAIL" "$((PASS+FAIL))"
    exit 1
fi
