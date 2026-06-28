#!/usr/bin/env bash
# scripts/tests/test-per-entry.sh — test suite for the BD-164 per-entry
# split helpers (scripts/lib/per-entry/).
#
# Test cases (per integration parent §18.2 #1):
#   1. Stream-shape lookups: entry-regex / supporting-file / dir-suffix
#      accessors per stream (sanity).
#   2. Back-pointer add/strip: line-1 HTML comment composed by
#      pe_backpointer_line, stripped by pe_strip_backpointer_stdin
#      (preserves byte-additive invariant).
#   9. TOC regeneration: decompose a pack-backlog tree, then regenerate
#      its `_toc.md` (status-grouped, links, deterministic).
#  10. pack-changelog per-release decompose + TOC (BD-203 CHANGE 2):
#      per-RELEASE granularity, nested subsections preserved.
#  11. Bash 3.2 compatibility smoke: helpers source cleanly under
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
. "$LIB_DIR/toc-regenerate.sh"

# Track per-test scratch dirs for cleanup.
SCRATCH_ROOT=$(mktemp -d -t per-entry-tests.XXXXXX)
trap 'rm -rf "$SCRATCH_ROOT"' EXIT INT TERM

# ─────────────────────────────────────────────────────────────────
# Fixture helpers
# ─────────────────────────────────────────────────────────────────

# Build a synthetic pack-backlog mirror (3 entries + intro).
# BD-203 B8: no trailing v8 archive — `_v8-resolved-archive.md` is
# retired from the pack-backlog stream (the 19 v8 table rows are now
# real entries), so the round-trip fixture exercises entries + intro
# only.
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
Blockers: BD-101
Unblocks: None
File/Symbol: n/a
Description: Deferred to a later version.
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

# (BD-203 B8) The synthetic `_v8-resolved-archive.md` fixture builder is
# RETIRED — `_v8-resolved-archive.md` is no longer a pack-backlog
# supporting file (the 19 v8 summary-table rows are now real `BD-00N.md`
# entries after the pre-normalize step).

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

# No-mirror model: neither the pack nor the project monoliths exist; the
# per-entry tree + `_toc.md` is the SOLE SSOT. There are no `mirror)`
# stream constants and no canonical-mirror accessor — the lookup surface
# is the entry-regex / supporting-file / dir-suffix accessors below.
# BD-211: pack-backlog entry regex is canonical `BD-NNN.md` (no suffix).
assert_eq "1.6 pack-backlog entry regex"  "^BD-[0-9]+\.md$" "$(pe_entry_regex_for_stream pack-backlog)"
assert_eq "1.7 project-backlog entry regex" "^TD-[0-9]+\.md$" "$(pe_entry_regex_for_stream project-backlog)"
# BD-203 B8: the pack-backlog stream NO LONGER carries
# `_v8-resolved-archive.md` — the 19 v8 summary-table rows (BD-001..019)
# are now real `BD-00N.md` entries (pre-normalize Commit 1), so the
# archive supporting file is retired from the pack-backlog support set.
assert_eq "1.8 pack-backlog known supporting EXCLUDES _v8-resolved-archive.md (BD-203 B8)" \
    "no" "$(pe_supporting_files_known_for_stream pack-backlog | grep -q '_v8-resolved-archive.md' && echo yes || echo no)"
# BD-206: `_format.md` is FORBIDDEN — its content folds into the changelog
# `_rules.md` schema section, so it is no longer a supporting file.
assert_eq "1.9 project-changelog known supporting EXCLUDES _format.md (BD-206)" \
    "no" "$(pe_supporting_files_known_for_stream project-changelog | grep -q '_format.md' && echo yes || echo no)"
# BD-206: `_index.md` (the generated ordering sidecar) is ADMITTED for the
# project-implementation-plan stream (MUST-4).
assert_eq "1.9b project-implementation-plan known supporting INCLUDES _index.md (BD-206)" \
    "yes" "$(pe_supporting_files_known_for_stream project-implementation-plan | grep -q '_index.md' && echo yes || echo no)"

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
# Group 9: TOC regeneration
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 9: TOC regeneration ===\n"

# Build a decompose-populated pack-backlog tree (the TOC input). The
# `fixture_pack_backlog_mirror` heredoc is a `cat`-style input fixture
# (NOT a generated mirror); decompose splits it into per-entry files.
PB_ROOT="$SCRATCH_ROOT/pack-backlog-toc"
PB_DIR="$PB_ROOT/backlog"
mkdir -p "$PB_DIR"
fixture_pack_backlog_mirror "$PB_ROOT/BACKLOG.md"
fixture_pack_backlog_intro "$PB_DIR/_intro.md"
fixture_pack_backlog_rules "$PB_DIR/_rules.md"
per_entry_decompose pack-backlog "$PB_ROOT/BACKLOG.md" "$PB_DIR" 2>/dev/null

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
bash --norc -c ". $LIB_DIR/_lib.sh && . $LIB_DIR/decompose.sh && . $LIB_DIR/toc-regenerate.sh" 2>/dev/null || SMOKE_RC=$?
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
