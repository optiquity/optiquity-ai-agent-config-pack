# BD-290 W0 Gate Probe — IMPL-REPORT

Probe agent spawned with `isolation:"worktree"`; measurements taken 2026-08-25 against
WS = `/Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z`
(throwaway detached-HEAD worktree of the pack repo at HEAD `3cf436e`).
Probe's own isolated worktree (cwd): `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-afaeb347df8b75dd3`, also at HEAD `3cf436e`.

## §1 Verdict table

| Leg | Shape measured | Verdict | Evidence |
|---|---|---|---|
| A | Regime (`pwd`, toplevel, HEAD) | ALLOWED | §2-A |
| B / leg-a | Write tool → new file in out-of-prefix WS | ALLOWED | §2-B |
| C / leg-b | Edit tool → same WS file | ALLOWED | §2-C |
| D / leg-d | Non-git command (`python3`) with WS as cwd | ALLOWED | §2-D |
| E / leg-e | Realistic battery: `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` in WS | ALLOWED (ran and PASSED, exit 0) | §2-E |
| F / leg-b2 | Edit tool → TRACKED file (WS `README.md` line 1) | ALLOWED | §2-F |
| G / leg-c | `git status --porcelain=v1` in WS | ALLOWED | §2-G |
| H / leg-f | Patch-emit compound: `git diff > <handoff>/w0-probe.patch` + `wc -l` | ALLOWED (10-line non-empty patch) | §2-H |
| I | Guard/hook denials across all legs | NONE OBSERVED | §3 |

Every leg was ALLOWED on the first attempt; no second attempts were needed. Zero
permission prompts, guard messages, or hook denials were surfaced to the probe on
any leg.

## §2 Per-leg verbatim evidence

### §2-A — Leg A (regime)

Command:
```
pwd && git rev-parse --show-toplevel && git rev-parse HEAD
```
Output (verbatim):
```
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-afaeb347df8b75dd3
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-afaeb347df8b75dd3
3cf436ec46433556a218e086364871882c84490f
```
Interpretation: the probe runs inside its own isolated worktree (isolation
confirmed); the WS is an out-of-prefix linked worktree at the same HEAD.

### §2-B — Leg-a (workspace Write)

Tool call: `Write` with
`file_path = /Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z/w0-scratch.txt`,
content `w0 leg-a\n`.

Tool result (verbatim):
```
File created successfully at: /Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z/w0-scratch.txt
```

### §2-C — Leg-b (workspace Edit)

Tool call: `Edit` on the same file, `old_string = "w0 leg-a"`, `new_string = "w0 leg-b"`.

Tool result (verbatim):
```
The file /Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z/w0-scratch.txt has been updated successfully.
```

### §2-D — Leg-d (non-git command with WS cwd)

Command:
```
cd /Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z && python3 -c 'print(1)'; echo "EXIT=$?"
```
Output (verbatim):
```
1
EXIT=0
```

### §2-E — Leg-e (realistic battery shape)

Command:
```
cd /Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z && PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py; echo "EXIT=$?"
```
Result: ran to completion with NO pre-execution denial. Full 42.8KB output was
persisted by the harness to
`/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/03f94d7a-811d-445e-9727-7c003d6a116b/tool-results/bdq9awuqq.txt`.

Exit code: `0` (from the appended `EXIT=$?` echo).

