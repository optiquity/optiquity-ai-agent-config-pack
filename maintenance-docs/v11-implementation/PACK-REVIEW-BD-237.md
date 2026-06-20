# PACK-REVIEW-BD-237 — graphify pre-push background graph-refresh hook + LOCAL freshness check

**Reviewer:** `pack-reviewer` (fresh; read-only; reviewed independently — no prior review reports consulted)
**Worktree (work lives here, uncommitted):** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a2b879d0f53673f98`
**HEAD:** `2f53788620e1bdb233eb8ed645801c995093bafe` (verified at runtime)
**Status (verified):** 3 M (`.claude/skills/pack-startup/SKILL.md`, `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/PACK-CHAT.md`) + 2 ?? (`scripts/hooks/`, `scripts/install-graphify-hook.sh`) — exactly the expected set, nothing else
**Spec:** `/tmp/pack-handoff-bd237-plan2/PLAN-BD-237-FINAL.md` (authoritative)
**Date:** 2026-06-20

---

## VERDICT: CLEAN (ready for patch + commit)

The implementation is correct, complete, and faithfully realizes the plan's intent on all 5
surfaces. `validate-pack.py` is GREEN (exit 0, all 62 checks PASS), both new scripts pass
`bash -n`, scope is strictly `pack-only`, both new executables carry `# pack-internal: true`
and are executable, and NO rejected machinery (CI gate / new validate-pack check / committed
sentinel / commit-count "N" / fetch-depth) re-entered. Both plan-literal deviations are
**correct fixes**, one of which corrects a real bug in the plan's literal.

There are **0 BLOCKER, 0 MUST-FIX, 1 SHOULD, 2 NIT** findings — none block the commit. The
SHOULD and NITs are documentation-polish / belt-and-suspenders items; all preserve the safety
contract.

---

## Assessment of the two plan-literal deviations

### Deviation (i) — installer source-missing guard (additive) → CORRECT
The installer (`scripts/install-graphify-hook.sh` L24-27) adds a guard the plan's §4.1 sketch
omitted:
```bash
if [ ! -f "$SRC" ]; then
  echo "graphify pre-push hook: source not found at $SRC" >&2
  exit 1
fi
```
**Verdict: CORRECT.** The installer runs `set -euo pipefail` (L19). Without this guard, a
missing `$SRC` would surface as a `cp: No such file` from L36 — a cryptic failure. The guard
gives a clear actionable message and is additive (does not change the happy path). The non-zero
exit is appropriate here (the installer is an orchestrator-run setup tool, NOT the hook — a
failed install SHOULD fail loud). Consistent with the plan's idempotent-install intent.

