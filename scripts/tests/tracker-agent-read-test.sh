#!/usr/bin/env bash
# scripts/tests/tracker-agent-read-test.sh — LCD agent read path
# (BD-071 D-9 + V1 §8.1).
#
# Three groups:
#   1. Mode detection — flat-file vs tracker
#   2. Flat-file read — pack BD-* from the /backlog per-entry tree
#      (BD-204 C-6: pack monolith DELETED; tree is the SSOT) + TD-*
#      from the docs/project/backlog/ per-entry tree (BD-206: the
#      project monolith is abolished; the per-entry tree is the SSOT)
#   3. Tracker-mode read — mapping-resolution + provider_get
#   4. Direct-execution entrypoint — `bash tracker-agent-read.sh PACK-ID`

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

# shellcheck disable=SC1091
source "$LIB_DIR/tracker-agent-read.sh"

PATH_SAVED="$PATH"

# Build a small flat-mode test repo. Pack BD-* live in the per-entry
# tree under /backlog/ (BD-204 C-6: the pack monolith pack-ops/BACKLOG.md
# is DELETED — BD-203 no-mirror SSOT; the per-entry tree is the SSOT and
# the ONLY pack-surface read source). TD-* live in the per-entry tree
# under docs/project/backlog/ (BD-206: the docs/project/BACKLOG.md
# monolith is abolished — the per-entry tree is the project-side SSOT
# and the ONLY project-surface read source).
_setup_flat_repo() {
    local repo
    repo=$(mktemp -d -t tar-flat.XXXXXX)
    # BD-204 C-6: pack BD-* SSOT is the per-entry tree at /backlog/.
    # Each file IS the entry (with a line-1 back-pointer per Addendum-2
    # §2, stripped on agent-read output).
    mkdir -p "$repo/backlog"
    cat > "$repo/backlog/BD-001.md" <<'EOF'
<!-- per-entry source: backlog/BD-001.md; contract: backlog/_rules.md -->
**BD-001 — Add foo to bar**
Type: TODO(version)
Status: Open
Blockers: None
Description: Foo on bar surface.
Resolved: n/a
EOF
    cat > "$repo/backlog/BD-002.md" <<'EOF'
<!-- per-entry source: backlog/BD-002.md; contract: backlog/_rules.md -->
**BD-002 — Refactor bar**
Type: TODO(version)
Status: Unblocked
Blockers: BD-001
Description: Refactor bar.
Resolved: n/a
EOF
    # Project-side TD-* SSOT is the per-entry tree at
    # docs/project/backlog/ (BD-206 no-mirror standard — the
    # docs/project/BACKLOG.md monolith is abolished). Each file IS the
    # entry, with a line-1 back-pointer stripped on agent-read output.
    mkdir -p "$repo/docs/project/backlog"
    cat > "$repo/docs/project/backlog/TD-010.md" <<'EOF'
<!-- per-entry source: docs/project/backlog/TD-010.md; contract: docs/project/backlog/_rules.md -->
**TD-010 — Document quux**
Type: TODO(scope)
Status: Open
Description: Doc gap.
Resolved: n/a
EOF
    echo "$repo"
}

# Build a tracker-mode test repo.
_setup_tracker_repo() {
    local repo
    repo=$(mktemp -d -t tar-tracker.XXXXXX)
    touch "$repo/PACK-CHAT.md"   # surface=pack
    cat > "$repo/tracker.toml" <<'EOF'
schema_version = 1
[backend]
name = "github"
repo = "fixture-org/x"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
EOF
    mkdir -p "$repo/.pack-tracker"
    cat > "$repo/.pack-tracker/id-map.json" <<'EOF'
{
  "BD-001": {"id": "42", "url": "http://x/42"},
  "TD-010": {"id": "55", "url": "http://x/55"}
}
EOF
    echo "$repo"
}

