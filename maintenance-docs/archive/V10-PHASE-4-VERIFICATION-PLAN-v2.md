# V10-PHASE-4-VERIFICATION-PLAN-v2.md — Per-section runbook for C-V10-15 (with OT real-project verification)

*Status: Active (v10-dev). Supersedes `V10-PHASE-4-VERIFICATION-PLAN.md` for execution of C-V10-15. v1 content carries forward verbatim; v2 ADDS §4.6 / §4.7 / §4.8 (Optiquity Trader real-project verification) without replacing any v1 section.*
*Companion plan to `V10-PHASE-4-PLAN.md` Part 4.*
*Authoritative spec for what evidence is required: `V10-PHASE-4-PLAN.md` Part 4 (§4.1–§4.5). §4.6 / §4.7 / §4.8 are project-lead-authorized v2 additions; their evidence requirements are defined in this v2 plan (Parts 6.5–6.7) and folded into Gate F readiness.*
*Authoritative spec for fixture sourcing: `V10-PHASE-3B-PLAN.md` Part 5 §5.1–§5.5 (carried forward by V10-PHASE-3B-PLAN-v2 §5). The OT real-project fixture is a v2-only addition not covered by that spec.*
*Authoritative spec for cross-surface matrix: `V10-PHASE-3B-DESIGN-v2.md` Part 11.*
*Authoritative spec for the manual-mode pointer wording: `V10-PHASE-3B-PLAN-v2.md` §3.3.*

**v2 supersession note.** This document is the single execution reference for C-V10-15 once v2 is approved. v1 (`V10-PHASE-4-VERIFICATION-PLAN.md`) remains on disk as a historical artifact and as the source-of-truth for content that v2 inherits verbatim. Where v2 inserts new material, the section numbering is non-overlapping with v1: v1's Part 6 (§4.4 synthetic migration) is preserved unchanged; v2 adds Parts 6.5 / 6.6 / 6.7 between Part 6 and Part 7 to host the §4.6 / §4.7 / §4.8 runbooks. Parts 0, 2, 9, 10, 11, 12, 13 receive additive sub-section inserts (§0.8 / Part 2 sub-table 2.0.1 / Part 9 ordering rows / Part 10 rows R10-15..R10-17 + §10.1 update / Part 11 rows 13–15 / OQ-VP4-8 / M-OT). Every other section of v1 is byte-identical in v2.

---

## Part 0 — Status, scope, and what this plan IS / ISN'T

### 0.1 Status

C-V10-01 through C-V10-14 have landed on `v10-dev`. Tip is **`459161b`** (or
a descendant). All 31 audit findings are resolved (AF-027 alone is "no
action — accepted plan-reality drift"). `scripts/test-detect.sh` exists
and passes 34/34. **One commit remains before Gate F: C-V10-15** — the
Phase 4 verification harness, which creates one new file
`maintenance-docs/V10-PHASE-4-VERIFICATION.md` capturing evidence from
five independent verification streams.

### 0.2 Scope of this plan

This plan governs **execution of C-V10-15 only.** It is a per-section
runbook that supplements `V10-PHASE-4-PLAN.md` Part 4 with:

- Copy-pasteable command sequences for every fixture, every check, and
  every cleanup.
- A "who runs what where" matrix that names the runner (this CLI / dev
  in another CLI / dev in browser) for each section.
- A surface-availability pre-flight that fires **before** any
  verification work begins, so an unavailable surface triggers F-B at
  the right moment instead of mid-run.
- A unified evidence-capture template applied uniformly to all five
  sections.
- An explicit rollback table for every state-creating operation.

### 0.3 What this plan is NOT

- It does **not** supersede `V10-PHASE-4-PLAN.md`. Where this plan's
  procedural detail conflicts with that plan's specification, the
  specification wins; flag back to project lead before proceeding.
- It does **not** change Gate F entry criteria. Those are
  `V10-PHASE-4-PLAN.md` Part 5 (12 numbered criteria).
- It does **not** authorise edits to any pack file other than
  `maintenance-docs/V10-PHASE-4-VERIFICATION.md` (the one file C-V10-15
  creates).
- It does **not** change the eight flag-backs F-A..F-H in
  `V10-PHASE-4-PLAN.md` Part 8. Section runbooks below name flag-backs
  by ID; the wording lives in the parent plan.

### 0.4 Hard guardrails (every section must obey)

1. **Every fixture path is under `/tmp/phase-4-fixtures/`.** Never under
   `~/tmp/`, never under any pack worktree, never under
   `maintenance-docs/v10-working/`. `/tmp/` is volatile, ungitignored,
   and outside any tracked tree.
2. **Every state-creating operation has a rollback row in §10.** No
   exceptions. If the implementer adds a step that creates state, they
   add the matching rollback row first.
3. **No git command in this plan targets the live pack repo at
   `/Users/david/Developer/dhs-ai-agent-config-pack`.** Migration smoke
   (§4.4) operates exclusively on `/tmp/phase-4-fixtures/v9-project/`.
   The v9.3 pack source clone lives at `/tmp/v9-pack-source/`. Both are
   independent of any pack worktree.
4. **`PACK` always points at the v10-dev worktree** for verification
   purposes:
   `PACK=/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev`. The
   migration smoke uses this `PACK` value (it is the v10 source the
   v9.3 fixture is migrated against).
5. **`git status` clean on `v10-dev` before C-V10-15 begins**, and
   `git status` must remain clean throughout — only the single new
   verification file is touched at commit time.
6. **No silent deferrals.** Any unavailable surface, any failing run,
   any unexpected output triggers the corresponding F-B / F-G / F-H
   flag-back row recorded inline in `V10-PHASE-4-VERIFICATION.md` with
   project-lead acknowledgement.

### 0.5 Resolved environment facts (from this plan's preparation)

| Fact | Value | How verified |
|---|---|---|
| v10-dev worktree path | `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev` | `git status` shows clean tree at `459161b`. |
| Main pack worktree path | `/Users/david/Developer/dhs-ai-agent-config-pack` | Lives alongside v10-dev; **not touched** by this plan. |
| Latest v10-dev commit | `459161b` (`feat: v10 — scripts/test-detect.sh unit tests for detect.sh library functions`) | `git -C $PACK rev-parse HEAD`. |
| Available surfaces (this Mac) | `claude` (CLI), `codex`, `gemini` all on `$PATH` | `command -v claude codex gemini`. |
| v9.3 tag exists in remote | yes | `git -C $PACK tag --list 'v9*'` shows `v9 v9.0 v9.1 v9.2 v9.3`. |
| `bash scripts/test-detect.sh` | 34 passed, 0 failed | Re-run pre-§4.5 capture. |
| `init-project.sh` interactive prompts | Exactly one: `Proceed? [y/N]` at line 232; default `N` (must reply `y` to advance past preview gate). | `grep -nE 'read -[rp]' scripts/init-project.sh` returns one match. |
| Pack repo visibility | **PRIVATE** on GitHub. `git clone https://github.com/DShaneNYC/dhs-ai-agent-config-pack` requires auth and may fail. | `gh repo view DShaneNYC/dhs-ai-agent-config-pack --json visibility` returns `PRIVATE`. |
| v9.3 tag in live pack repo | Present (also v9.0, v9.1, v9.2, bare v9). | `git -C /Users/david/Developer/dhs-ai-agent-config-pack tag --list 'v9*'`. |
| §6.3 v9.3 source method | **Local clone** from live pack repo (NOT network clone from GitHub) — sidesteps private-repo auth and is faster (git hard-link optimization). | See §6.3 below. |
| Live worktree branch | `main` (independent of v10-dev) | `git -C /Users/david/Developer/dhs-ai-agent-config-pack rev-parse --abbrev-ref HEAD`. |

If any of these facts has shifted by execution time, **re-confirm in
the pre-flight (Part 1) and update this table inline** before starting
§4.1.

### 0.6 Scope decisions made before execution (project-lead resolved)

Project lead resolved several scope decisions before plan execution
began. These supersede the corresponding open questions in Part 12:

- **§4.2 cross-surface live runs are DEFERRED.** Per project-lead
  direction (2026-04-25): Codex CLI and Gemini CLI live runs are not
  required for v10.0; instead, a **docs-research pass** runs after
  §4.1 Claude Code CLI tests succeed, identifying where each surface
  would deviate from the Claude Code CLI behavior and what to flag
  for v10.1. Same applies to Desktop Commander. Resolves OQ-VP4-1
  and OQ-VP4-7 as MOOT.
- **§3.2.3 F3 simulator-empty test uses PATH-based stub** (option a
  from gap discussion), not chat-side fakery. Resolves OQ-VP4-2.
- **§4.4 fixture realism: thin v9.3 fixture for v10.0;** richer
  fixture (x-files, custom skills, populated PROMPT-TEMPLATES.md) is
  a v10.1 candidate. Resolves OQ-VP4-4.
- **Evidence file size: verbatim outputs preferred; no hard ceiling.**
  Resolves OQ-VP4-5.
- **§6.3 v9.3 source: local clone from `/Users/david/Developer/dhs-
  ai-agent-config-pack` (not GitHub).** No network egress required.
  Resolves OQ-VP4-6.

OQ-VP4-3 (F2 multi-scheme model behavior) remains open — needs
execution context.

### 0.7 Hybrid execution scope

Project lead chose **hybrid scope** (start minimal; expand if
anomalies surface). Practical execution order under hybrid scope:

1. **§4.5** — `test-detect.sh` capture (autonomous; this CLI session)
2. **§4.1 F1 only** — Claude Code CLI happy-path (developer in a
   separate `claude` session)
3. **Reassess.** If F1 surfaces no defects, proceed; if a defect
   appears, stop and re-plan.
4. **§4.4** — migration script smoke (autonomous; this CLI session)
5. **§4.3** — Claude Web manual-mode (developer in browser)
6. **Docs-research pass (replaces §4.2 live runs)** — autonomous;
   this CLI session
7. **§4.1 F2..F6 corner-case fixtures** — only if §4.1 F1 succeeds and
   the project lead opts in to expanded coverage

Sections F2..F6 are conditional on hybrid expansion. The "minimal"
scope is sections 1, 2, 4, 5, 6 (no F2..F6, no live cross-surface).

### 0.8 v2 additions — Optiquity Trader (OT) real-project verification

Project lead has authorized adding three sections to C-V10-15 evidence to
exercise the v10 pack against a real, in-the-wild v9.3-shaped project
("Optiquity Trader", abbreviated **OT** below, located at
`/Users/david/Developer/OptiquityTrader/`). v1's §4.4 synthetic v9.3
fixture stays in scope and is **not** replaced; §4.6 / §4.7 / §4.8 run
**in addition** to v1's §4.1–§4.5. By the time §4.6 begins, most defects
should already be caught by §4.1–§4.5; §4.6 / §4.7 / §4.8 are the
in-the-wild final-mile validation.

#### 0.8.1 New sections at a glance

| § | Stream | Runner | Goal |
|---|---|---|---|
| 4.6 | OT migration smoke (NEW) | this CLI session (autonomous) | Run `migrate-v9-to-v10.sh` against a clone of OT; capture stdout, post-migration `git diff --stat`, and the §6.6-equivalent verification checks adapted for OT realities. |
| 4.7 | OT post-migration kickoff smoke (NEW) | dev in a separate `claude` session (manual **M-OT**) | Reuse §4.6's post-migration OT clone; paste the kickoff variant with placeholders pre-filled with OT's actual project name; exercise Procedure 7. |
| 4.8 | OT-vs-synthetic comparison (NEW) | this CLI session (autonomous) | Structural comparison only (NO OT content quoted): file-path diffs, validate-pack.py exit codes, migration script stdout differences (Procedure 5-R prompt verbatim — pack-generated text), quantitative summary. |

#### 0.8.2 Hard OT-safety guardrails (every §4.6 / §4.7 / §4.8 procedure must obey)

1. **OT live repo at `/Users/david/Developer/OptiquityTrader/` is
   read-only throughout.** Never written to. Source git config /
   branches / tags / refs / working tree untouched. Verified explicitly
   in §6.5.7 cleanup with a post-cleanup
   `git -C /Users/david/Developer/OptiquityTrader/ status --porcelain`
   that MUST return empty.
2. **No commits to the OT clone push to any remote.** The migration
   script never pushes (read `scripts/migrate-v9-to-v10.sh` lines 1–463
   to confirm — no `git push` invocation anywhere); this plan never
   invokes `git push` against the clone. The migration branch
   `migration-v9-to-v10` (created by the script per
   `scripts/migrate-v9-to-v10.sh` line 110) lives only inside the clone
   and dies with the clone at cleanup.
3. **Cleanup leaves zero trace.** `rm -rf /tmp/phase-4-fixtures/ot-project`
   deletes the clone. Source OT repo is byte-identical to before
   C-V10-15 ran, verified by:
   - `git -C /Users/david/Developer/OptiquityTrader/ rev-parse HEAD`
     equals the SHA captured at §6.5.3 baseline.
   - `git -C /Users/david/Developer/OptiquityTrader/ status --porcelain`
     returns empty.
   - `git -C /Users/david/Developer/OptiquityTrader/ rev-parse
     --abbrev-ref HEAD` equals the branch captured at §6.5.3 baseline.
4. **Evidence file is sanitized.** Pack behavior described structurally;
   no OT source code / no OT documentation body / no proprietary content
   reproduced. **Pack-generated text** (kickoff prompt body,
   Procedure 5-R prompt, migration script stdout, the script's report
   under `.pack-migration-backup/v9.3-to-v10.0/report.md`) IS allowed
   verbatim — that is pack content, not OT content. The §6.5.10 /
   §6.6.7 / §6.7.5 evidence-block shapes enumerate which fields are
   OT-quoting-safe and which require structural-only summary.
5. **§4.6 / §4.7 / §4.8 are ADDITIONS, not replacements.** §4.4 synthetic
   stays in scope. Skipping §4.4 is NOT an acceptable substitute for
   §4.6 — they probe different things (synthetic = controlled minimum;
   OT = real-project complexity: custom skills, populated content,
   real source layout). §4.8 explicitly compares both.

#### 0.8.3 OT-specific scope decisions resolved before execution

- **Clone method.** `git clone --no-hardlinks /Users/david/Developer/
  OptiquityTrader /tmp/phase-4-fixtures/ot-project`. The
  `--no-hardlinks` flag ensures the clone is a fully independent copy
  of the live repo's object store; the live OT repo is untouched even
  if the clone's `.git/` is corrupted or unexpectedly modified. (Local
  git clones across the same filesystem default to hardlinks, which
  share blobs — `--no-hardlinks` is the safety guarantee.)
- **Clone scope.** Full clone (all branches / refs the live repo
  carries). `--depth 1` is NOT used — the migration script's S6 stage
  (`git -C "$PACK" show v9.3:supporting-docs/PROMPT-TEMPLATES.md`)
  reads from `$PACK`, not from the project repo, so depth-1 on the
  clone would not break the script; we keep full history for forensic
  value if §4.6 surfaces a defect that needs OT-side bisection.
- **OT pre-flight read-only checks.** Before clone, this CLI session
  runs `git -C /Users/david/Developer/OptiquityTrader/ rev-parse HEAD`,
  `git -C /Users/david/Developer/OptiquityTrader/ rev-parse
  --abbrev-ref HEAD`, and `git -C /Users/david/Developer/
  OptiquityTrader/ status --porcelain` — all READ-ONLY operations.
  No writes / no checkouts / no fetches / no `git gc` / no `git fsck
  --connectivity-only` (which writes a lock-file in some git versions)
  against the live OT repo. The captured HEAD SHA + branch + status
  are the byte-identity baseline checked at §6.5.7 cleanup.
- **Sanitization shape.** §6.5.10 / §6.6.7 / §6.7.5 below define the
  evidence-block fields that are safe to populate with verbatim OT-
  derived output (pack-generated text only) versus structural summary
  only. The implementer follows the per-field guidance — silent
  expansion of an evidence field beyond its sanitization rule is F-E
  (silent scope expansion).
- **OT-clone disk budget.** §4.6 pre-flight verifies ≥1 GB free under
  `/tmp` (a real repo with full history can be hundreds of MB; the
  migration backup adds another tens of MB). Insufficient disk is a
  pre-flight FAIL — the implementer reports F-B-style unavailability
  before clone, not mid-clone.

#### 0.8.4 What v2 leaves unchanged from v1

OT additions do **not** change v1 scope decisions. §0.6 (deferred
surfaces, F3 stub method, fixture realism, evidence sizing, §6.3
local-clone source) and §0.7 (hybrid execution; minimal-scope = §4.5,
§4.1 F1, §4.4, §4.3, docs-research; expanded scope adds F2..F6) all
carry forward unchanged. The OT additions are a **third tier** layered
on top of v1's hybrid scope: minimal scope → expanded F2..F6 → OT
real-project. Each tier is a separate project-lead opt-in decision;
running v2's §4.6 / §4.7 / §4.8 does not require running v1's F2..F6
expansion (and vice versa).

---

---

## Part 1 — Surface-availability pre-flight (run this FIRST)

**When:** Before any §4.1 / §4.2 / §4.3 / §4.4 work begins.
**Where:** This CLI session, in the v10-dev worktree.
**Why:** R-V10-2 (Phase 4 Plan Part 9) — discovering an unavailable
surface mid-run forces an awkward F-B at the wrong point. Pre-flight
fires F-B once, up front, and the project lead resolves it once.

### 1.1 Pre-flight commands (copy-paste verbatim)

```bash
# Anchor the pack path for the entire session.
export PACK=/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev

# Sanity: pack worktree exists and is on v10-dev.
[[ -d "$PACK" ]] && echo "OK: PACK exists" || echo "FAIL: PACK missing"
git -C "$PACK" rev-parse --abbrev-ref HEAD     # expect: v10-dev
git -C "$PACK" status --porcelain              # expect: empty (clean)
git -C "$PACK" rev-parse HEAD                  # expect: 459161b… or descendant

# v9.3 tag resolvable in pack remote (used by §4.4).
git -C "$PACK" rev-parse v9.3 >/dev/null && echo "OK: v9.3 resolvable" || echo "FAIL: v9.3 missing"

# Surface presence — record results into a scratch buffer.
{
  printf 'Pre-flight surface check (%s)\n' "$(date -u +%FT%TZ)"
  for tool in claude codex gemini bash python3 git; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '  %-10s present at %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '  %-10s MISSING\n' "$tool"
    fi
  done
  # Versions where they exist.
  command -v claude  >/dev/null && claude  --version 2>&1 | head -1 | sed 's/^/  claude:  /'
  command -v codex   >/dev/null && codex   --version 2>&1 | head -1 | sed 's/^/  codex:   /'
  command -v gemini  >/dev/null && gemini  --version 2>&1 | head -1 | sed 's/^/  gemini:  /'
} > /tmp/phase-4-preflight.txt
cat /tmp/phase-4-preflight.txt

# Fixture base directory — created here, removed by §10 row R10-1.
mkdir -p /tmp/phase-4-fixtures
ls -ld /tmp/phase-4-fixtures
```

### 1.2 Pre-flight pass criteria

All must be true before the implementer proceeds to §4.1:

- `PACK` exports to a directory that exists.
- `git -C "$PACK" status --porcelain` returns empty.
- `git -C "$PACK" rev-parse --abbrev-ref HEAD` returns `v10-dev`.
- `git -C "$PACK" rev-parse v9.3` returns a SHA (no error).
- `claude`, `bash`, `python3`, `git` all present on `$PATH`.
- `/tmp/phase-4-fixtures/` exists and is writable.

### 1.3 Surface unavailability handling (F-B status under §0.6 decisions)

Under §0.6 scope decisions, **Codex CLI / Gemini CLI / Desktop
Commander are pre-deferred** — they do not need to be present at
pre-flight, and their absence does NOT block C-V10-15. The §4.2 live
runs are replaced by a docs-research pass (Part 4) that runs
autonomously after §4.1 succeeds.

**Required surfaces for hybrid scope:**

| Surface | Required? | Why |
|---|---|---|
| `claude` (Claude Code CLI) | **Yes** | §4.1 fixture runs; §4.5 test-detect.sh capture; this implementer session |
| `bash`, `git`, `python3` | **Yes** | every section |
| Claude Web (in browser) | **Yes** for §4.3 | manual-mode smoke; developer-in-browser |
| `codex` | No (deferred) | docs-research pass instead |
| `gemini` | No (deferred) | docs-research pass instead |
| Claude Desktop + filesystem MCP | No (deferred) | docs-research pass instead |

If a **required** surface is missing (`claude` / `bash` / `git` /
`python3`), F-B fires and C-V10-15 cannot proceed until resolved.

If an **optional** surface (`codex` / `gemini` / Desktop Commander)
happens to be present anyway, the implementer records its presence
in the §4.5 evidence block "available surfaces" line; the docs-
research pass still runs (we do not opportunistically expand to live
runs without project-lead direction).

### 1.4 Verbatim wording for v10.1-deferred surface entries

The §4.2 docs-research-pass output (see Part 4 below) uses this
wording for each cross-surface row that names a deferred-to-v10.1
risk:

> **Surface deferred to v10.1 docs-research pass per §0.6 scope
> decision.** No live run was performed against `<surface name>`
> for v10.0. The behavior described in this row is derived from
> documentation (cite source) and architectural reasoning, not from
> direct observation. Tracked as v10.1 candidate per V10-PHASE-4-PLAN
> F-B resolution.

---

## Part 2 — Who runs what where (matrix)

One row per Part-4 section. Columns: section / surface / runner /
prerequisite-check command (run before starting that section).

| § | Surface | Runner | Where | Prerequisite check (run before starting) |
|---|---|---|---|---|
| 4.1 | Claude Code CLI | **Developer in a separate `claude` session** (this implementer cannot run claude inside claude) | Inside fixture `/tmp/phase-4-fixtures/<fixture>/` | `command -v claude && [[ -d /tmp/phase-4-fixtures ]] && echo OK` |
| 4.2 (docs-research) | (no live surface) | **This CLI session** | v10-dev worktree | §4.1 has captured at least F1; pack docs (`pm-chat.md`, `METHODOLOGY.md` Procedure 7, `V10-PHASE-3B-DESIGN-v2.md` Part 11) all readable. |
| 4.3 | Claude Web (no MCP) | **Dev in browser** at `claude.ai` | New chat, **no** project / no GitHub connector / no Desktop Commander | Dev opens a fresh chat window; pre-condition is "no tooling attached." |
| 4.4 | Bash | **This CLI session** | `/tmp/phase-4-fixtures/v9-project/` (NOT the pack worktree) | Pre-flight passes; v9.3 resolvable in live pack repo; `$PACK` set. |
| 4.5 | Bash | **This CLI session** | v10-dev worktree | `bash $PACK/scripts/test-detect.sh` was already run (and is re-run during §4.5 capture); already-passing per 0.5. |

### 2.0.1 Matrix — v2 OT additions (§4.6 / §4.7 / §4.8)