### Deviation (ii) — NEW-BRANCH range derivation → CORRECT FIX of a plan bug
The plan §4 step 2 literal says: NEW BRANCH → "that ref's range = `local_oid` (all commits on
the new branch)" then "the doc-gate runs `git diff --name-only <range>` over EACH ... ref's
range." Taken literally, `git diff --name-only <local_oid>` is `git diff --name-only
<single-sha>` = **diff(working-tree, that-commit)**, NOT "all commits on the new branch."

The implementation (`scripts/hooks/graphify-pre-push.sh` L58-66, `_changed_names`) instead uses:
```bash
git rev-list "$_lo" --not --remotes | git diff-tree --no-commit-id --name-only -r --stdin
```
**Verified empirically** in a scratch repo (`/tmp/bd237-gittest`): a new branch `feature` with
two new commits (`c.md`, `d.py`) on top of a pushed `main`:
- Implemented form → `d.py`, `c.md` (CORRECT — exactly the new-branch commits' files; doc
  `c.md` detected → SEMANTIC branch, which is correct).
- Plan-literal `git diff --name-only <tip-sha>` → **EMPTY** (working tree == tip), which would
  MISS all doc changes and wrongly fall to the CODE branch on every clean-tree new-branch push.

The implemented `rev-list <tip> --not --remotes | diff-tree --stdin` correctly enumerates
"commits reachable from the new tip but not on any remote-tracking ref" — the precise
realization of the plan's *stated intent* ("all commits on the new branch"). **This is a
correct fix of a defect in the plan's literal text**, not a regression. The coder's comment
(L53-56) documents the reasoning accurately.

---

## Findings (ordered)

### SHOULD-1 — `_changed_names` new-branch path: pipeline `$?` can mask a `rev-list` failure (no `pipefail`)
**File:** `scripts/hooks/graphify-pre-push.sh` L58-66 (`_changed_names`), consumed at L107-111.
**Concern:** On the new-branch path, `_changed_names` is a pipeline (`git rev-list … | git
diff-tree …`). The hook (correctly) does NOT set `set -o pipefail` (would risk aborting), so
`$?` captured at L108 reflects only `diff-tree`'s exit, not `rev-list`'s. If `rev-list` fails
(e.g. an unreachable/garbage local oid) but `diff-tree` succeeds on empty stdin, the function
returns **0 with empty output** — so `RANGE_ERROR` is NOT set; the ref contributes no
doc/delete signal and the hook lands on `REFRESH_MODE="code"` (full `update`).
**Evidence (measured):**
```
--- bad local oid (rev-list fails), remote=zero (new-branch path) ---
pipeline $?=0 (last cmd = diff-tree on empty stdin -> 0, so RANGE_ERROR NOT set)
```
**Assessment — why this is SHOULD, not MUST/BLOCKER:** the resulting behavior is STILL the
plan's *conservative-fallback intent* — an opaque/empty new-branch range falls to the safe full
code-only `update` (§4 step 2 "Conservative fallback ... full code-only update"). The safety
contract ("never the costlier semantic by accident, never a hard error, never block the push")
is preserved. It just reaches that outcome via the empty-result path rather than the explicit
`RANGE_ERROR` path. In practice a `pre-push` local oid is always a real, reachable commit (git
gives the hook validated refs it is about to push), so the failure precondition is near-zero.
**Concrete fix (optional, belt-and-suspenders):** capture `rev-list`'s status explicitly, e.g.
materialize the commit list first and check it, OR add a guard comment noting the
empty-result→safe-code-fallback equivalence so a future maintainer does not mistake it for a
missed error path. No behavior change is strictly required.

### NIT-1 — SKILL.md python alternative: `$GRAPH` inside single quotes will not expand
**File:** `.claude/skills/pack-startup/SKILL.md` L103.
**Evidence (quoted):**
```
`python3 -c 'import json; print(json.load(open("$GRAPH"))["built_at_commit"])'`
```
`$GRAPH` sits inside SINGLE quotes, so a shell would pass the literal `$GRAPH` to python (no
expansion) → `FileNotFoundError`. **Why NIT:** this is an OPTIONAL alternative offered in doc
prose ("You MAY use ... if it is more robust"); the PRIMARY wired path is the `tail`+`grep`
form (L100-102, in the executable code block), which I verified works against the real graph
(extracted `190e1985...`). The python line is illustrative guidance, not executed code.
**Concrete fix:** if kept as copy-pasteable guidance, switch to double quotes around the
`python3 -c` body with single quotes inside (`python3 -c "import json; print(json.load(open('$GRAPH'))['built_at_commit'])"`),
or replace `$GRAPH` with a literal-path note. Cosmetic.

### NIT-2 — maintenance-docs preservation (plan §2 surface #6) not in this changeset
**Evidence:** `maintenance-docs/v11-implementation/` has no `*BD-237*` files in this worktree.
**Why NIT (not a defect of the coder's work):** the plan §7 explicitly states surface #6
"rides the SAME commit OR a trailing `docs:` commit (orchestrator's call)" and the active
project state defers BD-228-style audit-docs preservation to an orchestrator step. The five
TRACKED code/doc surfaces (the load-bearing fix) are all present and correct. **Flagging only so
the orchestrator does not forget** the preservation step (CAPABILITY-REPORT / DESIGN / PLAN /
ADVERSARIAL / IMPL-REPORT → `maintenance-docs/v11-implementation/`) per the BD-225 pattern.
Not a coder fix.

---

## Surface-by-surface verification

### 1. `scripts/hooks/graphify-pre-push.sh` (hook body) — CORRECT
- **Shebang + marker:** `#!/usr/bin/env bash` (L1); `# pack-internal: true` (L2). ✔
- **NO `set -e`:** confirmed absent; documented at L11. ✔ (a non-zero refresh must not abort
  before `exit 0`)
- **bash-3.2 safe:** no `mapfile`/`readarray`/bash-4 features; field-split via `IFS` + `set --`
  (L85-94). Verified the field-split recovers all 4 columns under bash 3.2.57 (the live shell).
  ✔
- **stdin drained FIRST:** `STDIN_REFS="$(cat)"` (L23) before any other work — git's pipe never
  blocks. ✔
- **Doc-gate range handling — ALL cases:**
  - DELETE (local_oid == zero) → `continue`, no range (L100-102). ✔
  - NEW BRANCH (remote_oid == zero) → `rev-list <tip> --not --remotes | diff-tree` (L60-62) —
    **verified correct** (deviation ii). ✔
  - UPDATE / force-push → `git diff --name-only <ro..lo>` (L64) — same shape; force-push needs
    no special case (verified two-dot diff works on non-ff). ✔
  - MULTIPLE refs → per-line loop with union semantics (any doc anywhere → SEMANTIC) (L89-119,
    L112-114). ✔
  - Conservative fallback: `RANGE_ERROR || RANGE_SEEN==0 → code` full update (L122-124); a bad
    two-dot range returns 128 → `RANGE_ERROR=1` (verified). ✔
