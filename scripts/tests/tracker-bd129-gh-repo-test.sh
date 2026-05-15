#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/tracker-bd129-gh-repo-test.sh — BD-129 / D-1
# regression coverage.
#
# Pins the fix for the gh-CLI git-remote-resolution failure that
# caused `pack tracker init` to abort with a misleading
# "labels_ensure: cannot read existing labels (gh auth or network
# failure)" error in any working copy whose git remote did not point
# at a known GitHub host (local-path clones, internal mirrors,
# freshly-cloned repos before `git remote` setup, monorepo subtree
# imports, repos with non-GitHub remotes).
#
# Fix: scripts/lib/tracker-config.sh::tracker_gh_repo_setup exports
# GH_REPO from the active tracker.toml's backend.repo. The helper is
# called from _gh_run (tracker-provider-gh.sh) and from
# tracker_labels_ensure (tracker-labels.sh) so every gh invocation in
# the tracker libs targets the configured slug regardless of git
# remote state.
#
# All scenarios are mock-based (fake `gh` on PATH that records its
# environment). No live GitHub state is touched.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

PASS=0
FAIL=0
t_pass() { PASS=$((PASS + 1)); printf "  pass: %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  FAIL: %s\n" "$1"; [[ -n "${2:-}" ]] && printf "        %s\n" "$2"; }

assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' actual='$3'"; fi
}

assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' missing from: ${2:0:200}"; fi
}

# Source the libs (same load order as scripts/pack-tracker.sh).
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

# ─────────────────────────────────────────────────────────────────
# Fake gh on PATH. Records every invocation's GH_REPO env var and
# the args it was called with into $GH_LOG. Returns canned JSON for
# `gh label list` so tracker_labels_ensure exercises the full path.
# ─────────────────────────────────────────────────────────────────

WORKDIR=$(mktemp -d -t bd129.XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

export GH_LOG="$WORKDIR/gh.log"
mkdir -p "$WORKDIR/bin"
cat > "$WORKDIR/bin/gh" <<'GHEOF'
#!/usr/bin/env bash
# Record env + argv. Each invocation appends one line of the form
#   GH_REPO=<value>|<arg1> <arg2> ...
# GH_LOG is exported by the parent test so this fake inherits it.
printf 'GH_REPO=%s|%s\n' "${GH_REPO:-<unset>}" "$*" >> "${GH_LOG:-/dev/null}"
case "$1" in
    label)
        case "$2" in
            list)   printf '[]'   ;;  # empty existing label set → all canonical labels are missing → all created
            create) exit 0 ;;
        esac
        ;;
    issue)
        case "$2" in
            view)
                # Return enough JSON to satisfy _gh_normalize_issue.
                cat <<JSON
{"number": 1, "title": "stub", "body": "", "state": "OPEN", "labels": [], "assignees": [], "milestone": null, "createdAt": "2026-01-01T00:00:00Z", "updatedAt": "2026-01-01T00:00:00Z", "url": "https://example/issues/1"}
JSON
                ;;
            *) exit 0 ;;
        esac
        ;;
    *)
        exit 0
        ;;
esac
GHEOF
chmod +x "$WORKDIR/bin/gh"

ORIG_PATH="$PATH"
export PATH="$WORKDIR/bin:$PATH"

# ─────────────────────────────────────────────────────────────────
# Group 1: tracker_gh_repo_setup helper
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: tracker_gh_repo_setup ===\n"

# 1.1 No tracker.toml in scope → no-op (does not export GH_REPO).
unset GH_REPO _TRACKER_PROVIDER_CONFIG_PATH
tracker_gh_repo_setup
assert_eq "1.1 no config in scope → GH_REPO unset" "" "${GH_REPO:-}"

# 1.2 tracker.toml present but missing → no-op.
unset GH_REPO
export _TRACKER_PROVIDER_CONFIG_PATH="/nonexistent/tracker.toml"
tracker_gh_repo_setup
assert_eq "1.2 missing config file → GH_REPO unset" "" "${GH_REPO:-}"

