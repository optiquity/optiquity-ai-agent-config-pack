---
name: pm-startup
description: PM chat startup and orientation. Run when starting fresh, resuming on a new machine, or after compaction. Reads current project state from repo files and reports ready status. Do NOT run on normal same-machine resumes — session history is sufficient.
allowed-tools: Read, Bash, Grep
---

You are the PM chat for this project. Run this startup sequence now and report
the result. Do not ask questions — execute each step in order.

## Step 0 — Check for pending one-shot procedures

Before running the standard startup sequence, check whether any one-shot
post-migration procedures are pending. The migration is designed as a
single atomic session (mechanical pass + Procedure 5-C reconciliation +
single commit, all in one chat); this Step 0 sweep is the safety net for
sessions that ended mid-migration (chat closed, machine restarted, etc.).
The migration produces two kinds of signals: the post-run housekeeping
sentinel (Procedure 5-S) and any `*.v9-customized` reconciliation
sidecars (Procedure 5-C).

```bash
[[ -f .pack-migration-backup/v9.3-to-v10.0/postrun-pending ]] && \
    echo "POSTRUN-PENDING: Procedure 5-S"
sidecar_count=$(find . -name '*.v9-customized' \
    -not -path './.pack-migration-backup/*' \
    -not -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')
legacy_backup=$([[ -f docs/pack/prompts/_v9-backup.md ]] && echo 1 || echo 0)
if (( sidecar_count > 0 || legacy_backup > 0 )); then
    echo "RECON-PENDING: Procedure 5-C (${sidecar_count} sidecar(s); legacy=${legacy_backup})"
    # Detect whether the migration was prematurely committed
    # (single-commit-model violation). If migration commits exist on
    # the branch, surface that fact — Procedure 5-C still runs, but
    # the developer should know the protocol was breached.
    if [[ "$(git branch --show-current 2>/dev/null)" == "migration-v9-to-v10" ]]; then
        if [[ -n "$(git log --oneline main..HEAD 2>/dev/null)" ]]; then
            echo "WARN: migration-v9-to-v10 branch has commits ahead of main while sidecars are present — single-commit model breached. Procedure 5-C will still run; flag this to the developer."
        fi
    fi
fi
```

If RECON-PENDING is emitted, this is an interrupted migration. Do NOT
run the standard startup sequence yet. Resume Procedure 5-C from
`docs/pack/INSTALL-PROCEDURES.md` on the existing uncommitted (or, in
the breach case, partially committed) working tree. The procedure walks
each remaining sidecar, then ends with a single migration commit (or a
second commit, in the breach case). Sub-procedure 5-C.1 handles the
legacy `_v9-backup.md` filename for pre-C7 v10.0 installs.

If POSTRUN-PENDING is emitted (and RECON-PENDING is not), reconciliation
already completed — run Procedure 5-S (post-migration housekeeping).

After all triggered procedures complete (or the developer explicitly
defers remaining items), resume the standard startup sequence at Step 1.

If neither line is emitted, this step is a no-op — proceed directly to
Step 1.

## Step 1 — Sync repo

```bash
git pull
```
Note what was fetched, or confirm "already up to date."

## Step 2 — Read core state files

Read these files in full:
- `BACKLOG.md`
- `STATUS.md`
- `PM-CHAT.md`
- `PLATFORM-SKILLS.md`

Read only the most recent dated section from `CHANGELOG.md`.

Identify the current phase from STATUS.md, then read only that phase's section
from `IMPLEMENTATION_PLAN.md`.

Read the first 5 lines of `METHODOLOGY.md` to get the version number.

Use the Document locations section in the project context file to resolve file paths.

## Step 3 — Read active skills

Read the `## Skill loading` section of the project context file. Find the **Active skills:**
line and extract the skill list. If the line still contains the placeholder text
(square brackets), note that active skills have not been set yet — the PM chat
must populate this during kickoff.

## Step 4 — Check RAG ingest freshness

Run:
```bash
git log -1 --format="%H %cd" --date=short -- docs/pack/METHODOLOGY.md
```

If this file was modified since the last known RAG ingest, re-ingest it now
using the mcp-local-rag tool before any queries. If unsure of last ingest date,
re-ingest it.

## Step 5 — Check for TD-TBD sentinel

```bash
grep -rn "TD-TBD" . --include="*.swift" --include="*.py" --include="*.md" \
  --exclude-dir=".git" 2>/dev/null | head -20
```

Any result is a defect requiring immediate attention before proceeding.

## Step 6 — Report current state

Read the project name from the heading at the top of `PM-CHAT.md` — it will be
the first `#` heading (e.g., `# YourProject — PM Chat Instructions`).
Use that name in the output summary below.
Output a summary in exactly this format:

---
**PM Chat Ready — [project name from PM-CHAT.md]**

**Current phase:** Phase N — [title] ([not started / in progress / complete])
**Open BACKLOG items:** [count of Status: Open + Status: Unblocked]
**Last TD number:** TD-NNN (or "none yet" if BACKLOG is empty)
**TD-TBD check:** [Clean / N instances found — [files]]
**Last commit:** [date] — [commit summary from git log -1 --oneline]
**Pack version:** [read from the version header line in METHODOLOGY.md]
**Skills profile:** [project type from PLATFORM-SKILLS.md — e.g., "iOS Swift app" or "Python gRPC server"]
**Active skills:** [list from project context file, or "not set — populate during kickoff"]

**Awaiting instructions.**
---
