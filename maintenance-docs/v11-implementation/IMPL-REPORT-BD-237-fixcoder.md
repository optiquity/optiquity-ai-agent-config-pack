# IMPL-REPORT — BD-237 fix-coder (two reviewer-approved fixes)

## Runtime regime (verified ground-truth)

- **Worktree (pwd):** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a2b879d0f53673f98`
- **Branch base / HEAD SHA:** `2f53788620e1bdb233eb8ed645801c995093bafe` (unchanged — no commit; HEAD identical at start and finish)
- **Worktree reuse (BD-226):** REUSED the existing coder worktree (cd in + verified `pwd` and `git rev-parse HEAD` match the orchestrator-named values). No new worktree created. No state-changing git verb run.
- **Pre-edit `git status --short`:** the expected 3 M + 2 ?? BD-237 set
  (`M .claude/skills/pack-startup/SKILL.md`, `M pack-ops/OPTIONAL-FEATURES.md`, `M pack-ops/PACK-CHAT.md`, `?? scripts/hooks/`, `?? scripts/install-graphify-hook.sh`).

## Scope

Applied EXACTLY the two reviewer-approved non-blocking fixes. No other changes. No rejected machinery (no CI check, no sentinel, no `N`, no fetch-depth). NIT-2 (maintenance-docs preservation) NOT touched — that is the orchestrator's commit-time step.

Files touched (both pack-ops):
1. `.claude/skills/pack-startup/SKILL.md` (modified)
2. `scripts/hooks/graphify-pre-push.sh` (modified — file is part of the untracked `scripts/hooks/` BD-237 addition)

---

## FIX 1 (NIT-1) — `.claude/skills/pack-startup/SKILL.md`

**Problem.** The Step-5 OPTIONAL "python alternative" example wrapped the
`python3 -c '...'` program in SINGLE quotes, with `$GRAPH` *inside* those single
quotes:

```
python3 -c 'import json; print(json.load(open("$GRAPH"))["built_at_commit"])'
```

Inside single quotes the shell does NOT expand `$GRAPH`, so Python received the
literal string `$GRAPH` and tried to `open("$GRAPH")` — a non-existent path —
raising `FileNotFoundError`. The example was broken as written.

**Fix.** Swapped the quoting so the OUTER quotes are DOUBLE (shell expands
`$GRAPH`) and the INNER Python string literals are SINGLE (stay literal):

```
python3 -c "import json; print(json.load(open('$GRAPH'))['built_at_commit'])"
```

Added a short inline note pointing out the OUTER-double / INNER-single rationale.
Kept it an OPTIONAL alternative; the primary `tail`+`grep` path is unchanged; no
other part of the Step-5 logic was altered.

**Line delta (this fix's region):** the python-snippet line replaced 1:1 plus a
2-line inline note added (the file's overall 45/5 diff-stat vs HEAD is the
pre-existing BD-237 Step-5 block — HEAD `2f53788` predates BD-237 — not extra
change from this fix).

**Verification (snippet actually expands + runs):**
Built `/tmp/gtest-snippet/graph.json` = `{"foo":1,"built_at_commit":"abc1234"}`, set `GRAPH` to it.
- Corrected (double-outer) snippet:
  ```
  python3 -c "import json; print(json.load(open('$GRAPH'))['built_at_commit'])"
  -> abc1234   (rc=0)
  ```
- OLD (single-outer) snippet, same `GRAPH`:
  ```
  python3 -c 'import json; print(json.load(open("$GRAPH"))["built_at_commit"])'
  -> Traceback ... open("$GRAPH")   (non-zero — the bug)
  ```
Corrected snippet expands and prints the value; old snippet fails — fix confirmed.

---

## FIX 2 (SHOULD-1) — `scripts/hooks/graphify-pre-push.sh`

**Problem.** In `_changed_names` (and the identical-shape `_deleted_names`), the
NEW-BRANCH path was a pipeline:

```
git rev-list <oid> --not --remotes 2>/dev/null \
  | git diff-tree ... --stdin 2>/dev/null