# 1.3 valid tracker.toml → GH_REPO exported from backend.repo.
TOML1="$WORKDIR/r1.toml"
cat > "$TOML1" <<'TOML'
schema_version = 1
[backend]
name = "github"
repo = "DShaneNYC/example-repo"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = false
TOML
unset GH_REPO
export _TRACKER_PROVIDER_CONFIG_PATH="$TOML1"
tracker_gh_repo_setup
assert_eq "1.3 valid config → GH_REPO=DShaneNYC/example-repo" \
    "DShaneNYC/example-repo" "${GH_REPO:-}"

# 1.4 GH_REPO already set → preserved (caller / test seam wins).
export GH_REPO="caller/override"
tracker_gh_repo_setup
assert_eq "1.4 pre-set GH_REPO preserved" "caller/override" "${GH_REPO:-}"
unset GH_REPO

# ─────────────────────────────────────────────────────────────────
# Group 2: _gh_run propagates GH_REPO from active tracker.toml
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: _gh_run propagates GH_REPO ===\n"

unset GH_REPO
export _TRACKER_PROVIDER_CONFIG_PATH="$TOML1"
: > "$GH_LOG"
# Use gh issue view via tracker_provider_gh_get; fake gh records env.
tracker_provider_gh_get 1 >/dev/null 2>&1 || true
got=$(grep -c '^GH_REPO=DShaneNYC/example-repo|' "$GH_LOG" || true)
[[ "$got" -ge 1 ]] && t_pass "2.1 _gh_run exports GH_REPO before invoking gh" \
    || t_fail "2.1 _gh_run exports GH_REPO before invoking gh" \
        "log: $(cat "$GH_LOG")"

# 2.2 BD-129 retro-fix F6: two-call sequence to actually exercise the
# "re-establishes between calls" invariant the test name claims. The
# previous shape only proved "first call sets it after unset", which
# duplicated 2.1. Now: caller unsets GH_REPO BETWEEN two calls; the
# helper must re-export on the next gh invocation. Assert the log
# contains the slug-bearing prefix at least twice (one per call).
unset GH_REPO
: > "$GH_LOG"
tracker_provider_gh_get 1 >/dev/null 2>&1 || true   # 1st call: helper sets GH_REPO
unset GH_REPO                                        # caller scrubs between calls
tracker_provider_gh_get 1 >/dev/null 2>&1 || true   # 2nd call: helper re-sets GH_REPO
got=$(grep -c '^GH_REPO=DShaneNYC/example-repo|' "$GH_LOG" || true)
[[ "$got" -ge 2 ]] && t_pass "2.2 _gh_run re-establishes GH_REPO between calls" \
    || t_fail "2.2 _gh_run re-establishes GH_REPO between calls" \
        "log: $(cat "$GH_LOG")"

# ─────────────────────────────────────────────────────────────────
# Group 3: tracker_labels_ensure routes through GH_REPO
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: tracker_labels_ensure GH_REPO routing ===\n"

unset GH_REPO
TOML2="$WORKDIR/r2.toml"
cat > "$TOML2" <<'TOML'
schema_version = 1
[backend]
name = "github"
repo = "owner-2/repo-2"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = false
TOML
export _TRACKER_PROVIDER_CONFIG_PATH="$TOML2"
: > "$GH_LOG"

# Run in a directory that has NO git remote configured. This is the
# exact failure mode BD-129 fixes: pre-fix, gh would abort here with
# "none of the git remotes configured for this repository point to a
# known GitHub host" and tracker_labels_ensure would report the
# misleading labels_ensure error.
mkdir -p "$WORKDIR/no-remote-repo"
cd "$WORKDIR/no-remote-repo"
git init -q . 2>/dev/null || true
# Explicitly do NOT add any remote.

out=$(tracker_labels_ensure 2>&1)
rc=$?
cd "$REPO_ROOT"

assert_eq "3.1 tracker_labels_ensure rc=0 with no git remote" "0" "$rc"

# Every recorded gh invocation must include GH_REPO=owner-2/repo-2.
total=$(wc -l < "$GH_LOG" | tr -d ' ')
ok=$(grep -c '^GH_REPO=owner-2/repo-2|' "$GH_LOG" || true)
assert_eq "3.2 all gh calls saw GH_REPO=owner-2/repo-2 (count=$total)" \
    "$total" "$ok"