# Build a fake gh that returns canned issue views for tracker reads.
_build_fake_gh_for_tracker() {
    local bin_dir="$1"
    cat > "$bin_dir/gh" <<'FG'
#!/usr/bin/env bash
case "$1 $2" in
    "issue view")
        case "$3" in
            42)
                echo '{"number":42,"title":"BD-001: Add foo","body":"<!-- pack-id: BD-001 -->\n\n## Description\n\nFoo on bar.","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:open"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/42"}'
                ;;
            55)
                echo '{"number":55,"title":"TD-010: Document quux","body":"<!-- pack-id: TD-010 -->\n\n## Description\n\nDoc gap.","state":"OPEN","stateReason":null,"labels":[{"name":"td-entry"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/55"}'
                ;;
        esac
        ;;
    "repo view") echo '{"nameWithOwner":"fixture-org/x"}' ;;
    *) ;;
esac
exit 0
FG
    chmod +x "$bin_dir/gh"
}

# ─────────────────────────────────────────────────────────────────
# Group 1: mode detection
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: mode detection ===\n"

# 1.1 No tracker.toml → flat-file
TR_NONE=$(mktemp -d -t tar-none.XXXXXX)
mode=$(tracker_agent_read_mode "$TR_NONE")
assert_eq "1.1 no tracker.toml → flat-file" "flat-file" "$mode"
rm -rf "$TR_NONE"

# 1.2 tracker.toml present + mode.state=tracker + forward_complete=true → tracker
TR_TR=$(_setup_tracker_repo)
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=github
mode=$(tracker_agent_read_mode "$TR_TR")
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE
assert_eq "1.2 tracker mode detected" "tracker" "$mode"
rm -rf "$TR_TR"

# ─────────────────────────────────────────────────────────────────
# Group 2: flat-file read
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: flat-file read ===\n"

REPO_F=$(_setup_flat_repo)

# 2.1 Read BD-001 — pack per-entry tree SSOT (BD-204 C-6).
out=$(tracker_agent_read_entry "BD-001" "$REPO_F")
rc=$?
assert_eq       "2.1 BD-001 rc=0"               "0" "$rc"
assert_contains "2.1 BD-001 source line (per-entry tree)" "$out" "Source: flat-file (per-entry:"
assert_contains "2.1 BD-001 names per-entry file" "$out" "backlog/BD-001.md"
assert_contains "2.1 BD-001 entry header"       "$out" "**BD-001 — Add foo to bar**"
assert_contains "2.1 BD-001 description"        "$out" "Foo on bar surface."
# Each per-entry file IS the entry — BD-002 cannot leak.
if [[ "$out" == *"BD-002"* ]]; then
    t_fail "2.1 BD-001 entry block bounded" "BD-002 leaked into BD-001 output"
else
    t_pass "2.1 BD-001 entry block bounded"
fi
# C-6 fail-loud: NO pack monolith read — the back-pointer line-1
# comment is stripped and the deleted monolith is never consulted.
if [[ "$out" == *"<!-- per-entry source:"* ]]; then
    t_fail "2.1 BD-001 back-pointer stripped" "back-pointer leaked into output"
else
    t_pass "2.1 BD-001 back-pointer stripped"
fi

# 2.2 Read BD-002 — has Blockers field
out=$(tracker_agent_read_entry "BD-002" "$REPO_F")
assert_contains "2.2 BD-002 entry header"   "$out" "**BD-002 — Refactor bar**"
assert_contains "2.2 BD-002 blockers"       "$out" "Blockers: BD-001"

# 2.3 Read TD-010 — project per-entry tree SSOT (BD-206: the
# docs/project/BACKLOG.md monolith is abolished; the per-entry tree
# at docs/project/backlog/ is the project-side SSOT).
out=$(tracker_agent_read_entry "TD-010" "$REPO_F")
assert_contains "2.3 TD-010 source line (per-entry tree)" "$out" "Source: flat-file (per-entry:"
assert_contains "2.3 TD-010 names per-entry file" "$out" "docs/project/backlog/TD-010.md"
assert_contains "2.3 TD-010 entry header"   "$out" "**TD-010 — Document quux**"
assert_contains "2.3 TD-010 description"    "$out" "Doc gap."
# Back-pointer line-1 comment is stripped on agent-read output.
if [[ "$out" == *"<!-- per-entry source:"* ]]; then
    t_fail "2.3 TD-010 back-pointer stripped" "back-pointer leaked into output"
