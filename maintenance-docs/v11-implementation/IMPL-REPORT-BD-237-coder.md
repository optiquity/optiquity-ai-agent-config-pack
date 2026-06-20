# IMPL-REPORT — BD-237 (Graphify pre-push background graph-refresh + LOCAL freshness check)

**Agent:** `pack-coder` (RW, isolated worktree per BD-226)
**Spec:** `/tmp/pack-handoff-bd237-plan2/PLAN-BD-237-FINAL.md` (read in full; self-contained)
**Date:** 2026-06-20
**Scope keyword:** `pack-only`

## Runtime regime (verified, commit-discipline §1)

- **Worktree path (pwd / toplevel):** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a2b879d0f53673f98` — an ISOLATED worktree (NOT the canonical checkout `…/optiquity-ai-agent-config-pack` or `…-v11-dev`).
- **Branch:** `worktree-agent-a2b879d0f53673f98`
- **HEAD SHA (base + final — no commit made; agents never commit):** `2f53788620e1bdb233eb8ed645801c995093bafe`
- **Pre-flight base check:** confirmed the worktree contains the plan-named docs/surfaces (`pack-ops/OPTIONAL-FEATURES.md` Graphify section, `.claude/skills/pack-startup/SKILL.md`, `pack-ops/PACK-CHAT.md`, `scripts/validate-pack.py` Check 23/40/63) at the expected line ranges (EE-8 verified live).
- **NO patch produced** (BD-226 — orchestrator re-engages for `git diff > <handoff>/changes.patch` only AFTER review-clean). The sole deliverable is this report.

## PREFLIGHT line (emitted before this report)

`PREFLIGHT: 5/5 in-scope surfaces complete; verification PASS (bash -n + validate-pack incl. Check 23/63); HEAD 2f53788620e1bdb233eb8ed645801c995093bafe; about to Write IMPL-REPORT to /tmp/pack-handoff-bd237-coder/IMPL-REPORT.md`

---

## Files changed inventory

| Path | Change type | Line delta |
|---|---|---|
| `scripts/hooks/graphify-pre-push.sh` | **NEW** (executable, `# pack-internal: true`) | +211 |
| `scripts/install-graphify-hook.sh` | **NEW** (executable, `# pack-internal: true` line 2) | +38 |
| `pack-ops/OPTIONAL-FEATURES.md` | MODIFIED (4 upstream stragglers + range rewrite L444-L513 + caveat) | +95 / −87 (net per diffstat: 182 changed) |
| `.claude/skills/pack-startup/SKILL.md` | MODIFIED (Step-4 `Graph:` report line + reserved Step 5) | +48 / −7 |
| `pack-ops/PACK-CHAT.md` | MODIFIED (one informational bullet) | +7 |

