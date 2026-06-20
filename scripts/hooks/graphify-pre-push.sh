#!/usr/bin/env bash
# pack-internal: true
# graphify pre-push background graph-refresh (BD-237). Never blocks a push.
#
# Installed (per-clone, one-time) by scripts/install-graphify-hook.sh into the
# shared common git hooks dir as `pre-push`. On every `git push` it refreshes
# the gitignored Graphify knowledge graph IN THE BACKGROUND (detached) and
# returns immediately so a refresh problem NEVER blocks the push.
#
# Design notes (BD-237 plan §4):
#   - NO `set -e`: a non-zero refresh must not abort the hook before `exit 0`.
#   - Stock macOS bash is 3.2 — no `mapfile`/`readarray`/bash-4 features.
#   - flock(1) is ABSENT on macOS, so the skip-lock is the `mkdir`-atomic
#     primitive; the BACKGROUND subshell (not the foreground) releases it.
#   - Root = the push-invoking worktree via `git rev-parse --show-toplevel`
#     + an existence guard; the refresh subshell `cd`s into $ROOT so graphify's
#     `_git_head()` (git rev-parse HEAD against process CWD) stamps the correct
#     built_at_commit.

# 1. Drain stdin FIRST so git's pipe never blocks, then keep it for the range
#    derivation. pre-push delivers one line per pushed ref:
#       <local ref> <local oid> <remote ref> <remote oid>
STDIN_REFS="$(cat)"
zero="$(git hash-object --stdin </dev/null 2>/dev/null | tr '0-9a-f' '0')"

# 2. Resolve the root + existence guard (plan §3 / resolution 1).
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$ROOT" ] && [ -d "$ROOT/graphify-out" ] || exit 0

# 3. graphify-executable guard (silent no-op if graphify is missing).
GFX="$(command -v graphify)"
[ -n "$GFX" ] && [ -x "$GFX" ] || exit 0

# 4. Derive the doc-gate decision over the whole push (plan §4 step 2 /
#    resolution 6). Walk every pushed-ref line:
#      - DELETE  (local_oid == zero)  -> contributes no range (skip that ref)
#      - NEW BRANCH (remote_oid == zero) -> range = local_oid (all new commits)
#      - UPDATE / force (else)        -> range = remote_oid..local_oid
#    Union semantics: if ANY non-delete range touches a .md/.pdf doc-layer
#    file -> SEMANTIC branch; else -> CODE branch.
#    Conservative fallback (covers ambiguity): if any `git diff` over a range
#    errors, OR stdin is empty/unavailable, OR the push is delete-only -> full
#    code-only `update` (never the costlier semantic branch by accident, never
#    a hard error). A range that DELETED a file sets GRAPHIFY_FORCE on the
#    CODE branch only.
REFRESH_MODE="code"      # code | semantic
RANGE_SEEN=0             # did we see at least one non-delete ref?
SAW_DOC=0                # did any non-delete range touch a .md/.pdf?
SAW_DELETE_IN_RANGE=0    # did any non-delete range delete a file?
RANGE_ERROR=0            # did any name-derivation over a range error?

# Emit the names changed by a pushed ref, ONE per line, on stdout.
# - NEW BRANCH (remote oid all-zeros): names across ALL new commits — the
#   commits reachable from the tip but not on any remote-tracking ref
#   (`git rev-list <tip> --not --remotes` | `git diff-tree --stdin`).
# - UPDATE / force-push: the two-dot diff `remote_oid..local_oid`.
# Prints nothing + returns non-zero on any failure (-> conservative fallback).
_changed_names() {
  _lo="$1"; _ro="$2"
  if [ -n "$zero" ] && [ "$_ro" = "$zero" ]; then
    # Capture rev-list output FIRST and check its rc BEFORE piping to
    # diff-tree. A pipeline's exit status reflects only its LAST command, so a
    # bare `rev-list | diff-tree` would MASK a rev-list failure (diff-tree
    # succeeds on empty input -> return 0 + empty -> caller never trips
    # RANGE_ERROR). Capturing decouples the two rcs (bash-3.2-safe; no
    # pipefail, no `set -e`).
    _revs="$(git rev-list "$_lo" --not --remotes 2>/dev/null)" || return 1
    printf '%s\n' "$_revs" \
      | git diff-tree --no-commit-id --name-only -r --stdin 2>/dev/null
  else
    git diff --name-only "$_ro..$_lo" 2>/dev/null
  fi
}