| § | Surface | Runner | Where | Prerequisite check (run before starting) |
|---|---|---|---|---|
| 4.6 | Bash | **This CLI session** | `/tmp/phase-4-fixtures/ot-project/` (NOT the live OT repo at `/Users/david/Developer/OptiquityTrader/`) | Pre-flight passes; §4.4 synthetic completed and its evidence captured; live OT repo exists and is on its expected branch with clean working tree; `$PACK` set; `command -v git` |
| 4.7 | Claude Code CLI | **Developer in a separate `claude` session** (this implementer cannot run claude inside claude) | Inside `/tmp/phase-4-fixtures/ot-project/` (the §4.6 post-migration clone — DO NOT tear down between §4.6 and §4.7) | §4.6 has reached pass; the OT-tailored kickoff paste file exists at `/tmp/phase-4-fixtures/kickoff-paste-OT.txt`; `command -v claude` |
| 4.8 | Bash | **This CLI session** | v10-dev worktree (read-only) | §4.4 synthetic post-migration tree at `/tmp/phase-4-fixtures/v9-project/` AND §4.6 OT post-migration tree at `/tmp/phase-4-fixtures/ot-project/` BOTH still present (both must NOT be torn down before §4.8 runs); §4.7 evidence captured |

The §4.6 / §4.7 / §4.8 rows extend the v1 Part 2 matrix; they do not
replace any v1 row. Concurrency rules in §2.1 below apply only to v1
sections; v2 ordering / parallelism is in §9.4.

### 2.1 Concurrency rules (see also Part 9 parallelization)

- §4.1 fixtures (F1 only under hybrid scope; F2..F6 conditional) are
  built and torn down per fixture. No reuse across sections under the
  current scope.
- §4.2 docs-research pass runs autonomously after §4.1 — it consumes
  the §4.1 evidence (specifically the F1 capture) and pack
  documentation, not live surfaces.
- §4.3 (browser) is independent of every other section. Run in
  parallel with §4.1 / §4.4 freely.
- §4.4 (migration smoke) operates on a **separate** fixture
  (`/tmp/phase-4-fixtures/v9-project/`) that has no overlap with §4.1
  fixtures. §4.4 may run in parallel with any other section.
- §4.5 is capture-only; the test runner already passed at C-V10-14.

### 2.2 Surfaces this plan does NOT exercise

ChatGPT Web is mentioned in `pm-chat.md` line 25 as a non-shell
surface. ChatGPT Web is **not** on the §4.2 cross-surface matrix and
is **not** required for §4.3 — Claude Web is the canonical manual-mode
surface per `V10-PHASE-3B-PLAN-v2` Part 7 criterion 8. Do not expand
§4.3 scope to ChatGPT Web; that is an F-E (silent scope expansion)
trigger.

---

## Part 3 — §4.1 Fixture evidence runbook

**Goal of §4.1.** For each of the six fixtures F1..F6, demonstrate that
the kickoff → Procedure 7 path produces the expected Form R / I / E /
M outputs (or the expected refusal / skip behavior) on at least one
Bash-capable surface (Claude Code CLI is canonical).

**Reference spec.** `V10-PHASE-4-PLAN.md` §4.1 (six fixtures table);
`V10-PHASE-3B-PLAN.md` Part 5 §5.1–§5.4 (fixture sourcing strategy);
`supporting-docs/METHODOLOGY.md` Procedure 7 (the procedure under
test).

### 3.1 Prerequisites (run once before any fixture)

```bash
# Must already be exported from Part 1 pre-flight:
echo "PACK=$PACK"      # expect: /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
[[ -n "${PACK:-}" ]] || { echo "FAIL: re-run Part 1 pre-flight"; exit 1; }

# Fixture base directory.
mkdir -p /tmp/phase-4-fixtures
ls -ld /tmp/phase-4-fixtures
```

**`init-project.sh` interactive note.** Each fixture builder calls
`"$PACK/scripts/init-project.sh" .` which prompts exactly once with
`Proceed? [y/N]` (script line 232). Default is `N`. The fixture
builder must reply `y` (or `yes`) to advance past the preview gate.
No other prompts fire during init — the script auto-detects project
state from the filesystem.

### 3.2 Fixture-construction commands

Each fixture is constructed inline below. **Do NOT condense the
six blocks into a loop** — each fixture has subtle differences (Apple
vs Python, gRPC vs no-gRPC, single vs multi scheme, etc.) and a loop
hides those differences from the evidence record.

#### 3.2.1 F1 — `apple-spm-single-scheme`

**Exercises.** Single SPM scheme; happy-path Form R + I + E + M.

```bash
F1=/tmp/phase-4-fixtures/apple-spm-single-scheme
rm -rf "$F1"   # idempotent — safe even on first run
mkdir -p "$F1"
cd "$F1"
git init -q

# Pack-template install.
"$PACK/scripts/init-project.sh" .   # answer prompts: Apple/Swift, no gRPC

# Minimal SPM project — single scheme.
cat > Package.swift <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "F1App",
    products: [.library(name: "F1App", targets: ["F1App"])],
    targets: [
        .target(name: "F1App", path: "Sources/F1App"),
        .testTarget(name: "F1AppTests", dependencies: ["F1App"], path: "Tests/F1AppTests"),
    ]
)
EOF
mkdir -p Sources/F1App Tests/F1AppTests
cat > Sources/F1App/F1App.swift <<'EOF'
public struct F1App { public init() {} }
EOF
cat > Tests/F1AppTests/F1AppTests.swift <<'EOF'
import XCTest
@testable import F1App
final class F1AppTests: XCTestCase { func testInit() { _ = F1App() } }
EOF
git add -A && git commit -q -m "F1 baseline"
```

**Expected Procedure 7 behavior (for evidence comparison).**
- **Form R (G7-discovery).** `xcodebuild -list` reports exactly one
  scheme (`F1App`); `xcrun simctl list devices available` returns
  ≥1 simulator. Form R reply default `yes`; PM chat may proceed.
- **Form E (G7-edit).** Proposes edits to
  `scripts/validate-swift.sh`, `scripts/test-swift.sh`,
  `scripts/format-swift.sh`, and `.claude/settings.json`'s `env`
  block setting `XCODE_SCHEME="F1App"` and a chosen
  `XCODE_DESTINATION`. JSON is parse-mutate-serialise (not regex).
- **Form I (G7-install).** Proposes `brew install swift-format` if
  not already installed; default `skip`.
- **Form M (G7-machine).** Lists four `cp` invocations under
  `~/Library/Developer/Xcode/CodingAssistant/`; default `skip`.

**Capture for §4.1 evidence block.** Form R verbatim output; Form E
proposed diff (verbatim); Form I tool list; Form M
companion-files-batch list; pass/fail; deviations.

**Pre-built paste file (implementer adds this step).** After fixture
construction, pre-fill placeholders so the developer never edits
the paste text by hand:

```bash
awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' \
    "$PACK/project-template/docs/pack/prompts/pm-chat.md" \
  | sed '$d' \
  | sed \
      -e 's/\[PROJECT_NAME\]/F1 Smoke Test/g' \
      -e 's/\[2-3 sentence description of what the project is and does\]/Phase 4 verification fixture (F1) — SPM single-scheme baseline; no real project./g' \
      -e 's|\[e\.g\., macOS 15+, Xcode 26\.3, Swift 6 / Python 3\.12+\]|macOS 15+, Xcode 26.3, Swift 6|g' \
      -e 's/Phase \[N\] — \[Phase title\] (\[not started \/ in progress\])/Phase 0 — Smoke (not started)/g' \
      -e 's/\[Architecture pattern, e\.g\., MVVM with layered domain\/data\/presentation\]/MVVM with layered domain\/data\/presentation/g' \
      -e 's/\[Key protocol decisions, e\.g\., DataStore protocol over SwiftData\]/none for smoke/g' \
      -e 's/\[Any other settled decisions\]/none for smoke/g' \
  > /tmp/phase-4-fixtures/kickoff-paste-F1.txt
wc -l /tmp/phase-4-fixtures/kickoff-paste-F1.txt
# Confirm no remaining bracketed placeholders:
grep -nE '\[[^]]+\]' /tmp/phase-4-fixtures/kickoff-paste-F1.txt | head -5
# Expect: zero matches in the project-context block (some [BRACKETED] text
# elsewhere in the variant body is fine — those are kickoff prose, not fields).
```

**Cleanup.** `rm -rf /tmp/phase-4-fixtures/apple-spm-single-scheme`
(safe to run after §4.1 F1 evidence capture is recorded; no cross-
section dependency under hybrid scope per §0.6 / §0.7).

#### 3.2.2 F2 — `apple-multi-scheme`

**Exercises.** Ambiguous scheme list; Form R presents choices.

```bash
F2=/tmp/phase-4-fixtures/apple-multi-scheme
rm -rf "$F2"
mkdir -p "$F2"
cd "$F2"
git init -q
"$PACK/scripts/init-project.sh" .

cat > Package.swift <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "F2",
    products: [
        .library(name: "F2Core", targets: ["F2Core"]),
        .executable(name: "F2CLI", targets: ["F2CLI"]),
    ],
    targets: [
        .target(name: "F2Core", path: "Sources/F2Core"),
        .executableTarget(name: "F2CLI", dependencies: ["F2Core"], path: "Sources/F2CLI"),
    ]
)
EOF
mkdir -p Sources/F2Core Sources/F2CLI
echo 'public struct F2Core { public init() {} }' > Sources/F2Core/F2Core.swift
echo 'import F2Core; @main struct F2CLI { static func main() { _ = F2Core() } }' > Sources/F2CLI/main.swift
git add -A && git commit -q -m "F2 baseline"
```

**Expected Procedure 7 behavior.** Form R lists ≥2 schemes
(`F2Core`, `F2CLI`); reply grammar (Procedure 7 §7.5) accepts
"bare scheme name" — PM chat re-prompts the developer to pick one.
Form E does not propose edits until a scheme is chosen.

**Capture.** Form R verbatim output (must show ≥2 schemes); the
re-prompt text the PM chat emits; the developer's reply (a chosen
scheme name); Form E diff after disambiguation.

**Cleanup.** `rm -rf /tmp/phase-4-fixtures/apple-multi-scheme`.

#### 3.2.3 F3 — `apple-no-simulator`

**Exercises.** `simctl list devices available` returns empty; Form R
reports no destination; G7-discovery declines.

```bash
F3=/tmp/phase-4-fixtures/apple-no-simulator
rm -rf "$F3"
mkdir -p "$F3"
cd "$F3"
git init -q
"$PACK/scripts/init-project.sh" .

# Same minimal Package.swift as F1, different name.
cat > Package.swift <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(name: "F3App", products: [.library(name: "F3App", targets: ["F3App"])],
    targets: [.target(name: "F3App", path: "Sources/F3App")])
EOF
mkdir -p Sources/F3App
echo 'public struct F3App {}' > Sources/F3App/F3App.swift
git add -A && git commit -q -m "F3 baseline"
```

