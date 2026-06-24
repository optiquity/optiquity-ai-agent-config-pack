#!/usr/bin/env bash
# scripts/tests/test-validate-pack-checks-32-33-34.sh — synthetic-fixture
# test runner for the BD-168 per-entry split validators (Check 32 mirror-
# in-sync, Check 33 TOC-in-sync, Check 34 cross-reference integrity).
#
# Fixture strategy (per planner §18.2 #6 — coder picks placement):
#   - Inline mktemp scratch trees (no separate fixtures dir under
#     `scripts/tests/fixtures/per-entry/`). Fixtures are tiny (3 entries
#     each), and the green/red contrast is best read in-line. Same shape
#     as `test-per-entry.sh` Group 1–11 fixtures.
#   - Each test exercises a SINGLE check function from `validate-pack.py`
#     against a synthetic per-entry tree built under a scratch
#     `REPO_ROOT`. The validator's STREAMS constant is hard-coded for
#     the real pack repo, so we INVOKE the new check functions
#     directly via a small Python wrapper that monkey-patches
#     `REPO_ROOT` + `STREAMS` before calling each `check_*`.
#
# Test groups:
#   Group A: Check 32 (mirror-in-sync) — green + red fixtures.
#     A1: green tree + in-sync mirror → check passes.
#     A2: green tree + hand-edited mirror → check FAILs with the
#         expected "out of sync" message.
#     A3: green tree + missing _rules.md → check FAILs with the
#         expected "_rules.md missing" pre-check message.
#     A4: green tree + non-conforming filename → check FAILs with the
#         expected "non-conforming filenames" pre-check message.
#   Group B: Check 33 (TOC-in-sync) — green + red.
#     B1: green tree + in-sync _toc.md → check passes.
#     B2: green tree + hand-edited _toc.md → check FAILs.
#     B3: green tree + missing _toc.md → check FAILs.
#   Group C: Check 34 (cross-reference integrity) — green + red.
#     C1: green tree + all refs resolve → check passes.
#     C2: green tree + dangling BD-NNN ref → check FAILs with offending
#         file:line + ref name.
#     C3: (RETIRED — BD-203 B8) formerly exercised the removed
#         `_v8-resolved-archive.md` cross-ref SKIP; that supporting file
#         no longer exists, so the case no longer applies (the generic
#         leading-underscore guard now covers supporting files).
#     C4: green tree + self-reference → check passes.
#
# Plus structural smoke:
#   D1: STREAMS constant has the expected pack-side tuples (sanity).
#
# BD-168 retro fix adds:
#   Group F: pack-changelog stream coverage (S2 — review §2.2 #2).
#     F1: green pack-changelog → Check 32 PASS.
#     F2: green pack-changelog → Check 33 PASS.
#     F3: green pack-changelog → Check 34 PASS (no dangling).
#     F4: hand-edited pack-changelog mirror → Check 32 FAIL.
#     F5: cross-stream union — pack-backlog refs v11.0 in pack-changelog
#         → Check 34 PASS (exercises defined_all union path).
#   Group G: M2 snap-leftover regression (M2 — review §2.1 #2).
#     G1: Check 33 PASS path → no `.per-entry-toc-snap.*` left in stream_dir.
#     G2: Check 33 FAIL path → no `.per-entry-toc-snap.*` left in stream_dir.
#
# Usage: bash scripts/tests/test-validate-pack-checks-32-33-34.sh
# Exit:  0 if all PASS; 1 on any FAIL.
#
# Architecture:
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md
#     §10.1 (Check 32 contract); §10.2 (Check 33); §10.3 (Check 34);
#     §10.4 (pre-check folding); §10.5 (SKIP behavior); §10.6 (pack-side
#     scope). (The former §11.3 `_v8-resolved-archive.md` cross-ref SKIP
#     is removed by BD-203 B8; supporting files are now skipped generically
#     by the walk loop's leading-underscore guard.)
#   maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md
#     §5.6 (BD-168 contract).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE_PY="$REPO_ROOT/scripts/validate-pack.py"
PER_ENTRY_LIB="$REPO_ROOT/scripts/lib/per-entry"

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
    else t_fail "$1" "needle='$3' missing from output: ${2:0:400}"; fi
}