# Return 0 (success) iff the ref's changes DELETED at least one file.
# Same range logic as _changed_names, filtered to deletions.
_deleted_names() {
  _lo="$1"; _ro="$2"
  if [ -n "$zero" ] && [ "$_ro" = "$zero" ]; then
    # Same masking fix as _changed_names: capture rev-list FIRST so a rev-list
    # failure is detectable (return 1 = "no deletion seen", the conservative
    # outcome) rather than being swallowed by the trailing grep's rc.
    _revs="$(git rev-list "$_lo" --not --remotes 2>/dev/null)" || return 1
    printf '%s\n' "$_revs" \
      | git diff-tree --no-commit-id --name-only -r --diff-filter=D --stdin 2>/dev/null \
      | grep -q .
  else
    git diff --name-only --diff-filter=D "$_ro..$_lo" 2>/dev/null | grep -q .
  fi
}

# bash-3.2-safe line iteration (no `mapfile`); skip blank lines.
# Iterate lines with IFS=newline; split each line's fields back on whitespace
# (default IFS = space/tab/newline) so `set --` recovers the four columns
# (<local ref> <local oid> <remote ref> <remote oid>).
NL='
'
OLD_IFS="$IFS"
IFS="$NL"
for line in $STDIN_REFS; do
  [ -n "$line" ] || continue
  IFS=' 	'"$NL"
  # shellcheck disable=SC2086
  set -- $line
  IFS="$NL"
  local_oid="$2"
  remote_oid="$4"
  if [ -z "$local_oid" ]; then
    continue
  fi
  if [ -n "$zero" ] && [ "$local_oid" = "$zero" ]; then
    continue                       # DELETE ref: no range
  fi
  RANGE_SEEN=1
  # Names changed by this ref (any change). A derivation error or empty set is
  # treated conservatively: empty -> no doc/delete signal (stays code); the
  # explicit error sentinel below forces the full-update fallback.
  names="$(_changed_names "$local_oid" "$remote_oid")"
  if [ $? -ne 0 ]; then
    RANGE_ERROR=1
    continue
  fi
  if printf '%s\n' "$names" | grep -Eq '\.(md|pdf)$'; then
    SAW_DOC=1
  fi
  # A deletion anywhere in this ref's changes binds GRAPHIFY_FORCE (code branch).
  if printf '%s\n' "$names" | grep -q . && _deleted_names "$local_oid" "$remote_oid"; then
    SAW_DELETE_IN_RANGE=1
  fi
done
IFS="$OLD_IFS"

if [ "$RANGE_ERROR" -eq 1 ] || [ "$RANGE_SEEN" -eq 0 ]; then
  REFRESH_MODE="code"              # ambiguous / empty / delete-only -> full update
  SAW_DELETE_IN_RANGE=0           # full update on an opaque/delete-only push
elif [ "$SAW_DOC" -eq 1 ]; then
  REFRESH_MODE="semantic"
else
  REFRESH_MODE="code"
fi

# 5. Outer mkdir skip-lock (plan §4 step 5; flock absent -> mkdir-atomic).
#    The lock is a DIRECTORY; it is released by the BACKGROUND subshell's EXIT
#    trap (step 7a), NOT here — the foreground exits immediately, so it must
#    NOT rmdir the lock (that would double-rmdir / drop the in-flight guard).
LOCK="$ROOT/graphify-out/.pack-refresh.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "graphify: refresh already in flight; skipping" >&2
  exit 0
fi