**Simulating "no simulator available" — PATH-based stub (per §0.6
gap-#4 decision).** This Mac genuinely has simulators installed, so
the empty-list condition cannot be reproduced naturally. We simulate
by placing a fake `xcrun` script earlier on `$PATH` than the real one,
**only for the F3 test session**. The agent's invocation of `xcrun`
genuinely runs (subprocess + exit code + stdout); the stub answers
the simulator-list query with empty output and passthrough-execs all
other `xcrun` invocations to the real binary. Procedure 7 sees real
empty output — no chat-side fakery.

```bash
# F3 fixture-local stub bin dir (CLEAN UP via R10-14 in Part 10).
F3_BIN=/tmp/phase-4-fixtures/F3-bin
mkdir -p "$F3_BIN"
cat > "$F3_BIN/xcrun" <<'STUB'
#!/usr/bin/env bash
# Test stub for F3 — simulates a Mac with no Xcode simulators installed.
# Active only when this directory is prepended to PATH.
if [[ "$1 $2 $3" == "simctl list devices available" ]]; then
  echo "== Devices =="
  exit 0
fi
exec /usr/bin/xcrun "$@"   # passthrough for any other xcrun call
STUB
chmod +x "$F3_BIN/xcrun"
which xcrun                       # before stub: /usr/bin/xcrun
export PATH="$F3_BIN:$PATH"
which xcrun                       # after stub:  $F3_BIN/xcrun
xcrun simctl list devices available    # quick sanity: prints "== Devices =="
xcrun --version                       # passthrough sanity: real version output
```

The developer then opens `claude` in `$F3` (the F3 fixture dir) **with
this same shell environment** so the stub PATH is inherited. After the
F3 capture is complete, the stub is removed and PATH restored:

```bash
# After F3 capture — restore PATH and remove stub.
PATH="${PATH#$F3_BIN:}"
which xcrun                       # back to /usr/bin/xcrun
rm -rf "$F3_BIN"
ls -ld "$F3_BIN" 2>&1              # expect: No such file or directory
```

**Expected Procedure 7 behavior.** `xcrun simctl list devices
available` returns the stub's empty output. Form R reports no
destinations. Procedure 7 §7.4 row 4 ("No simulators available")
fires — the assistant declines to compose Form E (cannot fill
`XCODE_DESTINATION` without a destination), proposes `platform=macOS`
only if `[PLATFORM_TARGETS]` includes macOS, otherwise reports the gap
and waits for developer input. G7-discovery yields a "no path
forward" report.

**Capture.** Form R output (verbatim — should show the stub's empty
output); the assistant's §7.4 row-4 behavior text; pass/fail; PATH
restoration confirmation.

**Cleanup.** Two operations (both required, see Part 10 R10-4 + R10-14):

```bash
rm -rf /tmp/phase-4-fixtures/apple-no-simulator
rm -rf /tmp/phase-4-fixtures/F3-bin
```

#### 3.2.4 F4 — `apple-non-spm-layout`

**Exercises.** Non-SPM layout; Form M skips on absence of expected SPM
markers.

```bash
F4=/tmp/phase-4-fixtures/apple-non-spm-layout
rm -rf "$F4"
mkdir -p "$F4"
cd "$F4"
git init -q
"$PACK/scripts/init-project.sh" .

# Stub Xcode-style project — NO Package.swift, NO Sources/.
mkdir -p F4App F4AppTests F4App.xcodeproj
cat > F4App/F4App.swift <<'EOF'
import Foundation
struct F4App {}
EOF
cat > F4AppTests/F4AppTests.swift <<'EOF'
import XCTest
final class F4AppTests: XCTestCase { func testNoOp() {} }
EOF
# Stub xcodeproj sentinel so the directory is recognisable as Xcode-shaped.
touch F4App.xcodeproj/project.pbxproj
git add -A && git commit -q -m "F4 baseline"
```

**Expected Procedure 7 behavior.** Form R discovery still runs (Apple
side). Form E proposes `SWIFT_SOURCE_DIRS="F4App F4AppTests"` in
`scripts/format-swift.sh` (the non-SPM branch documented in
SETUP-NEW.md § 5.A). Form M (companion files) defaults to `skip` per
§7.4 row 8 ("Source layout indeterminate" → conservative).

**Capture.** Form R output; Form E
`SWIFT_SOURCE_DIRS=` proposal verbatim; Form M skip behavior.

**Cleanup.** `rm -rf /tmp/phase-4-fixtures/apple-non-spm-layout`.

#### 3.2.5 F5 — `python-grpc-server`

**Exercises.** Python + gRPC; Form I includes `grpcio-tools`.

```bash
F5=/tmp/phase-4-fixtures/python-grpc-server
rm -rf "$F5"
mkdir -p "$F5"
cd "$F5"
git init -q
"$PACK/scripts/init-project.sh" .

# Minimal Python + gRPC fixture.
cat > pyproject.toml <<'EOF'
[project]
name = "f5"
version = "0.0.1"
requires-python = ">=3.11"
dependencies = []
EOF
mkdir -p proto/f5/v1 server
cat > proto/f5/v1/echo.proto <<'EOF'
syntax = "proto3";
package f5.v1;
service Echo { rpc Say (EchoRequest) returns (EchoReply); }
message EchoRequest { string text = 1; }
message EchoReply   { string text = 1; }
EOF
cat > server/main.py <<'EOF'
def main() -> None:
    pass
if __name__ == "__main__":
    main()
EOF
git add -A && git commit -q -m "F5 baseline"
```

**Expected Procedure 7 behavior.** Form R Python lines (8–9 of the
discovery enum) detect `pyproject.toml` + `proto/`. K3 sub-flow fires.
§7.3.1 Form I proposes `brew install bufbuild/buf/buf swift-protobuf
grpc-swift` only if `[PLATFORM_TARGETS]` includes Apple targets;
otherwise skipped. §7.3.2 Form I proposes `uv add grpcio-tools grpcio
grpcio-status grpcio-reflection`.

**Capture.** Form R (Python + gRPC lines visible); §7.3.1 Form I
behavior; §7.3.2 Form I quadruplet verbatim.

**Cleanup.** `rm -rf /tmp/phase-4-fixtures/python-grpc-server`.

#### 3.2.6 F6 — `python-only`

**Exercises.** Python without gRPC; Form I skips proto deps.

```bash
F6=/tmp/phase-4-fixtures/python-only
rm -rf "$F6"
mkdir -p "$F6"
cd "$F6"
git init -q
"$PACK/scripts/init-project.sh" .

cat > pyproject.toml <<'EOF'
[project]
name = "f6"
version = "0.0.1"
requires-python = ">=3.11"
dependencies = []
EOF
mkdir -p src/f6
cat > src/f6/__init__.py <<'EOF'
def hello() -> str: return "f6"
EOF
git add -A && git commit -q -m "F6 baseline"
```

**Expected Procedure 7 behavior.** Form R detects `pyproject.toml`
but no `proto/` dir; K3 sub-flow does **not** fire. §7.3.1 / §7.3.2
Form I are not rendered. §7.2.* Apple sub-flow does not fire (no
`[PLATFORM_TARGETS]` Apple value).

**Capture.** Form R output (showing no `proto/`); confirmation that
Form I for gRPC is **not** emitted; pass/fail.

**Cleanup.** `rm -rf /tmp/phase-4-fixtures/python-only`.

### 3.3 Per-fixture run procedure (Claude Code CLI, the canonical surface)

The per-fixture run is a **manual step executed by the developer** in
a separate `claude` session. Explicit step-by-step instructions for
the developer live in **Part 13 — M1** (and M3..M7 for F2..F6 under
hybrid expansion). This section focuses on the implementer-side
preconditions and the rationale behind the runbook's reply choices.

**Implementer-side preconditions.** Before reporting "ready for M1"
to the developer, this CLI session must:

1. Have built the F1 fixture per §3.2.1 (or the relevant Fn per §3.2.x).
2. Have generated the placeholder-filled paste file per §3.2.x's
   "Pre-built paste file" sub-step (e.g., `kickoff-paste-F1.txt`).
3. Have confirmed `claude` is on the developer's PATH and the fixture
   path exists.
4. Have not yet started any other manual step that would conflict
   (see Part 9 ordering / parallelization).

**Why the developer replies `skip` rather than `yes` on Form E / I /
M.** The fixture is ephemeral; persisting Form E edits to it adds
nothing to the evidence record (we already capture the proposed diff
verbatim). Skipping preserves the fixture's baseline state — useful
if the developer needs to re-run the same fixture under hybrid
expansion or post-defect retest. Form I `yes` would actually `brew
install`; Form M `yes` would write to `~/Library/Developer/Xcode/`
machine-level. Both are real side effects we don't want in a smoke
test.

### 3.4 §4.1 evidence-block shape (per fixture)

Use the §8 unified template. Each fixture row in
`V10-PHASE-4-VERIFICATION.md` §4.1 has these fields populated:

- Timestamp (UTC, `date -u +%FT%TZ`)
- Surface (e.g., `Claude Code CLI v<output of claude --version>`)
- Fixture name (e.g., `F1 apple-spm-single-scheme`)
- Construction commands run (the §3.2.x block, abbreviated to the
  command list — not re-pasted in full)
- Form R output (verbatim, fenced)
- Form E proposed diff (verbatim, fenced)
- Form I proposed installs (verbatim, fenced)
- Form M proposed companion-files batch (verbatim, fenced)
- Pass / fail
- Deviations vs §3.2.x "Expected Procedure 7 behavior"
- Cleanup confirmation: `rm -rf` exit 0 + `ls -ld
  /tmp/phase-4-fixtures/<name>` returning "No such file" for the
  cleanup audit.

### 3.5 §4.1 failure-mode actions

| If… | Action |
|---|---|
| Form R produces no output (e.g., `xcodebuild` errors out on F4) | Capture the error verbatim; record as deviation; proceed — Procedure 7 §7.4 row 1/8 is the design behavior. |
| Form E produces a regex-style edit to `.claude/settings.json` (forbidden by Procedure 7 §7.2.2) | **Defect.** Flag-back F-G (defect in Procedure 7 wording). Stop §4.1; do not run remaining fixtures until resolved. |
| Form M proposes destructive overwrite without `cmp -s` byte-identity check | **Defect.** F-G. Stop §4.1. |
| Procedure 7 cannot be reached (e.g., kickoff variant breaks before pointer) | **Defect.** F-G mapped to Phase 3-B retrofit. Stop §4.1. |
| Fixture construction step fails (e.g., `init-project.sh` errors) | **Defect** in `init-project.sh` — flag-back F-G (init-project.sh is core infrastructure). Stop §4.1. |
| Surface-side claude/codex/gemini transient (network blip, rate limit) | Retry once. If second attempt fails, move on to the next fixture and note as "deferred — surface transient" (NOT F-B). Re-attempt at end of §4.1. |

### 3.6 §4.1 ordering

Run F1 → F2 → F3 → F4 → F5 → F6. Rationale: F1 is the happy path —
landing F1 first verifies the kickoff → Procedure 7 chain works at all
before exercising the corner cases. F3 (no-simulator) is mid-list
because it requires the manual-stub trick from §3.2.3, which is easier
to apply confidently after F1/F2 have established baseline behavior.

---

## Part 4 — §4.2 Cross-surface docs-research pass (replaces live runs per §0.6)

**Goal of §4.2 (revised under §0.6).** Identify, by close reading of
pack documentation and architectural reasoning, where Codex CLI /
Gemini CLI / Desktop Commander would deviate from the Claude Code CLI
behavior captured in §4.1 — so that any surface-specific defect is
documented for v10.1 follow-up rather than discovered in production.

**Why this replaces live runs.** Project-lead direction (§0.6): live
runs across three additional surfaces multiply test effort without
proportionate yield, given that the Procedure 7 abstraction layer is
designed to be surface-agnostic and the surface-specific behaviors
(Codex sandbox model, Gemini plan-mode handling, Desktop Commander
filesystem-MCP semantics) are documented. The docs-research pass
catches deviations the docs already imply; any deviation the docs do
NOT imply is by definition a v10.1-discoverable defect.

**Reference reading (mandatory before writing the §4.2 evidence
block).**

- `V10-PHASE-3B-DESIGN-v2.md` Part 11 (surface matrix) — the canonical
  per-surface behavior expectations.
- `project-template/docs/pack/prompts/pm-chat.md` lines 23–48 —
  surface-declaration block + plan-mode warning.
- `project-template/docs/pack/PM-CHAT.md` line 124 — RAG-vs-direct-read
  access pattern.
- `supporting-docs/METHODOLOGY.md` Procedure 7 §7.0–§7.7 — the
  procedure each surface executes.
- `maintenance-docs/V10-DESIGN.md` AD-N rows that reference cross-tool
  parity (search for "Codex", "Gemini", "Desktop").
- `maintenance-docs/TOOL-COMPARISON.md` — cross-tool capability
  reference.

### 4.1 Per-surface deviation analysis (one section per surface)

For each of the three deferred surfaces, the §4.2 evidence block
contains a deviation-analysis row covering five dimensions:

| Dimension | What to assess |
|---|---|
| **Surface declaration** | Will pm-chat.md's "Confirm one of: shell / manual" Q/A correctly classify this surface as shell-capable per its own `shell` bullet (lines 44–45)? Cite supporting docs. |
| **Plan-mode handling** | Does the surface have an equivalent of Gemini's plan mode that prevents shell execution? If yes, does pm-chat.md line 24 cover it adequately? |
| **Tool / shell sandbox** | Can the surface actually shell out (real subprocess)? Where is this documented? For sandboxed surfaces (Codex), what's the escalation pattern when a command needs higher privilege than the sandbox grants (e.g., `brew install`)? |
| **METHODOLOGY.md access** | Does the surface read METHODOLOGY.md directly (full procedure body) or via RAG (chunked)? Procedure 7 is order-sensitive; does the surface honor that? |
| **Form R/I/E/M rendering** | Is there any surface-specific rendering quirk (markdown rendering, tool-call wrapping, fence preservation) that would make Forms display incorrectly? |

For each dimension, the analyst notes:
- **Per-docs expected behavior** (cite source line).
- **Risk identified** (none / low / medium / high).
- **v10.1 follow-up flag** (yes / no — and the BACKLOG candidate text
  if yes).

### 4.2 Surfaces in scope (docs-research pass)

| ID | Surface | Authoritative docs | Live run status |
|---|---|---|---|
| DR1 | Codex CLI | `pm-chat.md` line 44 (`shell`-capable enumeration); `METHODOLOGY.md` Phase routing table; `TOOL-COMPARISON.md`; `V10-DESIGN.md` AD-1 cross-tool parity decision; Codex CLI public docs (workspace-write sandbox model) | Deferred to v10.1 per §0.6 |
| DR2 | Gemini CLI | `pm-chat.md` line 24 (plan-mode warning) + line 44 (shell-capable enumeration); `V10-DESIGN.md` BD-043 (Gemini native subagent architecture); `agent-run.sh` translation logic; Gemini CLI public docs | Deferred to v10.1 per §0.6 |
| DR3 | Desktop Commander | `pm-chat.md` line 44–45 ("Claude Desktop with Desktop Commander enabled"); `TOOL-COMPARISON.md`; filesystem-MCP capability docs; Procedure 7 §7.2.4 (machine-level Form M) | Deferred to v10.1 per §0.6 |

If any surface happens to be present in the implementer environment
(see §1.3 optional surfaces), record its presence in the §4.2 evidence
block but **do not opportunistically run a live test** — the scope
decision is "docs research only" and silent expansion is F-E (Phase 4
Plan flag-back).

### 4.3 §4.2 evidence-block shape (per deferred surface)

Use the §8 unified template, with deviation-analysis fields specific
to the docs-research pass. One row per surface (DR1 Codex, DR2 Gemini,
DR3 Desktop Commander). Fields:

- Timestamp
- Surface name (DR1 / DR2 / DR3)
- Reference docs cited (file paths + line numbers — every claim must
  cite a source)
- Per-dimension deviation analysis (table from §4.1, five rows)
- Risk summary (overall: low / medium / high)
- v10.1 follow-up flags (zero or more; each names a BACKLOG candidate
  with title + one-line description)
- Verbatim §1.4 deferred-status wording at the end of the row
- Note: this section emits **no live-run evidence** — that is the
  intended scope per §0.6.

### 4.4 §4.2 ordering

DR1 (Codex) → DR2 (Gemini) → DR3 (Desktop Commander). Rationale:
Codex's sandbox model is the most architecturally distinct from the
Claude Code CLI baseline, so its deviation analysis surfaces the most
likely v10.1 candidates first. Gemini's main risk is plan-mode
behavior (already documented in pm-chat.md). Desktop Commander is the
most surface-similar to Claude Code CLI of the three (same model,
different UI shell), so its analysis is shortest.

### 4.5 §4.2 fixture cleanup

The docs-research pass uses no fixtures. Nothing to clean up at the
end of §4.2. (Live-run procedures from earlier plan revisions used
F1 across all three surfaces; that approach is superseded by §0.6.)

---

## Part 5 — §4.3 Claude Web manual-mode smoke runbook

**Goal of §4.3.** Demonstrate that on a non-shell surface (Claude Web,
no Desktop Commander, no MCP), pasting the kickoff variant and
replying `manual` produces ONLY the `pm-chat.md` continuation pointer
naming `SETUP-NEW.md § Manual fallback` sub-sections 5.A–5.D — no tool
call, no inline command summary.

**Reference spec.** `V10-PHASE-3B-PLAN-v2.md` Part 7 criterion 8;
`V10-PHASE-3B-DESIGN-v2.md` Part 3 row 15 (pointer-only shape);
`V10-PHASE-3B-PLAN-v2.md` §3.3 (verbatim pointer wording).

### 5.1 Runner

**Developer in browser** at `claude.ai`. New chat. **No** project /
**no** GitHub connector / **no** Desktop Commander. The chat must be
unambiguously non-shell — that's the whole point of §4.3.

### 5.2 Paste content (implementer builds the paste file)

The implementer (this CLI session) pre-builds a placeholder-filled
paste file at a known path so the developer never edits the paste
text by hand:

```bash
awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' \
    "$PACK/project-template/docs/pack/prompts/pm-chat.md" \
  | sed '$d' \
  | sed \
      -e 's/\[PROJECT_NAME\]/Phase 4 Web Smoke Test/g' \
      -e 's/\[2-3 sentence description of what the project is and does\]/Phase 4 Claude Web manual-mode smoke; no real project, no shell, browser-only./g' \
      -e 's|\[e\.g\., macOS 15+, Xcode 26\.3, Swift 6 / Python 3\.12+\]|macOS 15+, Xcode 26.3, Swift 6|g' \
      -e 's/Phase \[N\] — \[Phase title\] (\[not started \/ in progress\])/Phase 0 — Smoke (not started)/g' \
      -e 's/\[Architecture pattern, e\.g\., MVVM with layered domain\/data\/presentation\]/MVVM/g' \
      -e 's/\[Key protocol decisions, e\.g\., DataStore protocol over SwiftData\]/none for smoke/g' \
      -e 's/\[Any other settled decisions\]/none for smoke/g' \
  > /tmp/phase-4-fixtures/kickoff-paste-W3.txt
wc -l /tmp/phase-4-fixtures/kickoff-paste-W3.txt
# Expected: ~72 lines (variant body + pointer; the trailing
# `## Variant: backlog-status-update` line is stripped by sed '$d').
```

The developer never edits the paste file — they `cat` it (or `pbcopy
< file`) and paste into the Claude Web chat verbatim.

### 5.3 Run procedure

The §4.3 run is a **manual step executed by the developer** in a
browser session. Explicit step-by-step instructions for the developer
live in **Part 13 — M2**.

**Implementer-side preconditions.** Before reporting "ready for M2"
to the developer, this CLI session must:

1. Have generated the placeholder-filled web paste file per §5.2
   (`/tmp/phase-4-fixtures/kickoff-paste-W3.txt`).
2. Have run the §6.6 OQ-VP4-6 confirmation (no network needed for
   M2 — the file is local; just confirm the file exists and is
   the right size, ~70 lines).

The developer's manual sequence is in Part 13 — M2 (steps 1–10).
This section is the implementer's reference for what M2 covers and
how it's verified.

### 5.4 Expected assistant reply (pass criterion)

The assistant's reply must contain the verbatim continuation pointer's
`manual` branch from `pm-chat.md` lines 87–89:

> **On `manual`: I will point you at `supporting-docs/SETUP-NEW.md` §
> Manual fallback (sub-sections 5.A–5.D) and wait for you to report
> values back, then compose the corresponding edits for you to apply.**

**Pass.** The reply names `SETUP-NEW.md § Manual fallback` and the
`5.A–5.D` sub-section range and waits for the developer to report
values. No tool call. No inline `xcodebuild -list` /
`brew install` / `cp ...` command summary.

**Soft pass.** The reply paraphrases the pointer (e.g., "I'll point
you at SETUP-NEW.md's manual fallback section"), but the reference is
unambiguous and lacks tool calls / command summaries. Capture as soft
pass with a note; flag-back F-E if the project lead wants the wording
tightened to verbatim.

**Fail.** Any of:

- The reply contains a tool-call attempt (e.g., `<tool_use>` or
  similar) → defect; pm-chat.md kickoff variant has a defect or the
  surface-declaration prompt is being mis-classified by the model.
  **Flag-back F-G** mapped to Phase 3-B retrofit.
- The reply contains an inline command summary (e.g., a fenced shell
  block with `xcodebuild -list` etc.) → defect; pointer wording is
  wrong (the §3.3 contract is "pointer only, not summary").
  **Flag-back F-G** mapped to Phase 3-B retrofit.
- The reply names `SETUP-NEW.md` Steps 5–8 (the OLD step numbers,
  pre-Phase-3-B) instead of `Manual fallback 5.A–5.D` → **defect**;
  pm-chat.md continuation pointer was not updated. F-G.

### 5.5 Capture format

```
| Field | Value |
|---|---|
| Timestamp | <UTC> |
| Surface | Claude Web (no MCP, no project) |
| Paste source | $PACK/project-template/docs/pack/prompts/pm-chat.md (kickoff variant body, ~72 lines) |
| Reply text | `manual` |
| Assistant reply | <verbatim, fenced> |
| Outcome | pass / soft pass / fail |
| Notes | <deviation if any> |
```

### 5.6 §4.3 dependencies

§4.3 depends on **nothing** in §4.1 / §4.2 / §4.4 / §4.5. Run any
time after Part 1 pre-flight passes. See Part 9 — §4.3 is the
canonical parallelization candidate.

---

## Part 6 — §4.4 Migration script smoke runbook

**Goal of §4.4.** Demonstrate that `scripts/migrate-v9-to-v10.sh`
successfully migrates a representative v9.3 project to the v10 layout
without manual intervention beyond the script's interactive prompts,
and that the post-migration state matches `V10-DESIGN.md` Part 6
§6.10.

**Reference spec.** `V10-PHASE-4-PLAN.md` §4.4;
`V10-DESIGN.md` Part 6;
`supporting-docs/MIGRATION-v9-to-v10.md` (user-facing migration guide).

### 6.1 Critical guardrail

**No git command in this section targets the live pack repo.** The
v9.3 fixture project is constructed entirely under `/tmp/phase-4-
fixtures/v9-project/`. The v9.3-pack-source clone lives at
`/tmp/v9-pack-source/`. Both are independent of the live main pack
worktree at `/Users/david/Developer/dhs-ai-agent-config-pack` and the
v10-dev worktree at `$PACK`. Verify before running each step that the
working directory is `/tmp/phase-4-fixtures/v9-project/` — `pwd`
**must** start with `/tmp/phase-4-fixtures/`.

### 6.2 Prerequisites

- Part 1 pre-flight passed.
- `$PACK` set to the v10-dev worktree.
- v9.3 tag resolvable: `git -C "$PACK" rev-parse v9.3` succeeds.
- `python3` on `$PATH` (used by `merge-platform-skills.py`,
  `validate-pack.py`).

### 6.3 Step 1 — clone the v9.3 pack source (LOCAL clone, no network)

Per §0.6 (OQ-VP4-6 resolution): the pack repo is private on GitHub, so
HTTPS clone would require auth. We sidestep entirely by cloning from
the **local** pack repo at `/Users/david/Developer/dhs-ai-agent-
config-pack`, which already has the v9.3 tag in its history. This is
faster (git uses hard-link optimization for local clones) and uses no
network egress.

```bash
# v9.3 pack source — local clone from live pack repo.
LIVE_PACK=/Users/david/Developer/dhs-ai-agent-config-pack
git -C "$LIVE_PACK" rev-parse v9.3 >/dev/null \
  || { echo "FAIL: v9.3 not in live pack repo"; exit 1; }

rm -rf /tmp/v9-pack-source
git clone --branch v9.3 --depth 1 \
  "$LIVE_PACK" \
  /tmp/v9-pack-source

git -C /tmp/v9-pack-source describe --tags --exact-match HEAD   # expect: v9.3
ls -la /tmp/v9-pack-source/project-template | head -20
```

**Expected.** Clone succeeds (a few seconds, no network); `git
describe` returns `v9.3`; `project-template/` contains the v9.3 layout
(`.claude/agents/`, `docs/pack/PROMPT-TEMPLATES.md`, etc. — the v9.3
baseline invariants the migration script's S0 stage checks for at
lines 130–139 of `scripts/migrate-v9-to-v10.sh`).

**Guardrail.** The local clone creates a fresh repo at
`/tmp/v9-pack-source/` with its own `.git/` directory. Operations on
that clone (or on the v9-project fixture migrated from it) **never**
push to a remote and **never** modify the live pack repo. The live
pack repo is read-only for the duration of §4.4.

### 6.4 Step 2 — construct a minimal v9.3 fixture project

The fixture must be **real enough** that `migrate-v9-to-v10.sh`
exercises the splice / replace / merge paths meaningfully, but **small
enough** that diff inspection is tractable.

```bash
F9=/tmp/phase-4-fixtures/v9-project
rm -rf "$F9"
mkdir -p "$F9"
cd "$F9"
git init -q

# Copy the v9.3 project-template into the fixture.
cp -R /tmp/v9-pack-source/project-template/. .

# Trinity placeholder fill — minimal substitutions.
# `[PROJECT_NAME]` and `[PLATFORM_TARGETS]` are present in CLAUDE.md / AGENTS.md / GEMINI.md.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
  [[ -f "$f" ]] && sed -i.bak \
    -e 's/\[PROJECT_NAME\]/PhaseFourSmokeProject/g' \
    -e 's/\[PLATFORM_TARGETS\]/macOS 15+, Swift 6/g' \
    -e 's/\[TRANSPORT\]/(none)/g' \
    "$f" && rm -f "$f.bak"
done

# Active-skills line — fill so PLATFORM-SKILLS merge has something to reconcile.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
  [[ -f "$f" ]] && python3 -c "
import sys, pathlib
p = pathlib.Path('$f')
s = p.read_text()
s = s.replace(
    '**Active skills:** [PM chat writes this line during project kickoff',
    '**Active skills:** swift-best-practices, apple-architecture-core, macos-architecture\n[PM chat writes this line during project kickoff'
)
p.write_text(s)
"
done

# Minimal Swift source so any post-migration validation has substance.
cat > Package.swift <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "PhaseFourSmokeProject",
    products: [.library(name: "PhaseFourSmokeProject", targets: ["PhaseFourSmokeProject"])],
    targets: [.target(name: "PhaseFourSmokeProject", path: "Sources/PhaseFourSmokeProject")]
)
EOF
mkdir -p Sources/PhaseFourSmokeProject
echo 'public struct PhaseFourSmokeProject { public init() {} }' > Sources/PhaseFourSmokeProject/PhaseFourSmokeProject.swift

# Baseline commit — the migration script requires a clean working tree
# (S0 stage line 102 of migrate-v9-to-v10.sh).
git add -A
git commit -q -m "v9.3 baseline (Phase 4 smoke fixture)"

git status --porcelain   # expect: empty
git log --oneline        # expect: single commit "v9.3 baseline (Phase 4 smoke fixture)"
```

**Expected post-construction state.** Tree is clean; `.claude/agents/`
present; `.gemini/agents/` present (v9.3 carried BD-043);
`docs/pack/PROMPT-TEMPLATES.md` present; `docs/pack/PLATFORM-SKILLS.md`
present; trinity files have placeholder substitutions; one Swift
source. **Confirm before proceeding** — running migration against an
incomplete v9.3 baseline produces noise that's hard to distinguish
from script defects.

### 6.5 Step 3 — run the migration script

```bash
cd /tmp/phase-4-fixtures/v9-project   # MUST be /tmp/...; verify pwd
pwd | grep -q '^/tmp/phase-4-fixtures/v9-project$' || { echo "FAIL: wrong pwd"; exit 1; }

# Run with stdout + stderr captured to disjoint files for clean evidence.
"$PACK/scripts/migrate-v9-to-v10.sh" . \
  > /tmp/phase-4-fixtures/v9-migrate.stdout.txt \
  2> /tmp/phase-4-fixtures/v9-migrate.stderr.txt
echo "Migration exit: $?"
```

**Interactive prompts.** The script may prompt for the
"Resume / Start fresh / Abort" sentinel-cleanup question (S0 stage
line 76); since this is a fresh fixture the prompt should not fire.
If it does fire, type `f` (start fresh) — but this indicates a stale
backup directory that should not exist on a fresh fixture; flag-back
F-E for unexpected state.

**Expected.** Exit 0; stdout shows `S0 complete.` ... `S7 complete.`;
stderr empty or contains only the standard `find` warnings.

### 6.6 Step 4 — post-migration verification

```bash
cd /tmp/phase-4-fixtures/v9-project

# 4a. Working tree dirty (the script does NOT commit — see comment line 19 of script).
git status --porcelain | head -30
git diff --stat | tee /tmp/phase-4-fixtures/v9-migrate.diff-stat.txt

# 4b. v10 layout present.
[[ -d docs/pack/prompts ]]                         && echo "OK: docs/pack/prompts/"
[[ -f docs/pack/METHODOLOGY.md ]]                  && echo "OK: METHODOLOGY.md"
grep -q '^### Procedure 7' docs/pack/METHODOLOGY.md && echo "OK: Procedure 7 present" \
                                                    || echo "WARN: Procedure 7 missing — see §6.7 row 'Procedure 5-R note'"

# 4c. Trinity carries v10 layout.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
  grep -q 'docs/pack/' "$f" && echo "OK: $f references docs/pack/" || echo "FAIL: $f missing docs/pack/"
  grep -q 'Capabilities pattern\|capabilities pattern' "$f" && echo "OK: $f mentions capabilities pattern" || echo "WARN: $f missing capabilities pattern"
done

# 4d. Backup directory populated and gitignored.
[[ -d .pack-migration-backup/v9.3-to-v10.0 ]] && echo "OK: backup dir present"
ls .pack-migration-backup/v9.3-to-v10.0/ | head -10
grep -Fxq '.pack-migration-backup/' .gitignore && echo "OK: .gitignore entry present"

# 4e. PROMPT-TEMPLATES.md deleted (per V10-DESIGN Part 6).
[[ ! -f docs/pack/PROMPT-TEMPLATES.md ]] && echo "OK: PROMPT-TEMPLATES.md removed" || echo "FAIL: PROMPT-TEMPLATES.md still present"

# 4f. AF-001 parity — no references to validate.sh / test.sh / format.sh
# in the SETUP-derived files (the AF-001 ship-blocker fix's invariant).
grep -rnE '\b(validate|test|format)\.sh\b' docs/ scripts/ 2>/dev/null \
  | grep -v -- '-swift\.sh\|-python\.sh\|-proto\.sh\|wrappers detect' \
  | head -10
# Expect: only references to wrapper-detect prose and language-specific variants.

# 4g. validate-pack.py is a pack-repo-only check; running it against the
# project tree is NOT part of v10.0's project-level invariants.
# Per V10-PHASE-4-PLAN §4.4: "if it does not apply at the project level,
# skip with note." This plan calls SKIP and records the rationale.
echo "validate-pack.py: SKIPPED at project level — pack-repo-only check per V10-PHASE-4-PLAN §4.4."
```

### 6.7 Pass / fail criteria for §4.4

| Check | Pass | Fail behavior |
|---|---|---|
| Migration exit code | 0 | non-zero → F-G; v10.0 hold; defect in `migrate-v9-to-v10.sh`. |
| `docs/pack/prompts/` exists | yes | F-G; S4 stage failed. |
| `docs/pack/METHODOLOGY.md` exists | yes | F-G; S5 / S6 stage failed. |
| `docs/pack/METHODOLOGY.md` contains `### Procedure 7` | yes (post-Phase-3-B v10) | If missing: evaluate per `V10-PHASE-4-PLAN §4.4` failure-modes row 4 — Procedure 7 in the project copy is sourced from the v10 pack source, so it should land. If the migration somehow installs an older METHODOLOGY.md, F-G. |
| Trinity `docs/pack/` references | present | F-G; trinity splice failure (S5). |
| Capabilities-pattern wording in trinity | present | F-G; trinity splice / merge failed to land BD-045 content. |
| Backup directory present + gitignored | yes | F-G; S0 backup setup defective. |
| PROMPT-TEMPLATES.md absent post-migration | yes (V10-DESIGN §6) | F-G; deletion stage skipped. |
| AF-001 parity (no `validate.sh` / `test.sh` / `format.sh` outside wrapper-detect prose) | yes | F-G; the AF-001 fix did not propagate via migration — likely a script defect. |
| `validate-pack.py` at project level | skipped (per spec) | n/a — not a fail criterion. |
| **Procedure 5-R prompt note.** Script's stdout (per V10-DESIGN §6.10) emits a paste-ready PM-chat prompt that names the right files. | yes | If the prompt names files that do not exist post-migration → F-G. |

### 6.8 Step 5 — fixture cleanup

After §4.4 evidence is captured into
`V10-PHASE-4-VERIFICATION.md`, tear down the fixture and pack-source
clone:

```bash
cd /tmp                                              # leave the fixture
rm -rf /tmp/phase-4-fixtures/v9-project
rm -rf /tmp/v9-pack-source
ls -ld /tmp/phase-4-fixtures/v9-project /tmp/v9-pack-source 2>&1
# Expect: both "No such file or directory"
```

**Do not skip this cleanup** — `/tmp/v9-pack-source` is a full
pack-repo clone with its own `.git` directory (~5 MB+), and orphaning
it confuses any future `find /tmp -name '*.git' -type d` audit.

### 6.9 §4.4 evidence-block shape

Use the §8 unified template. Fields:

