# PACK-REVIEW-2-BD-237 — POST-FIX review of the BD-237 implementation

**Agent:** FRESH `pack-reviewer` (POST-FIX pass; did NOT read the prior review report)
**Worktree reviewed:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a2b879d0f53673f98`
**HEAD:** `2f53788620e1bdb233eb8ed645801c995093bafe` (verified)
**git status:** exactly 3 M (`.claude/skills/pack-startup/SKILL.md`, `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/PACK-CHAT.md`) + 2 ?? (`scripts/hooks/`, `scripts/install-graphify-hook.sh`) — verified
**Spec:** `/tmp/pack-handoff-bd237-plan2/PLAN-BD-237-FINAL.md`
**Date:** 2026-06-20

> **READ-ONLY:** no source edits, no state-changing git verbs, no `graphify update`/`extract`/`hook install`. Sole write = this report. All empirical tests were read-only (`git rev-parse`/`rev-list`/`diff-tree`/`diff`, `bash -n`, `python3 -c json.load`, `validate-pack.py`, scratch `/tmp` repos cleaned up).

---

## VERDICT: **CLEAN — ready for patch + commit**

Both fix-coder fixes are CORRECT and COMPLETE. The whole change is still clean: `validate-pack.py` exits 0 in the worktree, both new scripts parse (`bash -n` OK), scope is exactly the 5 expected pack-ops paths, no rejected machinery, both scripts executable + carry `# pack-internal: true`, and every earlier-validated hook-body essential still holds. No regression detected. **Zero BLOCKER / MUST-FIX / SHOULD / NIT findings.**

---

## FIX 1 — SKILL.md Step 5 python-alternative `$GRAPH` quoting: **CORRECT + COMPLETE**

**File:** `.claude/skills/pack-startup/SKILL.md` lines 102–106 (Step 5 OPTIONAL python alternative).

**The fixed snippet (line 103–104):**
```
`python3 -c "import json; print(json.load(open('$GRAPH'))['built_at_commit'])"`
```
plus the documenting prose (lines 105–106): *"note the OUTER double quotes so the shell expands `$GRAPH` and the INNER single quotes stay literal Python."*

**Why it is correct.** The `-c` program is wrapped in OUTER **double** quotes, so the shell expands `$GRAPH` to the absolute path before `python3` runs, while the INNER **single** quotes around the path keep the Python string literal intact. Empirically verified against the real graph:

```
# FIXED form (outer double, inner single):
python3 -c "import json; print(json.load(open('$GRAPH'))['built_at_commit'])"
→ 190e1985cbb8164d619d571a28d8c3228d3c6981   (rc=0)

# OLD broken form (outer single quotes) — for contrast:
python3 -c 'import json; print(json.load(open("$GRAPH"))["built_at_commit"])'
→ FileNotFoundError: ... open("$GRAPH")   (rc != 0)
```

The fixed form returns the real `built_at_commit`; the old single-outer-quote form fails because `$GRAPH` was passed to Python literally (Python tried to open a file named `$GRAPH`). The variable is in a shell-expanded position and the Python literals stay literal — the snippet is RUNNABLE.

**Primary path unchanged + still correct.** The PRIMARY `tail`+`grep` freshness path (lines 86–88) is the load-bearing path and is untouched; run verbatim it returns the same SHA:
```
built="$(tail -c 200 "$GRAPH" | grep -o '"built_at_commit": *"[0-9a-f]*"' | grep -o '[0-9a-f]\{7,\}')"
→ 190e1985cbb8164d619d571a28d8c3228d3c6981
```
Both the primary and the alternative yield identical results. The git diff confirms the change is scoped to the Step-5 alternative (no collateral edit elsewhere in SKILL.md).

---

## FIX 2 — rev-list rc-capture in `_changed_names` AND `_deleted_names`: **CORRECT + COMPLETE (happy path INTACT)**

**File:** `scripts/hooks/graphify-pre-push.sh`, new-branch path of both helper functions.

**Applied to BOTH functions** (`enumerate-encoding-surfaces` satisfied):
- `_changed_names`, line 67: `_revs="$(git rev-list "$_lo" --not --remotes 2>/dev/null)" || return 1`
- `_deleted_names`, line 83: `_revs="$(git rev-list "$_lo" --not --remotes 2>/dev/null)" || return 1`

Each captures `rev-list` output to `_revs` and checks its rc with `|| return 1` BEFORE piping `_revs` into `diff-tree`, decoupling the two exit codes.

