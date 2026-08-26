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
#  13. Walker total-routing repairs (BD-291): fence-first classification,
#      PE_DECOMPOSE_DROPPED capture sink (truncate-at-start, provenance
#      delimiters), H1-break class.
#  14. project-changelog whole-suffix naming + fail-loud guards (BD-291):
#      mandatory-slug id model, duplicate-id guard, bare-date guard,
#      written-count integrity.
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
SCRATCH_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/per-entry-tests.XXXXXX")
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
TMP_DIR1=$(mktemp -d "${TMPDIR:-/tmp}/pe-pathlookup.XXXXXX")
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
TMP_BP=$(mktemp "${TMPDIR:-/tmp}/pe-bp.XXXXXX")
{
    echo '<!-- per-entry source: /backlog/BD-100.md; contract: /backlog/_rules.md -->'
    echo '**BD-100 — Sample**'
    echo 'Type: TODO(version)'
} >"$TMP_BP"
STRIPPED=$(pe_strip_backpointer_stdin <"$TMP_BP")
assert_eq "2.3 strip removes line-1 back-pointer" "**BD-100 — Sample**
Type: TODO(version)" "$STRIPPED"
# Strip on a file WITHOUT a back-pointer is a no-op.
TMP_BP2=$(mktemp "${TMPDIR:-/tmp}/pe-bp2.XXXXXX")
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

# Subshell wraps (this and every per_entry_regenerate_toc call below):
# the helper manages a private EXIT trap for its temp file (trap … EXIT,
# then trap - EXIT), which would clobber this script's SCRATCH_ROOT
# cleanup trap if run in the current shell — leaking the scratch tree
# on every normal exit.
( per_entry_regenerate_toc pack-backlog "$PB_DIR" 2>/dev/null )
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
( per_entry_regenerate_toc pack-backlog "$PB_DIR" 2>/dev/null )
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
( per_entry_regenerate_toc pack-changelog "$PC_DIR" 2>/dev/null )
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
# Group 12: project-groupings stream tuple + TOC axis (BD-262)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 12: project-groupings tuple + TOC axis (BD-262) ===\n"

# Tuple: TIGHTENED entry regex (exactly 3 digits zero-padded through
# GRP-999, unpadded 4+ from GRP-1000 — GRP-0000 is killed); shipped-2
# support set + generated _toc.md (NO _kinds.md, NO _index.md);
# dir-suffix resolution; project-relative back-pointer.
assert_eq "12.1 project-groupings entry regex (tightened)" \
    '^GRP-([0-9]{3}|[1-9][0-9]{3,})\.md$' \
    "$(pe_entry_regex_for_stream project-groupings)"
assert_eq "12.2 project-groupings support set (no _kinds.md, no _index.md)" \
    "_rules.md _intro.md _toc.md" \
    "$(pe_supporting_files_known_for_stream project-groupings)"
assert_eq "12.3 project-groupings dir-suffix" \
    "docs/project/groupings" \
    "$(pe_dir_suffix_for_stream project-groupings)"
TMP_GRP_PATH=$(mktemp -d "${TMPDIR:-/tmp}/pe-grp-path.XXXXXX")
mkdir -p "$TMP_GRP_PATH/docs/project/groupings"
assert_eq "12.4 pe_stream_for_path resolves docs/project/groupings" \
    "project-groupings" \
    "$(pe_stream_for_path "$TMP_GRP_PATH/docs/project/groupings")"
rm -rf "$TMP_GRP_PATH"
assert_eq "12.5 project-groupings back-pointer line shape (project-relative)" \
    '<!-- per-entry source: docs/project/groupings/GRP-001.md; contract: docs/project/groupings/_rules.md -->' \
    "$(pe_backpointer_line project-groupings GRP-001)"