- Timestamp
- Surface (Bash on the implementer's Mac)
- Fixture: `/tmp/phase-4-fixtures/v9-project/` (constructed per §6.4)
- v9.3 source: `/tmp/v9-pack-source/` (cloned per §6.3)
- Migration command: `"$PACK/scripts/migrate-v9-to-v10.sh" .` from
  fixture root
- Migration exit code (verbatim)
- `git diff --stat` output (verbatim, fenced)
- §6.6 verification check results (each line of "OK:" / "FAIL:" /
  "WARN:" pasted verbatim)
- Procedure 5-R prompt from script stdout (verbatim, fenced — copied
  from `/tmp/phase-4-fixtures/v9-migrate.stdout.txt`)
- Pass / fail per §6.7 criteria
- Cleanup confirmation (§6.8)

### 6.10 §4.4 ordering and parallelism

§4.4 may run in parallel with §4.1 / §4.2 / §4.3 — it operates on a
disjoint fixture and uses no shared state. In practice, run §4.4 in
this CLI session while the developer runs §4.3 in the browser.

---

## Part 6.5 — §4.6 OT real-project migration smoke runbook

**Goal of §4.6.** Demonstrate that `scripts/migrate-v9-to-v10.sh`
successfully migrates a real, in-the-wild v9.3-shaped project (Optiquity
Trader, a clone of `/Users/david/Developer/OptiquityTrader/`) to the v10
layout, and that the post-migration state matches `V10-DESIGN.md` Part 6
§6.10 with the same shape as the §4.4 synthetic run — without writing to
the live OT repo and without leaking OT content into the evidence file.

**Reference spec.** `V10-PHASE-4-PLAN.md` §4.4 (the §4.6 evidence
requirement is a v2 superset of the §4.4 spec applied to a real
fixture); `V10-DESIGN.md` Part 6; `supporting-docs/MIGRATION-v9-to-v10.md`
(the user-facing migration guide); v2 §0.8.2 (hard OT-safety guardrails).

### 6.5.1 Critical guardrail — re-state inline

This runbook re-states v2 §0.8.2 verbatim because the implementer must
pause and read these guardrails again before executing any §4.6 step:

1. **No git command in this section targets the live OT repo at
   `/Users/david/Developer/OptiquityTrader/` for write.** Read-only
   commands (`git rev-parse`, `git status --porcelain`, `git
   rev-parse --abbrev-ref HEAD`) are explicitly allowed; every other
   git invocation MUST target the clone at
   `/tmp/phase-4-fixtures/ot-project/`. Verify before each step that
   the working directory is `/tmp/phase-4-fixtures/ot-project/` —
   `pwd` MUST start with `/tmp/phase-4-fixtures/`.
2. **No `git push` from the clone.** The migration script does not push
   (line-by-line audit of `scripts/migrate-v9-to-v10.sh` confirms zero
   `git push` invocations); this plan does not push.
3. **The clone is destroyed by §6.5 cleanup (after §4.7 / §4.8
   complete).** The migration branch `migration-v9-to-v10` and any
   migration commits live only inside the clone.
4. **OT content is NEVER reproduced in the evidence file.** §6.5.10
   below enumerates which evidence-block fields are OT-quoting-safe
   (pack-generated text only) versus structural-only.

### 6.5.2 Prerequisites (run once before §4.6 begins)

```bash
# Must already be exported from Part 1 pre-flight:
echo "PACK=$PACK"      # expect: /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
[[ -n "${PACK:-}" ]] || { echo "FAIL: re-run Part 1 pre-flight"; exit 1; }

# Live OT repo exists and is git-managed.
OT_LIVE=/Users/david/Developer/OptiquityTrader
[[ -d "$OT_LIVE/.git" ]] && echo "OK: OT live repo present" || { echo "FAIL: OT live repo missing or not git-managed"; exit 1; }

# §4.4 synthetic completed (its post-migration tree must still exist
# under /tmp/phase-4-fixtures/v9-project/ for §4.8 comparison).
[[ -d /tmp/phase-4-fixtures/v9-project ]] && echo "OK: §4.4 fixture present" || { echo "FAIL: §4.4 must complete first; v9-project missing"; exit 1; }

# Disk budget — ≥1 GB free under /tmp.
df -k /tmp | awk 'NR==2 { if ($4 < 1048576) { print "FAIL: <1 GB free under /tmp"; exit 1 } else { print "OK: ", $4, "KB free under /tmp" } }'

# /tmp/phase-4-fixtures/ot-project/ must NOT pre-exist (would mask a stale clone).
[[ ! -e /tmp/phase-4-fixtures/ot-project ]] && echo "OK: target clone path is clear" || { echo "FAIL: stale /tmp/phase-4-fixtures/ot-project — remove first"; exit 1; }
```

If any check fails, **do not proceed to §6.5.3.** Resolve first; if
unresolvable, flag-back F-B (surface unavailability — disk / OT
absence) or F-I (proposed; see Part 12 OQ-VP4-8) for OT-baseline
mismatch.

### 6.5.3 Step 1 — capture OT byte-identity baseline (read-only)

This is the byte-identity reference checked at §6.5.7 cleanup. Every
command in this step is read-only against the live OT repo.

```bash
OT_LIVE=/Users/david/Developer/OptiquityTrader

# Capture HEAD SHA, branch, and porcelain status into a baseline file.
{
  printf 'OT live-repo baseline (%s)\n' "$(date -u +%FT%TZ)"
  printf 'HEAD SHA: %s\n' "$(git -C "$OT_LIVE" rev-parse HEAD)"
  printf 'Branch:   %s\n' "$(git -C "$OT_LIVE" rev-parse --abbrev-ref HEAD)"
  printf 'Status (porcelain, line count): %s\n' "$(git -C "$OT_LIVE" status --porcelain | wc -l | tr -d ' ')"
  printf 'Status (porcelain, content):\n'
  git -C "$OT_LIVE" status --porcelain
  printf 'Tags listing OT carries (count): %s\n' "$(git -C "$OT_LIVE" tag --list | wc -l | tr -d ' ')"
  printf 'Remotes (names only):\n'
  git -C "$OT_LIVE" remote
} > /tmp/phase-4-fixtures/ot-baseline.txt

cat /tmp/phase-4-fixtures/ot-baseline.txt
```

**Pass criterion.** Baseline captured; status porcelain line-count is
0 (clean tree). If non-zero, OT has uncommitted local changes — flag
the developer (§4.6 cannot run cleanly against a dirty source repo
because the clone would inherit the uncommitted state, which then
confuses the evidence by mixing OT-side dirt with migration effects).
**Action on dirty OT:** abort §4.6 / §4.7 / §4.8; record as F-I
(proposed) deferral; project lead decides whether to wait for OT to
clean up or skip OT verification for v10.0.

### 6.5.4 Step 2 — clone OT to /tmp via --no-hardlinks

```bash
OT_LIVE=/Users/david/Developer/OptiquityTrader
OT_CLONE=/tmp/phase-4-fixtures/ot-project

git clone --no-hardlinks "$OT_LIVE" "$OT_CLONE"
# Note: --no-hardlinks ensures the clone is a fully independent copy of
# the object store. Without this flag, git uses hardlinks for local
# clones across the same filesystem, which share blobs with the live
# repo's .git/objects/. While the live repo's working tree is still
# untouched in either mode, --no-hardlinks gives the strictest
# byte-identity guarantee for cleanup verification.

git -C "$OT_CLONE" rev-parse HEAD          # expect: same SHA as ot-baseline.txt
git -C "$OT_CLONE" rev-parse --abbrev-ref HEAD  # expect: same branch as ot-baseline.txt
git -C "$OT_CLONE" status --porcelain      # expect: empty (clean)
```

**Pass criterion.** Clone HEAD matches baseline HEAD; clone is on
the same branch as live; clone working tree is clean.

**Concurrent live-repo check.** Re-run the live-repo read-only
baseline AFTER clone completes:

```bash
git -C "$OT_LIVE" rev-parse HEAD          # MUST match ot-baseline.txt
git -C "$OT_LIVE" status --porcelain      # MUST be empty
```

If either differs from the §6.5.3 baseline, **stop**. Something
modified the live repo between baseline-capture and clone-completion
(should not happen under correct guardrails). Record as F-I; do not
proceed.

### 6.5.5 Step 3 — confirm clone has v9.3 baseline invariants

The migration script's S0 stage (lines 130–139 of
`scripts/migrate-v9-to-v10.sh`) refuses to proceed unless the target
project carries:

- `docs/pack/PROMPT-TEMPLATES.md` present
- `.claude/agents/` directory with ≥16 pack agent files (non-x-prefixed `.md`)
- `.gemini/agents/` directory present (v9.3 BD-043)
- `docs/pack/PLATFORM-SKILLS.md` present
- Clean working tree

OT is documented as v9.3-shaped, but the implementer verifies
explicitly because a real project may have drifted (custom skills,
extra x-files, new directories) without losing v9.3 baseline status.

```bash
OT_CLONE=/tmp/phase-4-fixtures/ot-project
cd "$OT_CLONE"
pwd | grep -q '^/tmp/phase-4-fixtures/ot-project$' || { echo "FAIL: wrong pwd"; exit 1; }

# Baseline invariant checks (mirror the script's S0 logic).
[[ -f docs/pack/PROMPT-TEMPLATES.md ]]   && echo "OK: PROMPT-TEMPLATES.md"   || echo "FAIL: PROMPT-TEMPLATES.md absent"
[[ -d .claude/agents ]]                  && echo "OK: .claude/agents/"      || echo "FAIL: .claude/agents/ absent"
claude_count=$(find .claude/agents -mindepth 1 -maxdepth 1 -name "*.md" ! -name "x-*" | wc -l | tr -d ' ')
[[ "$claude_count" -ge 16 ]]             && echo "OK: $claude_count pack agents (≥16)" || echo "FAIL: only $claude_count pack agents (need ≥16)"
[[ -d .gemini/agents ]]                  && echo "OK: .gemini/agents/"      || echo "FAIL: .gemini/agents/ absent"
[[ -f docs/pack/PLATFORM-SKILLS.md ]]    && echo "OK: PLATFORM-SKILLS.md"   || echo "FAIL: PLATFORM-SKILLS.md absent"

# Custom-skill / x-file census (forensic — recorded in evidence as quantitative summary).
custom_skill_count=$(find .claude/skills -mindepth 1 -maxdepth 1 -type d -name "x-*" 2>/dev/null | wc -l | tr -d ' ')
x_file_count=$(find .claude/agents .gemini/agents .codex/agents -name "x-*" 2>/dev/null | wc -l | tr -d ' ')
echo "OT clone — custom-skill dirs: $custom_skill_count; x-files (across three tool dirs): $x_file_count"
```

**Pass criterion.** All invariants OK. The custom-skill / x-file
counts are recorded structurally in the §4.6 evidence (quantities
only, NOT names), useful for §4.8 comparison.

**Failure handling.** Any FAIL row → §4.6 cannot run. If FAIL is
"PROMPT-TEMPLATES.md absent" or "<16 pack agents", OT has drifted
from v9.3 baseline (perhaps to a partial v10 state, perhaps to a
non-pack state). Record as F-I (proposed) — project lead decides
whether to skip OT verification for v10.0 or wait for OT to be
re-aligned to v9.3.

### 6.5.6 Step 4 — run migration against the OT clone

```bash
OT_CLONE=/tmp/phase-4-fixtures/ot-project
cd "$OT_CLONE"
pwd | grep -q '^/tmp/phase-4-fixtures/ot-project$' || { echo "FAIL: wrong pwd"; exit 1; }

# Run with stdout + stderr captured to disjoint files.
"$PACK/scripts/migrate-v9-to-v10.sh" \
  > /tmp/phase-4-fixtures/ot-migrate.stdout.txt \
  2> /tmp/phase-4-fixtures/ot-migrate.stderr.txt
echo "Migration exit: $?"
```

**Note on the script's positional arg.** The §4.4 synthetic call
passes `.` as the positional arg; the OT call passes nothing because
the script (per `main "$@"` at line 463 + `pwd` at line 444) operates
on the current working directory regardless. Both forms are
equivalent. The §4.4 form is preserved in v1 verbatim; the §4.6 form
omits `.` for clarity. If the script's behavior differs between the
two forms, that is itself a defect — flag-back F-G.

**Interactive prompts.** Same as §6.5: the only interactive prompt
that may fire is the S0 sentinel-cleanup question if a stale
`.pack-migration-backup/` directory is somehow present in the OT
clone. On a fresh clone of a real OT repo this should NOT fire. If
it does fire, OT has a stale backup directory committed to its tree
or accidentally left in the working tree — record this in evidence
as a deviation, type `f` (start fresh) to proceed, and flag-back F-E
(silent scope deviation: OT carries pack-migration state that should
not be there).

**Expected.** Exit 0; stdout shows `S0 complete.` ... `S7 complete.`;
stderr empty or contains only standard `find` warnings. The script
will additionally:

- Create branch `migration-v9-to-v10` in the clone (the script's line
  111–112 logic). The clone now has this branch checked out — fine,
  the clone is ephemeral.
- Splice / replace files per V10-DESIGN §6 stages S1–S7.
- Write the post-migration report to
  `/tmp/phase-4-fixtures/ot-project/.pack-migration-backup/v9.3-to-v10.0/report.md`.

### 6.5.7 Step 5 — verify live OT repo unchanged (run IMMEDIATELY after migration completes)

This is the safety check that proves the migration touched only the
clone, not the live OT repo. It runs BEFORE the §6.5.8 post-migration
verification (because if the live repo was somehow touched, every
subsequent step is suspect).

```bash
OT_LIVE=/Users/david/Developer/OptiquityTrader

# Compare current live state against §6.5.3 baseline.
current_sha=$(git -C "$OT_LIVE" rev-parse HEAD)
baseline_sha=$(grep '^HEAD SHA: ' /tmp/phase-4-fixtures/ot-baseline.txt | awk '{print $3}')
[[ "$current_sha" == "$baseline_sha" ]] && echo "OK: OT HEAD SHA unchanged" || echo "FAIL: OT HEAD SHA differs ($current_sha vs $baseline_sha)"

current_branch=$(git -C "$OT_LIVE" rev-parse --abbrev-ref HEAD)
baseline_branch=$(grep '^Branch: ' /tmp/phase-4-fixtures/ot-baseline.txt | awk '{print $2}')
[[ "$current_branch" == "$baseline_branch" ]] && echo "OK: OT branch unchanged" || echo "FAIL: OT branch differs"

current_status=$(git -C "$OT_LIVE" status --porcelain | wc -l | tr -d ' ')
[[ "$current_status" == "0" ]] && echo "OK: OT working tree still clean" || echo "FAIL: OT working tree dirty ($current_status entries)"
```

**Pass criterion.** All three OK lines. **Any FAIL is a hard safety
violation** — stop everything, do not run §4.7 or §4.8, do not delete
the clone (preserve as forensic evidence), report to project lead
immediately, flag-back F-I (proposed; OT safety violation).

### 6.5.8 Step 6 — post-migration verification (OT-adapted)

Mirrors v1 §6.6 but adapted for OT realities. Each check is the same
shape; pass criteria are the same except where OT's complexity makes
strict equality with §4.4 synthetic implausible (e.g., OT may carry
custom skills that synthetic does not; OT's PROMPT-TEMPLATES.md may
have diverged from v9.3 baseline, triggering S6's "divergence
detected" branch).

```bash
cd /tmp/phase-4-fixtures/ot-project

# 6a. Working tree dirty (script does NOT commit).
git status --porcelain | wc -l | tee /tmp/phase-4-fixtures/ot-migrate.status-count.txt
git diff --stat | tee /tmp/phase-4-fixtures/ot-migrate.diff-stat.txt

# 6b. v10 layout present.
[[ -d docs/pack/prompts ]]                          && echo "OK: docs/pack/prompts/"
[[ -f docs/pack/METHODOLOGY.md ]] && echo "OK: METHODOLOGY.md present at docs/pack/"
grep -q '^### Procedure 7' docs/pack/METHODOLOGY.md 2>/dev/null && echo "OK: Procedure 7 present" \
                                                   || echo "WARN: Procedure 7 missing — see §6.7 row 'Procedure 5-R note'"

# 6c. Trinity carries v10 layout.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
  grep -q 'docs/pack/' "$f" 2>/dev/null && echo "OK: $f references docs/pack/" || echo "FAIL: $f missing docs/pack/"
  grep -qi 'capabilities pattern' "$f" 2>/dev/null && echo "OK: $f mentions capabilities pattern" || echo "WARN: $f missing capabilities pattern"
done

# 6d. Backup directory populated and gitignored.
[[ -d .pack-migration-backup/v9.3-to-v10.0 ]] && echo "OK: backup dir present"
ls .pack-migration-backup/v9.3-to-v10.0/ | wc -l | sed 's/^/  backup dir entry count: /'
grep -Fxq '.pack-migration-backup/' .gitignore 2>/dev/null && echo "OK: .gitignore entry present"

# 6e. PROMPT-TEMPLATES.md handled per S6 (deleted if undivergent; preserved as _v9-backup.md if divergent).
if [[ -f docs/pack/PROMPT-TEMPLATES.md ]]; then
  echo "FAIL: PROMPT-TEMPLATES.md still present at canonical path"
elif [[ -f docs/pack/prompts/_v9-backup.md ]]; then
  echo "OK: PROMPT-TEMPLATES.md preserved as _v9-backup.md (S6 divergence branch — Procedure 5-R will fire)"
else
  echo "OK: PROMPT-TEMPLATES.md removed (S6 no-divergence branch)"
fi

# 6f. AF-001 parity — same check as §6.6 §4.4.
grep -rnE '\b(validate|test|format)\.sh\b' docs/ scripts/ 2>/dev/null \
  | grep -v -- '-swift\.sh\|-python\.sh\|-proto\.sh\|wrappers detect' \
  | head -10

# 6g. Migration report exists.
[[ -f .pack-migration-backup/v9.3-to-v10.0/report.md ]] && echo "OK: report.md present"
wc -l .pack-migration-backup/v9.3-to-v10.0/report.md | sed 's/^/  report line count: /'

# 6h. validate-pack.py at project level — same SKIP rationale as §6.6.
echo "validate-pack.py: SKIPPED at project level — pack-repo-only check per V10-PHASE-4-PLAN §4.4."

# 6i. validate-pack.py against the OT clone (informational only — captured for §4.8 comparison).
# We run it knowing it will likely report not-applicable / skip; capture exit code for §4.8.
python3 "$PACK/scripts/validate-pack.py" --target . > /tmp/phase-4-fixtures/ot-vp.stdout.txt 2> /tmp/phase-4-fixtures/ot-vp.stderr.txt || true
echo "validate-pack.py exit (against OT clone, informational): $?"
# If validate-pack.py does NOT support --target or against-tree usage, the run will exit non-zero
# with usage error — that is acceptable; §4.8 captures the behavior, does not assert pass/fail.
```

### 6.5.9 Pass / fail criteria for §4.6

| Check | Pass | Fail behavior |
|---|---|---|
| §6.5.7 OT live-repo unchanged | All three OK | **F-I (proposed) hard safety violation; STOP.** |
| Migration exit code | 0 | non-zero → F-G; v10.0 hold; defect in `migrate-v9-to-v10.sh` exposed by OT realism. |
| `docs/pack/prompts/` exists | yes | F-G; S4 stage failed against OT. |
| docs/pack/METHODOLOGY.md present | yes | F-G; S5 / S6 stage failed against OT. |
| METHODOLOGY.md contains `### Procedure 7` | yes | If missing, evaluate per V10-PHASE-4-PLAN §4.4 row 4; F-G if installed METHODOLOGY.md is older than v10. |
| Trinity `docs/pack/` references | present | F-G; trinity splice failure (S5) against OT-shaped trinity. |
| Backup directory present + gitignored | yes | F-G; S0 backup setup defective. |
| PROMPT-TEMPLATES.md handled per S6 (either deleted or preserved as `_v9-backup.md`) | yes | If neither branch fired, F-G; S6 logic broken. |
| AF-001 parity | yes | F-G; AF-001 fix did not propagate via migration against OT. |
| Migration report present | yes | F-G; S7 stage failed. |
| `validate-pack.py` at project level | skipped (per spec) | n/a — not a fail criterion. |
| `validate-pack.py` against OT clone (informational) | exit code captured (any value); behavior recorded for §4.8 | n/a — informational only. |
| **Procedure 5-R prompt note.** Migration stdout (per V10-DESIGN §6.10) emits a paste-ready PM-chat prompt that names the right files. | yes | If the prompt names files that do not exist post-migration → F-G. |
| **OT-vs-synthetic divergence in pass behavior.** §6.5.7+§6.5.8 outcomes that pass on synthetic (§4.4) but fail on OT, OR vice versa, are by themselves NOT a fail — they are the §4.8 comparison's signal. They are flagged in §4.6 evidence with a "divergence flag" note for §4.8 to interpret. | n/a (§4.8 interprets) | n/a — not a §4.6 fail. |

### 6.5.10 §4.6 evidence-block shape (sanitized)

Use the §8 unified template with explicit per-field sanitization
guidance. Fields and their **OT-content safety classification**:

| Field | Sanitization rule |
|---|---|
| Timestamp | OK to populate verbatim — universal. |
| Surface | OK — "Bash on the implementer's Mac". |
| Fixture: clone path | OK — `/tmp/phase-4-fixtures/ot-project/` is a pack-managed path, not OT content. |
| Live OT path | OK — already a known reference to the live repo's location; does not reveal anything beyond the path itself. |
| OT live-repo baseline (§6.5.3 file) | OK — HEAD SHA, branch name, status line-count, tag count, remote names. Branch name is OT-derived but is a single token reasonably treated as identifier-only metadata, not source content. |
| §6.5.5 invariant-check output | OK — pack-defined invariants; the count fields (custom-skill-dir count, x-file count) are quantitative summaries, no names. |
| Migration command | OK — pack-generated. |
| Migration exit code | OK — single integer. |
| **Migration stdout** | OK — **pack-generated text by design.** The script's `say()` output is pack content, not OT content. Including the verbatim Procedure 5-R prompt is REQUIRED for §4.8 comparison. |
| Migration stderr | OK if empty / standard `find` warnings; if stderr contains OT file paths or content excerpts (e.g., a python merge script erroring on a real OT file), structurally summarize ("merge-platform-skills.py warned on N files in OT-side custom-skills section; not reproduced verbatim per sanitization rule"). |
| `git diff --stat` output | **STRUCTURAL SUMMARY ONLY.** This output names every changed file in the OT clone, which IS pack-managed paths in this case (the migration only touches pack files), so paths themselves are pack content. **However**, line-count deltas alongside file paths can imply OT content size for files that the migration spliced into existing OT trinity. Capture as: file-count by category (changed pack files / changed trinity files / new pack files / removed pack files) plus total +/- line summary. Do NOT paste the raw `git diff --stat`. |
| §6.5.8 verification check results | OK to paste verbatim each "OK:" / "WARN:" / "FAIL:" line — they reference pack paths and pack invariants only. |
| Backup-dir entry count + report.md line count | OK — quantitative. |
| **Procedure 5-R prompt from script stdout** | OK — **pack-generated text.** Quote verbatim from `/tmp/phase-4-fixtures/ot-migrate.stdout.txt`. This is REQUIRED for §4.8 comparison against §4.4 stdout. |
| Migration report (`.pack-migration-backup/v9.3-to-v10.0/report.md`) | **MIXED.** The report's headings, section labels, and rollback wording are pack-generated and quotable. Sections like "x- files preserved" enumerate OT file names — STRUCTURAL SUMMARY ONLY (count, not names). Sections like "Improperly-added files" likewise. Capture: report skeleton (pack-generated heading list) plus per-section element counts; do NOT paste verbatim. |
| Pass / fail per §6.5.9 | OK. |
| §6.5.7 cleanup verification (live OT unchanged) | OK — pack-defined check; exact OT HEAD SHA is metadata and matches §6.5.3 baseline. |
| Cleanup confirmation (§6.5.11) | OK to paste — pack paths only. |
| Notes / deviations | Author per-note: pack-generated deviations OK verbatim; OT-content deviations summarized structurally. |
| Failure-mode link | OK — references F-N IDs only. |

**Sanitization audit before commit.** Before staging the §4.6
evidence into `V10-PHASE-4-VERIFICATION.md`, the implementer runs:

```bash
# Search the §4.6 evidence block for OT-side identifiers that should not be present.
# Identifiers are caught structurally (OT module names, function names, doc bodies)
# by greppin for any OT-source path patterns the implementer can think of.
# Final guard: the implementer reads the §4.6 block end-to-end and confirms
# every quoted output is pack-generated.
```

If any OT content leaked into the evidence block, **revise the block
before commit**; this is not a flag-back, it is an
implementer-correctable sanitization slip.

### 6.5.11 Step 7 — DO NOT clean up yet

Per §0.8.1 / §6.6 prerequisite list, **§4.7 reuses the §4.6
post-migration OT clone**. After §6.5.8 evidence is captured, the
implementer:

1. Confirms `/tmp/phase-4-fixtures/ot-project/` is intact.
2. Runs no `rm -rf` against it.
3. Reports "ready for M-OT" to the developer (see Part 13 — M-OT).
4. Proceeds to §4.7 / §4.8 before any cleanup.

The OT-cleanup procedure (final teardown after §4.7 + §4.8 evidence
is captured) is in §6.7.7. R10-15 in Part 10 documents the rollback.

### 6.5.12 §4.6 failure-mode actions

| If… | Action |
|---|---|
| §6.5.2 / §6.5.3 pre-flight fails (OT absent, dirty, disk short) | F-B (surface unavailability) for OT-side; project lead decides whether to wait, repair, or skip OT verification for v10.0. Do NOT proceed. |
| §6.5.5 baseline-invariant check fails (OT not v9.3-shaped) | F-I (proposed) — OT-baseline mismatch. Project lead decides skip or wait. |
| §6.5.6 migration exit non-zero | F-G — migration script defect exposed by OT realism. v10.0 hold likely. STOP §4.7 / §4.8 until §4.6 re-runs cleanly post-fix. |
| §6.5.7 OT live-repo changed | F-I (proposed) — hard safety violation. Preserve clone as forensic evidence; do NOT delete; flag IMMEDIATELY. |
| §6.5.8 verification has any FAIL row | F-G — migration produced defective post-migration tree against OT. v10.0 hold candidate. |
| §6.5.8 has WARN rows but no FAIL | Soft pass; record deviations; proceed to §4.7 / §4.8 to gather full picture before deciding. |
| OT content accidentally leaked into evidence | Revise evidence block before commit. NOT a flag-back. |
| §6.5.6 Sentinel-cleanup prompt fires unexpectedly (stale .pack-migration-backup) | F-E (silent scope deviation: OT carries pack-migration state). Proceed with `f` (start fresh); record. |

### 6.5.13 §4.6 ordering and parallelism

§4.6 runs **after** §4.4 synthetic completes and its evidence is
captured. Rationale: if a defect exists in `migrate-v9-to-v10.sh`,
§4.4's controlled fixture surfaces it cheaply; running §4.6 first
risks attributing a synthetic-side defect to OT-side complexity and
conversely.

§4.6 runs **before** §4.7 (which reuses the clone) and **before**
§4.8 (which compares both trees).

§4.6 may run in parallel with §4.5 (test-detect.sh capture) or §4.2
(docs-research pass) since those are autonomous in this CLI session
and do not touch `/tmp/phase-4-fixtures/ot-project/`. §4.6 may NOT
run in parallel with §4.4 — they share the same `migrate-v9-to-v10.sh`
script invocation pattern and concurrent runs would muddle stdout
captures.

---

## Part 6.6 — §4.7 OT post-migration kickoff smoke runbook

**Goal of §4.7.** Demonstrate that on the §4.6 post-migration OT clone
(a real v10-shaped project after migration from v9.3), pasting the
kickoff variant with OT's actual project name pre-filled produces the
expected Procedure 7 path — Form R / I / E / M outputs, with all of
OT's real complexity (custom skills, populated content, real source
layout) flowing through unchanged.