```

A shell pipeline's exit status reflects ONLY its LAST command (`diff-tree`).
`diff-tree` succeeds (rc=0) on empty stdin, so a `rev-list` FAILURE was MASKED:
the function returned 0 with empty output, and the caller's
`names="$(_changed_names ...)"; if [ $? -ne 0 ]; then RANGE_ERROR=1; ...` guard
never tripped — silently mis-classifying a derivation failure as "no doc/delete
signal" (stays `code`) instead of routing to the conservative full-`update`
fallback (RANGE_ERROR).

**Fix (bash-3.2-safe, no pipefail at script scope, no `set -e`).** Capture the
`rev-list` output to a variable FIRST and check its rc via `|| return 1` BEFORE
piping the captured value to `diff-tree`. This decouples the two exit codes
without any `set -o pipefail` and without `set -e`:

```
_revs="$(git rev-list "$_lo" --not --remotes 2>/dev/null)" || return 1
printf '%s\n' "$_revs" | git diff-tree ... --stdin 2>/dev/null
```

Applied the SAME decoupling to `_deleted_names`'s new-branch pipeline (which had
the identical masking, with a trailing `grep -q .`); there `return 1` on a
rev-list failure maps to the conservative "no deletion seen" outcome (no false
`GRAPHIFY_FORCE`). The UPDATE / force-push two-dot branches of both functions
were left untouched. No `set -e` added; no script-scope `set -o pipefail` added.

**Caller routing (unchanged, now correctly driven):**
- `_changed_names` rc!=0 → caller sets `RANGE_ERROR=1; continue` → line
  `if [ "$RANGE_ERROR" -eq 1 ] ... ; then REFRESH_MODE="code"` → conservative
  full-`update` fallback. Correct.

**Verification — `bash -n`:** CLEAN (exit 0) under
`GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)` (stock macOS bash 3.2).

**Verification — logic simulation (extracted funcs + stubbed `git`, throwaway `/tmp` repo, NO real graph):**

- **Scenario A — rev-list FAILS (stub `git rev-list` returns 128) on new-branch path:**
  - `_changed_names "deadbeef" "$zero"` → `rc=1`, out empty → caller sets
    `RANGE_ERROR` → conservative full-`update` fallback. PASS (failure DETECTED).
  - `_deleted_names "deadbeef" "$zero"` → `rc=1` → no false `GRAPHIFY_FORCE`. PASS.
- **Scenario B — rev-list SUCCEEDS, doc in new-branch history (TEST C happy path):**
  - stub `git rev-list` emits commits (rc=0); stub `git diff-tree` emits
    `docs/foo.md` + `src/bar.sh`.
  - `_changed_names "abc123" "$zero"` → `rc=0`, out = `docs/foo.md\nsrc/bar.sh`;
    `.md` present → SEMANTIC. PASS (happy path intact; TEST C still SEMANTIC).
- **Contrast — OLD masked form, same rev-list 128 + empty-input diff-tree rc=0:**
  - reproduced inline old pipeline → `rc=0`, out empty == the masked bug. Confirms
    the fix changes exactly the masked behavior and nothing else.

All `/tmp` scratch dirs were removed after the runs (no real repo touched, no real graph).

---

## Mandatory verification summary

| Check | Command | Result |
|---|---|---|
| Hook syntax | `bash -n scripts/hooks/graphify-pre-push.sh` | CLEAN (exit 0), bash 3.2.57 |
| Full validator | `python3 scripts/validate-pack.py` | **EXIT 0 — PASSED — all checks clean** (62 checks; Check 59 registry == 62) |
| Python snippet | run corrected snippet vs real JSON | prints `abc1234` rc=0; old form fails |
| rev-list masking | extracted-func harness, stubbed git | A: failure detected→fallback; B: happy path→SEMANTIC |
| In-scope only | `git status --short` | same 5 paths (3 M + 2 ??); HEAD unchanged |

validate-pack tail:
```
PASSED — all checks clean
validate-pack EXIT CODE = 0
```

post-fix `git status --short`:
```
 M .claude/skills/pack-startup/SKILL.md
 M pack-ops/OPTIONAL-FEATURES.md
 M pack-ops/PACK-CHAT.md
