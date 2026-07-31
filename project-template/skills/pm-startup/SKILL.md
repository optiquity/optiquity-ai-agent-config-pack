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
older `_v9-backup.md` filename when present.

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
  reads the per-entry tree under `docs/project/backlog/`)
- STATUS entries (same resolver as above; reads `STATUS.md`)
- `PM-CHAT.md`
- `PLATFORM-SKILLS.md`
- `docs/project/pm-session-state.json` when present — the committed
  live-orchestration resume frontier (runtime-authored; absent on a fresh
  install — if absent, note "no resume frontier — fresh session" and
  continue). When present, note the active work + sub-step, the in-flight
  agents to re-spawn, the queue order + parallelization mode, the pending
  decisions, the review/fix-cycle position, and the boundary commit, and
  surface them on the Step 7 `**Resume:**` line. The PM chat primes from
  the frontier only — it never auto-spawns; re-spawning in-flight agents
  waits for the developer's approval.

Read only the most recent entry in the `docs/project/changelog/` tree.

Identify the current phase from STATUS, then read only that phase's entry
(`docs/project/implementation-plan/phase-N.md`).

Read the groupings contract (`docs/project/groupings/_rules.md`) and list the
`docs/project/groupings/` tree, then compute the groupings counts for Step 7:

```bash
. scripts/groupings-lib.sh && \
    grp_nudge_counts docs/project/groupings docs/project/implementation-plan
```

The output is one `N=<n> M=<m> K=<k>` row — N = real groupings declared,
M = living phases in no grouping, K = declared stays-ungrouped living
phases (superseded phases are excluded from M and K). If the library or
the tree is missing, note "Groupings: not provisioned" for Step 7.

Read the first 5 lines of `METHODOLOGY.md` to get the version number.

Resolve every BACKLOG / STATUS / IMPLEMENTATION-PLAN / CHANGELOG read through
the trinity `## Document locations` table in the project context file.
The table points at the named files in `docs/project/` (the per-entry tree).

Project streams under `docs/project/backlog/`, `docs/project/implementation-plan/`,
`docs/project/changelog/`, and `docs/project/groupings/` are per-entry trees;
read each `<stream>/_rules.md` for the per-stream contract before any per-entry
edit. Each stream's generated `_toc.md` is the readable index of its tree. The
per-entry tree is the sole source of truth — there is no monolithic mirror.

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
is reported in the Step 7 summary.**

**Why this matters.** Orphan chunks (paths in the index but not in
the manifest) are not benign — the retriever returns them on
matching queries, citing dead paths and surfacing stale guidance.
Auto-deleting them on every startup is mandatory. See
`METHODOLOGY.md § RAG index hygiene` for the principle.

Procedure (use the `local-rag` MCP tool channel — the MCP server is
already wired up via `.mcp.json` for Claude Code, via
`.codex/config.toml` for Codex (the wiring is shipped commented-out
in `.codex/config.toml.example` and must be uncommented or copied
into `.codex/config.toml` to take effect), and `.agents/mcp_config.json`
for Antigravity):

1. **List current ingest.** Call the `local-rag` `list` tool. This
   returns the set of currently-ingested paths.
2. **Read the manifest.** Read `docs/pack/PM-CHAT.md` § RAG
   ingestion manifest to determine the intended set. The default
   manifest is exactly one path: `docs/pack/METHODOLOGY.md`
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
6. **Record the diff** for inclusion in the Step 7 startup summary.
   Format: `RAG: N ingested, N stale, N orphans removed: [<paths>]`
   (or `RAG: N ingested, 0 stale, 0 orphans` for the clean case).

**If `local-rag` is not available in this CLI surface** (Codex
without the optional MCP block, Antigravity without `local-rag` configured,
or first-time-on-this-machine before the embedding model is
downloaded), skip this step and report `RAG: not available — skipped`
in the Step 7 summary. Do not block startup on RAG availability.

**If the manifest is missing or malformed** (e.g., the `## RAG
ingestion manifest` section has been removed from PM-CHAT.md), skip
this step and report `RAG: manifest not found — skipped` in the
Step 7 summary. Surface this as a defect to the developer in the
report so they know to restore the manifest.