**Reference spec.** v1 Part 3 (§4.1 fixture runbook — same shape, OT
clone instead of synthetic fixtures); `supporting-docs/METHODOLOGY.md`
Procedure 7; `project-template/docs/pack/prompts/pm-chat.md` kickoff
variant.

### 6.6.1 Critical guardrail

§4.7 inherits all §0.8.2 hard guardrails. In particular:

- The developer's `claude` session opens **inside the clone**, never
  inside the live OT repo. The Part 13 M-OT step explicitly enforces
  `cd /tmp/phase-4-fixtures/ot-project/` before `claude`.
- The developer replies `skip` to Form E / I / M (same rationale as
  v1 §3.3 — fixture is ephemeral; persisting edits adds nothing).
- The developer captures Form R / final-summary verbatim into
  evidence files; the implementer applies §6.6.7 sanitization rules
  before staging into `V10-PHASE-4-VERIFICATION.md`.

### 6.6.2 Runner

**Developer in a separate `claude` session** (this implementer cannot
run `claude` inside `claude`). Manual step is **M-OT** in Part 13.

### 6.6.3 Implementer-side preconditions

Before reporting "ready for M-OT" to the developer, this CLI session
must:

1. Have completed §4.6 §6.5.6–§6.5.9 with a pass (or soft pass) — the
   post-migration OT clone exists at `/tmp/phase-4-fixtures/ot-project/`
   and is intact.
2. Have built the OT-tailored kickoff paste file per §6.6.4 below
   (`/tmp/phase-4-fixtures/kickoff-paste-OT.txt`).
3. Have confirmed `claude` is on the developer's PATH and the clone
   path exists.
4. Have NOT torn down `/tmp/phase-4-fixtures/ot-project/` (M-OT runs
   inside it).

### 6.6.4 Step 1 — pre-fill the OT-tailored kickoff paste file

The implementer extracts OT's project name and `[PLATFORM_TARGETS]`
from the **clone's** post-migration trinity (NOT from live OT — read-
only against the clone is fine; the clone is ours to read). The
extracted values fill the kickoff variant's bracketed placeholders.

```bash
OT_CLONE=/tmp/phase-4-fixtures/ot-project

# Extract project name from the clone's post-migration CLAUDE.md.
# Post-migration trinity should have [PROJECT_NAME] either replaced
# (if OT had filled it pre-migration) or still bracketed (if OT was
# template-state). We do NOT mutate the clone — read-only.
ot_project_name=$(awk '
  /^#[[:space:]]*[^[:space:]]/ { print; exit }
' "$OT_CLONE/CLAUDE.md" 2>/dev/null | sed 's/^#[[:space:]]*//' | head -1)
# Fallback if H1 extraction fails: use a sanitized literal.
[[ -z "$ot_project_name" ]] && ot_project_name="OT (Phase 4 v2 smoke)"
echo "Extracted OT project name (used in paste file): $ot_project_name"

# Extract PLATFORM_TARGETS from clone (best-effort; structural inspection).
# If a "**Platform targets:**" line exists, extract its value; otherwise default.
ot_platforms=$(grep -m1 -i '\*\*platform targets\*\*' "$OT_CLONE/CLAUDE.md" 2>/dev/null | sed 's/^.*\*\*[Pp]latform targets\*\*:\s*//')
[[ -z "$ot_platforms" ]] && ot_platforms="macOS 15+, Xcode 26.3, Swift 6"
echo "Extracted OT platforms (used in paste file): $ot_platforms"

# Build the OT-tailored paste file using the same awk / sed pipeline
# as v1 §3.2.1 / §5.2 — only the substitution values change.
awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' \
    "$PACK/project-template/docs/pack/prompts/pm-chat.md" \
  | sed '$d' \
  | sed \
      -e "s/\[PROJECT_NAME\]/${ot_project_name//\//\\/}/g" \
      -e "s/\[2-3 sentence description of what the project is and does\]/Phase 4 v2 OT real-project smoke; post-migration v10 clone exercising Procedure 7 against real-project complexity (custom skills, populated content, real source layout)./g" \
      -e "s|\[e\.g\., macOS 15+, Xcode 26\.3, Swift 6 / Python 3\.12+\]|${ot_platforms//\//\\/}|g" \
      -e 's/Phase \[N\] — \[Phase title\] (\[not started \/ in progress\])/Phase 0 — Smoke (not started)/g' \
      -e 's/\[Architecture pattern, e\.g\., MVVM with layered domain\/data\/presentation\]/per OT trinity/g' \
      -e 's/\[Key protocol decisions, e\.g\., DataStore protocol over SwiftData\]/per OT trinity/g' \
      -e 's/\[Any other settled decisions\]/none for smoke/g' \
  > /tmp/phase-4-fixtures/kickoff-paste-OT.txt

wc -l /tmp/phase-4-fixtures/kickoff-paste-OT.txt
# Confirm no remaining bracketed placeholders in the project-context block:
grep -nE '^\*\*[A-Z][^*]*\*\*:.*\[' /tmp/phase-4-fixtures/kickoff-paste-OT.txt | head -5
# Expect: zero matches in the project-context fields.
```