# Regex kill/admit via pe_list_entry_files: GRP-0000 skipped, GRP-1000
# admitted, sidecars skipped.
GRP_DIR="$SCRATCH_ROOT/groupings-toc"
mkdir -p "$GRP_DIR"
write_grp_fixture() {
    # $1=NNN $2=kind $3=title $4=members-value
    {
        printf '<!-- per-entry source: docs/project/groupings/GRP-%s.md; contract: docs/project/groupings/_rules.md -->\n' "$1"
        printf '**GRP-%s — %s**\n' "$1" "$3"
        printf 'Entry-Type: grouping\n'
        printf 'Kind: %s\n' "$2"
        printf 'Member-phases: %s\n' "$4"
    } >"$GRP_DIR/GRP-${1}.md"
}
write_grp_fixture 000 unassigned "Ungrouped (declared)" "phase-9"
write_grp_fixture 001 user-journey "Auth flows" "phase-1, phase-2"
write_grp_fixture 002 refactor-cluster "Split the parser" "phase-3"
write_grp_fixture 003 user-journey "Onboarding" "phase-4, phase-5, phase-6"
write_grp_fixture 1000 user-journey "Scale test" "phase-7, phase-8"
write_grp_fixture 0000 bug-fix "Masquerade" "phase-1"
cat >"$GRP_DIR/_rules.md" <<'EOF'
# Per-stream contract — project-groupings (fixture)

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
EOF
LISTED=$(pe_list_entry_files project-groupings "$GRP_DIR" | xargs -n1 basename 2>/dev/null | tr '\n' ' ')
assert_contains "12.6 pe_list_entry_files admits GRP-1000.md" "$LISTED" "GRP-1000.md"
assert_eq "12.7 pe_list_entry_files kills GRP-0000.md (tightened regex)" \
    "no" "$(printf '%s' "$LISTED" | grep -q 'GRP-0000.md' && echo yes || echo no)"

# TOC axis: Kind-grouped (alphabetical by slug), IDs ascending within
# each group; the pinned row grammar `- GRP-NNN — <Title> (phases: N)`;
# byte-exact golden; determinism ×2.
( per_entry_regenerate_toc project-groupings "$GRP_DIR" 2>/dev/null )
[[ -f "$GRP_DIR/_toc.md" ]] && t_pass "12.8 groupings _toc.md created" || t_fail "12.8 groupings _toc.md created"
cat >"$SCRATCH_ROOT/grp-toc-expected.md" <<'EOF'
# Table of contents — project-groupings

<!-- generated by scripts/lib/per-entry/toc-regenerate.sh — DO NOT EDIT BY HAND -->

## refactor-cluster

- GRP-002 — Split the parser (phases: 1)

## unassigned

- GRP-000 — Ungrouped (declared) (phases: 1)

## user-journey

- GRP-001 — Auth flows (phases: 2)
- GRP-003 — Onboarding (phases: 3)
- GRP-1000 — Scale test (phases: 2)
EOF
assert_byte_identical "12.9 groupings _toc.md byte-exact golden (Kind groups alphabetical; IDs ascending; pinned row grammar; GRP-0000 absent)" \
    "$SCRATCH_ROOT/grp-toc-expected.md" "$GRP_DIR/_toc.md"
cp "$GRP_DIR/_toc.md" "$SCRATCH_ROOT/grp-toc.snap1"
( per_entry_regenerate_toc project-groupings "$GRP_DIR" 2>/dev/null )
assert_byte_identical "12.10 groupings TOC regeneration is byte-deterministic" \
    "$SCRATCH_ROOT/grp-toc.snap1" "$GRP_DIR/_toc.md"
# Mangle the derived index; regeneration restores the canonical bytes.
printf 'HAND-EDITED JUNK\n' >"$GRP_DIR/_toc.md"
( per_entry_regenerate_toc project-groupings "$GRP_DIR" 2>/dev/null )
assert_byte_identical "12.10b mangled _toc.md is restored to canonical bytes on regen" \
    "$SCRATCH_ROOT/grp-toc-expected.md" "$GRP_DIR/_toc.md"

# Empty tree seeds the BD-164 empty form.
GRP_EMPTY="$SCRATCH_ROOT/groupings-empty"
mkdir -p "$GRP_EMPTY"
( per_entry_regenerate_toc project-groupings "$GRP_EMPTY" 2>/dev/null )
cat >"$SCRATCH_ROOT/grp-toc-empty-expected.md" <<'EOF'
# Table of contents — project-groupings