- **Root resolution:** `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"` + `[ -n "$ROOT" ]
  && [ -d "$ROOT/graphify-out" ] || exit 0` (L27-28). ✔ (NO worktree-list scan)
- **graphify-exec guard:** `GFX="$(command -v graphify)"; [ -n "$GFX" ] && [ -x "$GFX" ] ||
  exit 0` (L31-32). ✔
- **mkdir skip-lock at `$ROOT/graphify-out/.pack-refresh.lock`:** `mkdir "$LOCK" || { echo …;
  exit 0; }` (L135-139); released by the BACKGROUND subshell's `trap … EXIT` (L161), NOT the
  foreground (comment L132-134 warns against double-rmdir). ✔
- **Dual-signal next-run consult:** (a) `fail` token (L145-147); (b) `built_at_commit`-behind
  via bounded `tail -c 200` + grep (L150-155). Both LOCAL reads. ✔ (verified extraction works)
- **Background-detached subshell `cd "$ROOT"`:** L160-207; `cd "$ROOT" || exit 0` (L166) —
  load-bearing for the correct stamp (graphify `_git_head()` uses process CWD; EE-6). ✔
- **EXACT invocations:**
  - SEMANTIC: `GRAPHIFY_CLAUDE_CLI_PARALLEL=0 graphify extract "$ROOT" --backend claude-cli`
    (L176) — NO `GRAPHIFY_OUT` (inert on extract), NO `--no-viz`, NO `GRAPHIFY_FORCE`, NOT
    `--backend claude`. ✔
  - CODE: `GRAPHIFY_OUT="$ROOT/graphify-out" graphify update "$ROOT"` (L187), with
    `GRAPHIFY_FORCE=1` ONLY on delete-in-range (L183-185). ✔
- **Single self-retry (no loop):** `while [ "$attempt" -le 2 ]` with `break` on rc==0 (L170-193)
  — bounded at 2 attempts, no "N". ✔
- **Atomic status write:** `printf … > "$TMP"; mv "$TMP" "$STATUS_FILE"` (L200-206). ✔
- **Foreground `exit 0` on every non-skip path:** L28, L32, L138, L211; L166 is inside the
  subshell. Foreground never returns non-zero. ✔
- **disown:** L208 `disown 2>/dev/null || true` immediately after `) … &` (L207) — keeps the
  job alive past `git push` exit on bash 3.2 (no `setsid` on macOS). ✔

### 2. `scripts/install-graphify-hook.sh` (installer) — CORRECT
- `# pack-internal: true` (L2) — MANDATORY for Check 23 (top-level executable). Verified Check
  23 counts it as pack-internal (12 marked). ✔
- `SRC="$(cd "$(dirname "$0")" && pwd)/hooks/graphify-pre-push.sh"` (L21);
  `DEST="$(git rev-parse --git-path hooks)/pre-push"` (L22). ✔
- `chmod +x "$DEST"` (L37); idempotent via `cmp -s` no-op (L31-34). ✔
- `cp`+`chmod` only — NO git state-change. ✔
- Source-missing guard (L24-27) — deviation (i), assessed CORRECT above. ✔

### 3. `pack-ops/OPTIONAL-FEATURES.md` (§"How to keep it fresh" rewrite) — CORRECT
- Rewrite to the `pre-push` model (L449-531); install command; worktree-safety stated correctly
  per branch (update honors `GRAPHIFY_OUT`+arg, extract pinned by target arg + `cd`); mkdir
  skip-lock; advisory status record; dual-signal; LOCAL freshness. ✔