else
    t_pass "2.3 TD-010 back-pointer stripped"
fi

# 2.4 Missing entry → not-found typed error
err=$(tracker_agent_read_entry "BD-999" "$REPO_F" 2>&1 1>/dev/null) || true
assert_contains "2.4 missing entry → not-found" "$err" "ERROR: not-found"
assert_contains "2.4 message names BD-999"      "$err" "BD-999"

# 2.5 Empty pack-id → validation
err=$(tracker_agent_read_entry "" "$REPO_F" 2>&1 1>/dev/null) || true
assert_contains "2.5 empty pack-id → validation" "$err" "ERROR: validation"

# 2.6 Bad repo-root → validation
err=$(tracker_agent_read_entry "BD-001" "/no/such/repo" 2>&1 1>/dev/null) || true
assert_contains "2.6 bad repo-root → validation" "$err" "ERROR: validation"

# 2.7 No per-entry tree → not-found (BD-204 C-6: NO pack monolith
# fallback — the deleted pack-ops/BACKLOG.md is never consulted).
TR_EMPTY=$(mktemp -d -t tar-empty.XXXXXX)
err=$(tracker_agent_read_entry "BD-001" "$TR_EMPTY" 2>&1 1>/dev/null) || true
assert_contains "2.7 no tree → not-found"        "$err" "ERROR: not-found"
assert_contains "2.7 BD-* fail-loud names the per-entry tree (no monolith)" \
    "$err" "no monolith fallback"
# Defensive: even if a stale monolith were present it must NOT be read.
mkdir -p "$TR_EMPTY/pack-ops"
cat > "$TR_EMPTY/pack-ops/BACKLOG.md" <<'EOF'
**BD-001 — STALE MONOLITH (must never be read)**
Description: deleted-monolith sentinel.
EOF
out_stale=$(tracker_agent_read_entry "BD-001" "$TR_EMPTY" 2>&1) || true
if [[ "$out_stale" == *"STALE MONOLITH"* ]]; then
    t_fail "2.7 BD-* never reads the pack monolith" "deleted monolith was read"
else
    t_pass "2.7 BD-* never reads the pack monolith"
fi
rm -rf "$TR_EMPTY"

rm -rf "$REPO_F"

# ─────────────────────────────────────────────────────────────────
# Group 3: tracker-mode read
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: tracker-mode read ===\n"

REPO_T=$(_setup_tracker_repo)
FAKE_T=$(mktemp -d -t tar-fake.XXXXXX)
_build_fake_gh_for_tracker "$FAKE_T"

export PATH="$FAKE_T:$PATH_SAVED"
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=github

# 3.1 Read BD-001 via tracker
out=$(tracker_agent_read_entry "BD-001" "$REPO_T" 2>/dev/null)
rc=$?
assert_eq       "3.1 BD-001 tracker rc=0"          "0" "$rc"
assert_contains "3.1 BD-001 source line tracker"   "$out" "Source: tracker (gh #42"
# State annotation lowercase per V1 §2.2 canonical (PACK-REVIEW-
# BD062-069-071 #19 closure). gh emits OPEN/CLOSED; we normalize.
assert_contains "3.1 BD-001 source state lowercase"  "$out" "state=open"
if [[ "$out" == *"state=OPEN"* ]]; then
    t_fail "3.1 BD-001 state lowercase (no OPEN uppercase)" "raw GH state leaked"
else
    t_pass "3.1 BD-001 state lowercase (no OPEN uppercase)"
fi
assert_contains "3.1 BD-001 title"                 "$out" "BD-001: Add foo"
assert_contains "3.1 BD-001 body content"          "$out" "Foo on bar."