# 6. Next-run consult — DUAL signal, both LOCAL reads of the graph's own state
#    (plan §4 step 6 / resolution 2b). Human-visible at this push; the refresh
#    runs regardless.
STATUS_FILE="$ROOT/graphify-out/.pack-refresh-status"
if [ -f "$STATUS_FILE" ] && [ "$(cut -d' ' -f1 "$STATUS_FILE" 2>/dev/null)" = "fail" ]; then
  echo "graphify: previous refresh FAILED at $(cut -d' ' -f2 "$STATUS_FILE" 2>/dev/null); re-running" >&2
fi
# (b) built_at_commit-behind: catches a refresh KILLED mid-run (no token).
#     built_at_commit is the LAST JSON field, so a bounded tail recovers it.
GBC="$(tail -c 200 "$ROOT/graphify-out/graph.json" 2>/dev/null \
       | grep -o '"built_at_commit": *"[0-9a-f]*"' | grep -o '[0-9a-f]\{7,\}')"
HEADC="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)"
if [ -n "$GBC" ] && [ -n "$HEADC" ] && [ "$GBC" != "$HEADC" ]; then
  echo "graphify: graph is STALE (built at ${GBC}, HEAD ${HEADC}); refreshing" >&2
fi

# 7. Background-detached refresh subshell. `disown` after launch keeps it alive
#    past `git push` exit on bash 3.2 (no `setsid` on macOS). The subshell
#    releases the lock via its EXIT trap.
(
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT
  # Key-clean: refuse the paid auto-route (subscription-only); defense in depth
  # — every graphify line below also pins/honors --backend claude-cli.
  unset GEMINI_API_KEY GOOGLE_API_KEY OPENAI_API_KEY
  # cd into $ROOT so _git_head() stamps $ROOT's HEAD into $ROOT's graph.
  cd "$ROOT" || exit 0

  attempt=1
  rc=1
  while [ "$attempt" -le 2 ]; do
    if [ "$REFRESH_MODE" = "semantic" ]; then
      # extract derives its out-dir from the "$ROOT" target arg (appends
      # literal graphify-out); GRAPHIFY_OUT is INERT on extract, so it is NOT
      # set here. NEVER --backend claude (paid). NEVER --no-viz (unknown opt on
      # extract). NEVER GRAPHIFY_FORCE on extract (it prunes removals natively).
      GRAPHIFY_CLAUDE_CLI_PARALLEL=0 graphify extract "$ROOT" --backend claude-cli
      rc=$?
    else
      # update/_rebuild_code HONORS GRAPHIFY_OUT (absolute) AND takes the
      # explicit "$ROOT" scan-root arg; both pin the write to $ROOT/graphify-out.
      # GRAPHIFY_FORCE=1 only when this push DELETED a file (bypasses the
      # node-shrink safety check after a delete).
      if [ "$SAW_DELETE_IN_RANGE" -eq 1 ]; then
        GRAPHIFY_FORCE=1 GRAPHIFY_OUT="$ROOT/graphify-out" graphify update "$ROOT"
        rc=$?
      else
        GRAPHIFY_OUT="$ROOT/graphify-out" graphify update "$ROOT"
        rc=$?
      fi
    fi
    [ "$rc" -eq 0 ] && break        # success -> no retry
    attempt=$((attempt + 1))         # single self-retry (2 attempts total)
  done

  # Result record — written ATOMICALLY (tmp + mv) so a kill mid-write cannot
  # leave a torn first token. ADVISORY: the load-bearing staleness signal is
  # the built_at_commit-vs-HEAD check (step 6b + pack-startup).
  FINAL_HEAD="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)"
  NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"
  TMP="$ROOT/graphify-out/.pack-refresh-status.tmp"
  if [ "$rc" -eq 0 ]; then
    printf 'ok %s %s\n' "$FINAL_HEAD" "$NOW" > "$TMP" 2>/dev/null
  else
    printf 'fail %s %s\n' "$FINAL_HEAD" "$NOW" > "$TMP" 2>/dev/null
  fi
  mv "$TMP" "$STATUS_FILE" 2>/dev/null
) >/dev/null 2>&1 &
disown 2>/dev/null || true

# 8. Foreground returns immediately — the push proceeds.
exit 0
