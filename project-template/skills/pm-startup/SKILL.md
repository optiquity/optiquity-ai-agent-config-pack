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

Read these in full:
- BACKLOG entries (resolve via the trinity `## Document locations` table;
  reads `BACKLOG.md` in flat-file mode, the tracker in tracker mode)
- STATUS entries (same resolver as above; reads `STATUS.md` in flat-file mode,
  the tracker in tracker mode)
- `PM-CHAT.md`
- `PLATFORM-SKILLS.md`

Read only the most recent dated section from `CHANGELOG.md`.

Identify the current phase from STATUS, then read only that phase's section
from `IMPLEMENTATION_PLAN.md`.

Read the first 5 lines of `METHODOLOGY.md` to get the version number.

Resolve every BACKLOG / STATUS / IMPLEMENTATION_PLAN / CHANGELOG read through
the trinity `## Document locations` table in the project context file (V1 §8.4).
In flat-file mode the table points at the named files in `docs/project/`; in
tracker mode the table points at the tracker (BACKLOG / STATUS / CHANGELOG /
IMPLEMENTATION_PLAN are tracker-mirrored read-only files in that mode).

## Step 3 — Read active skills

Read the `## Skill loading` section of the project context file. Find the **Active skills:**
line and extract the skill list. If the line still contains the placeholder text
(square brackets), note that active skills have not been set yet — the PM chat
must populate this during kickoff.

## Step 4 — Reconcile RAG index against manifest

The RAG manifest in `docs/pack/PM-CHAT.md` § RAG ingestion manifest
is authoritative for which files belong in the local-rag index.
This step reconciles the actual ingested set against the manifest:
**orphans are auto-deleted, stale entries are re-ingested, the diff
is reported in the Step 6 summary.**

**Why this matters.** Orphan chunks (paths in the index but not in
the manifest) are not benign — the retriever returns them on
matching queries, citing dead paths and surfacing stale guidance.
Auto-deleting them on every startup is mandatory. See
`METHODOLOGY.md § RAG index hygiene` for the principle.

Procedure (use the `local-rag` MCP tool channel — the MCP server is
already wired up via `.mcp.json` for Claude Code, via
`.codex/config.toml` for Codex (the wiring is shipped commented-out
in `.codex/config.toml.example` and must be uncommented or copied
into `.codex/config.toml` to take effect), and `.gemini/settings.json`
for Gemini):

1. **List current ingest.** Call the `local-rag` `list` tool. This
   returns the set of currently-ingested paths.
2. **Read the manifest.** Read `docs/pack/PM-CHAT.md` § RAG
   ingestion manifest to determine the intended set. Default
   manifest in v10 is exactly one path: `docs/pack/METHODOLOGY.md`
   (plus any custom project documents declared under `## Additional
   project documents` near the bottom of `PM-CHAT.md`).
3. **Compute the diff:**
   - **Orphans** — paths in the index but not in the manifest.
   - **Stale** — manifest paths whose source file has been edited
     since the last ingest. If the `local-rag` `list` tool exposes a
     per-file ingest timestamp, compare it against
     `git log -1 --format=%ct -- <path>` and treat any
     source-mtime > ingest-timestamp as stale. **Fallback** — if
     `list` does not expose a per-file ingest timestamp (CLI surface
     varies; the verb prints baseDir + files but timestamp fields
     may be absent), treat every manifest path as potentially stale
     and re-ingest unconditionally on each startup. The cost of an
     unnecessary re-ingest is small; the cost of stale chunks is a
     confidently-wrong retrieval. Reflect this in the `RAG:` summary
     line by reporting `stale=N/A` instead of a zero count.
   - **Missing** — manifest paths not in the index.
4. **For each orphan:** call the `local-rag` `delete` tool with
   that path. No user approval is needed — the manifest is the
   source of truth and orphans are by definition outside it.
5. **For each stale or missing manifest path:** call `local-rag`
   `delete` (no-op if missing, clears stale chunks if stale)
   followed by `local-rag` `ingest`.