**Why it is correct (the masking it fixes is real).** Verified empirically on this machine (bash **3.2.57**):
```
# OLD pipeline masks the rev-list failure (pipeline rc = last command):
git rev-list <bogus-oid> --not --remotes 2>/dev/null | git diff-tree ... --stdin 2>/dev/null
→ rc=0   (rev-list FAILED, but diff-tree succeeds on empty input → MASKED)

# NEW capture-first form detects it:
_revs="$(git rev-list <bogus-oid> --not --remotes 2>/dev/null)" || return 1
→ return 1   (failure surfaced → caller sets RANGE_ERROR → conservative full-update)
```

**Caller wiring is correct.** The caller (lines 118–122) does `names="$(_changed_names ...)"; if [ $? -ne 0 ]; then RANGE_ERROR=1; continue; fi`. I verified `$?` propagates a function's `return 1` through command substitution in bash 3.2:
```
names="$(_changed_names <bogus-tip> <zero>)" → $? = 1   (→ RANGE_ERROR)
names="$(_changed_names HEAD HEAD~1)"        → $? = 0
```
`RANGE_ERROR=1` then routes to the conservative full-`update` fallback (lines 133–135), exactly as the spec (resolution 6) requires.

**(a) bash-3.2-safe — CONFIRMED.** Machine bash is 3.2.57. No `mapfile`/`readarray`/bash-4 features anywhere; no script-scope `set -e`/`set -euo` in the hook body (`grep -nE "^set -e..."` → none). Command substitution + `|| return 1` is POSIX/bash-3.2 portable. The installer's `set -euo pipefail` is correct (a foreground tool, where strict mode is appropriate) and is NOT in the hook body.

**(b) HAPPY path INTACT — not a regression to CODE.** Verified in a scratch repo: a real new branch (no remotes → `HEAD --not --remotes` = all commits) with a `.md` and a `.py` in its history:
```
_changed_names new-branch leg → file list: code.py, README.md
README.md matches \.(md|pdf)$  → SAW_DOC=1 → SEMANTIC branch (CORRECT — not CODE)
```
So a real new-branch with a `.md` in its history still returns the file list and routes to SEMANTIC. The rc-capture did NOT degrade the happy path to a spurious CODE/full-update.

**(c) No other behavior changed.** The only delta is the capture-then-check before the diff-tree pipe in the two new-branch legs; the UPDATE/force-push legs (`git diff --name-only "$_ro..$_lo"`, lines 71 and 88) are unchanged, and all downstream logic (doc-gate union, `SAW_DELETE_IN_RANGE`, refresh-mode selection) is unaffected.

**Observed edge-case note (NOT a finding, NOT introduced by this fix).** In the new-branch leg, `diff-tree --stdin` diffs each commit against its parent and does not diff the ROOT commit against the empty tree, so a file CREATED in the root commit and DELETED later within the same pushed range can net-zero out of `--diff-filter=D` (so `GRAPHIFY_FORCE` may not be set in that narrow case). A deletion in any non-root commit IS detected (verified). This is an inherent property of the per-commit `rev-list | diff-tree` approach the git `pre-push.sample` itself uses and that the plan endorsed (EE-7); the worst-case consequence is merely that graphify's node-shrink safety check might decline a shrink — a conservative, non-breaking outcome (`update`/`extract` still run). It is pre-existing to the fix under review and out of scope for this post-fix pass. Flagged only for the record.

---

## No-regression re-confirmation (all PASS)

| Check | Result |
|---|---|
| `python3 scripts/validate-pack.py` in the worktree | **exit 0** — "PASSED — all checks clean" (62 checks; Check 23 OK with "12 marked pack-internal"; Check 63 OK graphify-out never tracked) |
| `bash -n scripts/hooks/graphify-pre-push.sh` | OK (parses) |
| `bash -n scripts/install-graphify-hook.sh` | OK (parses) |
| Scope = exactly 5 expected paths, `pack-only` | OK — `git status --short` = the 3 M + 2 ?? above; `grep project-template/\|supporting-docs/` → none |
| NO rejected machinery | OK — no CI gate, no new validate-pack check (`validate-pack.py` untouched), no committed sentinel, no "N"/lag-tolerance, no `fetch-depth` (`grep -nEi "fetch-depth\|Check 65\|lag-tolerance"` → none) |
| Both scripts executable | OK — `-rwxr-xr-x` on both |
| Both scripts carry `# pack-internal: true` (within first ~2000 B) | OK — installer line 2; hook body line 2 |