?? scripts/hooks/
?? scripts/install-graphify-hook.sh
```
(The `pack-ops/OPTIONAL-FEATURES.md` + `pack-ops/PACK-CHAT.md` M entries are the
pre-existing BD-237 working-tree changes I did NOT author and did NOT touch.)

---

## Plan deviations

None. Applied exactly the two approved fixes; no rejected machinery; no other
files touched.

## New POQs introduced

None.

## Boundary discipline check

Both edited files are PACK-OPS surfaces (`.claude/skills/pack-startup/SKILL.md`
is a pack-dev startup skill; `scripts/hooks/graphify-pre-push.sh` is a pack-repo
hook). Neither is a `project-template/` / `supporting-docs/` client-shipped
surface, so the project-side-SSOT pre-flight does not apply. No project-side
file was edited. No pack-only reference was added to any project surface.
No boundary-discipline STOP triggered.

## Files changed inventory

| Path | Change type |
|---|---|
| `.claude/skills/pack-startup/SKILL.md` | modified (FIX 1 — python snippet quoting) |
| `scripts/hooks/graphify-pre-push.sh` | modified (FIX 2 — rev-list rc decoupling in `_changed_names` + `_deleted_names`) |

## New-file full contents

No new files created by this fix (both targets pre-existed in the worktree).

## Patch

NONE produced (per BD-226 / agents-never-commit). The orchestrator re-engages
for the `git diff` patch only AFTER the post-fix review is clean.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| FIX 1 applied (`$GRAPH` now expands in python alt; primary path unchanged) | PASS |
| FIX 1 verified (corrected snippet expands + prints value; old form fails) | PASS |
| FIX 2 applied (`_changed_names` rev-list rc no longer masked) | PASS |
| FIX 2 applied to `_deleted_names` (identical masking fixed) | PASS |
| FIX 2 happy path intact (new-branch doc → SEMANTIC, TEST C) | PASS |
| FIX 2 masked failure now routes to conservative full-`update` fallback | PASS |
| bash-3.2-safe; no `set -e`; no script-scope pipefail | PASS |
| `bash -n` clean | PASS |
| Full `validate-pack.py` EXIT 0 / PASSED | PASS |
| Only the two named files changed; `git status` in-scope | PASS |
| No rejected machinery reintroduced | PASS |
| No `maintenance-docs/` / NIT-2 touched | PASS |
| Worktree reused; no new worktree; no state-changing git verb; no patch | PASS |

---

## Rules-Applied Verification Block

| # | Rule name | Verification evidence | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | No `git add`/`commit`/`apply`/etc. run; HEAD unchanged (`git rev-parse HEAD` = `2f53788620e1bdb233eb8ed645801c995093bafe` start and finish); no patch produced. Only Read/Edit/Write/`bash -n`/`validate-pack`/read-only `git status`/`git diff --stat` used. | COMPLIANT |
| 2 | preflight-stop-means-stop | Emitted the single PREFLIGHT line `PREFLIGHT: 2/2 fixes complete; verification PASS (bash -n + validate-pack); worktree /Users/.../agent-a2b879d0f53673f98; HEAD 2f53788...; about to Write IMPL-REPORT` ONLY after both fixes + `bash -n` CLEAN + `validate-pack EXIT CODE = 0`. No stop directive received. | COMPLIANT |
| 3 | rules-applied-verification-block | This table ends the report (one row per prompt rule, quoted evidence, terminal conclusion). | COMPLIANT |
| 4 | separate-pack-ops-from-product | Both edited files are pack-ops (`.claude/skills/...`, `scripts/hooks/...`). `git status` shows zero `project-template/` or `supporting-docs/` paths. | COMPLIANT |
| 5 | enumerate-encoding-surfaces | Touched ONLY the two named files; `git status --short` = same 5 in-scope paths (3 M + 2 ??), no new files beyond the existing 2 ??. | COMPLIANT |
| 6 | scope-deliverables-to-the-ask | Applied only FIX 1 + FIX 2; `git diff` shows only the python-snippet line/note + the two rev-list-rc decouplings; no refactor, no CI check / sentinel / `N` / fetch-depth. | COMPLIANT |
| 7 | graph-first-context | Did not need the graph (the two fixes are local + exact-text); used Read + grep/sed for exact content; never recomputed a graph path from the worktree; never blocked. | N/A: graph not consulted (exact-text local task) |
| 8 | deferral-is-scope-creep / no-deferral | Both fixes landed now in the worktree; nothing deferred. | COMPLIANT |
| 9 | worktree-reuse (BD-226) | cd'd into the named existing worktree; verified `pwd` and `git rev-parse HEAD`; did NOT create a new worktree (no `git worktree` verb run). | COMPLIANT |