<!-- generated by scripts/lib/per-entry/toc-regenerate.sh — DO NOT EDIT BY HAND -->

(empty — no entries)
EOF
assert_byte_identical "12.11 empty groupings tree seeds '(empty — no entries)' _toc.md" \
    "$SCRATCH_ROOT/grp-toc-empty-expected.md" "$GRP_EMPTY/_toc.md"

# ─────────────────────────────────────────────────────────────────
# Group 13: walker total-routing repairs (BD-291) — fence state,
# dropped-content capture, H1-break
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 13: walker fence / capture / H1-break (BD-291) ===\n"

# Hazard fixture: fence carrying `## ` + `# ` lines inside an entry
# body; a mid-file `# Milestone`-style H1 divider; a trailing non-entry
# `## ` section; a pre-first-anchor preamble.
W13_ROOT="$SCRATCH_ROOT/walker-hazards"
W13_DIR="$W13_ROOT/backlog"
mkdir -p "$W13_DIR"
cat >"$W13_ROOT/BACKLOG.md" <<'EOF'
# Backlog

Preamble line one.

**BD-201 — Fence carrier**
Type: TODO(version)
Status: Open
Description: carries a fence.
```
## fenced H2 stays in-span
# fenced comment stays too
```
Tail line after fence.

**BD-202 — Second entry**
Type: TODO(version)
Status: Open

# Milestone divider
Milestone context line.

**BD-203 — Third entry**
Type: TODO(version)
Status: Open

## Deferred section
Deferred context line.
EOF

W13_CAP="$W13_ROOT/dropped.md"
PE_DECOMPOSE_DROPPED="$W13_CAP" per_entry_decompose pack-backlog "$W13_ROOT/BACKLOG.md" "$W13_DIR" 2>/dev/null

# Case 1: fenced `## ` inside an entry body stays in-span.
BD201_BODY=$(cat "$W13_DIR/BD-201.md")
assert_contains "13.1 fenced '## ' line stays in-span" "$BD201_BODY" "## fenced H2 stays in-span"

# Case 2: fenced `# ` (shell-comment shape) stays in-span — never an
# H1 break; the entry continues past the fence.
assert_contains "13.2a fenced '# ' line stays in-span" "$BD201_BODY" "# fenced comment stays too"
assert_contains "13.2b entry continues past the closing fence" "$BD201_BODY" "Tail line after fence."

# Case 3: capture receives preamble + H1 block + section-break block,
# verbatim, with exact `<!-- v10 monolith lines A–B -->` delimiters.
cat >"$SCRATCH_ROOT/w13-capture-expected.md" <<'EOF'
<!-- v10 monolith lines 1–4 -->
# Backlog

Preamble line one.

<!-- v10 monolith lines 19–21 -->
# Milestone divider
Milestone context line.

<!-- v10 monolith lines 26–27 -->
## Deferred section
Deferred context line.
EOF
assert_byte_identical "13.3 capture content + delimiters byte-exact" \
    "$SCRATCH_ROOT/w13-capture-expected.md" "$W13_CAP"

# Case 4: re-running decompose truncates-then-rewrites the capture
# (byte-identical after 2 runs — no double-append).
cp "$W13_CAP" "$SCRATCH_ROOT/w13-capture.snap1"
PE_DECOMPOSE_DROPPED="$W13_CAP" per_entry_decompose pack-backlog "$W13_ROOT/BACKLOG.md" "$W13_DIR" 2>/dev/null
assert_byte_identical "13.4 re-run truncates-then-rewrites the capture (no double-append)" \
    "$SCRATCH_ROOT/w13-capture.snap1" "$W13_CAP"