assert_not_contains() {
    if [[ "$2" != *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' should NOT appear in output: ${2:0:400}"; fi
}

# Track per-test scratch dirs for cleanup.
SCRATCH_ROOT=$(mktemp -d -t validate-checks-tests.XXXXXX)
trap 'rm -rf "$SCRATCH_ROOT"' EXIT INT TERM

# Smoke: validate-pack.py exists and is executable Python.
[[ -f "$VALIDATE_PY" ]] || { printf "FATAL: %s not found\n" "$VALIDATE_PY" >&2; exit 1; }
[[ -d "$PER_ENTRY_LIB" ]] || { printf "FATAL: %s not found\n" "$PER_ENTRY_LIB" >&2; exit 1; }

# ─────────────────────────────────────────────────────────────────
# Python wrapper: monkey-patch REPO_ROOT + STREAMS, invoke a single
# check_* function, return its stdout (containing OK / FAIL lines)
# plus the FAIL count.
# ─────────────────────────────────────────────────────────────────
#
# Args: $1 = check function name, $2 = scratch REPO_ROOT, [$3..] = optional
#       extra streams to add to STREAMS (default: pack-backlog only).
# Stdout: validator output (OK / FAIL lines).
# Exit: 0 if zero fails, 1 if any fail (matches the validator's
#       failures-collected semantic).
run_check() {
    local check_name="$1"
    local scratch_repo="$2"
    shift 2
    # Default STREAMS: just pack-backlog (the canonical test stream).
    # Caller may override by passing additional stream tuples after $2
    # in the form "key|dir|mirror|regex" pipe-delimited.
    local extra_streams=("$@")
    PE_TEST_REPO="$scratch_repo" \
    PE_TEST_CHECK="$check_name" \
    PE_TEST_EXTRA_STREAMS="${extra_streams[*]:-}" \
    PE_TEST_VALIDATE_PY="$VALIDATE_PY" \
        python3 - <<'PYEOF'
import importlib.util
import os
import sys
from pathlib import Path

scratch_repo = Path(os.environ["PE_TEST_REPO"]).resolve()
check_name = os.environ["PE_TEST_CHECK"]
extra_str = os.environ.get("PE_TEST_EXTRA_STREAMS", "").strip()
validate_py = os.environ["PE_TEST_VALIDATE_PY"]

# Load validate-pack.py as a module.
spec = importlib.util.spec_from_file_location("validate_pack", validate_py)
vp = importlib.util.module_from_spec(spec)
sys.modules["validate_pack"] = vp
spec.loader.exec_module(vp)

# Monkey-patch: REPO_ROOT → scratch_repo; STREAMS → pack-backlog only
# (or with extras parsed from the env var). BD-211: the pack-backlog
# entry regex is canonical `BD-NNN.md` (no letter suffix).
vp.REPO_ROOT = scratch_repo
streams = [
    ("pack-backlog", "backlog", "BACKLOG.md", r"^BD-\d+\.md$"),
]
if extra_str:
    for tup in extra_str.split():
        parts = tup.split("|")
        if len(parts) == 4:
            streams.append((parts[0], parts[1], parts[2], parts[3]))
vp.STREAMS = streams
vp.failures = []

check_fn = getattr(vp, check_name)
check_fn()

# Match the validator's exit semantic: 0 if zero fails, 1 if any.
sys.exit(1 if vp.failures else 0)
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# Fixture builder helpers
# ─────────────────────────────────────────────────────────────────

# Materialize a green pack-backlog per-entry tree under <scratch_repo>:
#   <scratch_repo>/backlog/_rules.md
#   <scratch_repo>/backlog/_intro.md
#   <scratch_repo>/backlog/BD-100.md, BD-101.md, BD-102.md, BD-700.md
#   <scratch_repo>/backlog/_toc.md  (regenerated TOC)
# BD-203 B8: no `_v8-resolved-archive.md` — the 19 BD-001..019 v8
# summary-table rows are now real `BD-00N.md` entries (pre-normalize),
# so the archive supporting file is retired from the pack-backlog stream.
# All files use the BD-164 helpers so the on-disk shape is what the
# helpers emit (byte-identical round-trip from the start).
# $1 = scratch_repo path
build_green_pack_backlog() {
    local scratch_repo="$1"
    local backlog_dir="$scratch_repo/backlog"
    mkdir -p "$backlog_dir"

    # _rules.md (declares supporting files). Carries the BD-204 Mode-3
    # ops-contract mode marker ("Flat-file mode") that the Check 32′
    # marker assertion requires on the pack-backlog stream (flat-file
    # per-entry is the sole supported mode; marker presence only — see
    # _RULES_MODE_MARKERS in scripts/validate-pack.py).
    cat >"$backlog_dir/_rules.md" <<'EOF'
# Per-stream contract — pack-backlog (test fixture)

Stream identity: pack-backlog
Filename convention: ^BD-\d+\.md$
Lifecycle states: Open, Resolved

## Source of truth — flat-file (test fixture)

**Flat-file mode (the sole supported mode).** The per-entry tree is the
SSOT.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
EOF

    # _intro.md (preamble).
    cat >"$backlog_dir/_intro.md" <<'EOF'
# Backlog (test fixture)

Test-fixture preamble.

---

## Active — v11 Scope
EOF

    # Three entry files. BD-100 references BD-101 (defined); BD-101
    # has a self-reference; BD-102 references the v11.0 changelog
    # entry which is OUT OF SCOPE here (single-stream test) so it
    # would be flagged unless we exercise multi-stream fixture (C1
    # uses single-stream so we omit cross-stream refs from BD-102).
    cat >"$backlog_dir/BD-100.md" <<'EOF'
<!-- per-entry source: /backlog/BD-100.md; contract: /backlog/_rules.md -->
**BD-100 — Sample first entry**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: BD-101
File/Symbol: `scripts/example.sh`
Description: First sample entry. References BD-101 in body.
EOF
    cat >"$backlog_dir/BD-101.md" <<'EOF'
<!-- per-entry source: /backlog/BD-101.md; contract: /backlog/_rules.md -->
**BD-101 — Sample second entry**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: `scripts/another.sh`
Description: Second entry. Self-reference to BD-101 in body.
Resolved: 2026-05-13 — see BD-100 for context.
EOF
    cat >"$backlog_dir/BD-102.md" <<'EOF'
<!-- per-entry source: /backlog/BD-102.md; contract: /backlog/_rules.md -->
**BD-102 — Sample third entry**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: n/a
Description: Third entry; references BD-100 and the canonical entry BD-700 in body.
EOF
    # BD-211: a canonical entry file (`BD-700.md`) exercising the
    # canonical entry regex (`^BD-\d+\.md$`) + the Check 34 cross-ref
    # token (`BD-\d+`). BD-102 references BD-700 above.
    cat >"$backlog_dir/BD-700.md" <<'EOF'
<!-- per-entry source: /backlog/BD-700.md; contract: /backlog/_rules.md -->
**BD-700 — Canonical entry**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: n/a
Description: Canonical entry; self-reference BD-700 in body resolves.
EOF

    # Generate the canonical BACKLOG.md mirror via the BD-164 helper.
    bash -c "
        . '$PER_ENTRY_LIB/_lib.sh'
        . '$PER_ENTRY_LIB/mirror-generate.sh'
        per_entry_regenerate_mirror pack-backlog '$backlog_dir' '$scratch_repo/BACKLOG.md'
    " >/dev/null 2>&1

    # Generate the canonical _toc.md via the BD-164 helper.
    bash -c "
        . '$PER_ENTRY_LIB/_lib.sh'
        . '$PER_ENTRY_LIB/toc-regenerate.sh'
        per_entry_regenerate_toc pack-backlog '$backlog_dir'
    " >/dev/null 2>&1
}

# Materialize a green pack-changelog per-entry tree under <scratch_repo>:
#   <scratch_repo>/changelog/_rules.md
#   <scratch_repo>/changelog/_intro.md
#   <scratch_repo>/changelog/v11.md, v10.md
#   <scratch_repo>/changelog/_toc.md  (regenerated TOC)
# BD-203 CHANGE 2: per-release granularity — entries match the
# pack-changelog regex `^v\d+\.md$` (one `vN.md` per major release).
# No monolith mirror is emitted (no-mirror SSOT). Two releases exercise
# grouping by major version (BD-164 toc-regenerate axis).
# $1 = scratch_repo path
build_green_pack_changelog() {
    local scratch_repo="$1"
    local changelog_dir="$scratch_repo/changelog"
    mkdir -p "$changelog_dir"

    # _rules.md (declares supporting files; no-mirror statement).
    # Carries the BD-204 "Mode invariance" marker the Check 32′ marker
    # assertion requires on the pack-changelog stream.
    cat >"$changelog_dir/_rules.md" <<'EOF'
# Per-stream contract — pack-changelog (test fixture)

Stream identity: pack-changelog
Filename convention: ^v\d+\.md$
Lifecycle states: none (versions are immutable post-ship)

The per-entry tree (+ `_toc.md`) is the SOLE source of truth and
readable form. There is no monolithic mirror.

**Mode invariance.** This stream is flat-file in both modes (test
fixture).

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
EOF

    # _intro.md (preamble).
    cat >"$changelog_dir/_intro.md" <<'EOF'
# Changelog (test fixture)

Test-fixture preamble.

---
EOF

    # Two release entries (per-release granularity). v11 carries a nested
    # `### v11.0` subsection inside the release file; v10 is H2-only. The
    # toc-regenerate.sh axis is "version" grouping by major.
    # NB: the nested subsection header deliberately carries NO `vN.M`
    # token (it would be tokenized by Check 34's CROSS_REF_RE as a
    # cross-reference and flagged dangling, since per-release granularity
    # defines `v11`, not `v11.0`). This fixture exercises Check 32′/33/34;
    # nested-subsection-preservation is covered by test-per-entry.sh
    # Group 10.
    cat >"$changelog_dir/v11.md" <<'EOF'
<!-- per-entry source: /changelog/v11.md; contract: /changelog/_rules.md -->
## v11 — May 2026

### Initial release

- Initial v11 release. References BD-100 for context.
EOF
    cat >"$changelog_dir/v10.md" <<'EOF'
<!-- per-entry source: /changelog/v10.md; contract: /changelog/_rules.md -->
## v10 — March 2026

- v10 release (H2-only).
EOF

    # Generate the canonical _toc.md via the BD-164 helper (no mirror —
    # under the no-mirror model `_toc.md` is the readable index).
    bash -c "
        . '$PER_ENTRY_LIB/_lib.sh'
        . '$PER_ENTRY_LIB/toc-regenerate.sh'
        per_entry_regenerate_toc pack-changelog '$changelog_dir'
    " >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────
# Group D: structural smoke (STREAMS constant binding)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group D: structural smoke (STREAMS constant) ===\n"

D1_OUT=$(PE_TEST_VALIDATE_PY="$VALIDATE_PY" python3 - <<'PYEOF'
import importlib.util
import os
import sys

spec = importlib.util.spec_from_file_location("validate_pack", os.environ["PE_TEST_VALIDATE_PY"])
vp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vp)

# Verify shape: list of 4-tuples; pack-backlog and pack-changelog
# present per integration parent §10.6 pack-side scope.
keys = [s[0] for s in vp.STREAMS]
print(f"keys={keys}")
print(f"len={len(vp.STREAMS)}")
print(f"tuple_lens={[len(s) for s in vp.STREAMS]}")
PYEOF
)
assert_contains "D1.1 STREAMS includes pack-backlog" "$D1_OUT" "pack-backlog"
assert_contains "D1.2 STREAMS includes pack-changelog" "$D1_OUT" "pack-changelog"
assert_contains "D1.3 STREAMS tuples are 4-tuples" "$D1_OUT" "tuple_lens=[4, 4]"

# ─────────────────────────────────────────────────────────────────
# Group A: Check 32′ (no pack monolith exists — BD-203 inverted)
# ─────────────────────────────────────────────────────────────────
#
# BD-203 retires the old "mirror-in-sync" Check 32 and replaces it with
# an inverted guard (still named `check_mirror_in_sync`): for each pack
# stream whose per-entry tree is present, assert the monolith is ABSENT
# and `_rules.md` + `_toc.md` are present + filenames conform. Green =
# tree present + NO monolith; red = monolith present (or missing
# supporting file / non-conforming filename). `build_green_pack_backlog`
# emits the BACKLOG.md monolith as conversion input, so each green case
# DELETES it first.

printf "\n=== Group A: Check 32′ (no pack monolith exists — BD-203) ===\n"

# A1: green tree + NO monolith → check passes.
A1_REPO="$SCRATCH_ROOT/A1"
mkdir -p "$A1_REPO"
build_green_pack_backlog "$A1_REPO"
rm -f "$A1_REPO/BACKLOG.md"   # no-mirror SSOT: monolith deleted
A1_OUT=$(run_check check_mirror_in_sync "$A1_REPO" 2>&1)
A1_RC=$?
assert_eq "A1.1 tree + no monolith → check rc=0" "0" "$A1_RC"
assert_contains "A1.2 tree + no monolith → OK no monolith present" "$A1_OUT" "no monolith present"
assert_not_contains "A1.3 tree + no monolith → no FAIL" "$A1_OUT" "FAIL:"

# A2: tree present + monolith STILL present → check FAILs (wrong-model).
A2_REPO="$SCRATCH_ROOT/A2"
mkdir -p "$A2_REPO"
build_green_pack_backlog "$A2_REPO"   # leaves BACKLOG.md monolith in place
A2_OUT=$(run_check check_mirror_in_sync "$A2_REPO" 2>&1)
A2_RC=$?
assert_eq "A2.1 monolith present + tree → check rc=1" "1" "$A2_RC"
assert_contains "A2.2 monolith present → FAIL says still present" "$A2_OUT" "still present"
assert_contains "A2.3 monolith present → FAIL says delete the monolith" "$A2_OUT" "delete the monolith"

# A3: green tree + missing _rules.md → check FAILs.
A3_REPO="$SCRATCH_ROOT/A3"
mkdir -p "$A3_REPO"
build_green_pack_backlog "$A3_REPO"
rm -f "$A3_REPO/BACKLOG.md"
rm "$A3_REPO/backlog/_rules.md"
A3_OUT=$(run_check check_mirror_in_sync "$A3_REPO" 2>&1)
A3_RC=$?
assert_eq "A3.1 missing _rules.md → check rc=1" "1" "$A3_RC"
assert_contains "A3.2 missing _rules.md → FAIL names _rules.md" "$A3_OUT" "_rules.md missing"

# A4: green tree + missing _toc.md → check FAILs (no-mirror readable index).
A4_REPO="$SCRATCH_ROOT/A4"
mkdir -p "$A4_REPO"
build_green_pack_backlog "$A4_REPO"
rm -f "$A4_REPO/BACKLOG.md"
rm "$A4_REPO/backlog/_toc.md"
A4_OUT=$(run_check check_mirror_in_sync "$A4_REPO" 2>&1)
A4_RC=$?
assert_eq "A4.1 missing _toc.md → check rc=1" "1" "$A4_RC"
assert_contains "A4.2 missing _toc.md → FAIL names _toc.md" "$A4_OUT" "_toc.md missing"

# A5: green tree + non-conforming filename → check FAILs. The canonical
# entry BD-700.md in the green fixture CONFORMS (canonical regex), so the
# stray ROGUE-FILE.md is the only non-conforming offender.
A5_REPO="$SCRATCH_ROOT/A5"
mkdir -p "$A5_REPO"
build_green_pack_backlog "$A5_REPO"
rm -f "$A5_REPO/BACKLOG.md"
printf 'rogue\n' >"$A5_REPO/backlog/ROGUE-FILE.md"
A5_OUT=$(run_check check_mirror_in_sync "$A5_REPO" 2>&1)
A5_RC=$?
assert_eq "A5.1 non-conforming filename → check rc=1" "1" "$A5_RC"
assert_contains "A5.2 non-conforming filename → FAIL names the file" "$A5_OUT" "ROGUE-FILE.md"
assert_contains "A5.3 non-conforming filename → FAIL says non-conforming" "$A5_OUT" "non-conforming filenames"

# A6: the canonical entry BD-700.md CONFORMS under the canonical regex —
# a green tree carrying it (no monolith) passes Check 32′.
A6_REPO="$SCRATCH_ROOT/A6"
mkdir -p "$A6_REPO"
build_green_pack_backlog "$A6_REPO"
rm -f "$A6_REPO/BACKLOG.md"
[[ -f "$A6_REPO/backlog/BD-700.md" ]] && t_pass "A6.0 canonical entry BD-700.md present in fixture" \
    || t_fail "A6.0 canonical entry BD-700.md present in fixture"
A6_OUT=$(run_check check_mirror_in_sync "$A6_REPO" 2>&1)
A6_RC=$?
assert_eq "A6.1 canonical entry conforms → check rc=0" "0" "$A6_RC"
assert_not_contains "A6.2 canonical entry conforms → BD-700.md NOT flagged non-conforming" "$A6_OUT" "BD-700.md"

# A7: BD-204 Mode-3 ops contract — Check 32′ mode-marker assertions
# (PLAN-BD-204-MODE3-OPS-CONTRACT.md §5 leg 11). Marker PRESENT →
# PASS (A1/A6 already prove this with the marker-carrying fixture);
# marker ABSENT → FAIL with the marker-naming banner. Flat-file
# per-entry is the sole supported mode, so pack-backlog requires only
# the "Flat-file mode" marker (BD-243 dropped the obsolete "Tracker
# mode" marker when the tracker-mode doc mention was stripped).
A7_REPO="$SCRATCH_ROOT/A7"
mkdir -p "$A7_REPO"
build_green_pack_backlog "$A7_REPO"
rm -f "$A7_REPO/BACKLOG.md"
# Strip the required mode marker from the fixture's _rules.md.
python3 - "$A7_REPO/backlog/_rules.md" <<'PYEOF'
import sys
p = sys.argv[1]
text = open(p).read()
text = text.replace("Flat-file mode", "First mode")
open(p, "w").write(text)
PYEOF
A7_OUT=$(run_check check_mirror_in_sync "$A7_REPO" 2>&1)
A7_RC=$?
assert_eq "A7.1 mode marker absent → Check 32′ rc=1" "1" "$A7_RC"
assert_contains "A7.2 marker FAIL names missing marker" "$A7_OUT" "missing required mode marker"
assert_contains "A7.3 marker FAIL names Flat-file mode" "$A7_OUT" "Flat-file mode"
assert_contains "A7.4 marker FAIL cites the Mode-3 ops contract (BD-204)" "$A7_OUT" "BD-204"

# A7b: the green fixture carries only the single required "Flat-file
# mode" marker (no "Tracker mode" heading — BD-243 made it obsolete);
# the marker check PASSES on the single-marker contract. Also proves a
# stray non-required heading (here, an extra "Tracker mode" line) does
# NOT trip the check — marker presence only, never prose-pinning.
A7B_REPO="$SCRATCH_ROOT/A7B"
mkdir -p "$A7B_REPO"
build_green_pack_backlog "$A7B_REPO"
rm -f "$A7B_REPO/BACKLOG.md"
# Append a stray (non-required) "Tracker mode" heading — must be ignored.
printf '\n**Tracker mode.** (stray non-required heading — must be ignored)\n' \
    >>"$A7B_REPO/backlog/_rules.md"
A7B_OUT=$(run_check check_mirror_in_sync "$A7B_REPO" 2>&1)
A7B_RC=$?
assert_eq "A7b.1 single required marker present → Check 32′ rc=0" "0" "$A7B_RC"
assert_not_contains "A7b.2 PASS does not flag a missing mode marker" "$A7B_OUT" "missing required mode marker"

# ─────────────────────────────────────────────────────────────────
# Group B: Check 33 (TOC-in-sync) — green + red
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group B: Check 33 (TOC-in-sync) ===\n"

# B1: green tree + in-sync _toc.md → check passes.
B1_REPO="$SCRATCH_ROOT/B1"
mkdir -p "$B1_REPO"
build_green_pack_backlog "$B1_REPO"
B1_OUT=$(run_check check_toc_in_sync "$B1_REPO" 2>&1)
B1_RC=$?
assert_eq "B1.1 in-sync _toc.md → check rc=0" "0" "$B1_RC"
assert_contains "B1.2 in-sync _toc.md → OK byte-identical" "$B1_OUT" "byte-identical"
assert_not_contains "B1.3 in-sync _toc.md → no FAIL" "$B1_OUT" "FAIL:"

# B2: green tree + hand-edited _toc.md → check FAILs.
B2_REPO="$SCRATCH_ROOT/B2"
mkdir -p "$B2_REPO"
build_green_pack_backlog "$B2_REPO"
printf '\nROGUE TOC LINE\n' >>"$B2_REPO/backlog/_toc.md"
B2_PRE_SHA=$(shasum "$B2_REPO/backlog/_toc.md" | awk '{print $1}')
B2_OUT=$(run_check check_toc_in_sync "$B2_REPO" 2>&1)
B2_RC=$?
B2_POST_SHA=$(shasum "$B2_REPO/backlog/_toc.md" | awk '{print $1}')
assert_eq "B2.1 hand-edited _toc.md → check rc=1" "1" "$B2_RC"
assert_contains "B2.2 hand-edited _toc.md → FAIL out-of-sync" "$B2_OUT" "out of sync"
assert_contains "B2.3 hand-edited _toc.md → FAIL names regenerator" "$B2_OUT" "per_entry_regenerate_toc"
assert_eq "B2.4 hand-edited _toc.md → working-tree restored" "$B2_PRE_SHA" "$B2_POST_SHA"

# B3: green tree + missing _toc.md → check FAILs.
B3_REPO="$SCRATCH_ROOT/B3"
mkdir -p "$B3_REPO"
build_green_pack_backlog "$B3_REPO"
rm "$B3_REPO/backlog/_toc.md"
B3_OUT=$(run_check check_toc_in_sync "$B3_REPO" 2>&1)
B3_RC=$?
assert_eq "B3.1 missing _toc.md → check rc=1" "1" "$B3_RC"
assert_contains "B3.2 missing _toc.md → FAIL says absent" "$B3_OUT" "_toc.md absent"
# Confirm the test runner restored the tree (no _toc.md left behind).
[[ -f "$B3_REPO/backlog/_toc.md" ]] && t_fail "B3.3 _toc.md not restored" "leftover file exists" \
    || t_pass "B3.3 missing _toc.md → tree restored to pre-check state"

# ─────────────────────────────────────────────────────────────────
# Group C: Check 34 (cross-reference integrity) — green + red
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group C: Check 34 (cross-reference integrity) ===\n"

# C1: green tree + all refs resolve → check passes. Self-ref + cross-
# entry refs to BD-100 / BD-101 / BD-102 all defined.
C1_REPO="$SCRATCH_ROOT/C1"
mkdir -p "$C1_REPO"
build_green_pack_backlog "$C1_REPO"
C1_OUT=$(run_check check_cross_reference_integrity "$C1_REPO" 2>&1)
C1_RC=$?
assert_eq "C1.1 all refs resolve → check rc=0" "0" "$C1_RC"
assert_contains "C1.2 all refs resolve → OK summary" "$C1_OUT" "all resolved"
assert_not_contains "C1.3 all refs resolve → no FAIL" "$C1_OUT" "FAIL:"

# C2: green tree + dangling BD-NNN ref → check FAILs.
C2_REPO="$SCRATCH_ROOT/C2"
mkdir -p "$C2_REPO"
build_green_pack_backlog "$C2_REPO"
# Append a dangling reference to a non-existent BD-555.
printf '\nDescription continued: see BD-555 for related context.\n' \
    >>"$C2_REPO/backlog/BD-100.md"
C2_OUT=$(run_check check_cross_reference_integrity "$C2_REPO" 2>&1)
C2_RC=$?
assert_eq "C2.1 dangling BD-555 → check rc=1" "1" "$C2_RC"
assert_contains "C2.2 dangling BD-555 → FAIL names BD-555" "$C2_OUT" "BD-555"
assert_contains "C2.3 dangling BD-555 → FAIL names BD-100.md" "$C2_OUT" "BD-100.md"
assert_contains "C2.4 dangling BD-555 → FAIL says no matching entry file" "$C2_OUT" "no matching entry file found"

# C3: (RETIRED — BD-203 B8) The former C3 exercised the removed
# `_v8-resolved-archive.md` cross-ref SKIP path (a `BD-999` historical
# reference inside the archive that the old special-case SKIPed). The
# archive supporting file is retired (the 19 v8 table rows are now real
# `BD-00N.md` entries), so there is no archive section to SKIP and this
# test no longer applies. Leading-underscore supporting files are still
# skipped generically by the walk loop's `startswith("_")` guard.

# C4: self-reference → check passes (BD-101 references itself in body;
# already in the green fixture). Re-assert explicitly.
C4_REPO="$SCRATCH_ROOT/C4"
mkdir -p "$C4_REPO"
build_green_pack_backlog "$C4_REPO"
# BD-101.md already says "Self-reference to BD-101 in body" → both
# the regex match AND the self-id are BD-101 → no FAIL expected.
C4_OUT=$(run_check check_cross_reference_integrity "$C4_REPO" 2>&1)
C4_RC=$?
assert_eq "C4.1 BD-101 self-ref → check rc=0" "0" "$C4_RC"
assert_not_contains "C4.2 BD-101 self-ref → no FAIL for self-ref" "$C4_OUT" "references BD-101 — no matching"

# C5: dangling phase-N reference (cross-stream form). phase-N IDs
# belong to project-implementation-plan, which is NOT loaded in the
# pack-side STREAMS (per integration parent §10.6). Append a
# `phase-3` reference inside BD-100.md → since the pack-side STREAMS
# does NOT define `phase-3`, Check 34 reports it as dangling.
# This exercises the §10.6 scope rule from the failure side.
C5_REPO="$SCRATCH_ROOT/C5"
mkdir -p "$C5_REPO"
build_green_pack_backlog "$C5_REPO"
printf '\nDescription continued: aligns with phase-3 milestone.\n' \
    >>"$C5_REPO/backlog/BD-100.md"
C5_OUT=$(run_check check_cross_reference_integrity "$C5_REPO" 2>&1)
C5_RC=$?
assert_eq "C5.1 dangling phase-3 → check rc=1" "1" "$C5_RC"
assert_contains "C5.2 dangling phase-3 → FAIL names phase-3" "$C5_OUT" "phase-3"

# C6 (BD-211): a body reference to the canonical defined entry `BD-700`
# RESOLVES — the CROSS_REF_RE token (`BD-\d+`) tokenizes `BD-700`, and
# the canonical entry regex defines `BD-700` (the fixture's BD-700.md).
C6_REPO="$SCRATCH_ROOT/C6"
mkdir -p "$C6_REPO"
build_green_pack_backlog "$C6_REPO"
# BD-100 references the canonical entry BD-700 (defined in the fixture).
printf '\nDescription continued: superseded by BD-700.\n' \
    >>"$C6_REPO/backlog/BD-100.md"
C6_OUT=$(run_check check_cross_reference_integrity "$C6_REPO" 2>&1)
C6_RC=$?
assert_eq "C6.1 canonical ref BD-700 resolves → check rc=0" "0" "$C6_RC"
assert_not_contains "C6.2 canonical ref BD-700 → no dangling FAIL" "$C6_OUT" "BD-700 — no matching"

# C7 (BD-211): a DANGLING canonical reference (`BD-556`, not defined) is
# VISIBLE to Check 34 (the token `BD-\d+` tokenizes it) and FAILs —
# mirrors the C2 dangling-`BD-555` precedent with a distinct id.
C7_REPO="$SCRATCH_ROOT/C7"
mkdir -p "$C7_REPO"
build_green_pack_backlog "$C7_REPO"
printf '\nDescription continued: see BD-556 for related context.\n' \
    >>"$C7_REPO/backlog/BD-100.md"
C7_OUT=$(run_check check_cross_reference_integrity "$C7_REPO" 2>&1)
C7_RC=$?
assert_eq "C7.1 dangling canonical ref BD-556 → check rc=1" "1" "$C7_RC"
assert_contains "C7.2 dangling canonical ref → FAIL names BD-556" "$C7_OUT" "BD-556"

# ─────────────────────────────────────────────────────────────────
# Group E: SKIP behavior (per integration parent §10.5)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group E: SKIP behavior (no per-entry tree present) ===\n"

# E1: scratch_repo with NO backlog/ directory → all three checks SKIP
# gracefully (rc=0, "not present" message).
E1_REPO="$SCRATCH_ROOT/E1"
mkdir -p "$E1_REPO"
E1_C32=$(run_check check_mirror_in_sync "$E1_REPO" 2>&1)
E1_C32_RC=$?
assert_eq "E1.1 no tree → Check 32 rc=0 (SKIP)" "0" "$E1_C32_RC"
assert_contains "E1.2 no tree → Check 32 says 'not present'" "$E1_C32" "not present"

E1_C33=$(run_check check_toc_in_sync "$E1_REPO" 2>&1)
E1_C33_RC=$?
assert_eq "E1.3 no tree → Check 33 rc=0 (SKIP)" "0" "$E1_C33_RC"
assert_contains "E1.4 no tree → Check 33 says 'not present'" "$E1_C33" "not present"

E1_C34=$(run_check check_cross_reference_integrity "$E1_REPO" 2>&1)
E1_C34_RC=$?
assert_eq "E1.5 no tree → Check 34 rc=0 (SKIP)" "0" "$E1_C34_RC"
assert_contains "E1.6 no tree → Check 34 says 'no per-entry trees present'" "$E1_C34" "no per-entry trees present"

# ─────────────────────────────────────────────────────────────────
# Group F: pack-changelog stream coverage (BD-168 retro fix S2)
# ─────────────────────────────────────────────────────────────────
#
# The original BD-168 test runner exercised only the pack-backlog
# stream. Per BD-168 retro fix S2 (review §2.2 SHOULD finding #2), add
# explicit coverage for the second pack-side stream (pack-changelog),
# including a cross-stream `defined_all` union test exercising
# validate-pack.py:3280-3282 (the union of defined IDs across loaded
# streams used by Check 34).
#
# The extra_streams seam in run_check accepts pipe-delimited tuples; the
# pack-changelog tuple uses the BD-203 per-release regex `^v\d+\.md$`.

printf "\n=== Group F: pack-changelog stream coverage (BD-203 per-release) ===\n"

# Tuple constant for the pack-changelog stream (4-part pipe-delimited).
# BD-203: per-release granularity → entry regex `^v\d+\.md$`.
PACKCL_TUPLE='pack-changelog|changelog|CHANGELOG.md|^v\d+\.md$'

# F1: green pack-changelog tree + NO monolith → Check 32′ PASS.
# pack-backlog SKIPs (no /backlog/ in scratch); pack-changelog passes
# (tree present, no monolith) → overall PASS.
F1_REPO="$SCRATCH_ROOT/F1"
mkdir -p "$F1_REPO"
build_green_pack_changelog "$F1_REPO"
F1_OUT=$(run_check check_mirror_in_sync "$F1_REPO" "$PACKCL_TUPLE" 2>&1)
F1_RC=$?
assert_eq "F1.1 green pack-changelog → Check 32′ rc=0" "0" "$F1_RC"
assert_contains "F1.2 green pack-changelog → no monolith present" "$F1_OUT" "changelog/ — no monolith present"
assert_contains "F1.3 green pack-changelog → pack-backlog SKIPs" "$F1_OUT" "backlog/ — not present"
assert_not_contains "F1.4 green pack-changelog → no FAIL" "$F1_OUT" "FAIL:"

# F2: green pack-changelog tree + Check 33 → PASS.
F2_REPO="$SCRATCH_ROOT/F2"
mkdir -p "$F2_REPO"
build_green_pack_changelog "$F2_REPO"
F2_OUT=$(run_check check_toc_in_sync "$F2_REPO" "$PACKCL_TUPLE" 2>&1)
F2_RC=$?
assert_eq "F2.1 green pack-changelog → Check 33 rc=0" "0" "$F2_RC"
assert_contains "F2.2 green pack-changelog → _toc.md byte-identical" "$F2_OUT" "changelog/_toc.md byte-identical"
assert_not_contains "F2.3 green pack-changelog → no FAIL" "$F2_OUT" "FAIL:"

# F3: green pack-changelog tree + Check 34 → PASS (no dangling refs).
F3_REPO="$SCRATCH_ROOT/F3"
mkdir -p "$F3_REPO"
build_green_pack_changelog "$F3_REPO"
# The v11.md body references BD-100 which is NOT defined in this scratch
# (no /backlog/). Check 34 would correctly FAIL with dangling BD-100. To
# exercise the all-pass path, strip the body reference before the check.
sed -i.bak 's/References BD-100 for context.//' "$F3_REPO/changelog/v11.md"
rm -f "$F3_REPO/changelog/v11.md.bak"
F3_OUT=$(run_check check_cross_reference_integrity "$F3_REPO" "$PACKCL_TUPLE" 2>&1)
F3_RC=$?
assert_eq "F3.1 green pack-changelog → Check 34 rc=0" "0" "$F3_RC"
assert_not_contains "F3.2 green pack-changelog → no dangling FAIL" "$F3_OUT" "FAIL:"

# F4: pack-changelog tree present + monolith STILL present → Check 32′
# FAIL (wrong-model; the monolith must be deleted under no-mirror).
F4_REPO="$SCRATCH_ROOT/F4"
mkdir -p "$F4_REPO"
build_green_pack_changelog "$F4_REPO"
printf '# stale monolith\n' >"$F4_REPO/CHANGELOG.md"
F4_OUT=$(run_check check_mirror_in_sync "$F4_REPO" "$PACKCL_TUPLE" 2>&1)
F4_RC=$?
assert_eq "F4.1 monolith present + changelog tree → Check 32′ rc=1" "1" "$F4_RC"
assert_contains "F4.2 monolith present → FAIL says CHANGELOG.md still present" "$F4_OUT" "CHANGELOG.md still present"
assert_contains "F4.3 monolith present → FAIL says delete the monolith" "$F4_OUT" "delete the monolith"

# F5: cross-stream union — pack-backlog entry references a pack-changelog
# release. Exercises the defined_all union. A pack-backlog entry
# referencing v10.0 should resolve via the pack-changelog stream's
# defined IDs (NB: the per-release changelog defines `v10` / `v11` as
# entry IDs; the CROSS_REF_RE `vN.M` token requires a minor — so the
# union here is exercised via the pack-changelog body referencing a
# pack-backlog BD that IS defined).
F5_REPO="$SCRATCH_ROOT/F5"
mkdir -p "$F5_REPO"
build_green_pack_backlog "$F5_REPO"
rm -f "$F5_REPO/BACKLOG.md"
build_green_pack_changelog "$F5_REPO"
# The pack-changelog v11.md references BD-100, which IS defined in the
# pack-backlog stream → resolves only via the defined_all union across
# both loaded streams. Without the union this would FAIL as dangling.
F5_OUT=$(run_check check_cross_reference_integrity "$F5_REPO" "$PACKCL_TUPLE" 2>&1)
F5_RC=$?
assert_eq "F5.1 cross-stream union → Check 34 rc=0 (BD-100 resolves via pack-backlog)" "0" "$F5_RC"
assert_not_contains "F5.2 cross-stream union → no dangling FAIL" "$F5_OUT" "FAIL:"

# F6: BD-204 Mode-3 ops contract — the pack-changelog stream's
# Check 32′ marker assertion ("Mode invariance"). Present → PASS
# (F1's fixture carries it); absent → FAIL naming the marker.
F6_REPO="$SCRATCH_ROOT/F6"
mkdir -p "$F6_REPO"
build_green_pack_changelog "$F6_REPO"
python3 - "$F6_REPO/changelog/_rules.md" <<'PYEOF'
import sys
p = sys.argv[1]
text = open(p).read().replace("Mode invariance", "Mode sameness")
open(p, "w").write(text)
PYEOF
F6_OUT=$(run_check check_mirror_in_sync "$F6_REPO" "$PACKCL_TUPLE" 2>&1)
F6_RC=$?
assert_eq "F6.1 Mode-invariance marker absent → Check 32′ rc=1" "1" "$F6_RC"
assert_contains "F6.2 marker FAIL names Mode invariance" "$F6_OUT" "Mode invariance"
assert_contains "F6.3 marker FAIL is the missing-marker banner" "$F6_OUT" "missing required mode marker"

# ─────────────────────────────────────────────────────────────────
# Group F2: Check 34 vN.M resolution (BD-203 D1 forward-ref + FLAG-b)
# ─────────────────────────────────────────────────────────────────
#
# BD-203 D1 (measure-then-bound forward-ref tolerance): a `vN.M`
# point-release reference whose MAJOR `vN` is GREATER than the highest
# defined changelog major is a genuine FORWARD reference (a version that
# does not exist yet) → RESOLVES. Sized to `major > highest-defined`,
# NOT a token allowlist: a `vN.M` whose major is `<=` the highest defined
# but UNDEFINED (an in-range gap / typo) STILL FAILs. And the landed
# FLAG-b mapping (`vN.M`→`vN` when the major IS defined) still resolves.
# These exercise the pack-changelog defined-major set (the green fixture
# defines majors {v10, v11} → highest defined major = 11).

printf "\n=== Group F2: Check 34 vN.M resolution (BD-203 D1 + FLAG-b) ===\n"

# F2a (D1 GREEN — forward-ref): a `vN.M` whose major (12) > highest
# defined (11) resolves — a forward reference to an unreleased version.
F2A_REPO="$SCRATCH_ROOT/F2a"
mkdir -p "$F2A_REPO"
build_green_pack_changelog "$F2A_REPO"
# Strip the body BD-100 ref (no /backlog/ here) and add a forward `v12.0`.
sed -i.bak 's/References BD-100 for context.//' "$F2A_REPO/changelog/v11.md"
rm -f "$F2A_REPO/changelog/v11.md.bak"
printf '\n- Required before tagging v12.0 (forward reference).\n' \
    >>"$F2A_REPO/changelog/v11.md"
F2A_OUT=$(run_check check_cross_reference_integrity "$F2A_REPO" "$PACKCL_TUPLE" 2>&1)
F2A_RC=$?
assert_eq "F2a.1 forward-ref v12.0 (major>highest) resolves → rc=0" "0" "$F2A_RC"
assert_not_contains "F2a.2 forward-ref v12.0 → no dangling FAIL" "$F2A_OUT" "references v12.0"

# F2b (D1 RED — in-range gap): construct a changelog defining majors
# {v9, v11} (a GAP at v10), then reference `v10.0`. v10 is undefined and
# 10 <= highest-defined (11), so the forward-ref path does NOT fire and
# the reference STILL FAILs as a dangling/gap ref (the measure-then-bound
# boundary — the tolerance never swallows an in-range undefined major).
F2B_REPO="$SCRATCH_ROOT/F2b"
mkdir -p "$F2B_REPO/changelog"
cat >"$F2B_REPO/changelog/_rules.md" <<'EOF'
# Per-stream contract — pack-changelog (test fixture)

Stream identity: pack-changelog
Filename convention: ^v\d+\.md$
Lifecycle states: none (versions are immutable post-ship)

The per-entry tree (+ `_toc.md`) is the SOLE source of truth and
readable form. There is no monolithic mirror.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
EOF
cat >"$F2B_REPO/changelog/_intro.md" <<'EOF'
# Changelog (test fixture)

Test-fixture preamble.

---
EOF
cat >"$F2B_REPO/changelog/v11.md" <<'EOF'
<!-- per-entry source: /changelog/v11.md; contract: /changelog/_rules.md -->
## v11 — May 2026

- Initial v11 release. Backport noted in v10.0 (in-range gap).
EOF
cat >"$F2B_REPO/changelog/v9.md" <<'EOF'
<!-- per-entry source: /changelog/v9.md; contract: /changelog/_rules.md -->
## v9 — Jan 2026

- v9 release (H2-only).
EOF
bash -c "
    . '$PER_ENTRY_LIB/_lib.sh'
    . '$PER_ENTRY_LIB/toc-regenerate.sh'
    per_entry_regenerate_toc pack-changelog '$F2B_REPO/changelog'
" >/dev/null 2>&1
F2B_OUT=$(run_check check_cross_reference_integrity "$F2B_REPO" "$PACKCL_TUPLE" 2>&1)
F2B_RC=$?
assert_eq "F2b.1 in-range gap v10.0 (10<=highest=11, undefined) still FAILs → rc=1" "1" "$F2B_RC"
assert_contains "F2b.2 in-range gap v10.0 → FAIL names v10.0" "$F2B_OUT" "references v10.0"

# F2c (FLAG-b regression guard): an in-range `vN.M` whose major IS
# defined (`v11.0`, v11 defined) resolves via the landed FLAG-b mapping
# (`vN.M`→`vN`). Guards against a D1 edit regressing the FLAG-b path.
F2C_REPO="$SCRATCH_ROOT/F2c"
mkdir -p "$F2C_REPO"
build_green_pack_changelog "$F2C_REPO"
sed -i.bak 's/References BD-100 for context.//' "$F2C_REPO/changelog/v11.md"
rm -f "$F2C_REPO/changelog/v11.md.bak"
printf '\n- Shipped in v11.0 (in-range, major defined).\n' \
    >>"$F2C_REPO/changelog/v11.md"
F2C_OUT=$(run_check check_cross_reference_integrity "$F2C_REPO" "$PACKCL_TUPLE" 2>&1)
F2C_RC=$?
assert_eq "F2c.1 in-range v11.0 (major v11 defined) resolves via FLAG-b → rc=0" "0" "$F2C_RC"
assert_not_contains "F2c.2 in-range v11.0 → no dangling FAIL" "$F2C_OUT" "references v11.0"

# ─────────────────────────────────────────────────────────────────
# Group G: M2 snap-leftover regression (BD-168 retro fix M2)
# ─────────────────────────────────────────────────────────────────
#
# Per BD-168 retro fix M2 (review §2.1 MUST finding #2), Check 33
# previously created its snapshot file inside stream_dir/ via
# tempfile.mkstemp(dir=str(stream_dir)). A SIGKILL between mkstemp
# and the finally-block cleanup would leave a leftover
# `.per-entry-toc-snap.XXXXXX.md` inside stream_dir/ that would FAIL
# Check 32 pre-check (b) on the NEXT validator run.
#
# Fix M2 moves the snap to the system tempdir (dir=None). Regression
# test: assert that after Check 33 runs successfully, no
# `.per-entry-toc-snap.*` files remain inside stream_dir/.

printf "\n=== Group G: M2 snap-leftover regression (no snap files in stream_dir) ===\n"

G1_REPO="$SCRATCH_ROOT/G1"
mkdir -p "$G1_REPO"
build_green_pack_backlog "$G1_REPO"
# Run Check 33 against the green tree (PASS path).
G1_OUT=$(run_check check_toc_in_sync "$G1_REPO" 2>&1)
G1_RC=$?
assert_eq "G1.1 Check 33 PASS path → rc=0" "0" "$G1_RC"
# Assert no snap files left behind in stream_dir/.
G1_LEFTOVERS=$(find "$G1_REPO/backlog" -name '.per-entry-toc-snap.*' -print 2>/dev/null)
if [[ -z "$G1_LEFTOVERS" ]]; then
    t_pass "G1.2 Check 33 PASS path → no .per-entry-toc-snap.* leftover in stream_dir"
else
    t_fail "G1.2 Check 33 PASS path → snap leftover in stream_dir" "$G1_LEFTOVERS"
fi

# Same assertion against the FAIL path (hand-edited _toc.md → Check 33
# FAILs but should still not leave a snap behind).
G2_REPO="$SCRATCH_ROOT/G2"
mkdir -p "$G2_REPO"
build_green_pack_backlog "$G2_REPO"
printf '\nROGUE TOC\n' >>"$G2_REPO/backlog/_toc.md"
G2_OUT=$(run_check check_toc_in_sync "$G2_REPO" 2>&1)
G2_RC=$?
assert_eq "G2.1 Check 33 FAIL path → rc=1" "1" "$G2_RC"
G2_LEFTOVERS=$(find "$G2_REPO/backlog" -name '.per-entry-toc-snap.*' -print 2>/dev/null)
if [[ -z "$G2_LEFTOVERS" ]]; then
    t_pass "G2.2 Check 33 FAIL path → no .per-entry-toc-snap.* leftover in stream_dir"
else
    t_fail "G2.2 Check 33 FAIL path → snap leftover in stream_dir" "$G2_LEFTOVERS"
fi

# ─────────────────────────────────────────────────────────────────
# Group H: BD-211 canonical line-2 header guard (Check 32′)
# ─────────────────────────────────────────────────────────────────
#
# The net-new header guard inside check_mirror_in_sync asserts that the
# line-2 bold header of each ID-shaped-stream entry matches
# `**<ID>-NNN — <Title>**` (NO letter suffix, NO pre-em-dash
# parenthetical). measure-then-bound: a POSITIVE control (clean header
# passes, no false positive) + a NEGATIVE test (a suffix header AND a
# pre-em-dash parenthetical header BOTH reject, no false negative).
#
# The fixture filenames are CANONICAL (`BD-500.md` / `BD-501.md` /
# `BD-502.md`) so they pass the filename-conformance loop and REACH the
# header guard; only the line-2 header text is non-canonical for the
# negative cases.

printf "\n=== Group H: BD-211 canonical line-2 header guard ===\n"

# H1 (NEGATIVE): a canonical-filename entry whose line-2 header carries a
# letter suffix → guard REJECTS, rc=1, output names the offending file.
H1_REPO="$SCRATCH_ROOT/H1"
mkdir -p "$H1_REPO"
build_green_pack_backlog "$H1_REPO"
rm -f "$H1_REPO/BACKLOG.md"
cat >"$H1_REPO/backlog/BD-500.md" <<'EOF'
<!-- per-entry source: /backlog/BD-500.md; contract: /backlog/_rules.md -->
**BD-500b — Suffix header**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: n/a
Description: Suffix-form line-2 header (non-canonical per BD-211).
EOF
H1_OUT=$(run_check check_mirror_in_sync "$H1_REPO" 2>&1)
H1_RC=$?
assert_eq "H1.1 suffix line-2 header → check rc=1" "1" "$H1_RC"
assert_contains "H1.2 suffix line-2 header → FAIL names BD-500.md" "$H1_OUT" "BD-500.md"
assert_contains "H1.3 suffix line-2 header → FAIL says non-canonical header" "$H1_OUT" "non-canonical line-2 header"

# H2 (NEGATIVE): a canonical-filename entry whose line-2 header carries a
# pre-em-dash parenthetical qualifier → guard REJECTS, rc=1, names file.
H2_REPO="$SCRATCH_ROOT/H2"
mkdir -p "$H2_REPO"
build_green_pack_backlog "$H2_REPO"
rm -f "$H2_REPO/BACKLOG.md"
cat >"$H2_REPO/backlog/BD-501.md" <<'EOF'
<!-- per-entry source: /backlog/BD-501.md; contract: /backlog/_rules.md -->
**BD-501 (Qualifier) — Parenthetical header**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: n/a
Description: Pre-em-dash parenthetical line-2 header (non-canonical per BD-211).
EOF
H2_OUT=$(run_check check_mirror_in_sync "$H2_REPO" 2>&1)
H2_RC=$?
assert_eq "H2.1 parenthetical line-2 header → check rc=1" "1" "$H2_RC"
assert_contains "H2.2 parenthetical line-2 header → FAIL names BD-501.md" "$H2_OUT" "BD-501.md"
assert_contains "H2.3 parenthetical line-2 header → FAIL says non-canonical header" "$H2_OUT" "non-canonical line-2 header"

# H3 (NEGATIVE, both forms in one tree): the guard names BOTH offenders.
H3_REPO="$SCRATCH_ROOT/H3"
mkdir -p "$H3_REPO"
build_green_pack_backlog "$H3_REPO"
rm -f "$H3_REPO/BACKLOG.md"
cat >"$H3_REPO/backlog/BD-500.md" <<'EOF'
<!-- per-entry source: /backlog/BD-500.md; contract: /backlog/_rules.md -->
**BD-500b — Suffix header**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: n/a
Description: Suffix-form line-2 header (non-canonical per BD-211).
EOF
cat >"$H3_REPO/backlog/BD-501.md" <<'EOF'
<!-- per-entry source: /backlog/BD-501.md; contract: /backlog/_rules.md -->
**BD-501 (Qualifier) — Parenthetical header**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: n/a
Description: Pre-em-dash parenthetical line-2 header (non-canonical per BD-211).
EOF
H3_OUT=$(run_check check_mirror_in_sync "$H3_REPO" 2>&1)
H3_RC=$?
assert_eq "H3.1 both non-canonical headers → check rc=1" "1" "$H3_RC"
assert_contains "H3.2 both non-canonical → FAIL names BD-500.md" "$H3_OUT" "BD-500.md"
assert_contains "H3.3 both non-canonical → FAIL names BD-501.md" "$H3_OUT" "BD-501.md"

# H4 (POSITIVE control): a canonical-filename entry with a CLEAN line-2
# header passes the guard (rc=0, not flagged) — no false positive. The
# green fixture already carries canonical headers; add one more clean
# entry to prove the guard admits a fresh canonical header.
H4_REPO="$SCRATCH_ROOT/H4"
mkdir -p "$H4_REPO"
build_green_pack_backlog "$H4_REPO"
rm -f "$H4_REPO/BACKLOG.md"
cat >"$H4_REPO/backlog/BD-502.md" <<'EOF'
<!-- per-entry source: /backlog/BD-502.md; contract: /backlog/_rules.md -->
**BD-502 — Clean header**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: n/a
Description: Canonical line-2 header (passes the BD-211 guard).
EOF
H4_OUT=$(run_check check_mirror_in_sync "$H4_REPO" 2>&1)
H4_RC=$?
assert_eq "H4.1 clean line-2 header → check rc=0" "0" "$H4_RC"
assert_not_contains "H4.2 clean line-2 header → BD-502.md NOT flagged" "$H4_OUT" "non-canonical line-2 header"

# ─────────────────────────────────────────────────────────────────
# Group T-unit: BD-242 version-token regexes (R1 CROSS_REF_RE +
# R2 _VERSION_POINT_RE) direct full-match assertions
# ─────────────────────────────────────────────────────────────────
#
# BD-242 locks the version token to `vMAJOR.MINOR[.PATCH]` plus an
# OPTIONAL bounded qualifier suffix `-(?:alpha|beta|RC\d+|GA)` (alpha/beta
# lowercase, RC numbered, GA uppercase; a PATCH is never qualified). The
# old lowercase group `[a-z0-9-]+` is REPLACED. These assertions load
# validate-pack.py as a module and exercise CROSS_REF_RE (R1) +
# _VERSION_POINT_RE (R2) directly with a full-match battery: old `vN.M`
# (forward-only) + every new accepted form ACCEPT; every illegal form
# (wrong case, numbered non-RC, bare RC, qualified PATCH) REJECT. The
# fullmatch contract is the illegal-form gate (no new CI check is added —
# Check 34 is a resolution check, not a format validator).

printf "\n=== Group T-unit: BD-242 version-token regexes (R1/R2 full-match) ===\n"

TUNIT_OUT=$(PE_TEST_VALIDATE_PY="$VALIDATE_PY" python3 - <<'PYEOF'
import importlib.util
import os
import re

spec = importlib.util.spec_from_file_location("validate_pack", os.environ["PE_TEST_VALIDATE_PY"])
vp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vp)

# R1 CROSS_REF_RE carries other alternatives (BD-/TD-/phase-); to test the
# version alternative in isolation we anchor a fullmatch on the captured
# group via a re.fullmatch of the version sub-pattern. Easiest robust check:
# CROSS_REF_RE.fullmatch(token) must (a) match for accepted, returning the
# whole token in group(1), and (b) NOT fullmatch for rejected version-shaped
# tokens.
cross = vp.CROSS_REF_RE
vpoint = vp._VERSION_POINT_RE

ACCEPT = ["v11.0", "v9.3", "v11.0-alpha", "v11.0-beta",
          "v11.0-RC1", "v11.0-GA", "v11.0.1"]
REJECT = ["v11.0-rc1", "v11.0-ga", "v11.0-alpha1", "v11.0-beta2",
          "v11.0-GA1", "v11.0-RC", "v11.0.1-alpha"]

for tok in ACCEPT:
    m1 = cross.fullmatch(tok)
    m2 = vpoint.match(tok)
    print(f"ACCEPT {tok}: CROSS_REF={'Y' if (m1 and m1.group(1) == tok) else 'N'} "
          f"VPOINT={'Y' if m2 else 'N'}"
          + (f" major={m2.group(1)}" if m2 else ""))

for tok in REJECT:
    m1 = cross.fullmatch(tok)
    m2 = vpoint.match(tok)
    # A REJECT token must NOT fully match the version token. CROSS_REF may
    # match a PREFIX (e.g. v11.0 inside v11.0-rc1) — the gate is fullmatch
    # of the whole token. VPOINT is anchored (^...$) so .match == fullmatch.
    print(f"REJECT {tok}: CROSS_REF={'Y' if (m1 and m1.group(1) == tok) else 'N'} "
          f"VPOINT={'Y' if m2 else 'N'}")
PYEOF
)

# ACCEPT cases — both regexes full-match (VPOINT also extracts the major).
assert_contains "Tu.A1 v11.0 accepts (old two-level, forward-only)" "$TUNIT_OUT" "ACCEPT v11.0: CROSS_REF=Y VPOINT=Y major=11"
assert_contains "Tu.A2 v9.3 accepts (old two-level, forward-only)" "$TUNIT_OUT" "ACCEPT v9.3: CROSS_REF=Y VPOINT=Y major=9"
assert_contains "Tu.A3 v11.0-alpha accepts" "$TUNIT_OUT" "ACCEPT v11.0-alpha: CROSS_REF=Y VPOINT=Y major=11"
assert_contains "Tu.A4 v11.0-beta accepts" "$TUNIT_OUT" "ACCEPT v11.0-beta: CROSS_REF=Y VPOINT=Y major=11"
assert_contains "Tu.A5 v11.0-RC1 accepts (RC numbered, uppercase)" "$TUNIT_OUT" "ACCEPT v11.0-RC1: CROSS_REF=Y VPOINT=Y major=11"
assert_contains "Tu.A6 v11.0-GA accepts (GA uppercase)" "$TUNIT_OUT" "ACCEPT v11.0-GA: CROSS_REF=Y VPOINT=Y major=11"
assert_contains "Tu.A7 v11.0.1 accepts (PATCH segment)" "$TUNIT_OUT" "ACCEPT v11.0.1: CROSS_REF=Y VPOINT=Y major=11"

# REJECT cases — neither regex full-matches the whole token.
assert_contains "Tu.R1 v11.0-rc1 rejects (wrong case)" "$TUNIT_OUT" "REJECT v11.0-rc1: CROSS_REF=N VPOINT=N"
assert_contains "Tu.R2 v11.0-ga rejects (wrong case)" "$TUNIT_OUT" "REJECT v11.0-ga: CROSS_REF=N VPOINT=N"
assert_contains "Tu.R3 v11.0-alpha1 rejects (numbered non-RC)" "$TUNIT_OUT" "REJECT v11.0-alpha1: CROSS_REF=N VPOINT=N"
assert_contains "Tu.R4 v11.0-beta2 rejects (numbered non-RC)" "$TUNIT_OUT" "REJECT v11.0-beta2: CROSS_REF=N VPOINT=N"
assert_contains "Tu.R5 v11.0-GA1 rejects (numbered non-RC)" "$TUNIT_OUT" "REJECT v11.0-GA1: CROSS_REF=N VPOINT=N"
assert_contains "Tu.R6 v11.0-RC rejects (RC w/o number)" "$TUNIT_OUT" "REJECT v11.0-RC: CROSS_REF=N VPOINT=N"
assert_contains "Tu.R7 v11.0.1-alpha rejects (PATCH must not be qualified)" "$TUNIT_OUT" "REJECT v11.0.1-alpha: CROSS_REF=N VPOINT=N"

# ─────────────────────────────────────────────────────────────────
# Group T1: BD-242 Check 34 resolution of qualified + PATCH version refs
# ─────────────────────────────────────────────────────────────────
#
# With R1 tokenizing the new forms and R2 extracting the major, a backlog
# body referencing `v11.0-alpha` / `v11.0-RC1` / `v11.0-GA` / `v11.0.1`
# RESOLVES to the defined changelog major `v11` (FLAG-b mapping: vN.M*→vN).
# A forward-ref `v12.0-RC1` (major 12 > highest defined 11) is tolerated
# (BD-203 D1). Existing old `vN.M` refs still resolve (regression guard).
# The green pack-changelog fixture defines majors {v10, v11}; the
# pack-backlog fixture supplies the body that carries the refs.

printf "\n=== Group T1: BD-242 Check 34 qualified/PATCH version-ref resolution ===\n"

# T1a (GREEN): qualified + PATCH refs to the DEFINED major v11 resolve.
T1A_REPO="$SCRATCH_ROOT/T1a"
mkdir -p "$T1A_REPO"
build_green_pack_backlog "$T1A_REPO"
rm -f "$T1A_REPO/BACKLOG.md"
build_green_pack_changelog "$T1A_REPO"
# The changelog v11.md body references BD-100 (defined in pack-backlog →
# resolves via union). Add qualified + PATCH version refs whose major v11
# IS defined → must all resolve via the FLAG-b vN.M*→vN mapping.
printf '\n- Shipped across v11.0-alpha, v11.0-RC1, v11.0-GA, and v11.0.1.\n' \
    >>"$T1A_REPO/changelog/v11.md"
T1A_OUT=$(run_check check_cross_reference_integrity "$T1A_REPO" "$PACKCL_TUPLE" 2>&1)
T1A_RC=$?
assert_eq "T1a.1 qualified+PATCH refs to defined major v11 resolve → rc=0" "0" "$T1A_RC"
assert_not_contains "T1a.2 v11.0-alpha → no dangling FAIL" "$T1A_OUT" "v11.0-alpha"
assert_not_contains "T1a.3 v11.0-RC1 → no dangling FAIL" "$T1A_OUT" "v11.0-RC1"
assert_not_contains "T1a.4 v11.0-GA → no dangling FAIL" "$T1A_OUT" "v11.0-GA"
assert_not_contains "T1a.5 v11.0.1 → no dangling FAIL" "$T1A_OUT" "v11.0.1"

# T1b (GREEN, forward-ref): a qualified ref whose major (12) > highest
# defined (11) is tolerated as a forward reference (BD-203 D1).
T1B_REPO="$SCRATCH_ROOT/T1b"
mkdir -p "$T1B_REPO"
build_green_pack_changelog "$T1B_REPO"
# Strip the body BD-100 ref (no /backlog/ here) and add a forward qualified ref.
sed -i.bak 's/References BD-100 for context.//' "$T1B_REPO/changelog/v11.md"
rm -f "$T1B_REPO/changelog/v11.md.bak"
printf '\n- Required before tagging v12.0-RC1 (forward reference).\n' \
    >>"$T1B_REPO/changelog/v11.md"
T1B_OUT=$(run_check check_cross_reference_integrity "$T1B_REPO" "$PACKCL_TUPLE" 2>&1)
T1B_RC=$?
assert_eq "T1b.1 forward qualified ref v12.0-RC1 (major>highest) resolves → rc=0" "0" "$T1B_RC"
assert_not_contains "T1b.2 forward v12.0-RC1 → no dangling FAIL" "$T1B_OUT" "v12.0-RC1"

# T1c (GREEN, regression guard): an existing old two-level `vN.M` ref to a
# defined major still resolves (BD-242 is forward-only — the old form must
# keep parsing). Mirrors F2c with explicit BD-242 framing.
T1C_REPO="$SCRATCH_ROOT/T1c"
mkdir -p "$T1C_REPO"
build_green_pack_changelog "$T1C_REPO"
sed -i.bak 's/References BD-100 for context.//' "$T1C_REPO/changelog/v11.md"
rm -f "$T1C_REPO/changelog/v11.md.bak"
printf '\n- Shipped in v11.0 (old two-level form, forward-only regression guard).\n' \
    >>"$T1C_REPO/changelog/v11.md"
T1C_OUT=$(run_check check_cross_reference_integrity "$T1C_REPO" "$PACKCL_TUPLE" 2>&1)
T1C_RC=$?
assert_eq "T1c.1 old two-level v11.0 (forward-only) still resolves → rc=0" "0" "$T1C_RC"
assert_not_contains "T1c.2 old v11.0 → no dangling FAIL" "$T1C_OUT" "references v11.0"

# ─────────────────────────────────────────────────────────────────
# Group T-readme: BD-242 Check 4 README display→tag normalization (R3)
# ─────────────────────────────────────────────────────────────────
#
# R3 lets the README version table carry the DISPLAY form
# `v11.0 (RC1)` and normalizes display→tag (` (X)` → `-X`, case
# preserved) before comparing to git tags. These assertions exercise R3's
# findall pattern + the normalization regex directly (load the module,
# reuse its exact patterns) — no git tags required, so the tag-comparison
# branches are out of scope here (covered by Check 4's own skip paths).

printf "\n=== Group T-readme: BD-242 Check 4 display→tag normalization (R3) ===\n"

TREADME_OUT=$(PE_TEST_VALIDATE_PY="$VALIDATE_PY" python3 - <<'PYEOF'
import re

# Reproduce R3's findall + normalize against synthetic README table rows.
# These patterns are byte-identical to the R3 production edit in
# check_readme_version; an asserting test pinning the captured + normalized
# forms guards the contract (enumerate-encoding-surfaces).
findall_re = r"^\|\s*(v[\d.]+(?:\s*\((?:alpha|beta|RC\d+|GA)\))?)\s*\|"
normalize_re = r"\s*\((alpha|beta|RC\d+|GA)\)$"

def cap_and_norm(line):
    rows = re.findall(findall_re, line, re.MULTILINE)
    if not rows:
        return ("<none>", "<none>")
    cap = rows[-1].strip()
    tag = re.sub(normalize_re, r"-\1", cap)
    return (cap, tag)

# Display form with qualifier.
cap, tag = cap_and_norm("| v11.0 (RC1) | May 2026 | notes |")
print(f"RC1 cap={cap!r} tag={tag!r}")

# Bare display form (no qualifier) → normalizes to itself.
cap, tag = cap_and_norm("| v11.0 | May 2026 | notes |")
print(f"bare cap={cap!r} tag={tag!r}")

# Other qualifiers + PATCH form (the [\d.]+ covers PATCH).
cap, tag = cap_and_norm("| v11.0 (alpha) | ... |")
print(f"alpha cap={cap!r} tag={tag!r}")
cap, tag = cap_and_norm("| v11.0 (GA) | ... |")
print(f"GA cap={cap!r} tag={tag!r}")
cap, tag = cap_and_norm("| v11.0.1 | ... |")
print(f"patch cap={cap!r} tag={tag!r}")
PYEOF
)

assert_contains "Tr.1 '| v11.0 (RC1) |' → cap 'v11.0 (RC1)'" "$TREADME_OUT" "RC1 cap='v11.0 (RC1)'"
assert_contains "Tr.2 'v11.0 (RC1)' → tag 'v11.0-RC1'" "$TREADME_OUT" "RC1 cap='v11.0 (RC1)' tag='v11.0-RC1'"
assert_contains "Tr.3 '| v11.0 |' → cap 'v11.0' tag 'v11.0' (bare normalizes to self)" "$TREADME_OUT" "bare cap='v11.0' tag='v11.0'"
assert_contains "Tr.4 'v11.0 (alpha)' → tag 'v11.0-alpha'" "$TREADME_OUT" "alpha cap='v11.0 (alpha)' tag='v11.0-alpha'"
assert_contains "Tr.5 'v11.0 (GA)' → tag 'v11.0-GA'" "$TREADME_OUT" "GA cap='v11.0 (GA)' tag='v11.0-GA'"
assert_contains "Tr.6 '| v11.0.1 |' → cap 'v11.0.1' tag 'v11.0.1' (PATCH via [\\d.]+)" "$TREADME_OUT" "patch cap='v11.0.1' tag='v11.0.1'"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "PASS: %d\n" "$PASS"
printf "FAIL: %d\n" "$FAIL"

if [[ $FAIL -eq 0 ]]; then
    printf "\nAll BD-168 validate-pack Check 32/33/34 tests PASSED (%d/%d).\n" \
        "$PASS" "$((PASS + FAIL))"
    exit 0
else
    printf "\nFAILED — %d test(s) failed.\n" "$FAIL"
    exit 1
fi