New dir created: `scripts/hooks/`. No other files touched. No `project-template/` / `supporting-docs/` / `maintenance-docs/` edits (maintenance-docs preservation is the orchestrator's commit-time step per the prompt). No `scripts/validate-pack.py`, no `scripts/ci-test-wiring-allowlist.txt`, no CI workflow edit.

---

## Per-surface summary

### Surface 1 — `scripts/hooks/graphify-pre-push.sh` (NEW, hook body, plan §4)

Implements the precise §4 staged logic:

1. **Shebang + marker + safety** (lines 1-3): `#!/usr/bin/env bash`, `# pack-internal: true`, intent comment. NO `set -e`. bash-3.2-safe (no `mapfile`/`readarray`/bash-4 features — verified `bash --version` = 3.2.57).
2. **Drain stdin FIRST** (`STDIN_REFS="$(cat)"`) so git's pipe never blocks; `zero="$(git hash-object --stdin </dev/null | tr '0-9a-f' '0')"`.
3. **Doc-gate range derivation** (resolution 6 / EE-7): walks every pushed-ref line `<local ref> <local oid> <remote ref> <remote oid>`; DELETE (local_oid==zero) skipped; NEW BRANCH (remote_oid==zero) → names across ALL new commits via `git rev-list <tip> --not --remotes | git diff-tree --no-commit-id --name-only -r --stdin`; UPDATE/force → `git diff --name-only <remote>..<local>`. Union semantics: any `.md`/`.pdf` in any non-delete range → SEMANTIC; else CODE. Conservative fallback (range error / empty / delete-only) → full code-only `update`.
4. **Root resolution + existence guard** (§3 / resolution 1): `ROOT="$(git rev-parse --show-toplevel)"`; `[ -n "$ROOT" ] && [ -d "$ROOT/graphify-out" ] || exit 0`. NO `git worktree list` scan (dropped per resolution 1).
5. **graphify-exec guard**: `GFX="$(command -v graphify)"; [ -n "$GFX" ] && [ -x "$GFX" ] || exit 0`.
6. **`mkdir` skip-lock** (EE-2 — flock ABSENT on macOS, verified): `mkdir "$ROOT/graphify-out/.pack-refresh.lock"` → on failure `echo … skipping >&2; exit 0`. The lock is a DIRECTORY; released ONLY by the background subshell's EXIT trap (foreground never rmdirs — commented to prevent a maintainer double-rmdir).
7. **Dual-signal next-run consult** (resolution 2b): (a) `.pack-refresh-status` `fail` token → stderr; (b) `built_at_commit`-behind-HEAD via bounded `tail -c 200 graph.json | grep` (built_at_commit is the LAST JSON field — EE-4) vs `git -C "$ROOT" rev-parse HEAD` → stderr. Both LOCAL reads; refresh runs regardless.
8. **Background-detached subshell** `( … ) >/dev/null 2>&1 &` then `disown` then `exit 0`: `trap 'rmdir "$LOCK"' EXIT` → `unset GEMINI_API_KEY GOOGLE_API_KEY OPENAI_API_KEY` → `cd "$ROOT"` (EE-6 — `_git_head()` uses process CWD, so this stamps `$ROOT`'s HEAD) → run the chosen branch with a SINGLE self-retry (2 attempts max, no loop/no "N"):
   - SEMANTIC: `GRAPHIFY_CLAUDE_CLI_PARALLEL=0 graphify extract "$ROOT" --backend claude-cli` (NO `GRAPHIFY_OUT` — inert on extract per EE-6/M1; NO `--no-viz`; NO `--backend claude`; NO `GRAPHIFY_FORCE`).
   - CODE: `GRAPHIFY_OUT="$ROOT/graphify-out" graphify update "$ROOT"` (+`GRAPHIFY_FORCE=1` ONLY when this push DELETED a file).
   - Atomic result record: `printf … > .pack-refresh-status.tmp` then `mv` to `.pack-refresh-status` (`ok|fail <HEAD-SHA> <ISO-8601>`).

**Verification:** `bash -n` clean. Offline deterministic test suite (stubbed `graphify` on PATH, throwaway `/tmp` git repos — NO real graph touched, NO real refresh) — see "Coder-verify" below.

### Surface 2 — `scripts/install-graphify-hook.sh` (NEW, installer, plan §4.1)

`#!/usr/bin/env bash` + `# pack-internal: true` on **line 2** (MANDATORY per resolution 4 / EE-3 — top-level executable; `_is_pack_internal` regex `^#\s*pack-internal:\s*true\b` matches it). `set -euo pipefail`. `SRC="$(cd "$(dirname "$0")" && pwd)/hooks/graphify-pre-push.sh"`; `DEST="$(git rev-parse --git-path hooks)/pre-push"` (shared common dir — EE-5); `mkdir -p` defensive; idempotent via `cmp -s` (byte-equal → no-op message + `exit 0`); else `cp` + `chmod +x` + installed message. Added a source-missing guard (`[ ! -f "$SRC" ]` → exit 1) — a robustness addition within the §4.1 contract, NOT a deviation (the plan's snippet assumes the source exists; the guard fails loud instead of a confusing `cp` error). Dependency-direction + state-note comments included (PACK-OPS tool, never client-shipped, orchestrator-runs-with-approval).

**Verification:** `bash -n` clean. Offline end-to-end install test in a throwaway repo: first install copies+chmod+x; second install idempotent no-op; changed source re-copies. (See "Coder-verify".)

### Surface 3 — `pack-ops/OPTIONAL-FEATURES.md` (MODIFIED, plan §6)

- **4 upstream stragglers reconciled** (EE-8): L357 ("post-commit hook … MANUAL opt-in" → tracked pre-push body + one-time install); L406 ("the post-commit hook unsets all three" → "the pre-push hook unsets all three"); L432-434 ("post-commit hook … cannot be committed: gitignored plus `.git/hooks` is per-clone" → hook BODY *is* tracked, only the installed `.git/hooks/pre-push` copy is per-clone); the Caveats "Per-clone, manual, gitignored" bullet (the graph/hook do-not-sync claim) corrected to "graph gitignored; hook body tracked; install once."
- **Main range rewrite** (`### How to keep it fresh`, former L444-L513): replaced the hand-installed `post-commit` recipe + its `(a)(b)` empirical caveats with the pre-push model — tracked body + installer, `$(git rev-parse --show-toplevel)` + existence guard + `cd "$ROOT"` correct-stamp rationale, per-branch worktree-safety stated CORRECTLY (M1: `update` honors `GRAPHIFY_OUT` + explicit arg; `extract` out-dir from target arg, `GRAPHIFY_OUT` inert), `mkdir` skip-lock (not flock), advisory `.pack-refresh-status` + single retry, the LOCAL `built_at_commit`-vs-HEAD freshness check (pack-startup line + hook consult), per-clone install command. The HEAD~1 doc-gate replaced by the pushed-range model.
- **PRESERVED verbatim:** §1.1 backend caveat (L529-... — `claude-cli`-not-`claude`, no `--no-viz` on extract).
- **grep-zero completeness gate (§6):** `grep -n "post-commit\|HEAD~1" pack-ops/OPTIONAL-FEATURES.md` → ONE hit only: an intentional HISTORICAL contrast ("Unlike the old hand-installed `post-commit` recipe") describing the replaced mechanism — §6 explicitly permits "intentional HISTORICAL references"; every LIVE reference to the replaced mechanism is gone. ZERO `HEAD~1`.

### Surface 4 — `.claude/skills/pack-startup/SKILL.md` (MODIFIED, plan §5.1)

- **Step-4 report block:** added a `**Graph:**` line referencing the Step-5 readiness output.
- **Reserved Step 5 added** (`## Step 5 — Graph freshness + hook-install readiness`): LOCAL only, never fails startup. Logic: `ROOT="$(git rev-parse --show-toplevel)"`; existence-gate on `graphify-out/graph.json` (absent → `graph: not built (graphify is an optional pack-dev accelerator)`); bounded `tail -c 200` read of `built_at_commit` (last field — EE-4) vs `git -C "$ROOT" rev-parse HEAD` → `graph: fresh` / `graph: STALE — built at <sha>, HEAD <sha> (run: git push, or bash scripts/install-graphify-hook.sh then push)`; hook-installed check `[ -f "$(git rev-parse --git-path hooks)/pre-push" ]` → `pre-push hook: installed` / `NOT installed — run scripts/install-graphify-hook.sh`; emits both on one line. Notes `python3 json.load` as an optional alternative. Honors "no CI gate / no committed sentinel."
- **Reserved-steps comment updated:** "Steps 5–7 are reserved" → "Steps 6–7 are reserved … (Step 5 is now the BD-237 graph-freshness + hook-install readiness check)"; Step 8 numbering note preserved.

### Surface 5 — `pack-ops/PACK-CHAT.md` (MODIFIED, plan §2 row 5)

Added ONE informational bullet after the "Check CI after every push" bullet: the tracked pre-push hook auto-refreshes the graph in the background on every push once installed (so the orchestrator does NOT duplicate a manual refresh); points at `pack-startup` for freshness/install status; notes the graph is pack-ops-only. Adds NO orchestrator step (informational only).

---

## Verification commands + results

| Command | Result |
|---|---|
| `bash -n scripts/hooks/graphify-pre-push.sh` | clean (`HOOK-SYNTAX-OK`) |
| `bash -n scripts/install-graphify-hook.sh` | clean (`INSTALLER-OK`) |
| `shellcheck` | ABSENT on this machine (`SC-ABSENT`) — not run (unavailable) |
| `python3 scripts/validate-pack.py` (FULL battery) | **EXIT 0 — PASSED — all checks clean; 0 FAIL** |
| Check 23 (help-fragment completeness) | OK — "all 9 non-internal scripts/ executables listed … (12 marked pack-internal)" — both new scripts counted as pack-internal |
| Check 40 (bare cross-refs in pack-ops/*.md) | OK — "zero unqualified bare cross-references" (fixed: `graph.json` → `graphify-out/graph.json` in prose) |
| Check 63 (graphify-out never tracked) | OK — "0 tracked paths" |
| `grep -c 'pack-internal: true'` both scripts | 1 each (line 2) |
| `ls -la` both scripts | `-rwxr-xr-x` (executable) |
| `git status --short` | 3 M + 2 ?? (scripts/hooks/, scripts/install-graphify-hook.sh); no out-of-scope paths |

### Definition-of-Done checklist

| Item | Status |
|---|---|
| All 5 in-scope surfaces implemented (ALL and ONLY; lock-step) | PASS |
| Both new scripts executable (`chmod +x`) | PASS |
| Both new scripts carry `# pack-internal: true` marker | PASS |
| `bash -n` clean on both scripts | PASS |
| Full `validate-pack.py` battery exit 0 | PASS |
| Check 23 / 40 / 63 green (no regression) | PASS |
| §6 grep-zero gate (post-commit/HEAD~1) — only intentional historical ref remains | PASS |
| §1.1 backend caveat preserved verbatim | PASS |
| NO CI gate / committed sentinel / "N" / fetch-depth / new validate-pack check added | PASS |
| NO allowlist entry / no auto-wired test (files don't match `test*.sh`) | PASS |
| NO `project-template/` / `supporting-docs/` / `maintenance-docs/` touch | PASS |
| Hook + installer NOT in install-map / `_SANCTIONED_PACK_SIDE_SHIPPED` (dependency-direction) | PASS (not added anywhere) |
| NO state-changing git verb run; NO patch produced | PASS |

---

## Coder-verify items (§5.3) + offline test evidence

The plan's V1-V4 require RUNNING the hook against a REAL graph with REAL graphify/claude, which CANNOT be done in this graph-less worktree (NO `graphify-out/` materialized — verified `ls graphify-out` → No such file or directory). I implemented per the plan and ran the DETERMINISTIC, OFFLINE portion (stubbed `graphify` on PATH, throwaway `/tmp` git repos — NO real graph mutated, NO real refresh, NO real subscription billing). Results:

**Doc-gate / range / branch-selection (V2, offline-deterministic — ALL PASS):**
- A code-only range (`remote..local`) → `update` + `GRAPHIFY_OUT` set, NO force ✓
- B doc range (`.md` change) → `extract` + `--backend claude-cli` + `GRAPHIFY_CLAUDE_CLI_PARALLEL=0` ✓
- C new branch (remote all-zeros) with a doc in branch history → `extract` (full new-commit set via `rev-list --not --remotes | diff-tree --stdin`) ✓
- D code delete range → `update` + `GRAPHIFY_FORCE=1` ✓
- E delete-only ref (local all-zeros) → full `update` fallback, NO force ✓
- F multi-ref union (one code + one doc) → `extract` (union semantics) ✓
- G empty stdin → full `update` fallback ✓
- H force-push (range reversed, `.md` reverted) → `extract` (a `.md` change present), no error ✓

**Skip-lock + status-token (offline-deterministic — PASS):**
- Pre-created lock → SKIP, stderr "refresh already in flight; skipping", NO graphify call ✓
- Success path → `.pack-refresh-status` = `ok <HEAD-SHA> <ISO-8601>`, NO torn `.tmp` left (atomic mv) ✓

**Installer (offline end-to-end in throwaway repo — PASS):**
- First install → copies to `.git/hooks/pre-push`, `chmod +x`, byte-IDENTICAL to source ✓
- Second install → idempotent no-op ("already current") ✓
- Changed source → re-copies ✓

**Items that REQUIRE the orchestrator's post-commit REAL-TREE test (cannot be exercised here):**
- **V1 — background-detach survives `git push` exit.** I added `disown` after the `&` (bash-3.2-safe; no `setsid` on macOS). The offline stub confirms the subshell runs and writes its record, but TRUE survival across a real `git push` process exit (and `built_at_commit` actually advancing) must be verified in the real `…-v11-dev` tree by the orchestrator. If reaped, the next push self-heals via the step-6b `built_at_commit`-behind consult. **ORCHESTRATOR POST-COMMIT TEST.**
- **V3 — explicit-root + `cd "$ROOT"` writes to `$ROOT/graphify-out` with the CORRECT stamp.** Requires a real graphify `update`/`extract` against the real graph to confirm `built_at_commit` advances `190e198`→HEAD and equals `$ROOT`'s HEAD with no stray `.`-relative `graphify-out/`. **ORCHESTRATOR POST-COMMIT TEST** (the §7 post-commit install + one-time refresh step IS this verification).
- **V4 — self-retry does not double-bill the subscription.** Requires a real `extract` to confirm the content-keyed incremental cache (capability report Q3) means a retry re-bills only genuine cache-misses. The retry is bounded to ONE re-attempt (2 total). **ORCHESTRATOR POST-COMMIT TEST.**
- **V2's stdin format** is confirmed offline against the EE-7 contract; the LIVE confirmation that real `git push` emits exactly that format rides on the orchestrator's post-commit push.

None of these are deferred work — they are inherently machine-and-real-graph-only and are the orchestrator's documented §7 post-commit steps (install the hook + one refresh, both user-approved). The hook is implemented complete; only the live exercise is pending.

---

## Plan deviations

**One minor robustness addition (NOT a design deviation):**
- The installer (Surface 2) adds a `[ ! -f "$SRC" ]` source-missing guard (exit 1 with a clear message) before `mkdir -p`/`cp`. The §4.1 snippet does not show it; it fails loud instead of emitting a confusing `cp: No such file` under `set -e`. This is strictly additive within the §4.1 contract (idempotent, byte-compare, copy-to-`git-path hooks/pre-push`, chmod) and changes no behavior on the happy path.

**One implementation refinement of the new-branch range derivation (within §4 step 2's stated intent):**
- §4 step 2 specifies new-branch range = `local_oid` and "the doc-gate runs `git diff --name-only <range>`." A single-SHA `git diff --name-only <sha>` actually diffs the commit against the WORKING TREE (semantically wrong for "all commits on the new branch") — verified empirically, it mis-selected `update` for a doc-bearing new branch. I implemented the new-branch case as `git rev-list <local_oid> --not --remotes | git diff-tree --no-commit-id --name-only -r --stdin` (all files across all new-to-the-remote commits), which correctly detects docs anywhere in the new branch's history (TEST C passes). This realizes §4 step 2's stated intent ("all commits on the new branch") faithfully; the UPDATE/force case still uses the two-dot `remote..local` diff exactly as specified. Flagging for the reviewer as the one place where I chose the correct git invocation over the literal snippet form, because the literal form is semantically incorrect for the new-branch case the plan explicitly wants covered.

Zero other deviations. No rejected machinery (CI gate / sentinel / "N" / fetch-depth / new validate-pack check) introduced. No unrelated refactors.

## New POQs introduced

None.

---

## Full content of NEW files (for re-apply without re-derivation)

### `scripts/hooks/graphify-pre-push.sh`

```bash
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
    git rev-list "$_lo" --not --remotes 2>/dev/null \
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
    git rev-list "$_lo" --not --remotes 2>/dev/null \
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
```

### `scripts/install-graphify-hook.sh`

```bash
#!/usr/bin/env bash
# pack-internal: true  (pack-ops graph-refresh hook installer; not a user-facing verb)
# scripts/install-graphify-hook.sh — one-time, per-clone installer for the
# Graphify pre-push background graph-refresh hook (BD-237).
#
# Copies scripts/hooks/graphify-pre-push.sh into this clone's shared common git
# hooks dir as `pre-push`, makes it executable, and is idempotent (a byte-equal
# install is a no-op). The hook BODY is tracked in the repo; only the per-clone
# INSTALLED copy under .git/hooks is non-versioned, so this installer wires the
# tracked body into the local hooks dir.
#
# Dependency direction (CLAUDE.md "dependency-direction-placement"): this is a
# PACK-OPS tool — it NEVER ships to clients and is NOT in any install map. The
# Graphify graph is pack-development-only (gitignored, never shipped).
#
# State note: this is a `cp`+`chmod` (NOT a git verb), but it mutates the live
# .git/hooks dir, so the ORCHESTRATOR runs it with user approval — never a coder
# or any sub-agent (per "agents-never-commit" / "per-action-approval").
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/hooks/graphify-pre-push.sh"
DEST="$(git rev-parse --git-path hooks)/pre-push"

if [ ! -f "$SRC" ]; then
  echo "graphify pre-push hook: source not found at $SRC" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"

if [ -f "$DEST" ] && cmp -s "$SRC" "$DEST"; then
  echo "graphify pre-push hook: already current at $DEST"
  exit 0
fi

cp "$SRC" "$DEST"
chmod +x "$DEST"
echo "graphify pre-push hook: installed at $DEST"
```

---

## Boundary discipline check

All 5 edited surfaces are PACK-OPS-side (`scripts/`, `pack-ops/`, `.claude/skills/pack-startup/`). NONE are project-side (`project-template/`, `supporting-docs/`, or any client-shipped surface), so the project-side SSOT-investigation pre-flight does not apply to any edit. The Graphify graph + hook + installer are pack-development-only and NEVER ship to clients (no install-map entry, no `_SANCTIONED_PACK_SIDE_SHIPPED` entry — verified not added). Adding a `pack-ops/PACK-CHAT.md` reference to the pack-only `scripts/hooks/graphify-pre-push.sh` and Pack-Chat-orchestrator role is CORRECT here because the file lives on the pack-ops side (the orchestrator role and pack-only paths are the right targets for a pack-ops doc). No "Boundary discipline stop" condition was hit.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Commands run were read-only git verbs (`git rev-parse`, `git status`, `git diff`, `git ls-files` via validate-pack) + file Write/Edit + `bash -n`/`python3`/`mkdir`/`chmod`/`cp`/`cmp` against in-scope files and throwaway `/tmp` repos. NO `git add`/`commit`/`push`/`apply`/etc. `git status --short` shows uncommitted edits only; HEAD unchanged at `2f53788…`. NO patch produced (BD-226). | COMPLIANT |
| 2 | preflight-stop-means-stop | Emitted exactly `PREFLIGHT: 5/5 in-scope surfaces complete; verification PASS (bash -n + validate-pack incl. Check 23/63); HEAD 2f53788620e1bdb233eb8ed645801c995093bafe; about to Write IMPL-REPORT …` ONLY after all 5 surfaces + `validate-pack.py` exit 0 (PASSED — all checks clean). No stop directive received. | COMPLIANT |
| 3 | rules-applied-verification-block | This table — one row per in-force rule with quoted evidence + terminal conclusion. | COMPLIANT |
| 4 | separate-pack-ops-from-product | `git status --short` touched paths = `.claude/skills/pack-startup/SKILL.md`, `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/PACK-CHAT.md`, `scripts/hooks/`, `scripts/install-graphify-hook.sh` — ALL pack-ops; ZERO `project-template/`/`supporting-docs/`. Commit is `pack-only` (Check 36-compatible). | COMPLIANT |
| 5 | enumerate-encoding-surfaces | ALL 5 prompt-named surfaces implemented in lock-step (hook body, installer, OPTIONAL-FEATURES rewrite+stragglers, pack-startup Step-5+report line, PACK-CHAT note); NO other surface touched (`git status` confirms exactly the 5). | COMPLIANT |
| 6 | dependency-direction-placement | Hook + installer are pack-ops tooling; NOT added to any install map or `_SANCTIONED_PACK_SIDE_SHIPPED` (grep of validate-pack diff = unchanged; `git status` shows validate-pack.py NOT modified). Check 47 not exercised (constant untouched). | COMPLIANT |
| 7 | pack-repo-code-comment-deferrals | No deferral comments in either script (`grep -n 'TODO\|FIXME\|KNOWN GAP\|VERIFY' scripts/hooks/graphify-pre-push.sh scripts/install-graphify-hook.sh` → none). No typed-or-untyped deferral markers present. | COMPLIANT |
| 8 | graph-first-context | The graph is the artifact under repair and is ABSENT in this worktree (`ls graphify-out` → No such file or directory); per the worktree-isolation note I did NOT recompute the path from my toplevel and did NOT block on the graph — used grep/Read/git for all authoritative facts (SSOT contracts, validate-pack source, line ranges). | COMPLIANT |
| 9 | deferral-is-scope-creep / no-deferral | Whole plan implemented in this single fix; the 3 real-graph-only verify items (V1/V3/V4) are explicitly NOTED as the orchestrator's §7 post-commit real-tree steps (inherently machine-and-real-graph-only), NOT punted to a later BD/version. No new test added (plan §5.2 size/fit decision), no allowlist dodge. | COMPLIANT |
| 10 | scope-deliverables-to-the-ask | Implemented exactly the 5 surfaces per the plan; reintroduced NO rejected machinery (verified: NO CI gate, NO new validate-pack check — validate-pack.py unmodified; NO committed sentinel; NO "N"/commit-count; NO fetch-depth/workflow edit). No unrelated refactor. | COMPLIANT |

---

*End of IMPL-REPORT — BD-237. No patch produced (BD-226: orchestrator re-engages for `git diff > <handoff>/changes.patch` only after review-clean). No state-changing git verb run. Worktree edits + this report are the sole deliverables.*