**If a manifest path does not exist on disk** (e.g., the manifest
declares `docs/pack/METHODOLOGY.md` but the project has not yet run
the install copy step that creates it), skip ingest for that
specific path and report `RAG: manifest target missing — run
install/migration` in the Step 7 summary. This is the expected
first-run state on a project that has not yet installed
`docs/pack/METHODOLOGY.md`. Surface it to
the developer so they run `init-project.sh` (new install) or the
appropriate migrator (existing project).

## Step 5 — Check for TD-TBD sentinel

```bash
grep -rn "TD-TBD" . --include="*.swift" --include="*.py" --include="*.md" \
  --exclude-dir=".git" 2>/dev/null | head -20
```

Any result is a defect requiring immediate attention before proceeding.

## Step 6 — Modes readiness (Claude-only enforcement; LOCAL, never fails startup)

Surface the active operating modes and confirm the Claude-only enforcement hooks
still fire. LOCAL only — no CI gate, no committed sentinel; it NEVER fails the
session (it reports absent / wiring MISSING / self-test FAIL / n/a; it does not
error). Its output feeds the Step-7 report's `**Modes:**` line. This step writes
no file, no config, and no settings.

**(a) Echo the active modes.** Read the three mode values from the per-clone PM
session config, folding an absent / malformed / unreachable config to the family
defaults (`itemized` / `full` / `read-write-only`) per
`docs/pack/PM-OPERATING-MODES.md` § "Reading the config". Read only — never write
the config here.

```bash
cfg="$(git rev-parse --show-toplevel 2>/dev/null)/docs/project/pm-session-config.json"
rm=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("review_mode","itemized"))' "$cfg" 2>/dev/null || echo itemized)
im=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("intervention_mode","full"))' "$cfg" 2>/dev/null || echo full)
sm=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("isolation_mode","read-write-only"))' "$cfg" 2>/dev/null || echo read-write-only)
echo "modes: review=$rm intervention=$im isolation=$sm"
```

Re-state each value's behavior from the matching table in
`docs/pack/PM-OPERATING-MODES.md` (that doc is the SSOT — do not re-derive it
here). Note the per-CLI enforcement split: `review_mode` is cross-CLI salience
only (no hook); `intervention_mode` is cross-CLI salience with a Claude-only
commit-approval hook; `isolation_mode` is Claude-only enforcement. On Codex and
Antigravity the modes are honored by salience — the PM chat applies the recorded
value — but no hook backstops them.