6. **Record the diff** for inclusion in the Step 6 startup summary.
   Format: `RAG: N ingested, N stale, N orphans removed: [<paths>]`
   (or `RAG: N ingested, 0 stale, 0 orphans` for the clean case).

**If `local-rag` is not available in this CLI surface** (Codex
without the optional MCP block, Gemini without `local-rag` configured,
or first-time-on-this-machine before the embedding model is
downloaded), skip this step and report `RAG: not available — skipped`
in the Step 6 summary. Do not block startup on RAG availability.

**If the manifest is missing or malformed** (e.g., the `## RAG
ingestion manifest` section has been removed from PM-CHAT.md), skip
this step and report `RAG: manifest not found — skipped` in the
Step 6 summary. Surface this as a defect to the developer in the
report so they know to restore the manifest.

**If a manifest path does not exist on disk** (e.g., the manifest
declares `docs/pack/METHODOLOGY.md` but the project has not yet run
the install copy step that creates it), skip ingest for that
specific path and report `RAG: manifest target missing — run
install/migration` in the Step 6 summary. This is the expected
first-run state on a project that has not yet copied
`supporting-docs/METHODOLOGY.md` into `docs/pack/`. Surface it to
the developer so they run `init-project.sh` (new install) or the
appropriate migrator (existing project).

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
**RAG:** [diff from Step 4 — one of: "N ingested, N stale, N orphans" / "N ingested, N stale, N orphans removed: [<paths>]" / "N ingested, stale=N/A (timestamp unavailable; re-ingested unconditionally), N orphans" / "not available — skipped" / "manifest not found — skipped" (defect — surface to developer) / "manifest target missing — run install/migration" (manifest path not on disk; surface to developer)]

**Awaiting instructions.**
---

<!--
Step 7 is reserved. The V1 §10.2 tracker-mode triage queue
(provider.list filter=label:'needs-triage') lands here in a later
BD when tracker mode is wired into pm-startup. The Step 8 numbering
is fixed by V3 §28.1.9 to keep the recommendation check at the
documented insertion point regardless of when Step 7 lands.
-->

## Step 8 — Inflection-point recommendation check (D-19)

Run only in flat-file mode. In tracker mode this step is skipped
entirely (the recommendation system targets flat-file users who
have not yet opted in).

Tracker-mode detection: `docs/pack/tracker.toml` exists at the
project root and its `[mode] state` is `"tracker"`. Otherwise the
surface is flat-file.

In flat-file mode, source the lib (located inside the pack copy
under `docs/pack/scripts/lib/recommendation.sh` for client-side
projects, or via the pack-installed copy under `scripts/lib/` for
projects whose `init-project.sh` ships the libs) and run the test:

```bash
source scripts/lib/recommendation.sh
signals=$(recommendation_compute_signals client "$(pwd)")
state=$(recommendation_state_load .pack-tracker/recommendation-state.json client)
should=$(recommendation_should_recommend "$signals" "$state" client flat-file)
```

If `$should == "true"` AND no per-session "not now" dismiss is in
effect (chat-session memory only — not on disk), surface the prompt
once and record that the show happened:

```bash
recommendation_render_prompt "$signals" client
recommendation_record_shown .pack-tracker/recommendation-state.json "$signals"
```

Then route the user's response per V3 §28.1.7:
- `yes` / `y` / `enable` / `OK` / `sure` → suggest running
  `pack tracker init`. Do not auto-run; await explicit confirmation.
- `not now` / `later` / `no` / `n` / `skip` → set the per-session
  in-memory dismiss flag for this chat session. Do not modify state.
- `don't ask again` / `never` / `disable recommendations` / `stop` →
  call `recommendation_set_persistent_refusal .pack-tracker/recommendation-state.json true`
  and acknowledge.

Reference: ARCHITECTURE-V3.md §28.1.5 (should-recommend test),
§28.1.6 (refusal-respecting state machine), §28.1.7 (prompt shape
and routing), §28.1.9 (implementation surfaces).