# Case 5: PE_DECOMPOSE_DROPPED unset — legacy ignore semantics; the
# entry tree is byte-identical to the env-set run's (the capture sink
# never perturbs routing) and no capture file is created. (Groups 9/10
# pin the legacy fixtures' unset-env behavior.)
W13_UNSET_DIR="$W13_ROOT/backlog-unset"
mkdir -p "$W13_UNSET_DIR"
per_entry_decompose pack-backlog "$W13_ROOT/BACKLOG.md" "$W13_UNSET_DIR" 2>/dev/null
assert_byte_identical "13.5a unset-env BD-201.md byte-identical" "$W13_DIR/BD-201.md" "$W13_UNSET_DIR/BD-201.md"
assert_byte_identical "13.5b unset-env BD-202.md byte-identical" "$W13_DIR/BD-202.md" "$W13_UNSET_DIR/BD-202.md"
assert_byte_identical "13.5c unset-env BD-203.md byte-identical" "$W13_DIR/BD-203.md" "$W13_UNSET_DIR/BD-203.md"
UNSET_COUNT=$(ls "$W13_UNSET_DIR" | wc -l | tr -d ' ')
assert_eq "13.5d unset-env run creates no capture file (3 entry files only)" "3" "$UNSET_COUNT"

# Case 6: H1-break — the mid-file H1 closes the open entry; the entry
# file excludes it; the capture includes it.
BD202_BODY=$(cat "$W13_DIR/BD-202.md")
assert_eq "13.6a BD-202.md excludes the H1 divider" \
    "no" "$(printf '%s' "$BD202_BODY" | grep -q '# Milestone divider' && echo yes || echo no)"
assert_eq "13.6b BD-202.md excludes the post-H1 context line" \
    "no" "$(printf '%s' "$BD202_BODY" | grep -q 'Milestone context line.' && echo yes || echo no)"
W13_CAP_BODY=$(cat "$W13_CAP")
assert_contains "13.6c capture includes the H1 divider" "$W13_CAP_BODY" "# Milestone divider"

# ─────────────────────────────────────────────────────────────────
# Group 14: project-changelog whole-suffix naming + fail-loud guards
# (BD-291)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 14: project-changelog whole-suffix naming + fail-louds (BD-291) ===\n"

# Case 7: whole-suffix naming — a same-date same-phase pair with
# distinct suffixes yields TWO files (the collision shape), and a
# one-em-dash suffix slugifies whole.
W14_ROOT="$SCRATCH_ROOT/changelog-naming"
W14_DIR="$W14_ROOT/docs/project/changelog"
mkdir -p "$W14_DIR"
cat >"$W14_ROOT/CHANGELOG.md" <<'EOF'
# Changelog

### 2026-05-01 — Phase 1 — Alpha
- alpha bullet.

### 2026-05-01 — Phase 1 — Beta
- beta bullet.

### 2026-06-15 — Phase 1 milestone
- milestone bullet.
EOF
W14_ERR=$(per_entry_decompose project-changelog "$W14_ROOT/CHANGELOG.md" "$W14_DIR" 2>&1 >/dev/null)
[[ -f "$W14_DIR/2026-05-01-phase-1-alpha.md" ]] \
    && t_pass "14.1a same-date pair file 1 (2026-05-01-phase-1-alpha.md)" \
    || t_fail "14.1a same-date pair file 1 (2026-05-01-phase-1-alpha.md)"
[[ -f "$W14_DIR/2026-05-01-phase-1-beta.md" ]] \
    && t_pass "14.1b same-date pair file 2 (2026-05-01-phase-1-beta.md)" \
    || t_fail "14.1b same-date pair file 2 (2026-05-01-phase-1-beta.md)"
assert_contains "14.1c alpha entry carries its own body" "$(cat "$W14_DIR/2026-05-01-phase-1-alpha.md" 2>/dev/null)" "- alpha bullet."
assert_contains "14.1d beta entry carries its own body" "$(cat "$W14_DIR/2026-05-01-phase-1-beta.md" 2>/dev/null)" "- beta bullet."
[[ -f "$W14_DIR/2026-06-15-phase-1-milestone.md" ]] \
    && t_pass "14.2 one-em-dash suffix slugifies whole (2026-06-15-phase-1-milestone.md)" \
    || t_fail "14.2 one-em-dash suffix slugifies whole (2026-06-15-phase-1-milestone.md)"