**(b) Hook-readiness canary (Claude-only).** Confirm all three enforcement hooks
still fire. Branch on `CLAUDECODE`: on a non-Claude CLI the hooks do not exist
(report `n/a`); if the hook bodies are absent the feature is not built in this
clone; else run a wiring probe (grep the tracked `.claude/settings.json`) plus a
function canary per body. The commit-gate canary drives the body through its
`MODES_GATE_*` scratch seams and the deletion-boundary canary through its
`DELBOUND_*` seams — a synthetic registry + synthetic temp root — touching NO
live config, token, or filesystem:

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ "${CLAUDECODE:-}" = "1" ]; then
  ISO="$ROOT/scripts/pm-modes-enforce.py"
  GATE="$ROOT/scripts/pm-modes-commit-gate.py"
  DEL="$ROOT/scripts/pm-deletion-boundary.py"
  SETTINGS="$ROOT/.claude/settings.json"
  if [ ! -f "$ISO" ] || [ ! -f "$GATE" ] || [ ! -f "$DEL" ]; then
    echo "modes enforce: hook body absent (feature not built in this clone)"
  else
    if [ -f "$SETTINGS" ] && grep -q 'pm-modes-enforce.py' "$SETTINGS" && grep -q 'pm-modes-commit-gate.py' "$SETTINGS" && grep -q 'pm-deletion-boundary.py' "$SETTINGS"; then
      wired="wired"
    else
      wired="wiring MISSING — restore .claude/settings.json"
    fi
    ic='{"tool_name":"Agent","cwd":"'"$ROOT"'","tool_input":{"subagent_type":"coder","name":"pm-startup-iso-canary"}}'
    ip="$(printf '%s' "$ic" | python3 "$ISO" 2>/dev/null)"
    case "$ip" in *'"permissionDecision":"deny"'*) iso="isolation self-test PASS" ;; *) iso="isolation self-test FAIL — inspect scripts/" ;; esac
    cfg="$(mktemp)"; printf '%s\n' '{"schema":"pm-session-config/1","intervention_mode":"full"}' > "$cfg"
    gc='{"tool_name":"Bash","cwd":"'"$ROOT"'","tool_input":{"command":"git commit -m canary"}}'
    gp="$(printf '%s' "$gc" | MODES_GATE_CONFIG_FILE="$cfg" MODES_GATE_TOKEN_FILE="$cfg.no-token" python3 "$GATE" 2>/dev/null)"
    rm -f "$cfg"
    case "$gp" in *'"permissionDecision":"deny"'*) gate="commit-gate self-test PASS" ;; *) gate="commit-gate self-test FAIL — inspect scripts/" ;; esac
    dreg="$(mktemp)"; downed="/delbound-canary-owned"
    printf '%s\n' '{"agent_id":"delbound-canary","owned_dir":"'"$downed"'"}' > "$dreg"
    dc='{"tool_name":"Bash","agent_id":"delbound-canary","cwd":"'"$downed"'","tool_input":{"command":"rm -rf /delbound-canary-root/bd257-*"}}'
    dp="$(printf '%s' "$dc" | DELBOUND_REGISTRY_FILE="$dreg" DELBOUND_TEMP_ROOTS="/delbound-canary-tmp" python3 "$DEL" 2>/dev/null)"
    ac='{"tool_name":"Bash","agent_id":"delbound-canary","cwd":"'"$downed"'","tool_input":{"command":"rm -rf '"$downed"'/scratch && rm -rf /delbound-canary-tmp/x && rm -rf \"$WORK\""}}'
    ap="$(printf '%s' "$ac" | DELBOUND_REGISTRY_FILE="$dreg" DELBOUND_TEMP_ROOTS="/delbound-canary-tmp" python3 "$DEL" 2>/dev/null)"
    rm -f "$dreg"
    del="deletion-boundary self-test FAIL — inspect scripts/"
    case "$dp" in *'"permissionDecision":"deny"'*) case "$ap" in *'"permissionDecision":"deny"'*) : ;; *) del="deletion-boundary self-test PASS" ;; esac ;; esac
    echo "modes enforce: $wired ($iso, $gate, $del) — Claude-only"
  fi
else
  echo "modes enforce: n/a (non-Claude CLI — isolation_mode + the hooks are Claude-only)"
fi
```

On a fault, REPORT + OFFER — never auto-mutate. A canary FAIL means a broken
tracked hook body; the fix is a git-level restore (a user action) — report it,
do not run a git verb. Wiring MISSING means the tracked `.claude/settings.json`
was edited away — report it and point to restoring that file. Combine the two
outputs for the Step-7 report's `**Modes:**` line: `review=<r>, intervention=<i>,
isolation=<s>; enforce: <the canary result>`.

## Step 6b — Quality-gate enforcement (detect + suggest; LOCAL, never fails startup)

Detect whether the shipped `validate.sh` quality gate is actually ENFORCED —
run before code leaves the machine — and, when it is not, SUGGEST the opt-in
pre-push hook. This step is DETECT + REPORT + SUGGEST ONLY: it writes no file,
installs nothing, and never fails the session. Its output feeds the Step-7
report's `**Quality gate:**` line.

**This step NEVER runs any install script.** Installing the hook is a separate
action the PM chat performs only after the developer explicitly approves it
(see `PM-CHAT.md` § Behavioral rules) — never from inside this step.

Detection delegates to the shipped helper `scripts/detect-validate-enforcement.sh`,
which reads (never writes) the two enforcement channels and prints one verdict
token. This step only DRIVES that helper and formats the result — it does not
re-implement the matching:

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
DET="$ROOT/scripts/detect-validate-enforcement.sh"
if [ ! -f "$DET" ]; then
  gate="unavailable"          # detector not present in this clone — benign
else
  gate="$(bash "$DET" 2>/dev/null || echo unenforced)"
  case "$gate" in
    'enforced (ci-workflow)'|'enforced (git-hook)'|unenforced) ;;
    *) gate="unenforced" ;;   # empty / unknown token → safe default
  esac
fi
echo "quality gate: $gate"
```