# 3.2 Read TD-010 via tracker
out=$(tracker_agent_read_entry "TD-010" "$REPO_T" 2>/dev/null)
assert_contains "3.2 TD-010 source line tracker"   "$out" "Source: tracker (gh #55"
assert_contains "3.2 TD-010 description"           "$out" "Doc gap."

# 3.3 Pack-id not in mapping → not-found
err=$(tracker_agent_read_entry "BD-999" "$REPO_T" 2>&1 1>/dev/null) || true
assert_contains "3.3 missing in mapping → not-found" "$err" "ERROR: not-found"
assert_contains "3.3 message names BD-999"           "$err" "BD-999"

# 3.4 Tracker mode + missing mapping file → not-found
TR_NOMAP=$(mktemp -d -t tar-nomap.XXXXXX)
touch "$TR_NOMAP/PACK-CHAT.md"
cat > "$TR_NOMAP/tracker.toml" <<'EOF'
schema_version = 1
[backend]
name = "github"
repo = "x/y"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
EOF
err=$(tracker_agent_read_entry "BD-001" "$TR_NOMAP" 2>&1 1>/dev/null) || true
assert_contains "3.4 tracker + no mapping → not-found" "$err" "ERROR: not-found"
rm -rf "$TR_NOMAP"

unset _TRACKER_PROVIDER_BACKEND_OVERRIDE
export PATH="$PATH_SAVED"
rm -rf "$REPO_T" "$FAKE_T"

# ─────────────────────────────────────────────────────────────────
# Group 4: direct-execution entrypoint
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: direct-execution entrypoint ===\n"

REPO_D=$(_setup_flat_repo)

# 4.1 `bash tracker-agent-read.sh BD-001 <repo>` works as a one-shot.
out=$(bash "$LIB_DIR/tracker-agent-read.sh" "BD-001" "$REPO_D")
rc=$?
assert_eq       "4.1 direct exec rc=0"           "0" "$rc"
assert_contains "4.1 direct exec emits header"   "$out" "**BD-001"

# 4.2 Missing args → usage on stderr, rc=1
err=$(bash "$LIB_DIR/tracker-agent-read.sh" 2>&1 1>/dev/null) || true
assert_contains "4.2 no args → usage"        "$err" "Usage:"

# 4.3 Missing entry → not-found, rc=1
err=$(bash "$LIB_DIR/tracker-agent-read.sh" "BD-999" "$REPO_D" 2>&1 1>/dev/null) || true
assert_contains "4.3 direct exec missing → not-found" "$err" "ERROR: not-found"

rm -rf "$REPO_D"

# ─────────────────────────────────────────────────────────────────
# Group 5: no-monolith fall-through (BD-206) + prefer-branch coverage
# ─────────────────────────────────────────────────────────────────
#
# BD-206 repoint: the project-side per-entry tree is the no-mirror
# SSOT, so when no per-entry file resolves there is NO project
# monolith to fall back to — the fall-through fails loud with a typed
# not-found naming the per-entry file (fail-loud-delete-old-source).
# This group exercises both (a) the no-monolith fall-through when the
# per-entry tree is absent, and (b) the prefer-branch read path when
# per-entry files ARE present (originally added in BD-167 with no CI
# fixtures per PACK-REVIEW-BD-167-RETRO §4 Observation 2).

printf "\n=== Group 5: no-monolith fall-through + prefer-branch ===\n"

# Build a synthetic project-side repo with stale monoliths present but
# NO per-entry tree (defensive: the deleted-monolith model must never
# read them; the fall-through must fail loud).
_setup_project_fallback_repo() {
    local repo
    repo=$(mktemp -d -t tar-projfb.XXXXXX)
    mkdir -p "$repo/docs/project"
    cat > "$repo/docs/project/BACKLOG.md" <<'EOF'
**TD-005 — STALE MONOLITH (must never be read)**
Type: TODO(scope)
Status: Open
Description: deleted-monolith sentinel.
Resolved: n/a

---
EOF
    cat > "$repo/docs/project/IMPLEMENTATION-PLAN.md" <<'EOF'
## Phase 3 — Add foo subsystem

**Goal**: Ship foo to bar surface.

**Prerequisite**: Phase 2.

---

### Tasks

#### 3.1 — Wire foo to bar

Implement foo wiring with adapter pattern.

#### 3.2 — Add foo tests

Unit + integration coverage for foo.

### Verification

bash scripts/tests/test-foo.sh

### Agent

coder

### Risks

Adapter seam stability across SDK versions.
EOF
    echo "$repo"
}