# Case 10: written-count integrity — the summary's "wrote N" equals the
# number of entry files on disk.
WROTE_N=$(printf '%s\n' "$W14_ERR" | sed -n 's/^per-entry decompose: wrote \([0-9]*\) entry file(s).*/\1/p')
DISK_N=$(ls "$W14_DIR" | wc -l | tr -d ' ')
assert_eq "14.3 'wrote N' summary equals files on disk" "$DISK_N" "$WROTE_N"

# Case 8: identical-heading pair → fail-loud naming BOTH monolith
# lines; no partial write of the colliding entry.
W14_DUP_ROOT="$SCRATCH_ROOT/changelog-dup"
W14_DUP_DIR="$W14_DUP_ROOT/docs/project/changelog"
mkdir -p "$W14_DUP_DIR"
cat >"$W14_DUP_ROOT/CHANGELOG.md" <<'EOF'
### 2026-07-01 — Phase 2 — Gamma
- gamma one.
### 2026-07-01 — Phase 2 — Gamma
- gamma two.
EOF
DUP_RC=0
DUP_OUT=$(per_entry_decompose project-changelog "$W14_DUP_ROOT/CHANGELOG.md" "$W14_DUP_DIR" 2>&1) || DUP_RC=$?
assert_eq "14.4a duplicate full heading fails loud (non-zero rc)" "no" \
    "$([[ "$DUP_RC" -eq 0 ]] && echo yes || echo no)"
assert_contains "14.4b failure names both monolith lines" "$DUP_OUT" "monolith lines 1 and 3"
assert_contains "14.4c failure carries the authoring instruction" "$DUP_OUT" "extend the newer heading"
[[ -f "$W14_DUP_DIR/2026-07-01-phase-2-gamma.md" ]] \
    && t_fail "14.4d no partial write of the colliding entry" "file exists" \
    || t_pass "14.4d no partial write of the colliding entry"

# Case 9: bare-date anchor (no ` — <suffix>`) → fail-loud naming the
# line. Bites the guard WIRING: the strict anchor regex cannot see a
# bare `### YYYY-MM-DD` line (and `^## ` cannot either), so only the
# independent date-prefix classification can catch it.
W14_BARE_ROOT="$SCRATCH_ROOT/changelog-bare"
W14_BARE_DIR="$W14_BARE_ROOT/docs/project/changelog"
mkdir -p "$W14_BARE_DIR"
cat >"$W14_BARE_ROOT/CHANGELOG.md" <<'EOF'
### 2026-08-01 — Phase 3 — Delta
- delta bullet.
### 2026-08-09
- orphan bullet.
EOF
BARE_RC=0
BARE_OUT=$(per_entry_decompose project-changelog "$W14_BARE_ROOT/CHANGELOG.md" "$W14_BARE_DIR" 2>&1) || BARE_RC=$?
assert_eq "14.5a bare-date heading fails loud (non-zero rc)" "no" \
    "$([[ "$BARE_RC" -eq 0 ]] && echo yes || echo no)"
assert_contains "14.5b failure names the monolith line" "$BARE_OUT" "monolith line 3"
assert_contains "14.5c failure states the mandatory-slug contract" "$BARE_OUT" "mandatory slug"

# Empty-slug variant of the same guard: a suffix that slugifies to
# nothing is as fail-loud as a bare date.
W14_EMPTY_ROOT="$SCRATCH_ROOT/changelog-emptyslug"
W14_EMPTY_DIR="$W14_EMPTY_ROOT/docs/project/changelog"
mkdir -p "$W14_EMPTY_DIR"
cat >"$W14_EMPTY_ROOT/CHANGELOG.md" <<'EOF'
### 2026-08-01 — Phase 3 — Delta
- delta bullet.
### 2026-08-09 — !!!
- orphan bullet.
EOF
EMPTY_RC=0
EMPTY_OUT=$(per_entry_decompose project-changelog "$W14_EMPTY_ROOT/CHANGELOG.md" "$W14_EMPTY_DIR" 2>&1) || EMPTY_RC=$?
assert_eq "14.6a empty-slug suffix fails loud (non-zero rc)" "no" \
    "$([[ "$EMPTY_RC" -eq 0 ]] && echo yes || echo no)"
assert_contains "14.6b failure names the monolith line" "$EMPTY_OUT" "monolith line 3"

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