**Note on the project-name extraction.** If the clone's CLAUDE.md H1
is `# [PROJECT_NAME]` (i.e., OT never filled it), the extraction
yields `[PROJECT_NAME]` literally. The fallback default kicks in;
record the fallback in evidence as a deviation note ("OT did not
fill its CLAUDE.md H1; used 'OT (Phase 4 v2 smoke)' literal").

**Sanitization for the paste file.** The paste file contains the OT
project name (an OT-derived identifier). Per §6.6.7, the project
name token is OK to include in the evidence file's "paste source"
description (single-token identifier metadata), but the paste file's
verbatim contents are **NOT** pasted into the evidence file — only
the path + line count + a "no remaining placeholders" confirmation.

### 6.6.5 Step 2 — hand off to M-OT

The implementer reports to the developer:

> **OT clone migrated; paste file at
> `/tmp/phase-4-fixtures/kickoff-paste-OT.txt` (~70 lines, OT
> project name pre-filled); ready for M-OT.**

Per Part 13 — M-OT, the developer opens a fresh `claude` session
inside `/tmp/phase-4-fixtures/ot-project/`, pastes the OT-tailored
kickoff variant, replies `shell`, replies `yes` to Form R, then
`skip` to Form E / I / M.

### 6.6.6 Pass / fail criteria for §4.7

| Aspect | Pass | Fail behavior |
|---|---|---|
| Surface-declaration question fires | yes (model asks `shell` / `manual`) | F-G if absent — pm-chat.md kickoff variant defective on real-project complexity. |
| Form R is composed and runs | yes (G7-discovery ~11 commands) | F-G if absent. |
| Form R completes against OT (real Xcode / SPM / Python state) | exits without Procedure-7-side defect | If Procedure 7 declines for an OT-specific reason that synthetic missed (e.g., `xcodebuild` errors specific to OT's project structure), this is the gold §4.8 signal — not a §4.7 fail per se, but recorded as a divergence. |
| Form E proposes edits to the right pack-managed files | yes | F-G if it proposes edits outside `scripts/*-swift.sh` / `scripts/*-python.sh` / `.claude/settings.json` env block. |
| Form I and Form M render | yes | If Form M proposes destructive overwrite without `cmp -s`, F-G (same as v1 §3.5). |
| Developer replies `skip` and the assistant cleanly returns | yes | F-G if assistant does not honor `skip`. |
| Final-summary capture | yes (developer pastes `pbpaste > evidence-OT-final.txt`) | n/a — capture-side issue is M-OT-runner-corrected. |

**Pass.** Procedure 7 completes Form R → final summary on OT without
a defect; Form outputs are recorded structurally; deviations from
§4.4 / §4.1 F1 patterns are captured as §4.8-input divergences.

**Fail.** Any defect that Procedure 7's design says should not
happen (regex-style edit to `.claude/settings.json`, destructive
overwrite without `cmp -s`, Procedure 7 unreachable, etc.) — F-G.

**Soft pass.** Procedure 7 produces an OT-specific deviation that
synthetic did not (e.g., Form R reports "no schemes" because OT's
Package.swift is unusual, even though OT genuinely is a real Apple
project). Record as soft pass for §4.8 to interpret.

### 6.6.7 §4.7 evidence-block shape (sanitized)

Same per-field sanitization classification as §6.5.10, with these
§4.7-specific additions:

| Field | Sanitization rule |
|---|---|
| Surface | OK — "Claude Code CLI v\<output of `claude --version`\>" |
| Fixture or input | OK — `/tmp/phase-4-fixtures/ot-project/`. |
| Paste source | OK to include "OT-tailored kickoff variant; OT project name pre-filled (single-token identifier); paste file at `/tmp/phase-4-fixtures/kickoff-paste-OT.txt` (~N lines)". Do NOT paste the file's content. |
| Surface-declaration reply | OK — "shell". |
| Form R reply | OK — "yes". |
| **Form R verbatim output** | **STRUCTURAL SUMMARY ONLY.** Form R output enumerates real OT state — `xcodebuild -list` reveals OT's scheme names; `simctl list devices available` reveals OT's destination choices; `pyproject.toml`-detection lines reveal OT's package name; etc. Capture as: count of discovery commands run; presence/absence of Apple side / Python side / gRPC side; for each side, Boolean "succeeded / failed"; deviations from §4.1 F1 expectations. Do NOT paste raw stdout. |
| Form E proposed diff | **STRUCTURAL SUMMARY ONLY.** The diff names changed files (pack-managed paths — OK) but body lines may include OT-specific values (XCODE_SCHEME chosen from OT's actual scheme list; XCODE_DESTINATION chosen from OT's simulator list). Capture: file-list (pack paths only); env-block keys proposed (XCODE_SCHEME / XCODE_DESTINATION etc., names only); whether values are non-empty. Do NOT paste verbatim. |
| Form I proposed installs | OK — pack-defined install lists (`brew install swift-format` etc.) are pack content; the trigger conditions cite OT state but the proposal text is pack-generated. Capture verbatim. |
| Form M proposed companion-files batch | **STRUCTURAL SUMMARY ONLY.** Proposed `cp` paths target `~/Library/Developer/Xcode/CodingAssistant/` (machine-level, OK), but the batch list itself enumerates files derived from OT's source layout. Capture: count of files in batch; whether `cmp -s` byte-identity check is included. Do NOT paste verbatim. |
| Skip-replies behavior | OK — pack-defined. |
| Final-summary verbatim | **STRUCTURAL SUMMARY ONLY.** May reference OT module names, OT decisions, etc. Capture: presence of expected sections (kickoff complete signal / next-steps section); pack-generated wording quoted verbatim where it is unambiguously pack-side; OT-derived prose summarized. |
| Pass / fail / soft pass per §6.6.6 | OK. |
| Notes / deviations | Same author-judgment rule as §6.5.10. |
| Failure-mode link | OK. |

### 6.6.8 §4.7 dependencies and ordering

§4.7 depends on §4.6 (uses the same clone). §4.7 must complete BEFORE
§4.8 (which compares the post-§4.7 OT tree against §4.4's synthetic
post-migration tree). §4.7 may run in parallel with §4.5 / §4.3 if
the developer has the bandwidth — §4.7 is the developer's only
session inside the OT clone, so collisions are unlikely.

### 6.6.9 §4.7 failure-mode actions

| If… | Action |
|---|---|
| Surface-declaration question doesn't fire | F-G; pm-chat.md kickoff variant defective on real-project complexity. |
| Form R errors in a Procedure-7-defined way (e.g., declines per §7.4 row 4) | NOT a fail per se; record verbatim (per §6.6.7 sanitization), proceed to skip-replies, capture final state. The §7.4 declines are by design. |
| Form E proposes regex-style edit to `.claude/settings.json` | F-G (defect — same as v1 §3.5). v10.0 hold. |
| Form M proposes destructive overwrite without `cmp -s` | F-G. v10.0 hold. |
| Procedure 7 cannot be reached (kickoff variant breaks before pointer) | F-G mapped to Phase 3-B retrofit. v10.0 hold. |
| `claude` itself errors / network blip / rate limit | Retry once; if second attempt fails, mark §4.7 as "deferred — surface transient" and re-attempt before final-cleanup. NOT F-B. |
| Procedure 7 produces an OT-specific divergence from §4.1 F1 expectations (e.g., F2-multi-scheme behavior surfaces because OT has multi-scheme reality) | NOT a §4.7 fail; record as §4.8-input divergence with structural summary. |
| Developer accidentally runs `claude` inside live OT instead of clone | STOP IMMEDIATELY. Do NOT execute any further commands. Report to implementer; verify live OT state via the §6.5.7 check pattern; if live OT is unchanged (claude session was read-only), restart M-OT inside the clone. If live OT was modified, F-I (proposed) hard safety violation. |

---

## Part 6.7 — §4.8 OT-vs-synthetic comparison runbook

**Goal of §4.8.** Quantify the structural differences between the §4.4
synthetic post-migration tree and the §4.6 OT post-migration tree, so
that any defect specific to OT-shaped projects (versus the controlled
synthetic baseline) is identifiable. NO OT content is reproduced — the
comparison is structural only.

**Reference spec.** v2 §0.8.1 (the §4.8 row); v2 §6.5.10 / §6.6.7
sanitization rules.

### 6.7.1 Runner / where

**This CLI session** (autonomous). Operates on `/tmp/phase-4-fixtures/
v9-project/` (the §4.4 synthetic post-migration tree) and
`/tmp/phase-4-fixtures/ot-project/` (the §4.6 OT post-migration tree)
in read-only mode. Writes only to scratch files under
`/tmp/phase-4-fixtures/` (covered by R10-16 in Part 10).

### 6.7.2 Prerequisites

```bash
# Both trees must still exist.
[[ -d /tmp/phase-4-fixtures/v9-project ]]  || { echo "FAIL: §4.4 tree missing"; exit 1; }
[[ -d /tmp/phase-4-fixtures/ot-project ]]  || { echo "FAIL: §4.6 tree missing"; exit 1; }

# §4.7 evidence captured (the developer has reported M-OT done).
[[ -f /tmp/phase-4-fixtures/evidence-OT-final.txt ]] && echo "OK: §4.7 final captured" \
  || echo "WARN: §4.7 evidence file missing — was M-OT completed?"

# Stdout files from §4.4 and §4.6 still present.
[[ -f /tmp/phase-4-fixtures/v9-migrate.stdout.txt ]] && echo "OK: §4.4 stdout present"
[[ -f /tmp/phase-4-fixtures/ot-migrate.stdout.txt ]] && echo "OK: §4.6 stdout present"
```

### 6.7.3 Step 1 — file-path diffs (sanitized)

```bash
SYN=/tmp/phase-4-fixtures/v9-project
OT=/tmp/phase-4-fixtures/ot-project

# Enumerate post-migration tree paths (relative). Strip both trees' .git/
# and .pack-migration-backup/ to focus on pack-managed surface.
( cd "$SYN" && find . \( -path ./.git -prune -o -path ./.pack-migration-backup -prune \) -o -type f -print ) | sort > /tmp/phase-4-fixtures/cmp.syn-paths.txt
( cd "$OT"  && find . \( -path ./.git -prune -o -path ./.pack-migration-backup -prune \) -o -type f -print ) | sort > /tmp/phase-4-fixtures/cmp.ot-paths.txt

# Common paths (intersection).
comm -12 /tmp/phase-4-fixtures/cmp.syn-paths.txt /tmp/phase-4-fixtures/cmp.ot-paths.txt > /tmp/phase-4-fixtures/cmp.common-paths.txt
wc -l /tmp/phase-4-fixtures/cmp.common-paths.txt | sed 's/^/  common-path count: /'

# Synthetic-only paths.
comm -23 /tmp/phase-4-fixtures/cmp.syn-paths.txt /tmp/phase-4-fixtures/cmp.ot-paths.txt > /tmp/phase-4-fixtures/cmp.syn-only-paths.txt
wc -l /tmp/phase-4-fixtures/cmp.syn-only-paths.txt | sed 's/^/  synthetic-only-path count: /'
# Synthetic-only paths are SAFE to enumerate verbatim — they describe
# the synthetic fixture, which is pack-managed and pack-tested.
cat /tmp/phase-4-fixtures/cmp.syn-only-paths.txt | head -50

# OT-only paths.
comm -13 /tmp/phase-4-fixtures/cmp.syn-paths.txt /tmp/phase-4-fixtures/cmp.ot-paths.txt > /tmp/phase-4-fixtures/cmp.ot-only-paths.txt
wc -l /tmp/phase-4-fixtures/cmp.ot-only-paths.txt | sed 's/^/  OT-only-path count: /'
# OT-only paths are STRUCTURAL SUMMARY ONLY. They reveal OT source layout.
# Categorize without reproducing names: count by top-level directory; count by
# extension; count of files under x-* skill dirs; count of files outside .claude/
# .codex/ .gemini/ docs/ scripts/ (i.e., real source layout).
awk -F/ 'NF>1 { print $2 }' /tmp/phase-4-fixtures/cmp.ot-only-paths.txt | sort | uniq -c | sort -rn > /tmp/phase-4-fixtures/cmp.ot-only-toplevel.txt
echo "OT-only paths bucketed by top-level dir name (top-level dir names ARE OT-derived; capture COUNTS only, NOT names, in evidence):"
cat /tmp/phase-4-fixtures/cmp.ot-only-toplevel.txt
```

**Sanitization for the §4.8 evidence block.** The synthetic-only
paths and the count-by-top-level-dir output are OK; the OT-only
paths file (`cmp.ot-only-paths.txt`) is **internal forensic only** —
its content is not copied into the evidence file. Evidence captures:
common-path count, synthetic-only count + listing, OT-only count +
top-level-dir-bucket counts (numbers only).

### 6.7.4 Step 2 — validate-pack.py exit codes against each tree

```bash
# Capture exit codes against both post-migration trees.
python3 "$PACK/scripts/validate-pack.py" --target /tmp/phase-4-fixtures/v9-project \
  > /tmp/phase-4-fixtures/cmp.syn-vp.stdout 2> /tmp/phase-4-fixtures/cmp.syn-vp.stderr
syn_vp_exit=$?
echo "validate-pack.py exit (synthetic): $syn_vp_exit"

python3 "$PACK/scripts/validate-pack.py" --target /tmp/phase-4-fixtures/ot-project \
  > /tmp/phase-4-fixtures/cmp.ot-vp.stdout 2> /tmp/phase-4-fixtures/cmp.ot-vp.stderr
ot_vp_exit=$?
echo "validate-pack.py exit (OT): $ot_vp_exit"

# Flag if behaviors differ.
[[ "$syn_vp_exit" == "$ot_vp_exit" ]] \
  && echo "OK: validate-pack.py exits match across trees ($syn_vp_exit)" \
  || echo "DIVERGENCE: validate-pack.py exit codes differ — synthetic=$syn_vp_exit, OT=$ot_vp_exit"
```

**Note.** Per V10-PHASE-4-PLAN §4.4 and v1 §6.7 row, `validate-pack.py`
is a pack-repo-only check; running it against project trees may exit
non-zero with usage error. That is the expected state for both. The
**§4.8 signal** is whether the two trees produce the SAME exit code
and the SAME stderr-error class. A divergence (synthetic exits 1
with usage-error, OT exits 2 with missing-file-error) is the §4.8
flag — captured for project-lead interpretation.

### 6.7.5 Step 3 — migration script stdout differences

This is the section where verbatim quoting is REQUIRED — both stdout
files are pack-generated text.

```bash
# Side-by-side diff of the two migration script stdouts.
diff -u /tmp/phase-4-fixtures/v9-migrate.stdout.txt /tmp/phase-4-fixtures/ot-migrate.stdout.txt \
  > /tmp/phase-4-fixtures/cmp.stdout-diff.txt
echo "Migration stdout diff line count: $(wc -l < /tmp/phase-4-fixtures/cmp.stdout-diff.txt)"

# Extract the Procedure 5-R prompt from each stdout. Anchor: V10-DESIGN §6.10
# specifies the prompt's preamble — search by a stable phrase. (The exact
# phrase is implementer-discoverable from /tmp/phase-4-fixtures/v9-migrate.stdout.txt.)
grep -A 200 -F 'Procedure 5-R' /tmp/phase-4-fixtures/v9-migrate.stdout.txt > /tmp/phase-4-fixtures/cmp.syn-5r.txt 2>/dev/null || true
grep -A 200 -F 'Procedure 5-R' /tmp/phase-4-fixtures/ot-migrate.stdout.txt > /tmp/phase-4-fixtures/cmp.ot-5r.txt 2>/dev/null || true

# Compare the two Procedure 5-R prompts byte-for-byte (after stripping
# trailing whitespace and project-path differences in the prompt body).
# The prompt SHOULD be byte-identical except for project-path differences
# (synthetic uses /tmp/phase-4-fixtures/v9-project; OT uses
# /tmp/phase-4-fixtures/ot-project).
diff -u <(sed 's|/tmp/phase-4-fixtures/v9-project|<TARGET>|g' /tmp/phase-4-fixtures/cmp.syn-5r.txt) \
        <(sed 's|/tmp/phase-4-fixtures/ot-project|<TARGET>|g' /tmp/phase-4-fixtures/cmp.ot-5r.txt) \
  > /tmp/phase-4-fixtures/cmp.5r-diff.txt
echo "Procedure 5-R prompt diff (after path normalization): $(wc -l < /tmp/phase-4-fixtures/cmp.5r-diff.txt) lines"
# Expect: 0 lines (the prompt is pack-generated and identical modulo target path).
```

**Sanitization.** Both stdout files are pack-generated text (the
`say()` output of the migration script). Quoting their full diff in
the §4.8 evidence is OK. The Procedure 5-R prompt is the canonical
example: it is REQUIRED to be quoted verbatim (synthetic side and
OT side both) because this is the most direct evidence that the
script generates the same prompt regardless of fixture realism.

### 6.7.6 Step 4 — quantitative summary

```bash
{
  printf '%s\n' "── §4.8 quantitative summary ──"
  printf 'Generated: %s\n\n' "$(date -u +%FT%TZ)"

  printf 'File-count delta:\n'
  printf '  synthetic post-migration paths: %s\n' "$(wc -l < /tmp/phase-4-fixtures/cmp.syn-paths.txt)"
  printf '  OT post-migration paths:        %s\n' "$(wc -l < /tmp/phase-4-fixtures/cmp.ot-paths.txt)"
  printf '  common paths:                   %s\n' "$(wc -l < /tmp/phase-4-fixtures/cmp.common-paths.txt)"
  printf '  synthetic-only:                 %s\n' "$(wc -l < /tmp/phase-4-fixtures/cmp.syn-only-paths.txt)"
  printf '  OT-only:                        %s\n' "$(wc -l < /tmp/phase-4-fixtures/cmp.ot-only-paths.txt)"
  printf '\n'

  printf 'Trinity section-count delta:\n'
  for f in CLAUDE.md AGENTS.md GEMINI.md; do
    syn_secs=$(grep -c '^## ' "/tmp/phase-4-fixtures/v9-project/$f" 2>/dev/null || echo 0)
    ot_secs=$(grep -c '^## ' "/tmp/phase-4-fixtures/ot-project/$f"  2>/dev/null || echo 0)
    printf '  %s — synthetic %s sections; OT %s sections; delta %s\n' \
      "$f" "$syn_secs" "$ot_secs" "$((ot_secs - syn_secs))"
  done
  printf '\n'

  printf 'Custom-skills count (x-* directories under skills/):\n'
  syn_cs=$(find /tmp/phase-4-fixtures/v9-project/.claude/skills -mindepth 1 -maxdepth 1 -type d -name "x-*" 2>/dev/null | wc -l | tr -d ' ')
  ot_cs=$(find /tmp/phase-4-fixtures/ot-project/.claude/skills  -mindepth 1 -maxdepth 1 -type d -name "x-*" 2>/dev/null | wc -l | tr -d ' ')
  printf '  synthetic: %s\n' "$syn_cs"
  printf '  OT:        %s\n' "$ot_cs"
  printf '  delta:     %s\n\n' "$((ot_cs - syn_cs))"

  printf 'x-files count (across .claude/agents/, .codex/agents/, .gemini/agents/):\n'
  syn_xf=$(find /tmp/phase-4-fixtures/v9-project/.claude/agents /tmp/phase-4-fixtures/v9-project/.codex/agents /tmp/phase-4-fixtures/v9-project/.gemini/agents -name "x-*" 2>/dev/null | wc -l | tr -d ' ')
  ot_xf=$(find /tmp/phase-4-fixtures/ot-project/.claude/agents /tmp/phase-4-fixtures/ot-project/.codex/agents /tmp/phase-4-fixtures/ot-project/.gemini/agents -name "x-*" 2>/dev/null | wc -l | tr -d ' ')
  printf '  synthetic: %s\n' "$syn_xf"
  printf '  OT:        %s\n' "$ot_xf"
  printf '  delta:     %s\n\n' "$((ot_xf - syn_xf))"

  printf 'validate-pack.py exit codes:\n'
  printf '  synthetic: (captured at §6.7.4)\n'
  printf '  OT:        (captured at §6.7.4)\n\n'

  printf 'Migration stdout diff lines: %s\n' "$(wc -l < /tmp/phase-4-fixtures/cmp.stdout-diff.txt)"
  printf 'Procedure 5-R prompt diff (path-normalized): %s lines\n' "$(wc -l < /tmp/phase-4-fixtures/cmp.5r-diff.txt)"
} > /tmp/phase-4-fixtures/cmp.summary.txt
cat /tmp/phase-4-fixtures/cmp.summary.txt
```

### 6.7.7 §4.8 evidence-block shape (sanitized)

| Field | Sanitization rule |
|---|---|
| Timestamp | OK. |
| Surface | OK — "Bash; this CLI session". |
| Inputs | OK — both pack-managed paths. |
| Common-path count | OK. |
| Synthetic-only path listing | OK to paste verbatim — describes synthetic fixture. |
| OT-only path count | OK. |
| OT-only top-level-dir bucket counts | **STRUCTURAL ONLY** — counts by bucket, NOT names. Top-level dir names are OT-derived; do NOT enumerate names. |
| validate-pack.py exit codes | OK — single integers. |
| validate-pack.py stderr summary | If stderr is pack-generated usage/error text, OK to quote. If stderr names OT paths, summarize structurally. |
| Migration stdout diff | OK — full diff is pack-generated `say()` output on both sides. Pasting `cmp.stdout-diff.txt` verbatim is the §4.8 high-value capture. |
| Procedure 5-R prompt verbatim (synthetic side) | OK — pack-generated. Quote verbatim. |
| Procedure 5-R prompt verbatim (OT side, with target path normalized to `<TARGET>`) | OK — pack-generated. Quote verbatim. |
| Procedure 5-R prompt diff (path-normalized) | OK — pack-generated. Expected to be 0 lines. |
| Quantitative summary | OK — all numbers, no names. |
| Pass / fail per §6.7.8 | OK. |
| Notes / deviations | Author per-note: pack-generated OK verbatim; OT-derived structural only. |
| Failure-mode link | OK. |

### 6.7.8 §4.8 pass / fail criteria

| Check | Pass | Fail behavior |
|---|---|---|
| Both trees still exist at §4.8 start | yes | Procedural error — restart §4.6 / §4.7. |
| validate-pack.py exit codes match across trees | yes (both same value, whatever it is) | DIVERGENCE — flag for project-lead interpretation. May or may not be a defect (validate-pack.py was not designed for project-tree evaluation). NOT automatically F-G. |
| Migration stdout diff is bounded | (diff exists; path differences and quantitative differences expected) | n/a — informational. |
| Procedure 5-R prompt diff (path-normalized) | 0 lines (byte-identical modulo target path) | If non-zero, the migration script generates different prompts depending on fixture state — F-G. |
| Synthetic-only path count is small (≤ ~5) | yes | If synthetic-only count is large, synthetic fixture is not v9.3-faithful; flag back to v1 §4.4 fixture design. F-E (synthetic fixture under-spec). |
| OT-only path count is plausibly OT-derived (custom skills, real source layout, x-files) | yes | If OT-only count is small or zero, the §4.6 migration may have over-trimmed OT files — F-G. |
| Quantitative summary is fully populated | yes | n/a — recapture if blank. |

**Defect-flag rule.** If §4.8 reveals a defect specific to OT-shaped
projects (e.g., the migration script's S5 trinity splice fails on
trinity files that have more sections than synthetic carries), **F-G
fires; v10.0 hold.** §4.4 alone is insufficient regression coverage
for that class of defect.

### 6.7.9 Step 5 — final cleanup (OT clone teardown)

After §4.8 evidence is captured into `V10-PHASE-4-VERIFICATION.md`,
tear down the OT-related state. **This is the moment the hard OT-
safety guardrails (§0.8.2 row 3) are verified.**

```bash
# 1. Tear down OT clone.
cd /tmp                                       # leave the clone
rm -rf /tmp/phase-4-fixtures/ot-project
ls -ld /tmp/phase-4-fixtures/ot-project 2>&1
# Expect: "No such file or directory"

# 2. Tear down OT-related scratch files.
rm -f /tmp/phase-4-fixtures/kickoff-paste-OT.txt
rm -f /tmp/phase-4-fixtures/ot-baseline.txt
rm -f /tmp/phase-4-fixtures/ot-migrate.{stdout,stderr,status-count,diff-stat}.txt
rm -f /tmp/phase-4-fixtures/ot-vp.{stdout,stderr}.txt
rm -f /tmp/phase-4-fixtures/evidence-OT-form-r.txt
rm -f /tmp/phase-4-fixtures/evidence-OT-final.txt
rm -f /tmp/phase-4-fixtures/cmp.{syn,ot,common,syn-only,ot-only}-paths.txt
rm -f /tmp/phase-4-fixtures/cmp.ot-only-toplevel.txt
rm -f /tmp/phase-4-fixtures/cmp.{syn,ot}-vp.{stdout,stderr}
rm -f /tmp/phase-4-fixtures/cmp.{stdout-diff,syn-5r,ot-5r,5r-diff,summary}.txt
ls /tmp/phase-4-fixtures/ot-* /tmp/phase-4-fixtures/cmp.* /tmp/phase-4-fixtures/kickoff-paste-OT.txt /tmp/phase-4-fixtures/evidence-OT-* 2>&1
# Expect: each "No such file or directory"

# 3. **Critical: verify live OT repo is byte-identical to §6.5.3 baseline.**
OT_LIVE=/Users/david/Developer/OptiquityTrader
current_sha=$(git -C "$OT_LIVE" rev-parse HEAD)
baseline_sha=$(grep '^HEAD SHA: ' /tmp/phase-4-fixtures/ot-baseline.txt 2>/dev/null | awk '{print $3}')
# Note: at this point ot-baseline.txt is already deleted (step 2). The
# baseline SHA must therefore have been recorded into the §4.6 evidence
# block before reaching this step. Re-read it from the in-progress
# V10-PHASE-4-VERIFICATION.md draft instead, or capture again:
echo "Live OT HEAD now:    $current_sha"
echo "(Baseline captured into §4.6 evidence — confirm match by reviewing the §4.6 block)"

current_status=$(git -C "$OT_LIVE" status --porcelain | wc -l | tr -d ' ')
[[ "$current_status" == "0" ]] && echo "OK: live OT working tree clean" || echo "FAIL: live OT working tree dirty"

# 4. Single-command final cleanup also tears these down (§10.1 update).
```

**Pass criterion.** Step 1–2 tear-downs all confirm "No such file or
directory"; step 3 confirms live OT working tree is clean and HEAD
SHA matches the §6.5.3 baseline (recorded in §4.6 evidence).

**Fail handling.** If step 3 reveals live OT was modified, that is
a **post-hoc detection** of an §6.5.7-class safety violation. F-I
(proposed) hard safety violation. Project-lead notification IMMEDIATE.

### 6.7.10 §4.8 ordering

§4.8 runs after §4.7 evidence is captured. §4.8's cleanup (§6.7.9)
is the final OT-related teardown — no other section reuses OT state
after §4.8.

---

## Part 7 — §4.5 detect.sh test results runbook

**Goal of §4.5.** Capture the verbatim output of
`scripts/test-detect.sh` into `V10-PHASE-4-VERIFICATION.md`.

**Reference spec.** `V10-PHASE-4-PLAN.md` §4.5; `scripts/test-detect.sh`
(landed in C-V10-14, commit `459161b`).

### 7.1 Status

The runner already passes 34/34 (re-run during this plan's drafting:
`=== Results: 34 passed, 0 failed ===`). §4.5 is **capture only** —
no fixture construction (the runner builds and tears down its own
fixtures via `mktemp -d`), no decisions, no failure modes that aren't
already F-G.

### 7.2 Capture command

```bash
cd "$PACK"
bash scripts/test-detect.sh > /tmp/phase-4-fixtures/test-detect.out.txt 2>&1
echo "test-detect exit: $?"
tail -5 /tmp/phase-4-fixtures/test-detect.out.txt
wc -l /tmp/phase-4-fixtures/test-detect.out.txt
```

**Expected.** Exit 0; final line `=== Results: 34 passed, 0 failed
===`; ~80 lines total output.

### 7.3 Pass / fail

| Outcome | Action |
|---|---|
| Exit 0 + `34 passed, 0 failed` | Pass. Paste output verbatim into §4.5 evidence block. |
| Exit 0 + count differs from 34 (e.g., 33 passed, 1 failed; or 35 passed if a test was added) | If a failure: F-G; v10.0 hold per Phase 4 Plan F-G (detect.sh defect). If count grew without a failure: flag-back F-E (silent scope expansion — was a test added in scope without plan update?). |
| Exit non-zero | F-G. v10.0 hold. |
| Runner cannot be sourced (e.g., `lib/detect.sh` missing) | F-G. v10.0 hold. |

### 7.4 §4.5 evidence-block shape

Use the §8 unified template. Fields:

- Timestamp
- Surface (Bash; this CLI session)
- Test runner: `scripts/test-detect.sh`
- Pack tip: `git rev-parse HEAD` (e.g., `459161b…`)
- Command: `bash scripts/test-detect.sh`
- Exit code
- Output (verbatim, fenced — paste the entire 34-test output)
- Pass / fail
- Note: re-run was performed at C-V10-15 capture time (not just
  inheriting the C-V10-14 result).

### 7.5 §4.5 dependencies

§4.5 depends on `scripts/test-detect.sh` existing, which lands in
C-V10-14 (`459161b`). Per Gate F entry criterion 6 the harness must
pass before Gate F. §4.5 is the verification artifact for that
criterion.

---

## Part 8 — Unified evidence-capture template

Apply this template to **every** evidence entry across §4.1–§4.5.
Same field set, same shape, different fixture / surface values per
section. Embed inside `maintenance-docs/V10-PHASE-4-VERIFICATION.md`
as the §4.x evidence block(s).

### 8.1 Template (markdown, copy verbatim into V10-PHASE-4-VERIFICATION.md)

```markdown
#### Evidence — <section> — <fixture-or-surface label>

| Field | Value |
|---|---|
| Timestamp (UTC) | YYYY-MM-DDTHH:MM:SSZ |
| Surface | <e.g., Claude Code CLI vX.Y.Z / Codex CLI vX.Y.Z / Gemini CLI vX.Y.Z / Claude Desktop + filesystem MCP / Claude Web (no MCP) / Bash> |
| Fixture or input | <e.g., F1 apple-spm-single-scheme at /tmp/phase-4-fixtures/apple-spm-single-scheme; or "v9.3 fixture project at /tmp/phase-4-fixtures/v9-project"; or "kickoff variant body, ~72 lines from pm-chat.md"> |
| Command(s) run | <copy-paste-safe shell line(s) or chat action(s)> |
| Output (verbatim) | <fenced block> |
| Outcome | pass / soft pass / fail / unavailable (F-B (b)) |
| Notes / deviations | <one-line summary; null if none> |
| Failure-mode link | <flag-back F-N from V10-PHASE-4-PLAN.md Part 8 if outcome is fail or unavailable; null if pass> |
```

### 8.2 Rules for filling the template

- **Verbatim outputs go in fenced blocks.** Use ` ```text ` fences for
  shell stdout; ` ```diff ` for proposed Form E diffs; ` ```json ` for
  `.claude/settings.json` proposals.
- **Soft pass requires a one-line note** explaining the deviation
  from the strict pass criterion.
- **Fail and unavailable rows MUST link to a flag-back ID** from
  `V10-PHASE-4-PLAN.md` Part 8. No silent fail / silent unavailable.
- **Cleanup confirmation is part of the evidence**, not separate. For
  fixture-using sections (§4.1, §4.2, §4.4), append a `Cleanup` field
  to the table:

  ```markdown
  | Cleanup | rm -rf /tmp/phase-4-fixtures/<name>/ — exit 0; ls confirms "No such file or directory". |
  ```

- **Single template, all sections.** Resist the urge to specialise
  per-section schemas. Reviewers reading V10-PHASE-4-VERIFICATION.md
  benefit from one mental model.

### 8.3 Evidence file structure (skeleton of V10-PHASE-4-VERIFICATION.md)

```markdown
# V10-PHASE-4-VERIFICATION.md — C-V10-15 evidence harness

*Captures evidence from five Phase-4 verification streams.*
*Authoritative spec: V10-PHASE-4-PLAN.md Part 4.*
*Per-section runbook: V10-PHASE-4-VERIFICATION-PLAN.md (this file's sibling).*
*Pack tip at capture: <git rev-parse HEAD>.*

## Pre-flight

<paste of /tmp/phase-4-preflight.txt from §1.1>

## §4.1 Fixture evidence

#### Evidence — §4.1 — F1 apple-spm-single-scheme
<template>

#### Evidence — §4.1 — F2 apple-multi-scheme
<template>

... (F3, F4, F5, F6)

## §4.2 Cross-surface checks

#### Evidence — §4.2 — C1 Codex CLI on F1
<template>

#### Evidence — §4.2 — C2 Gemini CLI on F1
<template>

#### Evidence — §4.2 — C3 Desktop Commander on F1
<template>

## §4.3 Claude Web manual-mode smoke

#### Evidence — §4.3 — Claude Web (no MCP)
<template>

## §4.4 Migration script smoke

#### Evidence — §4.4 — migrate-v9-to-v10.sh on /tmp/phase-4-fixtures/v9-project
<template>

## §4.5 detect.sh unit-test results

#### Evidence — §4.5 — bash scripts/test-detect.sh
<template>

## §4.6 OT real-project migration smoke (v2 addition; conditional)

#### Evidence — §4.6 — migrate-v9-to-v10.sh on /tmp/phase-4-fixtures/ot-project
<template — sanitization per V10-PHASE-4-VERIFICATION-PLAN-v2 §6.5.10>

## §4.7 OT post-migration kickoff smoke (M-OT) (v2 addition; conditional)

#### Evidence — §4.7 — Claude Code CLI on /tmp/phase-4-fixtures/ot-project (post-migration)
<template — sanitization per V10-PHASE-4-VERIFICATION-PLAN-v2 §6.6.7>

## §4.8 OT-vs-synthetic comparison (v2 addition; conditional)

#### Evidence — §4.8 — Bash; structural comparison only
<template — sanitization per V10-PHASE-4-VERIFICATION-PLAN-v2 §6.7.7>

## Summary

| Section | Outcome | Notes |
|---|---|---|
| §4.1 | <pass/partial/fail> | <e.g., 6/6 passed> |
| §4.2 | <pass/partial/fail> | <e.g., 3/3 passed; or "C3 unavailable, deferred to v10.1 per F-B (b)"> |
| §4.3 | <pass/soft pass/fail> | |
| §4.4 | <pass/fail> | |
| §4.5 | <pass/fail> | <e.g., 34/34 passed> |
| §4.6 *(v2)* | <pass/soft pass/fail/DEFERRED> | <e.g., "pass"; or "DEFERRED — OT additions out of scope for this C-V10-15"> |
| §4.7 *(v2)* | <pass/soft pass/fail/DEFERRED> | |
| §4.8 *(v2)* | <pass/soft pass/fail/DEFERRED> | |

## Flag-backs invoked

<list of F-N rows fired during execution; null if none. Includes F-I (proposed) if approved at OQ-VP4-8 and fired during §4.6 / §4.7 / §4.8.>
```

---

## Part 9 — Ordering and parallelization

### 9.1 Ordering with rationale (hybrid scope per §0.7)

| Order | Section | Runner | Why this position |
|---|---|---|---|
| 1 | Part 1 pre-flight | this CLI session | Catches missing required surfaces / dirty tree before any state is created. |
| 2 | §4.5 detect.sh capture | this CLI session | Already passing; cheapest evidence; lands first to clear one of five sections. |
| 3 | §4.1 fixture F1 (`apple-spm-single-scheme`) | dev in separate `claude` session | F1 is the happy path; verifies the kickoff → Procedure 7 chain works at all. |
| 4 | **Reassessment checkpoint** | project lead | If F1 surfaces a defect, stop and re-plan. If F1 succeeds, decide whether to expand to F2..F6. |
| 5 | §4.4 migration script smoke | this CLI session | Independent fixture; runs in parallel with §4.3 (next row). |
| 6 | §4.3 manual-mode smoke | dev in browser | Independent of §4.1 / §4.4; runs in parallel with §4.4. |
| 7 | §4.2 docs-research pass | this CLI session | Consumes §4.1 evidence + pack docs; runs after §4.1 capture exists. |
| 8 | §4.1 F2..F6 (CONDITIONAL on hybrid expansion) | dev in separate `claude` session | Only if project lead opts in after step 4 reassessment. Each fixture independently constructed + torn down. |
| 9 | Final cleanup pass (§10.1 single-command rollback) | this CLI session | Tears down all `/tmp/` state. |

### 9.2 Parallelization opportunities

Under hybrid scope:

| Stream A (this CLI session, autonomous) | Stream B (dev-in-claude) | Stream C (dev-in-browser) |
|---|---|---|
| §4.5 capture | (idle) | (idle) |
| (waiting on F1 evidence) | §4.1 F1 build + capture | (idle) |
| §4.4 migration smoke | (idle or continues if F2..F6) | §4.3 manual-mode smoke (parallel) |
| §4.2 docs-research pass | (idle or continues if F2..F6) | (idle) |
| §10.1 cleanup pass | (idle) | (idle) |

Wall-clock estimate (minimal scope, no F2..F6): ~45–75 minutes.

### 9.3 Ordering anti-patterns to avoid

- **Do not** start §4.4 before §4.5 capture if `test-detect.sh` is
  somehow not passing — §4.5 is a Gate F gating signal that should be
  confirmed first.
- **Do not** start §4.2 docs-research pass before §4.1 F1 capture
  exists — the docs-research compares against the F1 evidence.
- **Do not** opportunistically run a live test on Codex / Gemini /
  Desktop Commander even if those surfaces are present — silent scope
  expansion is F-E (Phase 4 Plan flag-back).
- **Do not** parallelize §4.1 F1 build with anything that depends on
  F1 evidence. F1 is the gating fixture.

---

### 9.4 Ordering for v2 OT additions (§4.6 / §4.7 / §4.8)

§4.6 / §4.7 / §4.8 run as a **third tier** layered on top of v1's
hybrid scope (§9.1). The tier is itself a project-lead opt-in: a
minimal-scope C-V10-15 may complete without §4.6 / §4.7 / §4.8 and
re-add them in a follow-up commit if needed; a full-scope C-V10-15
includes them inline.

| Order | Section | Runner | Why this position |
|---|---|---|---|
| 10 | §4.6 OT migration smoke | this CLI session | Runs AFTER §4.4 synthetic completes and its evidence is captured. Rationale: synthetic surfaces simple defects cheaply; OT exposes real-project complexity. Inverting the order risks attributing a synthetic-side defect to OT. |
| 11 | **OT migration reassessment checkpoint** | project lead | Same shape as v1 §9.1 row 4 (post-F1 reassessment). If §4.6 surfaces a defect, stop — §4.7 / §4.8 do not run until §4.6 re-runs cleanly post-fix. |
| 12 | §4.7 OT post-migration kickoff smoke (M-OT) | dev in separate `claude` session | Runs AFTER §4.6. Reuses the §4.6 post-migration OT clone (the clone must NOT be torn down between §4.6 and §4.7). |
| 13 | §4.8 OT-vs-synthetic comparison | this CLI session | Runs AFTER §4.7. Compares §4.4 synthetic post-migration tree against §4.6 OT post-migration tree (both must still be present). |
| 14 | OT cleanup with live-repo unchanged verification | this CLI session | §6.7.9. Includes the byte-identity check confirming `/Users/david/Developer/OptiquityTrader/` was never touched. |
| (final) | Single-command full-rollback (§10.1) | this CLI session | Already covered by v1; updated in v2 §10.1 to also tear down OT-related state. |

**Reassessment dependency rule.** §4.6 → §4.7 → §4.8 is a strict
chain. Skipping §4.6 cancels §4.7 / §4.8. Skipping §4.7 cancels
§4.8. §4.8 cannot run on §4.7-incomplete state because §4.8 depends
on §4.7 having captured a developer-visible evidence file (M-OT
output is the §4.8 anchor for "did Procedure 7 succeed against OT").

### 9.5 Parallelization opportunities for v2 OT additions

| Stream A (this CLI session, autonomous) | Stream B (dev-in-claude, M-OT) | Stream C (dev-in-browser, §4.3) |
|---|---|---|
| §4.6 migration smoke | (idle) | (idle or §4.3 in parallel — no shared state) |
| (waiting on §4.6 pass) | (waiting on §4.6 pass) | (parallel possible) |
| (idle while M-OT runs) | §4.7 M-OT | (parallel possible) |
| §4.8 comparison | (idle) | (parallel possible) |
| §6.7.9 final OT cleanup | (idle) | (parallel possible) |

Wall-clock estimate (full scope, with v2 OT additions on top of
minimal v1 scope, no F2..F6): ~75–110 minutes. The OT-additions tier
adds ~30–40 minutes (≈ 5 min §4.6 migration + 10 min §4.7 M-OT + 5
min §4.8 comparison + 10–15 min evidence sanitization).

### 9.6 Ordering anti-patterns specific to v2 OT additions

- **Do not** start §4.6 before §4.4 synthetic finishes — §4.4 is the
  cheap baseline; defects surface there first.
- **Do not** tear down `/tmp/phase-4-fixtures/v9-project/` before §4.8
  runs — §4.8 requires both trees concurrently.
- **Do not** tear down `/tmp/phase-4-fixtures/ot-project/` between
  §4.6 and §4.7 — §4.7 reuses it.
- **Do not** start `claude` inside the live OT repo at any point.
  M-OT explicitly enforces `cd /tmp/phase-4-fixtures/ot-project/`
  BEFORE `claude`.
- **Do not** opportunistically run §4.6 commands against the live
  OT repo "to save time on cloning". The clone is the safety
  boundary; bypassing it violates §0.8.2 row 1.
- **Do not** quote OT source code, OT documentation body, or OT-
  derived names in the evidence file beyond the per-field
  sanitization rules in §6.5.10 / §6.6.7 / §6.7.7.

---

## Part 10 — Rollback table

One row per state-creating operation in this plan. The rollback
command **fully undoes** the state created by the operation. Verify
rollback succeeded with the named verification command.

| # | Operation | State created | Rollback command | Verify rollback |
|---|---|---|---|---|
| R10-1 | Part 1 pre-flight `mkdir /tmp/phase-4-fixtures` | Empty fixture base directory | `rm -rf /tmp/phase-4-fixtures` | `ls -ld /tmp/phase-4-fixtures 2>&1` returns "No such file or directory" |
| R10-2 | §3.2.1 F1 construction | `/tmp/phase-4-fixtures/apple-spm-single-scheme/` with git history + SPM source | `rm -rf /tmp/phase-4-fixtures/apple-spm-single-scheme` | `ls` confirms absence |
| R10-3 | §3.2.2 F2 construction | `/tmp/phase-4-fixtures/apple-multi-scheme/` | `rm -rf /tmp/phase-4-fixtures/apple-multi-scheme` | `ls` confirms |
| R10-4 | §3.2.3 F3 construction | `/tmp/phase-4-fixtures/apple-no-simulator/` | `rm -rf /tmp/phase-4-fixtures/apple-no-simulator` | `ls` confirms |
| R10-5 | §3.2.4 F4 construction | `/tmp/phase-4-fixtures/apple-non-spm-layout/` | `rm -rf /tmp/phase-4-fixtures/apple-non-spm-layout` | `ls` confirms |
| R10-6 | §3.2.5 F5 construction | `/tmp/phase-4-fixtures/python-grpc-server/` | `rm -rf /tmp/phase-4-fixtures/python-grpc-server` | `ls` confirms |
| R10-7 | §3.2.6 F6 construction | `/tmp/phase-4-fixtures/python-only/` | `rm -rf /tmp/phase-4-fixtures/python-only` | `ls` confirms |
| R10-8 | §6.3 v9.3 pack-source clone | `/tmp/v9-pack-source/` (~5 MB+ git clone) | `rm -rf /tmp/v9-pack-source` | `ls -ld /tmp/v9-pack-source 2>&1` returns "No such file or directory" |
| R10-9 | §6.4 v9.3 fixture project | `/tmp/phase-4-fixtures/v9-project/` (project + git history + .pack-migration-backup/) | `rm -rf /tmp/phase-4-fixtures/v9-project` | `ls` confirms |
| R10-10 | §5.2 kickoff-paste extract | `/tmp/phase-4-fixtures/kickoff-variant-paste.txt` | `rm -f /tmp/phase-4-fixtures/kickoff-variant-paste.txt` | `ls` confirms |
| R10-11 | §6.5 migration stdout/stderr | `/tmp/phase-4-fixtures/v9-migrate.{stdout,stderr,diff-stat}.txt` | `rm -f /tmp/phase-4-fixtures/v9-migrate.*` | `ls /tmp/phase-4-fixtures/v9-migrate.* 2>&1` returns "No such file" |
| R10-12 | §7.2 detect.sh capture | `/tmp/phase-4-fixtures/test-detect.out.txt` | `rm -f /tmp/phase-4-fixtures/test-detect.out.txt` | `ls` confirms |
| R10-13 | §1.1 pre-flight scratch | `/tmp/phase-4-preflight.txt` | `rm -f /tmp/phase-4-preflight.txt` | `ls` confirms |
| R10-14 | §3.2.3 F3 PATH stub | `/tmp/phase-4-fixtures/F3-bin/xcrun` (exec stub) + PATH env modification | `PATH="${PATH#/tmp/phase-4-fixtures/F3-bin:}"; rm -rf /tmp/phase-4-fixtures/F3-bin` | `which xcrun` returns `/usr/bin/xcrun` (NOT the stub); `ls -ld /tmp/phase-4-fixtures/F3-bin 2>&1` returns "No such file or directory" |

| R10-15 | §6.5.4 OT clone via `git clone --no-hardlinks` | `/tmp/phase-4-fixtures/ot-project/` (full clone with `.git/` history; ≥ a few hundred MB) | `rm -rf /tmp/phase-4-fixtures/ot-project` | `ls -ld /tmp/phase-4-fixtures/ot-project 2>&1` returns "No such file or directory" |
| R10-16 | §6.5 / §6.7 OT-related scratch files | `/tmp/phase-4-fixtures/ot-baseline.txt`, `ot-migrate.{stdout,stderr,status-count,diff-stat}.txt`, `ot-vp.{stdout,stderr}.txt`, `evidence-OT-{form-r,final}.txt`, `kickoff-paste-OT.txt`, `cmp.{syn,ot,common,syn-only,ot-only}-paths.txt`, `cmp.ot-only-toplevel.txt`, `cmp.{syn,ot}-vp.{stdout,stderr}`, `cmp.{stdout-diff,syn-5r,ot-5r,5r-diff,summary}.txt` | `rm -f /tmp/phase-4-fixtures/ot-* /tmp/phase-4-fixtures/cmp.* /tmp/phase-4-fixtures/kickoff-paste-OT.txt /tmp/phase-4-fixtures/evidence-OT-*` | `ls /tmp/phase-4-fixtures/ot-* /tmp/phase-4-fixtures/cmp.* 2>&1` returns "No such file or directory" |
| R10-17 | §6.5.7 / §6.7.9 OT live-repo byte-identity verification | (no state created; this is a read-only verification step) | n/a — read-only | `git -C /Users/david/Developer/OptiquityTrader/ status --porcelain` returns empty AND `git -C /Users/david/Developer/OptiquityTrader/ rev-parse HEAD` matches the §6.5.3 baseline (recorded in the §4.6 evidence block). |

### 10.1 Single-command full-rollback

After C-V10-15 lands and Gate F is approved, all `/tmp/` state can be
torn down with one command. **Important: also restore PATH if the
F3 stub was used** — the stub PATH modification is process-local, but
if the implementer is still in the shell where they exported it,
restoring is required:

```bash
# If F3 stub was used, restore PATH first.
PATH="${PATH#/tmp/phase-4-fixtures/F3-bin:}"

# Then tear down all /tmp/ state.
rm -rf /tmp/phase-4-fixtures /tmp/v9-pack-source /tmp/phase-4-preflight.txt
ls -ld /tmp/phase-4-fixtures /tmp/v9-pack-source /tmp/phase-4-preflight.txt 2>&1
# Expect: three "No such file or directory" lines.

# Sanity: confirm xcrun resolves to the real binary.
which xcrun
# Expect: /usr/bin/xcrun

# v2 addition — verify live OT repo is byte-identical to its §6.5.3 baseline
# (the §6.5.3 baseline SHA is recorded in the C-V10-15 §4.6 evidence block;
# the implementer reads it from there to perform the equality check).
OT_LIVE=/Users/david/Developer/OptiquityTrader
git -C "$OT_LIVE" status --porcelain
# Expect: empty (clean working tree).
git -C "$OT_LIVE" rev-parse HEAD
# Expect: matches §6.5.3 baseline SHA recorded in V10-PHASE-4-VERIFICATION.md.
git -C "$OT_LIVE" rev-parse --abbrev-ref HEAD
# Expect: matches §6.5.3 baseline branch recorded in V10-PHASE-4-VERIFICATION.md.
```

The v2 addition above does NOT delete anything from the live OT repo
— it is read-only verification that confirms cleanup left zero trace
on the source. This is the canonical post-cleanup safety check for
§0.8.2 row 3.

This is the canonical Phase-4 cleanup. Run it as the last step of
C-V10-15 evidence capture (after the V10-PHASE-4-VERIFICATION.md file
is written and reviewed) — recorded as a single line in the §4.x
cleanup field.

### 10.2 Rollback for partial-failure states

If §4.1 / §4.2 / §4.4 is interrupted mid-run (e.g., implementer pauses
for an F-B / F-G decision), **do NOT rollback partial fixture state
yet.** Leave fixtures in place so resume can pick up cleanly. The
fixture base `/tmp/phase-4-fixtures/` is volatile across reboots, so
even an indefinite pause is tolerable.

When a fixture is permanently abandoned (e.g., F-G escalates to a
v10.0 hold and the pack drops back to a `fix:` cycle), the
implementer:

1. Notes the abandoned-fixture state in the V10-PHASE-4-VERIFICATION.md
   §4.x evidence block (mark the row "incomplete — fixture preserved
   for resume").
2. Decides whether to retain or tear down the fixture; default is
   tear down (per §10.1 single-command rollback) and reconstruct on
   resume.

### 10.3 What never gets rolled back from `/tmp/`

Nothing. Every `/tmp/` artifact created by this plan has a rollback
row. If during execution the implementer creates additional `/tmp/`
state not covered here, **add a row to §10 before proceeding**.

### 10.4 What is never created OUTSIDE `/tmp/`

The v2 OT additions explicitly never write to:

- `/Users/david/Developer/OptiquityTrader/` (the live OT repo —
  read-only throughout per §0.8.2 row 1).
- Any GitHub remote (no `git push` from any clone — §0.8.2 row 2).
- The pack worktrees (`$PACK` and `/Users/david/Developer/dhs-ai-
  agent-config-pack`) — read-only throughout per v1 §0.4 row 3.
- Any path under `~/Library/` or other user-home machine-level
  locations (Form M `skip` discipline per v1 §3.3).

If the implementer discovers that any §4.6 / §4.7 / §4.8 step has
written outside `/tmp/`, that is a hard safety violation; flag-back
F-I (proposed).

---

## Part 11 — Gate-F-readiness entry checklist (prerequisites for C-V10-15 execution)

C-V10-15 may begin only when all rows below are true. Run each check
verbatim; capture the output for the C-V10-15 commit-approval request.

| # | Check | Command | Expected |
|---|---|---|---|
| 1 | C-V10-14 landed cleanly | `git -C "$PACK" log --oneline -1` | First word of message: `feat:`; subject mentions `test-detect.sh`. SHA is `459161b…` or descendant. |
| 2 | v10-dev tip is at or descended from `459161b` | `git -C "$PACK" merge-base --is-ancestor 459161b HEAD && echo OK` | `OK` |
| 3 | `PACK` exported to v10-dev | `echo "$PACK"` | `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev` |
| 4 | Working tree clean | `git -C "$PACK" status --porcelain` | empty |
| 5 | On `v10-dev` branch | `git -C "$PACK" rev-parse --abbrev-ref HEAD` | `v10-dev` |
| 6 | `validate-pack.py` passes at HEAD | `python3 "$PACK/scripts/validate-pack.py"` | exit 0 |
| 7 | `test-detect.sh` passes at HEAD | `bash "$PACK/scripts/test-detect.sh" \| tail -1` | `=== Results: 34 passed, 0 failed ===` |
| 8 | v9.3 tag resolvable | `git -C "$PACK" rev-parse v9.3` | non-empty SHA |
| 9 | `/tmp/phase-4-fixtures/` available (writable, no stale fixtures) | `mkdir -p /tmp/phase-4-fixtures && ls /tmp/phase-4-fixtures` | empty (or pre-existing fixtures from a prior run that the implementer accepts via §10.1 cleanup before starting) |
| 10 | Surface-availability pre-flight (Part 1) recorded | Part 1 §1.1 commands run; results captured to `/tmp/phase-4-preflight.txt` | F-B fired only if a surface is missing; project lead resolution noted |
| 11 | `V10-PHASE-4-VERIFICATION.md` does NOT yet exist | `ls "$PACK/maintenance-docs/V10-PHASE-4-VERIFICATION.md" 2>&1` | "No such file or directory" |
| 12 | Live pack worktree (`/Users/david/Developer/dhs-ai-agent-config-pack`) is independent | `git -C /Users/david/Developer/dhs-ai-agent-config-pack rev-parse --abbrev-ref HEAD` | `main` (NOT v10-dev — this plan never touches the live worktree) |
| 13 *(v2)* | Live OT repo at `/Users/david/Developer/OptiquityTrader/` exists, is git-managed, and is on a clean working tree | `[[ -d /Users/david/Developer/OptiquityTrader/.git ]] && git -C /Users/david/Developer/OptiquityTrader status --porcelain \| wc -l` | First test passes; second returns `0` (empty porcelain). If row fails, §4.6 / §4.7 / §4.8 are skipped for this C-V10-15 (project lead may opt to defer OT verification to a follow-up commit) — NOT a v1-scope blocker. |
| 14 *(v2)* | `/tmp` has ≥1 GB free | `df -k /tmp \| awk 'NR==2 { print $4 }'` | ≥ 1048576 (≈1 GB). If less, free space first or skip §4.6 / §4.7 / §4.8. |
| 15 *(v2)* | OT-related target paths under `/tmp/phase-4-fixtures/` are clear | `ls /tmp/phase-4-fixtures/ot-* /tmp/phase-4-fixtures/cmp.* /tmp/phase-4-fixtures/kickoff-paste-OT.txt /tmp/phase-4-fixtures/evidence-OT-* 2>&1 \| head -1` | "No such file or directory" (no stale state from a prior C-V10-15 attempt). If stale state exists, run R10-15 + R10-16 cleanup first. |

If any row 1–12 fails, **do not start C-V10-15.** Resolve first.
If any row 13–15 fails, **§4.6 / §4.7 / §4.8 are out of scope for
this C-V10-15.** Project lead decides skip vs. defer.

### 11.1 Approval surface for C-V10-15

Beyond the entry checklist, the C-V10-15 commit itself follows the
`V10-PHASE-4-PLAN.md` Part 7 per-commit verification checklist:

- Staged file is exactly one: `maintenance-docs/V10-PHASE-4-VERIFICATION.md`.
- Diff scope ~150–300 lines added (per Part 3 of Phase 4 Plan).
- All five sections present (§4.1, §4.2, §4.3, §4.4, §4.5).
- Every fail / unavailable entry references a Part 8 flag-back row.
- `validate-pack.py` exits 0 post-stage.
- Approval gate **G-V10-15** before `git commit`.

### 11.2 v2 evidence-presence checklist (§4.6 / §4.7 / §4.8 additions)

If §4.6 / §4.7 / §4.8 are in scope for this C-V10-15 (per row 13–15
of §11 and project-lead opt-in), the staging step requires these
additional evidence sections to be present in
`maintenance-docs/V10-PHASE-4-VERIFICATION.md` before `git commit`:

| # | Section | Check | Expected |
|---|---|---|---|
| 13 *(v2)* | §4.6 OT migration smoke evidence | Section heading `## §4.6 OT real-project migration smoke` exists; one evidence block populated per §6.5.10. | yes |
| 14 *(v2)* | §4.7 OT post-migration kickoff smoke evidence | Section heading `## §4.7 OT post-migration kickoff smoke (M-OT)` exists; one evidence block populated per §6.6.7. | yes |
| 15 *(v2)* | §4.8 OT-vs-synthetic comparison evidence | Section heading `## §4.8 OT-vs-synthetic comparison` exists; one evidence block populated per §6.7.7 with the migration-stdout diff and the path-normalized Procedure 5-R prompt diff. | yes |
| 16 *(v2)* | §4.6 evidence records the §6.5.3 OT live-repo baseline (HEAD SHA + branch) | Search the §4.6 block for "HEAD SHA: " and "Branch: " lines. | both present, both are non-empty values matching the §6.5.3 capture. |
| 17 *(v2)* | §6.5.7 / §6.7.9 live-repo unchanged verification recorded | Search the §4.6 + §4.8 blocks for "OT HEAD SHA unchanged" / "OT working tree still clean" lines. | both lines present, both `OK:`. |
| 18 *(v2)* | §4.7 evidence sanitization audit recorded | Implementer notes one-line sanitization-audit confirmation in the §4.7 evidence block (e.g., "Sanitization audit: no OT source body / OT-derived names enumerated; only counts and pack-generated text quoted."). | line present. |
| 19 *(v2)* | Updated Summary table includes §4.6 / §4.7 / §4.8 rows | Pre-commit grep on the Summary table. | three rows present (or three rows with "DEFERRED" if the project lead opted out before §4.6 began). |

If any row 13–15 / 16–19 fails AND §4.6 / §4.7 / §4.8 were in scope,
**do not commit.** Either complete the missing capture or, with
project-lead approval, drop the §4.6 / §4.7 / §4.8 sections and
record the deferral in the Summary table; the latter changes the
commit's scope and requires explicit approval at G-V10-15.

---

## Part 12 — Open questions for the project lead

Status legend: **RESOLVED** = decided pre-execution per §0.6 / §0.7;
**MOOT** = no longer applies after a related decision; **DEFERRED** =
needs execution context to answer.

1. **OQ-VP4-1 — Desktop Commander confirmation method.** **MOOT.**
   §0.6 deferred Desktop Commander to the §4.2 docs-research pass;
   no live-presence check is required. Original question: is the
   project lead comfortable with self-reported Desktop Commander
   availability vs. a config-file check? Resolution: irrelevant under
   docs-research scope.

2. **OQ-VP4-2 — F3 simulator stub method.** **RESOLVED — PATH-based
   stub** (§0.6, gap-#4 decision). §3.2.3 uses a fixture-local
   `/tmp/phase-4-fixtures/F3-bin/xcrun` script that the agent really
   invokes; the stub returns empty for `simctl list devices available`
   and passes through every other invocation. Real subprocess +
   exit code + stdout — no chat-side fakery.

3. **OQ-VP4-3 — F2 multi-scheme disambiguation reply.** **DEFERRED to
   execution context.** Whether the model genuinely re-prompts for a
   scheme name (per Procedure 7 §7.5) or auto-picks must be observed
   live. F2 only fires under hybrid-expansion scope (§0.7 step 7), so
   this OQ may not need to be resolved for v10.0 if minimal scope
   holds. Default if F2 runs: auto-pick = fail (defect, Procedure 7
   requires explicit disambiguation).

4. **OQ-VP4-4 — §4.4 fixture realism.** **RESOLVED — thin v9.3
   fixture for v10.0** (§0.6). §6.4 builds the minimal fixture; a
   richer v9.3 fixture (x-files, custom skills, populated
   PROMPT-TEMPLATES.md) is a v10.1 candidate. BACKLOG entry to be
   filed if this resolution holds at Gate F.

5. **OQ-VP4-5 — Evidence-file size discipline.** **RESOLVED — verbatim
   beats abbreviation; no hard ceiling** (§0.6). The file is one-shot
   reference, not steady-state; reviewer cost is one-time. Implementer
   does not abbreviate Form R / Form E outputs.

6. **OQ-VP4-6 — Network egress for §6.3 clone.** **RESOLVED — local
   clone from `/Users/david/Developer/dhs-ai-agent-config-pack`**
   (§0.6). §6.3 was rewritten to clone from the live pack repo
   (which has the v9.3 tag locally), eliminating network dependency
   and sidestepping the private-repo HTTPS auth issue. No offline-
   fallback needed.

7. **OQ-VP4-7 — Brew-install escalation wording.** **MOOT.** §0.6
   deferred Codex CLI live runs to the §4.2 docs-research pass; the
   docs-research pass cites the V10-PHASE-3B-DESIGN-v2 Part 3 §3.2
   wording as the documented expectation, without comparing against a
   live Codex output. Original question (live wording exact-match vs.
   equivalent) is not asked under docs-research scope.

8. **OQ-VP4-8 — Proposed F-I flag-back for OT real-project safety
   violations and baseline mismatches** *(v2; OPEN, awaiting
   project-lead approval)*.

   The v2 OT additions surface a class of risks that does not map
   cleanly onto v1's existing F-A..F-H flag-backs in
   `V10-PHASE-4-PLAN.md` Part 8. Specifically:

   - **OT-baseline mismatch.** §6.5.5 finds OT lacks the v9.3
     baseline invariants (PROMPT-TEMPLATES.md, ≥16 pack agents,
     `.gemini/agents/`, `docs/pack/PLATFORM-SKILLS.md`). This is
     neither a migration-script defect (F-G) nor a v10.1 candidate
     (F-E) — it is "OT is not the v9.3-shaped fixture we expected".
     The right action is to abort §4.6 / §4.7 / §4.8 cleanly; the
     decision (skip OT verification for v10.0 vs. wait for OT to
     re-align) is project-lead-side.
   - **OT live-repo safety violation.** §6.5.7 / §6.7.9 detects that
     the live OT repo was modified during execution (HEAD SHA
     drift, working-tree dirt, branch drift). This is a hard safety
     violation that requires immediate pause + forensic preservation
     of the clone + project-lead notification. Not F-G (migration
     script may have nothing to do with it; could be a CLI-session-
     side error) and not F-E.
   - **OT-content sanitization slip.** Implementer notices late
     that the §4.6 / §4.7 / §4.8 evidence block contains OT source
     code or OT-derived names beyond the per-field sanitization
     rules. NOT a flag-back per se — implementer-correctable before
     commit. Listed here for completeness; if a sanitization slip
     reaches commit and is detected post-commit, that becomes a
     separate `fix:` commit and is out of Phase 4 scope.

   **Proposed F-I — OT real-project verification baseline mismatch
   or safety violation** (text for project lead to approve / reject /
   modify before C-V10-15 execution):

   > If during §4.6 / §4.7 / §4.8 execution the implementer detects
   > (a) OT does not satisfy the v9.3 baseline invariants per §6.5.5,
   > or (b) the live OT repo at `/Users/david/Developer/OptiquityTrader/`
   > is modified at any point (HEAD SHA drift, working-tree dirt,
   > branch drift) detected at §6.5.7 or §6.7.9:
   >
   > **Pause point:** at detection.
   > **Decision needed:** (a) for baseline mismatch — skip OT
   > verification for v10.0, defer to follow-up commit, or wait for
   > OT to re-align? (b) for safety violation — preserve clone as
   > forensic evidence, investigate root cause, decide whether
   > C-V10-15 must be reverted or whether the violation is benign
   > (e.g., a developer manually modified live OT in another
   > session unrelated to verification).
   > **Default if unclear:** flag-back; do NOT silently skip §4.6 /
   > §4.7 / §4.8 (that is F-E silent scope expansion-by-omission).

   **Implementer note.** F-I is referenced throughout v2's runbooks
   (§6.5.2 / §6.5.5 / §6.5.7 / §6.5.12 / §6.6.9 / §6.7.9 / §10.4)
   on the assumption that project lead will approve it. If project
   lead rejects F-I, the implementer treats those failure modes as
   F-G (defects) instead — which has the same "v10.0 hold" default
   and slightly different decision wording.

---

## Part 13 — Manual-step instructions (developer-facing)

These are the explicit, copy-pasteable instructions for **every** step
the developer (project lead) executes during C-V10-15. The implementer
(this CLI session) handles fixture construction, paste-file generation,
migration smoke, docs-research, evidence assembly, and cleanup. The
developer's only manual touchpoints are listed here.

Under hybrid scope (§0.7 minimal path), the developer executes **M1**
and **M2** only. **M3..M7** are conditional on v1 hybrid expansion to
F2..F6 fixtures. **M-OT** is a v2 addition (§4.7 OT post-migration
kickoff smoke); it is conditional on v2 OT additions being in scope
for this C-V10-15 (§0.8 / §11.1 row 13 / §11.2).

Each manual step assumes:

- The implementer has reported "ready for **M-N**" in this CLI session.
- The relevant fixture and paste file exist (the implementer confirms
  this before handing off).
- The developer has at least two terminal windows open (or one terminal
  + one browser) at the same time.

### M1 — Run §4.1 F1 smoke in a separate `claude` session

**When:** After the implementer reports "F1 fixture built; paste file
at `/tmp/phase-4-fixtures/kickoff-paste-F1.txt`; ready for M1."

**Estimated time:** 5–10 minutes (mostly waiting on the assistant).

**Where:** A NEW terminal window (NOT the one this CLI session is
running in).

**What you'll do:** Open a fresh `claude` session inside the F1
fixture, paste the kickoff variant, walk through Form R / E / I / M,
and save the assistant's outputs to two evidence files.

**Steps:**

1. Open a new terminal window.
2. Run:

   ```bash
   cd /tmp/phase-4-fixtures/apple-spm-single-scheme
   ```

3. Confirm the paste file is present:

   ```bash
   ls -la /tmp/phase-4-fixtures/kickoff-paste-F1.txt
   ```

   Expect: a file ~70 lines long. If missing, stop and tell the
   implementer.

4. Optionally peek at the paste content:

   ```bash
   cat /tmp/phase-4-fixtures/kickoff-paste-F1.txt | head -30
   ```

5. Copy the paste content to your clipboard:

   ```bash
   pbcopy < /tmp/phase-4-fixtures/kickoff-paste-F1.txt
   ```

6. Start a fresh Claude Code CLI session in this terminal:

   ```bash
   claude
   ```

   You should see the Claude Code CLI prompt.

7. Paste the kickoff variant into the `claude` session (Cmd+V). Press
   Enter to send.

8. Wait for the assistant's reply. Within a turn or two, it should ask
   the surface-declaration question (looks like: "Reply with the single
   word `shell` or `manual` before continuing.").

9. Type exactly: `shell`

   Press Enter.

10. Wait for the assistant to read METHODOLOGY.md Procedure 7 and
    present **Form R** — a code-fenced block headed
    `PROPOSED ACTION — read-only discovery`. The block lists ~11
    discovery commands (xcodebuild, simctl, brew, etc.).

11. Type exactly: `yes`

    Press Enter. The assistant runs the discovery commands.

12. Wait for the assistant's next reply showing the discovery results.
    Once you have the assistant's full reply visible, COPY the entire
    reply (every line of the assistant's message — from the start of
    the message to the next user-input prompt).

13. Save the copied reply to an evidence file. Easiest method:

    ```bash
    # In a third terminal (or pause the claude session with Ctrl+Z and
    # `bg` if you prefer), run:
    open -e /tmp/phase-4-fixtures/evidence-F1-form-r.txt
    # In the editor that opens: paste (Cmd+V), save (Cmd+S), close.
    ```

    Or via clipboard:

    ```bash
    pbpaste > /tmp/phase-4-fixtures/evidence-F1-form-r.txt
    ```

14. Back in the `claude` session: the assistant should now propose
    **Form E** (file edits to validate-swift.sh / test-swift.sh /
    .claude/settings.json / format-swift.sh).

    Type exactly: `skip`

    Press Enter.

15. The assistant should now propose **Form I** (install swift-format
    via brew). Type exactly: `skip`. Press Enter.

16. The assistant should now propose **Form M** (Xcode companion
    files). Type exactly: `skip`. Press Enter.

17. The assistant should now print a "kickoff complete" or equivalent
    summary. COPY the entire summary reply.

18. Save the summary to:

    ```bash
    pbpaste > /tmp/phase-4-fixtures/evidence-F1-final.txt
    ```

19. Exit the `claude` session: type `/exit` (or press Ctrl+D).

20. Return to the terminal running this implementer CLI session and
    say (in chat):

    > **M1 done. Evidence files at:
    > `/tmp/phase-4-fixtures/evidence-F1-form-r.txt`
    > `/tmp/phase-4-fixtures/evidence-F1-final.txt`.**

The implementer will then read those files and ask follow-up questions
if anything looks off.

**If anything diverges (no Form R, error message, surface-declaration
question doesn't fire, assistant tries to actually run brew install
without asking, etc.) — STOP** and tell the implementer what happened.
Do not try to "fix" the assistant's behavior; the test is to observe
what it does.

---

### M2 — Run §4.3 Claude Web manual-mode smoke

**When:** After the implementer reports "Web paste file at
`/tmp/phase-4-fixtures/kickoff-paste-W3.txt`; ready for M2." Can run
in parallel with the implementer's §4.4 migration smoke.

**Estimated time:** 2–3 minutes.

**Where:** Browser at `claude.ai`.

**What you'll do:** Open a fresh non-shell Claude Web chat, paste the
kickoff variant, reply `manual`, and save the assistant's reply to an
evidence file.

**Steps:**

1. Open a browser to `https://claude.ai`.

2. Start a NEW chat. Critical preconditions:

    - **No project** selected (top-left should not show a project
      name; if it does, click "New Chat" without a project).
    - **No GitHub connector** active (if a connector banner shows
      at the top of the chat, dismiss it or start over).
    - **No Desktop Commander / no MCP** — Claude Web has no MCP
      surface by default; just confirm you're at `claude.ai` and
      not Claude Desktop.

3. (Switch to your terminal.) Copy the Web paste file to clipboard:

    ```bash
    pbcopy < /tmp/phase-4-fixtures/kickoff-paste-W3.txt
    ```

4. Switch back to the browser. Paste into the chat input (Cmd+V).
   Press Enter (or click Send).

5. Wait for the assistant's first reply. It may proceed directly to
   the surface-declaration question or first echo back your project
   context.

6. Once the surface-declaration question appears (asking for `shell`
   or `manual`), type exactly: `manual`

    Press Enter (or click Send).

7. Wait for the assistant's next reply. It should be SHORT (a few
   lines) and contain wording like:

    > On `manual`: I will point you at `supporting-docs/SETUP-NEW.md`
    > § Manual fallback (sub-sections 5.A–5.D) and wait for you to
    > report values back, then compose the corresponding edits for
    > you to apply.

8. COPY the entire assistant reply.

9. (Switch to your terminal.) Save the reply:

    ```bash
    pbpaste > /tmp/phase-4-fixtures/evidence-web-manual.txt
    ```

10. Return to this implementer CLI session and say:

    > **M2 done. Evidence file at
    > `/tmp/phase-4-fixtures/evidence-web-manual.txt`.**

**Pass / fail clues for M2 (what to watch for during step 7):**

- ✅ **PASS:** Reply is short, names `SETUP-NEW.md § Manual fallback`
  and the `5.A–5.D` sub-section range. No tool calls. No inline shell
  commands.
- ⚠️ **SOFT PASS:** Reply paraphrases the pointer but reference is
  unambiguous and contains no tool calls / no command lists. Tell
  the implementer; we'll evaluate together.
- ❌ **FAIL — tool call:** Reply contains text like "let me run
  xcodebuild..." with actual command output, OR a `<tool_use>` block.
  Stop, tell the implementer; this is a defect.
- ❌ **FAIL — inline command summary:** Reply contains a fenced shell
  block with `xcodebuild`, `brew install`, etc. instead of pointing
  at SETUP-NEW.md. Stop, tell the implementer; this is a defect.

---

### M-OT — Run §4.7 OT post-migration kickoff smoke (CONDITIONAL on v2 OT additions in scope)

**When:** ONLY if §4.6 OT migration smoke completed cleanly and the
project lead has opted into the v2 OT additions tier (§0.8). The
implementer reports: "OT clone migrated; paste file at
`/tmp/phase-4-fixtures/kickoff-paste-OT.txt` (~70 lines, OT project
name pre-filled); ready for M-OT."

**Estimated time:** 10–15 minutes (slightly longer than M1 because
OT is a real project — Form R discovery commands run against real
OT state and may take longer than synthetic).

**Where:** A NEW terminal window (NOT the one this CLI session is
running in, NOT a window already inside the live OT repo).

**What you'll do:** Open a fresh `claude` session inside the
post-migration OT clone (`/tmp/phase-4-fixtures/ot-project/`), paste
the OT-tailored kickoff variant, walk through Form R / E / I / M,
and save the assistant's outputs to two evidence files. The
developer-side discipline is identical to M1; the only differences
are (a) the working directory is the OT clone, (b) the paste file
is OT-tailored, (c) evidence files are named `evidence-OT-*.txt`,
(d) the developer must NEVER `cd` into `/Users/david/Developer/
OptiquityTrader/` during this session (M-OT operates on the clone
only).

**Critical safety rule.** Before starting `claude`, confirm `pwd`
is `/tmp/phase-4-fixtures/ot-project/` (NOT `/Users/david/Developer/
OptiquityTrader/`). If `pwd` shows the live OT path, STOP, exit,
re-`cd` to the clone, verify with `pwd` again. The clone path
ALWAYS starts with `/tmp/`.

**Steps:**

1. Open a new terminal window.

2. `cd` into the OT clone (NOT live OT):

   ```bash
   cd /tmp/phase-4-fixtures/ot-project
   pwd
   ```

   Expected output: `/tmp/phase-4-fixtures/ot-project`

   **If the output is `/Users/david/Developer/OptiquityTrader` or
   anything else, STOP.** Re-run `cd /tmp/phase-4-fixtures/ot-project`
   and verify with `pwd` again. M-OT cannot proceed until `pwd` is
   the clone path.

3. Confirm the paste file is present:

   ```bash
   ls -la /tmp/phase-4-fixtures/kickoff-paste-OT.txt
   ```

   Expect: a file ~70 lines long. If missing, stop and tell the
   implementer.

4. Optionally peek at the paste content:

   ```bash
   head -30 /tmp/phase-4-fixtures/kickoff-paste-OT.txt
   ```

   You should see the kickoff variant body with OT's project name
   filled in instead of `[PROJECT_NAME]`.

5. Copy the paste content to your clipboard:

   ```bash
   pbcopy < /tmp/phase-4-fixtures/kickoff-paste-OT.txt
   ```

6. **Re-confirm `pwd`** (defense-in-depth — `pbcopy` does not change
   directory, but the discipline is to verify before every `claude`
   invocation):

   ```bash
   pwd
   ```

   Expected output: `/tmp/phase-4-fixtures/ot-project`. If anything
   else, STOP and re-cd.

7. Start a fresh Claude Code CLI session in this terminal:

   ```bash
   claude
   ```

   You should see the Claude Code CLI prompt. The session's working
   directory is now `/tmp/phase-4-fixtures/ot-project/` — the
   migrated OT clone.

8. Paste the kickoff variant into the `claude` session (Cmd+V).
   Press Enter to send.

9. Wait for the assistant's reply. Within a turn or two, it should
   ask the surface-declaration question (looks like: "Reply with the
   single word `shell` or `manual` before continuing.").

10. Type exactly: `shell`

    Press Enter.

11. Wait for the assistant to read METHODOLOGY.md Procedure 7 and
    present **Form R** — a code-fenced block headed
    `PROPOSED ACTION — read-only discovery`. The block lists ~11
    discovery commands (xcodebuild, simctl, brew, pyproject.toml
    detection, etc.).

12. Type exactly: `yes`

    Press Enter. The assistant runs the discovery commands AGAINST
    THE OT CLONE. This may take longer than synthetic because OT
    is a real project — `xcodebuild -list` runs against OT's actual
    Package.swift / Xcode project; `simctl` enumerates real
    simulators; etc.

13. Wait for the assistant's next reply showing the discovery
    results. Once you have the assistant's full reply visible, COPY
    the entire reply (every line of the assistant's message — from
    the start of the message to the next user-input prompt).

14. Save the copied reply to an evidence file:

    ```bash
    pbpaste > /tmp/phase-4-fixtures/evidence-OT-form-r.txt
    ```

    (You can do this in a third terminal, or pause `claude` with
    Ctrl+Z and `bg`, or use `open -e` on the evidence-file path
    and paste in TextEdit. Choose whichever you prefer.)

15. Back in the `claude` session: the assistant should now propose
    **Form E** (file edits to validate-swift.sh / test-swift.sh /
    .claude/settings.json / format-swift.sh, with values derived
    from OT's actual scheme list and simulator list).

    Type exactly: `skip`

    Press Enter.

    **Why `skip`:** OT is a real project, but the OT clone is
    ephemeral (gets deleted at §6.7.9 cleanup). Persisting Form E
    edits to the clone adds nothing to the evidence record (the
    proposed diff is captured verbatim by the implementer). Form E
    `yes` would also commit OT-derived values to the clone's git
    history, which is fine but unnecessary.

16. The assistant should now propose **Form I** (install
    swift-format via brew, possibly grpcio-tools via uv if OT has
    a `proto/` directory). Type exactly: `skip`. Press Enter.

    **Why `skip`:** Form I `yes` runs `brew install` for real,
    which is a machine-level side effect. We do NOT want that for
    a smoke test.

17. The assistant should now propose **Form M** (Xcode companion
    files batch). Type exactly: `skip`. Press Enter.

    **Why `skip`:** Form M `yes` writes to
    `~/Library/Developer/Xcode/CodingAssistant/` machine-level. Do
    NOT do that.

18. The assistant should now print a "kickoff complete" or
    equivalent summary. COPY the entire summary reply.

19. Save the summary to:

    ```bash
    pbpaste > /tmp/phase-4-fixtures/evidence-OT-final.txt
    ```

20. Exit the `claude` session: type `/exit` (or press Ctrl+D).

21. **Re-confirm live OT repo is unchanged.** This is the M-OT
    safety check — it runs even though M-OT operated on the clone,
    because we want belt-and-suspenders coverage.

    ```bash
    git -C /Users/david/Developer/OptiquityTrader status --porcelain
    ```

    Expected output: (empty — no lines)

    ```bash
    git -C /Users/david/Developer/OptiquityTrader rev-parse HEAD
    ```

    Expected output: a SHA. The implementer's §6.5.3 baseline file
    has this SHA recorded; the implementer will confirm match.

22. Return to the terminal running this implementer CLI session and
    say (in chat):

    > **M-OT done. Evidence files at:**
    > **`/tmp/phase-4-fixtures/evidence-OT-form-r.txt`**
    > **`/tmp/phase-4-fixtures/evidence-OT-final.txt`.**
    > **Live OT repo `git status --porcelain` returned empty;
    > HEAD SHA is `<paste the SHA from step 21>`.**

The implementer will then read those files (applying §6.6.7
sanitization rules before any content reaches
`V10-PHASE-4-VERIFICATION.md`) and ask follow-up questions if
anything looks off.

**Pass / fail clues for M-OT (what to watch for during steps
11–18):**

- ✅ **PASS:** Surface-declaration question fires; Form R composes
  and runs against OT real state; Form E proposes edits to the right
  pack-managed files (the `*-swift.sh` / `*-python.sh` wrappers and
  `.claude/settings.json` env block — NOT regex-style edits to JSON);
  Form I lists pack-defined install commands; Form M proposes the
  companion-files batch with `cmp -s` byte-identity check; `skip`
  replies are honored; final summary fires.

- ⚠️ **SOFT PASS:** Form R reports an OT-specific deviation from
  what synthetic would show (e.g., F2-style multi-scheme prompt
  fires because OT genuinely has multiple schemes; or §7.4 row 4
  declines because OT has unusual Apple state). This is NOT a
  defect — it is the §4.8 comparison's signal. Tell the implementer
  what you observed so they can capture it in the §4.7 evidence.

- ❌ **FAIL — surface-declaration question doesn't fire:** Defect.
  Stop, tell the implementer; pm-chat.md kickoff variant defective
  on real-project complexity.

- ❌ **FAIL — Form E proposes a regex-style edit to
  `.claude/settings.json`:** Defect (Procedure 7 §7.2.2 forbids
  regex on JSON). Stop, tell the implementer.

- ❌ **FAIL — Form M proposes destructive overwrite without `cmp -s`:**
  Defect. Stop, tell the implementer.

- ❌ **FAIL — assistant tries to execute `brew install` or
  machine-level `cp` without asking:** Defect. Stop, tell the
  implementer.

- ❌❌ **HARD-FAIL — `pwd` was inside `/Users/david/Developer/
  OptiquityTrader/` instead of the clone at any point during steps
  7–20:** STOP IMMEDIATELY. Do NOT execute any further commands in
  the `claude` session — type `/exit` first. Run step 21 (live OT
  status check) IMMEDIATELY. Report to implementer with the live OT
  status output. The implementer will run forensic comparison
  against the §6.5.3 baseline and decide whether F-I (proposed)
  fires.

**If anything diverges (no Form R, error message, surface-declaration
question doesn't fire, assistant tries to actually run brew install
without asking, etc.) — STOP** and tell the implementer what
happened. Do not try to "fix" the assistant's behavior; the test is
to observe what it does.

**One-paragraph script for the report-back wording (copy verbatim,
substituting your actual outcome and SHA):**

> M-OT done. Evidence files at
> `/tmp/phase-4-fixtures/evidence-OT-form-r.txt` and
> `/tmp/phase-4-fixtures/evidence-OT-final.txt`. Live OT
> `git status --porcelain` returned empty; HEAD SHA is
> `<sha-from-step-21>`. Outcome: `<pass / soft pass / fail>`.
> Notes: `<one-line summary of any deviation, or "no notes">`.

---

### M3..M7 — Run §4.1 F2..F6 smokes (CONDITIONAL on hybrid expansion)

**When:** ONLY if §4.1 F1 (M1) succeeded and the project lead opts
to expand coverage to corner cases (§0.7 step 7). Implementer will
explicitly ask before kicking off any of M3..M7.

**Estimated time:** 5–10 minutes per fixture.

**Pattern:** Identical to M1, with these per-fixture substitutions:

| ID | Fixture | Paste file | Evidence files |
|---|---|---|---|
| M3 | F2 `apple-multi-scheme` | `/tmp/phase-4-fixtures/kickoff-paste-F2.txt` | `evidence-F2-form-r.txt`, `evidence-F2-final.txt` |
| M4 | F3 `apple-no-simulator` | `/tmp/phase-4-fixtures/kickoff-paste-F3.txt` | `evidence-F3-form-r.txt`, `evidence-F3-final.txt` |
| M5 | F4 `apple-non-spm-layout` | `/tmp/phase-4-fixtures/kickoff-paste-F4.txt` | `evidence-F4-form-r.txt`, `evidence-F4-final.txt` |
| M6 | F5 `python-grpc-server` | `/tmp/phase-4-fixtures/kickoff-paste-F5.txt` | `evidence-F5-form-r.txt`, `evidence-F5-final.txt` |
| M7 | F6 `python-only` | `/tmp/phase-4-fixtures/kickoff-paste-F6.txt` | `evidence-F6-form-r.txt`, `evidence-F6-final.txt` |

**M4 (F3 no-simulator) special handling.** Before starting `claude`
in step 6 of M1, the F3 PATH stub (§3.2.3) must be active in your
shell:

```bash
cd /tmp/phase-4-fixtures/apple-no-simulator
export PATH="/tmp/phase-4-fixtures/F3-bin:$PATH"
which xcrun                       # MUST show /tmp/phase-4-fixtures/F3-bin/xcrun
xcrun simctl list devices available  # MUST print "== Devices ==" (empty)
claude
# Continue with M1 steps 7–20.
```

After M4 completes, **restore PATH** before any other manual step:

```bash
PATH="${PATH#/tmp/phase-4-fixtures/F3-bin:}"
which xcrun                       # Must show /usr/bin/xcrun
```

Per-fixture pass criteria differ slightly (F2 expects multi-scheme
disambiguation prompt; F3 expects "no destinations" report; F4 expects
SWIFT_SOURCE_DIRS proposal; F5 expects gRPC Form I; F6 expects no
gRPC Form I). The implementer will tell you what to watch for before
each one.

---

### M-Index — How to know which step is next

After each manual step completes, the implementer reports back:

| Reported message | Next step |
|---|---|
| "F1 fixture built; ready for M1." | Run M1. |
| "Web paste file ready; you can run M2 in parallel with §4.4 if you like." | Run M2 any time. |
| "F1 capture good; recommend hybrid expansion to F2 (M3)." | Decide: expand or stop. |
| "F2 fixture built; ready for M3." | Run M3 (only if you opted in). |
| (similarly for M4..M7) | Same pattern. |
| *(v2)* "OT clone migrated; paste file at `/tmp/phase-4-fixtures/kickoff-paste-OT.txt`; ready for M-OT." | Run M-OT (only if v2 OT additions were opted in for this C-V10-15). |
| *(v2)* "M-OT capture good; running §4.8 comparison now." | No action — implementer is autonomous on §4.8. |
| "All manual steps done; assembling evidence file." | No action — wait for commit-approval request. |

**You never proceed to a manual step without an explicit "ready for
M-N" signal from the implementer.** That signal means the fixture is
built, the paste file exists, and any prerequisite stubs are in place.

---

*End of V10-PHASE-4-VERIFICATION-PLAN.md.*