# Build a synthetic project-side repo with BOTH per-entry trees AND
# mirrors (prefer-branch shape).
_setup_project_per_entry_repo() {
    local repo
    repo=$(mktemp -d -t tar-projpe.XXXXXX)
    mkdir -p "$repo/docs/project"
    mkdir -p "$repo/docs/project/backlog"
    mkdir -p "$repo/docs/project/implementation-plan"
    # Per-entry source-of-truth files (with line-1 HTML-comment
    # back-pointer per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-
    # ADDENDUM-2.md §2).
    cat > "$repo/docs/project/backlog/TD-005.md" <<'EOF'
<!-- per-entry source: docs/project/backlog/TD-005.md; contract: docs/project/backlog/_rules.md -->
**TD-005 — Document log rotation**
Type: TODO(scope)
Status: Open
Description: Log rotation undocumented.
Resolved: n/a
EOF
    cat > "$repo/docs/project/implementation-plan/phase-3.md" <<'EOF'
<!-- per-entry source: docs/project/implementation-plan/phase-3.md; contract: docs/project/implementation-plan/_rules.md -->
## Phase 3 — Add foo subsystem

**Goal**: Ship foo to bar surface.

**Prerequisite**: Phase 2.

---

### Tasks

#### 3.1 — Wire foo to bar

Implement foo wiring with adapter pattern.

#### 3.2 — Add foo tests

Unit + integration coverage for foo.

### Verification

bash scripts/tests/test-foo.sh

### Agent

coder

### Risks

Adapter seam stability across SDK versions.
EOF
    # Mirrors (stale-but-present) — prefer-branch should bypass these.
    cat > "$repo/docs/project/BACKLOG.md" <<'EOF'
**TD-005 — STALE MIRROR ENTRY**
Status: Open
EOF
    cat > "$repo/docs/project/IMPLEMENTATION-PLAN.md" <<'EOF'
## Phase 3 — STALE MIRROR ENTRY

**Goal**: stale.
EOF
    echo "$repo"
}

# 5.1 TD-* no per-entry tree → not-found (BD-206: the project monolith
# docs/project/BACKLOG.md is abolished; NO monolith fallback).
REPO_PFB=$(_setup_project_fallback_repo)
err=$(tracker_agent_read_entry "TD-005" "$REPO_PFB" 2>&1 1>/dev/null) || true
assert_contains "5.1 TD-005 no tree → not-found"       "$err" "ERROR: not-found"
assert_contains "5.1 TD-005 fail-loud names per-entry tree (no monolith)" \
    "$err" "no monolith fallback"
# Defensive: the stale docs/project/BACKLOG.md monolith must NOT be read.
out_stale=$(tracker_agent_read_entry "TD-005" "$REPO_PFB" 2>&1) || true
if [[ "$out_stale" == *"STALE MONOLITH"* ]]; then
    t_fail "5.1 TD-* never reads the project monolith" "deleted monolith was read"
else
    t_pass "5.1 TD-* never reads the project monolith"
fi

# 5.2 phase-* no per-entry tree → not-found (BD-206: the project monolith
# docs/project/IMPLEMENTATION-PLAN.md is abolished; NO monolith fallback).
err=$(tracker_agent_read_entry "phase-3" "$REPO_PFB" 2>&1 1>/dev/null) || true
assert_contains "5.2 phase-3 no tree → not-found"      "$err" "ERROR: not-found"
assert_contains "5.2 phase-3 fail-loud names per-entry tree (no monolith)" \
    "$err" "no monolith fallback"