# At least one `gh label list` and one `gh label create` recorded
# (proves the labels surface flowed through).
[[ $(grep -c '|label list ' "$GH_LOG") -ge 1 ]] \
    && t_pass "3.3 gh label list recorded" \
    || t_fail "3.3 gh label list recorded" "log: $(cat "$GH_LOG")"
[[ $(grep -c '|label create ' "$GH_LOG") -ge 1 ]] \
    && t_pass "3.4 gh label create recorded" \
    || t_fail "3.4 gh label create recorded" "log: $(head -5 "$GH_LOG")"

# ─────────────────────────────────────────────────────────────────
# Group 4: GH_REPO env override wins (test seam preserved)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: caller GH_REPO override preserved ===\n"

export GH_REPO="forced/override-repo"
export _TRACKER_PROVIDER_CONFIG_PATH="$TOML2"
: > "$GH_LOG"
tracker_provider_gh_get 1 >/dev/null 2>&1 || true
got=$(grep -c '^GH_REPO=forced/override-repo|' "$GH_LOG" || true)
[[ "$got" -ge 1 ]] && t_pass "4.1 caller GH_REPO override wins over tracker.toml" \
    || t_fail "4.1 caller GH_REPO override wins over tracker.toml" \
        "log: $(cat "$GH_LOG")"
unset GH_REPO

# ─────────────────────────────────────────────────────────────────
# Group 5: BD-129 retro-fix F7 — non-GitHub remote variant
# (GitLab / GHE-on-different-host / internal mirror). The BACKLOG
# entry's Unblocks line names "non-GitHub remotes, internal mirrors,
# GHE-on-different-host" alongside "no remote at all"; Group 3
# already covers no-remote, this group covers the hostile-remote
# case where a wrong git remote exists and `tracker_gh_repo_setup`
# must still win and route every gh call to the tracker.toml slug.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: tracker.toml slug wins over hostile non-GitHub git remote ===\n"

unset GH_REPO
TOML5="$WORKDIR/r5.toml"
cat > "$TOML5" <<'TOML'
schema_version = 1
[backend]
name = "github"
repo = "owner-5/repo-5"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = false
TOML
export _TRACKER_PROVIDER_CONFIG_PATH="$TOML5"
: > "$GH_LOG"

mkdir -p "$WORKDIR/gitlab-remote-repo"
cd "$WORKDIR/gitlab-remote-repo"
git init -q . 2>/dev/null || true
# Hostile (non-GitHub) remote: simulates a working copy whose git
# remote points at a GitLab instance (or any non-GitHub host). Pre-
# fix and pre-helper-call, gh would either consult this URL and emit
# the misleading "none of the git remotes ..." error, or attempt to
# auth against the wrong host. Post-fix, GH_REPO must be exported
# from tracker.toml and gh's git-remote resolution must be skipped
# entirely.
git remote add origin "https://gitlab.example.com/owner-5/repo-5.git" 2>/dev/null || true

out5=$(tracker_labels_ensure 2>&1)
rc5=$?
cd "$REPO_ROOT"

assert_eq "5.1 tracker_labels_ensure rc=0 with hostile non-GitHub git remote" "0" "$rc5"

total5=$(wc -l < "$GH_LOG" | tr -d ' ')
ok5=$(grep -c '^GH_REPO=owner-5/repo-5|' "$GH_LOG" || true)
assert_eq "5.2 all gh calls saw GH_REPO=owner-5/repo-5 (count=$total5) — tracker.toml slug won over gitlab remote" \
    "$total5" "$ok5"

# Negative assertion: NO gh call should have been made with GH_REPO=<unset>
# (which would indicate the helper failed to fire and gh might have
# fallen back to the gitlab remote URL).
unset_count=$(grep -c '^GH_REPO=<unset>|' "$GH_LOG" || true)
assert_eq "5.3 no gh call saw GH_REPO unset (helper fired for every invocation)" \
    "0" "$unset_count"

# Restore PATH for any post-suite tooling.
export PATH="$ORIG_PATH"

printf "\n=== Results: %d passed, %d failed ===\n" "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