**Earlier-validated hook-body essentials — all still hold:**
- Foreground `exit 0` on every non-skip path: root-guard (L28), graphify-guard (L32), skip-lock-held (L149), foreground final (L222). `cd "$ROOT" || exit 0` (L177) exits the SUBSHELL only — foreground already returned.
- `cd "$ROOT"` before the refresh (L177).
- `extract` line (L187): `GRAPHIFY_CLAUDE_CLI_PARALLEL=0 graphify extract "$ROOT" --backend claude-cli` — NO `GRAPHIFY_OUT`, NO `--no-viz`, NO `--backend claude`. CORRECT (M1).
- `update` lines (L195/L198): `GRAPHIFY_OUT="$ROOT/graphify-out" graphify update "$ROOT"`; `GRAPHIFY_FORCE=1` only on the delete path.
- `mkdir`-atomic skip-lock (L147); lock-release `rmdir` trap ONLY inside the subshell (L172) — foreground never rmdirs.
- Atomic status write `mv "$TMP" "$STATUS_FILE"` after tmp write (L213/L215/L217).
- Dual-signal next-run freshness consult: token-`fail` (L156–157) + `built_at_commit`-behind (L161–165).
- Detach: subshell `( ... ) >/dev/null 2>&1 &` (L218) + `disown 2>/dev/null || true` (L219).

**Cross-surface (not the two fixes; confirmed no regression):**
- `OPTIONAL-FEATURES.md`: §"How to keep it fresh" (L449+) describes the `pre-push` model; 15 `pre-push` refs; the single remaining `post-commit` mention (L453, "Unlike the old hand-installed `post-commit` recipe…") is an INTENTIONAL HISTORICAL contrast, permitted by the plan §6 grep-zero gate; zero `HEAD~1` refs; §1.1 backend caveat preserved (L530+).
- `PACK-CHAT.md` L213–215: informational note that the `pre-push` hook auto-refreshes the graph on every push.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | All commands read-only: `git rev-parse`/`rev-list`/`diff-tree`/`diff`/`status`/`hash-object`(read), `bash -n`, `python3 -c json.load`, `validate-pack.py`, `ls`/`grep`/`sed`/`head`/`tail`, scratch `/tmp` repos via `git init` (isolated, removed). NO `graphify update`/`extract`/`hook install`; NO source edit; NO state-changing git verb on the repo. Sole write = this report. | COMPLIANT |
| 2 | separate-pack-ops-from-product | `git status --short` = `scripts/`, `pack-ops/`, `.claude/skills/pack-startup/` only; `grep -E 'project-template/\|supporting-docs/'` on the change set → none; hook+installer in no install map. | COMPLIANT |
| 3 | enumerate-encoding-surfaces | FIX 2 verified present in BOTH encoding surfaces — `_changed_names` (L67) AND `_deleted_names` (L83); change set is exactly the 5 expected paths (no missing/extra surface). | COMPLIANT |
| 4 | verify-availability-not-just-existence | Did not assume — measured: rev-list-rc masking vs capture-first on bash 3.2.57 (pipeline rc=0 masks; `\|\| return 1` returns 1); `$?` propagation through command substitution (=1 on failure, =0 on success); python `$GRAPH` expansion (double-outer expands rc=0; single-outer FileNotFoundError); validate-pack exit 0; happy-path new-branch → SEMANTIC in a scratch repo. | COMPLIANT |
| 5 | graph-first-context | Injected `--graph` path noted; the graph IS the stale artifact (built_at `190e198` < HEAD `2f53788`). Used grep/Read/git for all authoritative facts (SSOT files, source, uncommitted worktree state); never blocked on the graph. | COMPLIANT |
| 6 | scope-deliverables-to-the-ask | Reviewed exactly: the two named fixes + no-regression + no-rejected-machinery. No scope creep introduced by either fix (SKILL.md diff scoped to Step-5 alt; hook delta scoped to the two new-branch legs). Flagged no out-of-ask items as actionable. | COMPLIANT |
| 7 | deferral-is-scope-creep / no-deferral | Both fixes judged COMPLETE here (not deferred); the one edge-case note is explicitly classified pre-existing + out-of-scope-for-this-pass with rationale, not a punt of in-scope work. | COMPLIANT |
| 8 | rules-applied-verification-block | This block — one row per in-force rule with quoted/measured evidence + a terminal conclusion. | COMPLIANT |

---

*End of PACK-REVIEW-2-BD-237. Read-only reviewer output; no source edits, no state-changing git verbs, no graph mutation. Sole write = this file.*