Last 3 output lines of the battery (verbatim, from `tail` of the persisted output;
the `EXIT=0` line below them is the probe's own echo):
```
============================================================
PASSED — all checks clean
EXIT=0
```
(The line immediately preceding those was the Check 94 OK line:
`  OK: Check 94 — install-merge token wire intact (init-project.sh writes + resolve-merge-conflicts Case-3 selects action `merge-2way`) and the Case-3 On-success block KEEPS `.user-orig` (no affirmative removal verb).`)

### §2-F — Leg-b2 (tracked-file Edit)

Read of WS `README.md` lines 1–5 succeeded; line 1 was
`# Optiquity AI Agent Config Pack`.

Tool call: `Edit` on
`/Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z/README.md`,
`old_string = "# Optiquity AI Agent Config Pack"`,
`new_string = "# Optiquity AI Agent Config Pack <!-- w0-probe marker -->"`.

Tool result (verbatim):
```
The file /Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z/README.md has been updated successfully.
```

### §2-G — Leg-c (git status in WS)

Command:
```
cd /Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z && git status --porcelain=v1; echo "EXIT=$?"
```
Output (verbatim):
```
 M README.md
?? w0-scratch.txt
EXIT=0
```
Matches expectation exactly: the leg-b2 README modification + the leg-a untracked
scratch file.

### §2-H — Leg-f (patch-emit compound)

Command:
```
cd /Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z && git diff > /Users/david/.local/state/optiquity-pack-handoff/bd290-w0-20260825T165603Z/w0-probe.patch; echo "DIFF_EXIT=$?"; wc -l /Users/david/.local/state/optiquity-pack-handoff/bd290-w0-20260825T165603Z/w0-probe.patch
```
Output (verbatim):
```
DIFF_EXIT=0
      10 /Users/david/.local/state/optiquity-pack-handoff/bd290-w0-20260825T165603Z/w0-probe.patch
```
Patch content (verbatim, confirming a real non-empty diff from leg-b2):
```
diff --git a/README.md b/README.md
index 567179d..d12eadc 100644
--- a/README.md
+++ b/README.md
@@ -1,4 +1,4 @@
-# Optiquity AI Agent Config Pack
+# Optiquity AI Agent Config Pack <!-- w0-probe marker -->
 
 The Config Pack is a versioned **multi-agent project workflow system** for
 Claude Code, Codex CLI, and Antigravity. A persistent **PM Chat** session
```

## §3 Guard messages

**None observed.** No leg produced a permission prompt, sandbox denial, hook
rejection, or guard message of any kind. Every tool call and command returned a
normal success result on the first attempt.

## §4 Anomalies

1. **Leg-e output persisted, not inlined.** The battery's 42.8KB stdout exceeded
   the harness inline limit and was saved to a harness tool-results file (path in
   §2-E). This is normal harness behavior, not a guard event; exit code and tail
   were recovered from the persisted file.
   - Context: the BD-290 design's battery leg will produce similarly large output.
   - Options: (a) design battery invocations to tail/summarize output
     (`... 2>&1 | tail -n 20` or capture to a file in the workspace/handoff dir);
     (b) rely on the harness persisted-output path.
   - Recommendation (evidence-based): (a) — pipe or redirect battery output at
     invocation time so exit code + tail are always inline; the persisted-output
     path worked here but its filename is harness-generated and not predictable.
2. **No other anomalies.** All eight measured shapes behaved as the design's
   optimistic branch assumes: from an `isolation:"worktree"` spawn, Write/Edit
   (untracked AND tracked files), non-git execution, the deep validate battery,
   read-only git (`status`, `diff`-with-redirect) against the out-of-prefix WS,
   and cross-dir patch-emit into the owned handoff dir are ALL permitted with
   zero friction.

## §5 Rules-Applied Verification Block

1. **agents-never-commit**
   - Evidence (quoted): the only git verbs invoked were `git rev-parse --show-toplevel` / `git rev-parse HEAD` (§2-A), `git status --porcelain=v1` (§2-G, output ` M README.md` / `?? w0-scratch.txt`), and `git diff > .../w0-probe.patch` (§2-H, `DIFF_EXIT=0`) — all read-only; the transcript contains zero occurrences of `git commit`, `git add`, `git push`, `git stash`, `git reset`, `git checkout`, `git restore`, `git rm`, `git mv`, `git apply`, `git clean`, `git branch`, `git switch`, `git worktree`, `git config`, `git fetch`, `git pull`, or `git tag`.
   - Conclusion: **COMPLIANT**
2. **per-action-approval-sub-agents**
   - Evidence (quoted): all writes were exactly the sanctioned set — WS files `w0-scratch.txt` (`File created successfully at: /Users/david/.local/state/optiquity-pack-workspaces/w0-probe-20260825T165603Z/w0-scratch.txt`, §2-B/§2-C) and WS `README.md` (§2-F), plus owned-dir files `w0-probe.patch` (§2-H) and this `IMPL-REPORT.md`. No `rm`, `rmdir`, `unlink`, `mv`, `shred`, `truncate`, `find … -delete`, or any deletion was run anywhere; nothing outside WS + owned dir was written.
   - Conclusion: **COMPLIANT**
3. **preflight-stop-means-stop**
   - Evidence (quoted): the probe emitted the plain line `PREFLIGHT: legs A-I complete; about to Write IMPL-REPORT` in the assistant message immediately before this report's Write call; no stop/halt/revert message was received from the parent at any point (nothing to halt on).
   - Conclusion: **COMPLIANT**
4. **rules-applied-verification-block**
   - Evidence (quoted): this §5 block itself — each of the 5 rules-in-force is listed by name with quoted measurement evidence and a terminal COMPLIANT conclusion; no rule is left AMBIGUOUS or evidence-empty.
   - Conclusion: **COMPLIANT**
5. **open-item-surfacing**
   - Evidence (quoted): §4 item 1 surfaces the sole anomaly (persisted-output on the battery leg) with context ("the battery's 42.8KB stdout exceeded the harness inline limit"), two options (a)/(b), and an evidence-based recommendation ("(a) — pipe or redirect battery output at invocation time … the persisted-output path's filename is harness-generated and not predictable"). No deferral-to-another-BD recommendation was made.
   - Conclusion: **COMPLIANT**