**Report + suggest by verdict:**

- `enforced (ci-workflow)` / `enforced (git-hook)` — report `Quality gate:
  enforced (<CI workflow | git hook>)`. No suggestion.
- `unenforced` — report `Quality gate: unenforced` and SUGGEST, in one terse
  line: *"`validate.sh` is not enforced before pushes on this clone. If you
  approve, I can install an opt-in local pre-push hook that runs it — the
  installer is `scripts/install-validate-hook.sh`. It is advisory; bypass any
  push with `git push --no-verify`. (This is a best-effort local check — if you
  already run `validate.sh` via a CI system or a wrapper I can't see, just
  decline.)"* The installer runs only after the developer's explicit approval,
  as a separate action — never from this step.
- `unavailable` — report `Quality gate: check unavailable (detector not present
  in this clone)`. No suggestion.

**Safe bias.** When detection is uncertain, report UNENFORCED and re-suggest —
never a speculative "enforced." A false "unenforced" costs one declined
suggestion; a false "enforced" silently rots the gate. Detection is a
best-effort local heuristic covering GitHub Actions workflows and the local
pre-push / pre-commit hook bodies; it does not see other CI systems or wrapper
targets, so a project enforced another way may still see this suggestion — that
is the safe bias, not a bug.

## Step 7 — Report current state

Read the project name from the heading at the top of `PM-CHAT.md` — it will be
the first `#` heading (e.g., `# YourProject — PM Chat Instructions`).
Use that name in the output summary below.
Output a summary in exactly this format:

---
**PM Chat Ready — [project name from PM-CHAT.md]**

**Current phase:** Phase N — [title] ([not started / in progress / complete])
**Open BACKLOG items:** [count of Status: Open + Status: Unblocked]
**Last TD number:** TD-NNN (or "none yet" if BACKLOG is empty)
**Groupings:** [from the Step 2 counts — `N declared; M phases ungrouped (K declared stays-ungrouped)`, or "not provisioned"]
**TD-TBD check:** [Clean / N instances found — [files]]
**Last commit:** [date] — [commit summary from git log -1 --oneline]
**Pack version:** [read from the version header line in METHODOLOGY.md]
**Skills profile:** [project type from PLATFORM-SKILLS.md — e.g., "iOS Swift app" or "Python gRPC server"]
**Active skills:** [list from project context file, or "not set — populate during kickoff"]
**RAG:** [diff from Step 4 — one of: "N ingested, N stale, N orphans" / "N ingested, N stale, N orphans removed: [<paths>]" / "N ingested, stale=N/A (timestamp unavailable; re-ingested unconditionally), N orphans" / "not available — skipped" / "manifest not found — skipped" (defect — surface to developer) / "manifest target missing — run install/migration" (manifest path not on disk; surface to developer)]
**Modes:** [from the Step 6 Modes readiness step — `review=<r>, intervention=<i>, isolation=<s>; enforce: <readiness>`, where <readiness> is one of: `wired (isolation self-test PASS, commit-gate self-test PASS, deletion-boundary self-test PASS) — Claude-only` / `wired (isolation self-test PASS, commit-gate self-test PASS, deletion-boundary self-test FAIL — inspect) — Claude-only` / `wiring MISSING — restore .claude/settings.json` / `hook body absent (feature not built in this clone)` / `n/a (non-Claude CLI)`]
**Quality gate:** [from the Step 6b enforcement check — one of: `enforced (ci-workflow)` / `enforced (git-hook)` / `unenforced (pre-push hook suggested)` / `check unavailable (detector not present in this clone)`]
**Resume:** [from `docs/project/pm-session-state.json` — `no resume frontier — fresh session` if absent, else `active: <work item> @ <sub-step>; in-flight: <agents to re-spawn>; queue: <order>; mode: <serial|parallel>; pending: <decisions>; cycle: <position>; boundary <sha8>`]

**Awaiting instructions.**
---