- Four upstream stragglers reconciled (L357 area, L406 "pre-push hook unsets", L432-436 "hook
  BODY *is* committed"). ✔
- **§1.1 backend caveat PRESERVED** (L539+ "do NOT 'correct' it") — verbatim, untouched. ✔
- grep-zero gate: the ONLY remaining `post-commit` (L453) is an intentional HISTORICAL ref
  ("Unlike the old hand-installed `post-commit` recipe") — correct per plan §6. Zero `HEAD~1`
  refs remain. ✔
- Does NOT repeat graphify's upstream merge-driver error. ✔

### 4. `.claude/skills/pack-startup/SKILL.md` (Step 5 + Step-4 report line) — CORRECT
- New `**Graph:**` line in the Step-4 report block. ✔
- New reserved Step 5 (LOCAL freshness + hook-install readiness), with the reserved-steps
  comment updated (5 → now BD-237; 6-7 still reserved). ✔
- LOCAL only, never fails startup; existence-gates on `graph.json`; `built_at_commit` read via
  bounded `tail`+grep (primary path verified working). ✔
- See NIT-1 for the optional python-alt single-quote cosmetic.

### 5. `pack-ops/PACK-CHAT.md` (one-line note) — CORRECT
- Informational note (L213-219) that the pre-push hook auto-refreshes in the background; "do
  NOT duplicate a manual graph refresh"; adds NO orchestrator step. ✔

---

## Cross-cutting verification

| Item | Result | Evidence |
|---|---|---|
| `validate-pack.py` (worktree) | **PASS — exit 0, all 62 checks clean** | `PASSED — all checks clean` |
| Check 23 (new executables) | PASS | `all 9 non-internal scripts/ executables listed … (12 marked pack-internal)` — installer counted internal |
| Check 63 (graphify-out never tracked) | PASS | `graphify-out/ is not tracked … 0 tracked paths` |
| Check 64 (no dangling .example refs) | PASS | `162 deliverable file(s) walked … every cite resolves` |
| Check 40 (bare cross-ref) | PASS | full battery clean (no Check-40 failure surfaced) |
| `bash -n` hook | OK | clean |
| `bash -n` installer | OK | clean |
| Both new scripts executable | YES | `-rwxr-xr-x` both; `git add --dry-run` would add them executable |
| Both carry `# pack-internal: true` | YES | hook L2, installer L2 |
| Scope `pack-only` | YES | no `project-template/` / `supporting-docs/` in status; status == expected 3 M + 2 ?? |
| NO rejected machinery | CONFIRMED | no Check 65 / no `built_at_commit`/`pre-push` in validate-pack.py; no committed sentinel; no lag/N; no `.github`/workflow touched |
| New-branch range git behavior | VERIFIED LIVE | scratch repo `/tmp/bd237-gittest`: implemented form → correct new-branch files; plan-literal → empty |

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | All git ops read-only: `git rev-parse HEAD`/`status --short`/`diff`/`ls-files -s`/`add --dry-run` (read/dry); scratch-repo tests confined to `/tmp/bd237-gittest` (NOT the pack repo); NO `graphify update/extract/hook install` run; NO source edit; sole write = this report at `/tmp/pack-handoff-bd237-review/PACK-REVIEW-BD-237.md`. | COMPLIANT |
| 2 | separate-pack-ops-from-product | `git status --short \| grep -E "project-template\|supporting-docs"` → `NONE (pack-only clean)`; every surface is `scripts/`, `pack-ops/`, `.claude/skills/pack-startup/`; hook+installer never in any install map (Check 64 passed, 0 dangling). | COMPLIANT |
| 3 | enumerate-encoding-surfaces | `git status --short` == exactly the 5 expected surfaces (3 M + 2 ??), nothing else touched; verified each of the 5 surfaces present + correct; runtime files (`.pack-refresh-status`, `.pack-refresh.lock`) inside gitignored `graphify-out/` (Check 63: 0 tracked). | COMPLIANT |
| 4 | verify-availability-not-just-existence | New-branch range derivation tested LIVE in `/tmp/bd237-gittest` (`rev-list --not --remotes \| diff-tree` → `d.py c.md`; plan-literal `diff <single-sha>` → empty); two-dot bad range → exit 128 (RANGE_ERROR set); bash field-split verified under live bash 3.2.57; `built_at_commit` tail+grep extraction verified against the real canonical graph (`190e1985…`); pipeline `$?` masking measured (rev-list-fail + diff-tree-empty → `$?=0`). Did not assume. | COMPLIANT |
| 5 | graph-first-context | Worktree has no graph; used grep/Read/git for all authoritative facts (validate-pack source, hook/installer text, plan SSOT, live git behavior); injected `--graph` not needed for exact-text review; did not block on the graph. | COMPLIANT |
| 6 | scope-deliverables-to-the-ask | Reviewed BD-237 only (the 5 surfaces); confirmed NO rejected machinery re-entered (CI gate / new check / committed sentinel / "N" / fetch-depth — all measured ABSENT); no scope creep flagged. | COMPLIANT |
| 7 | deferral-is-scope-creep / no-deferral | Every concern surfaced as a finding (SHOULD-1, NIT-1, NIT-2) with severity + concrete fix; nothing deferred. NIT-2 (maintenance-docs) flagged as an orchestrator step per plan §7, not a coder defer. | COMPLIANT |
| 8 | rules-applied-verification-block | This block — one row per in-force rule with quoted/measured evidence + COMPLIANT/N/A/VIOLATED. | COMPLIANT |

---

*End of PACK-REVIEW-BD-237. Read-only reviewer output; no source edits, no state-changing git
verbs, no graph mutation. Sole write = this report.*