# The message names the per-entry implementation-plan path, not the
# abolished monolith — and confirms no wrong-stream routing.
assert_contains "5.2 phase-3 names per-entry plan tree" \
    "$err" "docs/project/implementation-plan/phase-3.md"

# 5.3 phase-N.M no per-entry tree → not-found, resolving to phase-N
# (per Addendum #1 §6.4 tasks-inline contract).
err=$(tracker_agent_read_entry "phase-3.2" "$REPO_PFB" 2>&1 1>/dev/null) || true
assert_contains "5.3 phase-3.2 no tree → not-found"    "$err" "ERROR: not-found"
assert_contains "5.3 phase-3.2 resolves to phase-3 per-entry file" \
    "$err" "docs/project/implementation-plan/phase-3.md"

# 5.7 Unknown pack-id prefix → pack-surface default. BD-204 C-6: the
# `*)` default fails loud with a typed not-found (NO pack monolith
# fallback — pack-ops/BACKLOG.md is deleted, BD-203 no-mirror SSOT).
err=$(tracker_agent_read_entry "X-007" "$REPO_PFB" 2>&1 1>/dev/null) || true
assert_contains "5.7 unknown prefix → not-found"            "$err" "ERROR: not-found"
assert_contains "5.7 unknown prefix names no-monolith fallback" "$err" "no monolith fallback"

rm -rf "$REPO_PFB"

# Prefer-branch tests (Observation 2 — new CI coverage).
REPO_PE=$(_setup_project_per_entry_repo)

# 5.4 TD-* prefer-branch reads per-entry file (bypasses mirror).
out=$(tracker_agent_read_entry "TD-005" "$REPO_PE" 2>/dev/null)
rc=$?
assert_eq       "5.4 TD-005 prefer rc=0"               "0" "$rc"
assert_contains "5.4 TD-005 prefer source attribution" "$out" "Source: flat-file (per-entry:"
assert_contains "5.4 TD-005 prefer entry header"       "$out" "**TD-005 — Document log rotation**"
# Back-pointer stripped per Addendum #2 §2.
if [[ "$out" == *"<!-- per-entry source:"* ]]; then
    t_fail "5.4 TD-005 back-pointer stripped" "back-pointer leaked into output"
else
    t_pass "5.4 TD-005 back-pointer stripped"
fi
# Confirm mirror was NOT consulted (stale fixture sentinel absent).
if [[ "$out" == *"STALE MIRROR ENTRY"* ]]; then
    t_fail "5.4 TD-005 prefer skipped mirror" "stale mirror leaked"
else
    t_pass "5.4 TD-005 prefer skipped mirror"
fi

# 5.5 phase-* prefer-branch reads per-entry file.
out=$(tracker_agent_read_entry "phase-3" "$REPO_PE" 2>/dev/null)
rc=$?
assert_eq       "5.5 phase-3 prefer rc=0"              "0" "$rc"
assert_contains "5.5 phase-3 prefer source attribution" "$out" "Source: flat-file (per-entry:"
assert_contains "5.5 phase-3 prefer entry header"      "$out" "## Phase 3 — Add foo subsystem"
if [[ "$out" == *"STALE MIRROR ENTRY"* ]]; then
    t_fail "5.5 phase-3 prefer skipped mirror" "stale mirror leaked"
else
    t_pass "5.5 phase-3 prefer skipped mirror"
fi

# 5.6 phase-N.M prefer-branch resolves to phase-N per-entry file.
out=$(tracker_agent_read_entry "phase-3.2" "$REPO_PE" 2>/dev/null)
rc=$?
assert_eq       "5.6 phase-3.2 prefer rc=0"            "0" "$rc"
assert_contains "5.6 phase-3.2 resolves to phase-3"    "$out" "Source: flat-file (per-entry:"
assert_contains "5.6 phase-3.2 names phase-3.md"       "$out" "phase-3.md"
assert_contains "5.6 phase-3.2 reads phase-3 content"  "$out" "## Phase 3 — Add foo subsystem"

rm -rf "$REPO_PE"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
