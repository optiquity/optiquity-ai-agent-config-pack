# RESEARCH-BD-241-EXTERNAL — Naming, Finding, Resuming Spawned Agents (verified capability matrix)

**Agent:** pack-docs-researcher (READ-ONLY, EXTERNAL half) · **Date:** 2026-06-20
**Repo:** optiquity-ai-agent-config-pack-v11-dev @ branch `v11-dev`, HEAD `af73ffb` (MAIN checkout)
**Scope:** BD-241 — verify, against authoritative external sources + observed CLI behavior,
the real mechanics of NAMING / FINDING / RESUMING spawned agents across Claude Code, Codex
CLI, and Antigravity CLI. NO design proposal — facts + capability matrix only.

**Live environment verified:** `claude --version` → `2.1.178 (Claude Code)`;
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is SET in this session. All Claude-side observations
below are measured against this binary unless noted.

---

## 0. TL;DR — three headline verdicts

1. **Claude-only? NO — NOT anymore.** The pack's prior research conclusion ("Codex/Antigravity
   peer-messaging confirmed-absent per Codex issue #12462 + Gemini hub-and-spoke") is **STALE
   as of 2026-06-20**. Codex issue #12462 is now **CLOSED as COMPLETED** (2026-05-02); Codex
   shipped a full multi-agent-v2 (MAv2) tool set (`spawn_agent` / `send_message` /
   `followup_task` / `wait_agent` / `list_agents` / `close_agent` / `resume_agent`, behind the
   `multi_agent_v2` feature flag). Antigravity CLI (`agy`, the Gemini-CLI successor) ships
   inter-agent messaging too: "agents can communicate ... with any other active agent whose ID
   is known," idle agents auto-rewake on message, and `/agents` lists active/completed
   subagents. **BD-241's discoverability concept is now expressible (with caveats) on all
   three CLIs** — though the *find/registry mechanism* the pack builds is still implemented in
   Claude-specific surfaces today. See §5 for the corrected matrix.

2. **Validated lookup precedence (Claude, measured):** `name → agentId → (no separate
   message-id)`. **Both** the spawn `name` AND the auto-generated `agentId` work as
   `SendMessage.to`. Measured in the live session transcript: 38 SendMessage calls — 37 by
   `agentId` (`a`+16 hex), 1 by spawn `name` (`reviewer2-bd204-cdocs`); the name-addressed one
   returned `{"success":true,"message":"Message queued for delivery to reviewer2-bd204-cdocs at
   its next tool round."}`. There is **no distinct "message-id" addressing primitive** for
   subagent recall — the BD-241 "else message-id" tier does not map to a real Claude mechanism
   (flagged §1.4).

3. **Liveness/discovery for SUBAGENTS has no first-class registry API in the SDK/CLI tool
   surface.** Claude's built-in durable registry (`members` array) exists **only for Agent
   TEAMS** (`~/.claude/teams/{team}/config.json`), NOT for the Agent-tool SUBAGENTS the pack
   actually spawns. The `/agents` slash command Running tab lists running subagents
   interactively, and the typeahead shows named running background subagents — but neither is a
   programmatic registry an orchestrator agent can query as a tool. For subagents, the only
   durable on-disk artifact is the per-subagent transcript `agent-{agentId}.jsonl` — i.e. the
   "transcript archaeology" BD-241 wants to eliminate is the *actual current state*. (Confirmed
   §1.5 / §4.)

---

## 1. Claude Code — SUBAGENTS (the Agent/Task tool path the pack uses)

> The BD-241 worked example (`a7202065c22979cf5`) is a **subagent** (a `pack-docs-researcher`
> spawned via the Agent tool), NOT an Agent-Teams teammate. This section is the load-bearing one.

### 1.1 The Agent-tool spawn `name` parameter — VERIFIED it exists and is addressable

**Measured (parent-session transcript Agent tool_use inputs):** every Agent spawn carries the
input keys `['description', 'name', 'prompt', 'run_in_background', 'subagent_type']`. The
orchestrator in this very project HAS been naming spawns: 393 Agent spawns, 367 distinct
`name` values (e.g. `coder-bd204-cdocs`, `reviewer2-bd204-cdocs`, `fixcoder-bd204-cdocs`).
Command: parsed `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack-v11-dev/150d5bad-…jsonl`.

- The `--help` JSON for `--agents` confirms the schema fragment
  `{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}`.
- **Official semantics (Agent-tool description, per BD-241 entry L10):** `name` "Makes it
  addressable via SendMessage({to: name}) while running." This is corroborated empirically (§1.3).

**Uniqueness / collision:** No hard uniqueness enforcement was observed at the Agent-tool spawn
level (367 distinct of 393 — names repeat across cycles, e.g. a `coder-…` reused per BD). The
related SUBAGENT-DEFINITION `name` field (frontmatter, the *type* not the *instance*) IS
required-unique: docs (sub-agents.md L185) — "Keep `name` values unique across the whole tree:
if two files within one scope declare the same name, Claude Code keeps one and discards the
other without warning." That is the agent *type* identity, distinct from the per-spawn instance
`name`. **GAP (flagged):** I found no doc statement of a uniqueness/pattern constraint on the
per-spawn instance `name`; collision behavior for two live spawns sharing an instance name is
UNVERIFIED (see §6).

### 1.2 The auto-generated `agentId` — VERIFIED format + provenance

- **Format:** `a` followed by 16 lowercase hex chars (17 chars total). Measured filenames:
  `agent-a5213f27c0c27688c.jsonl`, `agent-a8749099ea5686a6c.jsonl`, `agent-ab121bc5b74c07c03.jsonl`.
  The BD-241 worked example `a7202065c22979cf5` fits this exactly.
- **Where it is returned:** the Agent tool_result text — measured verbatim:
  > `Async agent launched successfully.`
  > `agentId: a9982c9481ec73991 (internal ID - do not mention to user. Use SendMessage with to: 'a9982c9481ec73991' to continue this agent.)`
- **Where it is durably stored:** `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`
  (confirmed on disk). Doc corroboration: sub-agents.md L834 — "find IDs in the transcript files
  at `~/.claude/projects/{project}/{sessionId}/subagents/`. Each transcript is stored as
  `agent-{agentId}.jsonl`." This IS the "transcript archaeology" path BD-241 cites.
- **Transcript also carries a human-readable `slug`** (top-level JSONL field): measured
  `slug = "purrfect-orbiting-fairy"` for agent `a5213f27c0c27688c`, and an `attributionAgent`
  field = `"pack-architect"` (the subagent TYPE). **GAP/flag:** the `slug` is an
  auto-generated cosmetic id (not the spawn `name`); whether `slug` is addressable via
  SendMessage is UNVERIFIED — I did not observe a SendMessage by slug. The spawn `name`
  (`reviewer2-bd204-cdocs`) does NOT appear as a top-level transcript field on the subagent
  side; it lives in the PARENT session's Agent tool_use `input.name`. So **today the only place
  the spawn `name`↔`agentId` correlation is recorded is the parent session JSONL** — exactly
  the archaeology problem.

### 1.3 SendMessage addressing — VERIFIED: BOTH name AND agentId accepted

Measured in the live parent-session transcript (38 SendMessage tool_use calls):

| `to` value form | count | result |
|---|---|---|
| agentId (`a`+16hex) | 37 | succeeded (resume/shutdown) |
| spawn NAME (`reviewer2-bd204-cdocs`) | 1 | `{"success":true,"message":"Message queued for delivery to reviewer2-bd204-cdocs at its next tool round."}`, `is_error: None` |

This **empirically validates the BD-241 `name → agentId` precedence**: a named-spawn is
reachable by `name`; an unnamed (or name-forgotten) spawn is reachable by `agentId`. The pack's
existing memory `reference_sendmessage_uuid_addressing` already records the same fact
(2026-05-21: UUID addressing works despite the tool description's misleading "never by UUID"
text; shutdown_requests to `a9de19670f308743b` / `a88c576b02642958b` succeeded).

**Doc note (important nuance):** sub-agents.md L820 documents resume via **agentId** only —
"Claude uses the `SendMessage` tool with the agent's ID as the `to` field to resume it." The
agent-teams.md doc documents teammate messaging by **name** (L263–265). So the official docs
split: TEAMMATE→name, SUBAGENT-resume→agentId. **Reality (measured) is more permissive: name
works for subagents too.** This is a doc-vs-behavior discrepancy worth the architect noting —
the pack should rely on the *measured* behavior but flag that the docs only *guarantee* agentId
for subagent resume.

### 1.4 "message-id" tier — NO real mapping (FLAGGED gap)

BD-241 lists a fallback `... → message-id → whatever works`. I found **no SendMessage/Agent
addressing primitive keyed on a "message id."** `SendMessage.to` accepts a teammate/subagent
**name** or **agentId**; there is no third "message-id" handle for agent *recall*. (Individual
messages/tool-uses have UUIDs in the transcript, but those address *messages*, not *agents*,
and are not a SendMessage target.) **Recommendation to architect:** treat the BD-241
"message-id" tier as a non-existent primitive — the real precedence is `name → agentId →
(transcript archaeology / re-spawn)`. Flagging rather than silently dropping.

### 1.5 Subagent resume / liveness / persistence — VERIFIED semantics

- **`SendMessage` requires Agent Teams flag.** sub-agents.md L820: "The `SendMessage` tool is
  only available when agent teams are enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`."
  Confirmed: the flag IS set in this session and SendMessage works. **So even the SUBAGENT
  resume-by-agentId path depends on the experimental Agent-Teams flag.**
- **Auto-resume of a STOPPED subagent.** sub-agents.md L832: "If a stopped subagent receives a
  `SendMessage`, it auto-resumes in the background without requiring a new `Agent` invocation."
  This is the "resumed a COMPLETED agent from transcript" behavior BD-241 observed — VERIFIED
  by doc + matches the measured agentId-addressed sends.
- **One-shot agents cannot resume.** sub-agents.md L820: built-in **Explore** and **Plan**
  agents "are one-shot and return no agent ID, so they can't be resumed; use `general-purpose`
  or a custom subagent." (Pack agents are custom subagents → resumable.)
- **Persistence across compaction:** sub-agents.md L836–838 — subagent transcripts persist
  independently; main-conversation compaction does NOT affect them (separate files). VERIFIED
  the separate-file storage on disk.
- **Persistence across session restart:** sub-agents.md L839 — "You can resume a subagent after
  restarting Claude Code by resuming the same session." Resumability is **scoped to the parent
  session**; transcripts are cleaned per `cleanupPeriodDays` (default 30 days, L840).
- **"alive/running" vs "resumable-from-transcript":** these are DISTINCT. A live subagent is
  addressable by name/agentId while running; a *completed/stopped* subagent is not "alive" but
  is *resumable-from-transcript* — sending it a SendMessage auto-resumes it (L832). The pack's
  worktree-isolation model already leans on this ("resumed a completed agent from transcript").
- **No programmatic subagent registry/list tool.** The Running tab of `/agents` lists running
  subagents (sub-agents.md L788, flat list) and named running background subagents appear in the
  `@`-typeahead with status (L677) — but these are INTERACTIVE UI surfaces, not a tool an
  orchestrator subagent can call. **There is no `TaskList`/`AgentList` tool that enumerates live
  subagents with their name↔agentId mapping.** (The Task* tools — TaskCreate/Get/Update/List —
  are the shared-task-list tools for Agent TEAMS, not a subagent registry; see §2.)

---

## 2. Claude Code — AGENT TEAMS (the teammate path — has a built-in registry)

> Distinct from subagents. The pack's sub-agent isolation rules are subagent-based, but Agent
> Teams is the only Claude surface with a **built-in durable agent registry** — directly
> relevant to BD-241's "durable registry the orchestrator consults" goal.

Source: official doc `https://code.claude.com/docs/en/agent-teams` (full text fetched; this page
describes agent teams "as of v2.1.178" — matching the live binary).

- **Built-in registry = the team config `members` array.** agent-teams.md L230: "The team config
  contains a `members` array with each teammate's name, agent ID, and agent type. Teammates can
  read this file to discover other team members." Stored at
  `~/.claude/teams/{team-name}/config.json` where `{team-name}` = `session-` + first 8 chars of
  the session ID (L219–221). **This IS a name↔agentId↔type registry** — the closest existing
  primitive to what BD-241 wants. **CAVEAT:** it is TEAMS-only. **Measured:** `~/.claude/teams/`
  and `~/.claude/tasks/` do **not exist** in this session — confirming agent-teams.md L18: with
  the flag set but **no teammate spawned**, "no team directories are written." The pack spawns
  subagents, not teammates, so this registry is currently **never materialized** for pack work.
- **Teammate addressing is by NAME.** L263–265: "send a message to one specific teammate by
  name ... The lead assigns every teammate a name when it spawns them, and any teammate can
  message any other by that name. To get predictable names you can reference in later prompts,
  tell the lead what to call each teammate."
- **Task tools (TaskCreate/TaskGet/TaskUpdate/TaskList)** are the SHARED TASK LIST for teams, not
  an agent registry (agent-teams.md L162–169). `TaskList` lists *tasks*, not *agents* — so it is
  NOT the "list live agents" primitive BD-241 implies.
- **Liveness limitations (teams):** L404 — "**No session resumption with in-process
  teammates**: `/resume` and `/rewind` do not restore in-process teammates. After resuming a
  session, the lead may attempt to message teammates that no longer exist." L407 — "One team per
  session." L408 — "No nested teams." Team CONFIG dir is removed at session end; the TASK LIST
  dir persists (L224). So teammate liveness does NOT survive a session restart, even though
  tasks do.
- **Idle teammate "hidden but addressable":** L91 / L368 — an idle teammate's row hides after 30s
  but "stays running and addressable while hidden"; "send the teammate a message by name to bring
  it back." (Distinct from a *stopped* teammate.)
- **Version note (registry shape changed):** agent-teams.md L18 — `TeamCreate`/`TeamDelete` tools
  **no longer exist** (removed pre-v2.1.178); the `team_name` Agent-tool input "is accepted but
  ignored." So any pack rule that referenced TeamCreate would be stale.

---

## 3. Claude Code — BACKGROUND SESSIONS / agent view (a THIRD, separate layer)

> Source: `https://code.claude.com/docs/en/agent-view` (full text fetched; research preview,
> requires v2.1.139+). **This is NOT the subagent path** but it is the surface that DOES have a
> durable, queryable session registry + named lookup — relevant context the architect should not
> conflate with subagents.

- **Background sessions ≠ subagents/teammates.** agent-view.md L83 (explicit): "Subagents and
  teammates a session spawns aren't listed as separate rows." Agent view tracks sibling Claude
  Code *sessions*, not the Agent-tool children the pack spawns.
- **Durable registry + named lookup EXISTS here:** `~/.claude/daemon/roster.json` ("List of
  running background sessions, used to reconnect after a restart", L484); per-session state
  `~/.claude/jobs/<id>/state.json` (L485). **Measured:** `~/.claude/daemon/` and
  `~/.claude/jobs/` do **not exist** in this environment — agent view's supervisor isn't running
  here (the pack doesn't use background sessions).
- **Programmatic discovery primitive (the real one):** `claude agents --json` (L447) "Print
  active sessions as a JSON array ... Each entry has `cwd`, `kind`, `startedAt` ... Background
  entries also have `id` ... and `state`: `working`/`blocked`/`done`/`failed`/`stopped` ...
  `sessionId` and `name` appear when set." Plus `--name` to set a session display name (L309),
  `claude attach <id>`, `claude logs <id>`, `claude respawn <id>`, `claude rm <id>` (L443–453).
  **This is a genuine name+id registry with a CLI query** — but it addresses SESSIONS, not the
  Agent-tool subagents BD-241 is about. **Flag for architect:** if BD-241 ever needs a *durable,
  process-independent, queryable* registry, the background-session model is the only Claude
  surface that natively provides one — but adopting it would change the spawn model (sessions
  vs subagents), which is a much larger change than BD-241 scopes.

---

## 4. Claude — the discoverability gap, stated precisely (grounds the BD-241 architect)

| Need (BD-241) | Does Claude provide it natively for SUBAGENTS? | Evidence |
|---|---|---|
| Unique NAME at spawn, addressable | YES — Agent-tool `name`; `SendMessage({to:name})` works | measured §1.1/§1.3 |
| agentId fallback addressing | YES — `SendMessage({to:agentId})`; auto-resume of stopped subagent | measured §1.3; docs L820/L832 |
| "message-id" fallback | NO such primitive | §1.4 |
| Durable REGISTRY the orchestrator consults (name↔agentId↔purpose↔status) | **NO** for subagents. Only the parent-session JSONL records name↔agentId (archaeology). TEAMS has `members` (teams-only, not materialized for subagent spawns); SESSIONS have `roster.json`+`agents --json` (different spawn model) | §1.2, §2, §3 |
| List/enumerate LIVE subagents programmatically (a tool) | **NO** tool. `/agents` Running tab + `@`-typeahead are interactive only | §1.5 (docs L788/L677) |

**Net:** BD-241's *naming* + *agentId/name lookup* are already real and measured. The genuinely
missing piece on Claude is the **durable, orchestrator-consultable registry** mapping
name↔agentId↔purpose↔status for SUBAGENTS — there is no built-in one; the pack must build it as
a discipline/artifact. Today's only record is parent-session transcript archaeology, which is
exactly the BD-241 pain point. This is a verified FACT, not an assumption.

---

## 5. Cross-CLI reality — CORRECTED (prior "confirmed-absent" is STALE)

> **IMPORTANT for the architect:** the pack's existing rules say peer-messaging is "confirmed
> absent" on Codex (issue #12462) and Antigravity/Gemini (hub-and-spoke) — see
> `pack-ops/PACK-MEMORY-RATIONALE.md:193`, `CLAUDE.md:415-416`, and the v11 archive research
> (`maintenance-docs/archive/v11/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md`, retrieved 2026-05-16).
> That conclusion is **now out of date**. Verified refresh below (2026-06-20).

### 5.1 Codex CLI — inter-agent messaging + named recall + resume NOW EXIST (flag-gated)

- **Issue #12462 is CLOSED as COMPLETED** (not "closed as enhancement request"). `gh issue view
  12462 --repo openai/codex` → `state: CLOSED`, `stateReason: COMPLETED`, `closedAt:
  2026-05-02T05:40:00Z`. (Prior pack research described it as an open/enhancement gap.)
- **Merged PRs implementing it (verified via `gh`):**
  - #15556 "feat: new op type for sub-agents communication" — MERGED 2026-03-23
  - #15985 "feat: spawn v2 as inter agent communication" — MERGED 2026-03-27
  - #16010 "feat: add mailbox concept for wait" — MERGED 2026-03-30
  - #26210 "Encrypt multi-agent v2 message payloads" — MERGED 2026-06-05
  - #28561 "Add join key for MAv2 inter-agent messages" — MERGED 2026-06-17
- **The MAv2 tool set (from PR/architecture sources):** `spawn_agent` (returns
  `{ task_name, nickname }`), `send_message` (enqueue, no turn), `followup_task` (enqueue +
  trigger turn; `interrupt:true` preempts), `wait_agent` (wait on mailbox update; returns
  `{message, timed_out}`), **`list_agents`** (list live agents, filterable by `path_prefix`),
  `close_agent`, **`resume_agent`** (resume a previously closed agent by id). This is a
  near-complete analog of BD-241's name→id→list→resume needs.
  (Source: serialx multi-agent architecture gist + merged PR titles; the per-tool spec is from
  community/architecture write-ups, not the official subagents page — see caveat below.)
- **Feature-gated (verify-availability):** the tool set sits behind the `multi_agent_v2` feature
  flag — `gh search code --repo openai/codex "MultiAgentV2"` → `Feature::MultiAgentV2`,
  `config.features.enabled(Feature::MultiAgentV2)`, `features.multi_agent_v2` in
  `codex-rs/core/src/session/config_lock.rs` / `features/src/lib.rs`. This is the Codex analog of
  Claude's `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` — present but flag-gated, not default-on.
- **Official user-facing doc lag:** `https://developers.openai.com/codex/subagents` (fetched)
  documents only `spawn_agent` and **`nickname`** ("Nicknames are presentation-only. Codex still
  identifies and spawns the agent by [name/id]"; `nickname_candidates` example `["Atlas","Delta",
  "Echo"]`) plus a per-agent `name` field (required) and `spawn_agents_on_csv`. It does NOT yet
  document `send_message`/`list_agents`/`resume_agent`/`mailbox`. So on Codex: **named identity
  (`name`) + display `nickname` are GA-documented; the peer-messaging/list/resume tools are
  merged-in-source behind a flag but not in the official subagents doc.**
- **Caveat (open verification item):** I verified the tools are *merged* (gh PRs) and
  *flag-gated* (gh code search). I did NOT exercise the Codex CLI to confirm the tools are
  user-reachable end-to-end on a given install/version (no Codex binary observed here). Treat
  "Codex has it" as: shipped-in-source + flag-gated, NOT yet GA-documented. (verify-availability
  honored: capability exists; *USABLE-on-default-install* is the open caveat.)

### 5.2 Antigravity CLI (`agy`, Gemini-CLI successor) — inter-agent messaging + named recall + auto-rewake EXIST

- **Antigravity CLI = the Gemini-CLI successor** ("the Antigravity CLI (invoked as `agy`) is the
  successor to Gemini CLI"). The pack already renamed Gemini→Antigravity (BD-221), so the prior
  "Gemini hub-and-spoke" finding maps to Antigravity.
- **Inter-agent messaging + named recall (authoritative, antigravity.google sources):** "Agents
  can communicate not only with their direct parents or subagents, but also with **any other
  active agent whose ID is known**. Additionally, **if an idle agent receives a message, it is
  automatically re-awakened** to process the new information." "Agents can view each other's
  conversation transcripts." (Source: antigravity.google/blog I/O-2026 deep dive +
  antigravity.google/docs/subagents.) → This is **direct addressing by agent ID + auto-resume of
  idle agents + cross-transcript visibility** — a strong analog of BD-241's needs, and the
  *opposite* of the prior "hub-and-spoke report-back-only" conclusion.
- **Discovery primitive:** `/agents` opens the subagents panel showing "a list of active and
  completed subagents, including ... status (running, done, killed, etc.) and the current step."
  (Interactive, analogous to Claude's `/agents` Running tab.)
- **Caveat:** addressing is described as "any other active agent **whose ID is known**" — i.e.
  ID-based (not necessarily a stable human-NAME the orchestrator assigns); whether a durable
  queryable registry (vs interactive `/agents` panel) is exposed is UNVERIFIED. Subagent modes:
  built-in roles / generic clones / dynamically registered (`define_subagent`-style), matching
  the pack's existing BD-221 characterization.

### 5.3 Corrected cross-CLI capability matrix

| Capability | Claude Code (subagents) | Codex CLI (MAv2) | Antigravity CLI (`agy`) |
|---|---|---|---|
| Spawn carries human NAME | YES (`name`, measured) | YES (agent `name`; `nickname` display-only) | Partial — addressing is by **ID known**; named-role types yes |
| Address a live agent by NAME | YES (measured) | via `task_name`/agent name (MAv2) | by **ID** (name-addressing not confirmed) |
| Address/resume by ID | YES (`agentId`) | YES (`resume_agent` by id) | YES (by known agent ID; idle auto-rewake) |
| Separate "message-id" recall | NO | NO (message-level only) | NO |
| Auto-resume stopped/idle on message | YES (stopped subagent) | n/a (explicit `resume_agent`) | YES (idle auto-rewake) |
| LIST live agents (programmatic) | NO tool (interactive `/agents` only) | **YES — `list_agents` tool** | Interactive `/agents` panel (programmatic unconfirmed) |
| Durable registry (name↔id↔status) | TEAMS `members` (teams-only, not for subagents) / SESSIONS `roster.json` (diff. model) | mailbox/tree state (MAv2) | cross-transcript visibility; durable registry unconfirmed |
| Gating | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (for SendMessage) | `multi_agent_v2` feature flag | shipped in `agy` 2.0 (GA per I/O-2026) |

**Verdict on the Claude-only question:** BD-241's *concept* (named + id-addressable + resumable
agents, with a discovery primitive) is **achievable in principle on all three CLIs today** — so
the pack should NOT assert "necessarily Claude-only" on capability grounds. HOWEVER: (a) the
pack's *find/registry mechanism* and the spawn discipline are implemented in Claude-specific
surfaces (Agent tool `name`, SendMessage, transcript layout) and the existing trinity exemption
is Claude-scoped; (b) Codex's tools are flag-gated + not-yet-GA-documented and Antigravity's
name-addressing/durable-registry specifics are partly unverified. So the architect's defensible
position is: **the unique-naming discipline applies wherever agents spawn (all CLIs); the
concrete registry+precedence mechanism is built Claude-first, with Codex/Antigravity
applicability now PLAUSIBLE (no longer "confirmed absent") and properly scoped to BD-217 —
because their analogs exist but need their own verification + mapping.** This is a material
correction the architect must carry: do NOT cite "#12462 confirmed absent" — cite "#12462 CLOSED
COMPLETED; Codex MAv2 + Antigravity inter-agent messaging exist; cross-CLI mapping = BD-217."

---

## 6. Explicitly-flagged gaps (could NOT verify — surfaced, not deferred silently)

1. **Per-spawn instance-`name` uniqueness/collision behavior (Claude).** What happens if two
   *live* subagents share the same instance `name` and you SendMessage by that name? UNVERIFIED
   (I observed 367 distinct of 393, with names reused across *sequential* cycles, not
   simultaneously). The architect should treat name-uniqueness as a *discipline the pack must
   enforce*, not a platform guarantee — and may want a quick empirical probe (spawn two
   identically-named live agents, SendMessage by name, observe routing).
2. **`slug` addressability (Claude).** The transcript carries an auto `slug`
   (`purrfect-orbiting-fairy`); I did NOT verify whether `SendMessage({to: slug})` resolves.
   Likely not (slug ≠ name ≠ agentId) but unconfirmed.
3. **Codex MAv2 end-to-end USABILITY on a default install.** Verified merged-in-source +
   flag-gated; NOT exercised against a live Codex binary. The per-tool spec
   (`spawn_agent`/`send_message`/`list_agents`/`resume_agent`/mailbox) is from merged-PR titles +
   community architecture write-ups, NOT the official subagents page (which documents only
   `spawn_agent`+`nickname`+agent `name`). Cross-check before relying on exact tool names.
4. **Antigravity durable-registry + human-NAME addressing.** Verified ID-based addressing +
   idle auto-rewake + `/agents` panel + cross-transcript visibility (authoritative
   antigravity.google sources); did NOT verify a *durable, queryable, name-keyed* registry an
   orchestrator can consult, nor exercise `agy`.
5. **Whether SendMessage-by-name survives across a CONTEXT COMPACTION of the parent
   (Claude).** Subagent transcripts survive compaction (verified, §1.5), but whether the PARENT
   still holds the name↔agentId map after its own compaction (so it can address by name) is
   UNVERIFIED — this is precisely why a durable external registry matters; flagging as a design
   input.

---

## 7. Authoritative facts the architect can build on (no-assumption summary)

- Claude Agent-tool spawn `name` is real, addressable; precedence is `name → agentId` (no
  message-id). [measured]
- `SendMessage` (name or agentId) requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, even for
  subagent resume. [doc L820 + measured]
- Stopped/completed Claude subagent auto-resumes on SendMessage; one-shot Explore/Plan can't
  resume. [doc L820/L832]
- The ONLY durable record of a subagent's name↔agentId today is parent-session JSONL archaeology;
  the `members` registry is teams-only and not materialized for subagent spawns; `roster.json`/
  `claude agents --json` is the (different) background-SESSION model. [measured + docs]
- Cross-CLI: peer-messaging/named-recall/resume are NO LONGER Claude-exclusive — Codex MAv2
  (flag-gated, #12462 CLOSED COMPLETED) and Antigravity `agy` (ID-addressing + auto-rewake +
  `/agents`) both ship analogs. The pack's "confirmed absent" rules are stale and should be
  re-pointed to BD-217 with the corrected evidence. [gh-verified + authoritative web]

**Sources:**
- [Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams)
- [Create custom subagents](https://code.claude.com/docs/en/sub-agents)
- [Manage multiple agents with agent view](https://code.claude.com/docs/en/agent-view)
- [Run agents in parallel](https://code.claude.com/docs/en/agents)
- [Subagents – Codex (OpenAI Developers)](https://developers.openai.com/codex/subagents)
- [Codex issue #12462 (CLOSED COMPLETED)](https://github.com/openai/codex/issues/12462) + PRs [#15556](https://github.com/openai/codex/pull/15556), [#15985](https://github.com/openai/codex/pull/15985), [#16010](https://github.com/openai/codex/pull/16010)
- [Codex Multi-Agent System Architecture (community gist)](https://gist.github.com/serialx/f842f7b41d0f74ff5f64845e4afbc260)
- [Antigravity I/O-2026 feature deep dive](https://antigravity.google/blog/google-io-2026-feature-deep-dive) + [Antigravity subagents docs](https://antigravity.google/docs/subagents)
- Measured: Claude Code v2.1.178 live session transcripts under `~/.claude/projects/.../subagents/agent-*.jsonl`; `gh` queries vs `openai/codex`.

---

## 8. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| verify-availability-not-just-existence | Each capability backed by a measurement or quoted doc, e.g. SendMessage-by-name result `{"success":true,...}` [measured]; Codex MAv2 `Feature::MultiAgentV2` flag in `config_lock.rs` [gh code]; issue #12462 `state:CLOSED stateReason:COMPLETED` [gh]. Codex end-to-end usability + Antigravity registry explicitly flagged as NOT-yet-verified (§6.3/§6.4) rather than asserted. | COMPLIANT |
| researcher-maps-blast-radius (exhaustive; flag gaps) | Covered all 5 BD-241 questions across 3 layers (subagents/teams/sessions) + 3 CLIs; §6 lists 5 explicit unverified gaps (name-collision, slug, Codex E2E, Antigravity registry, parent-compaction). | COMPLIANT |
| graph-first-context (G1/G2) | Graph existence confirmed (`GRAPH EXISTS`); queried graph first for repo agent-addressing docs — returned only fixture noise (external feature not a graph concept) → G2 fallback to grep/Read for repo internals (`grep -rln SendMessage`, read BD-241.md, memory file). | COMPLIANT |
| scope-deliverables-to-the-ask | Delivered exactly a capability matrix + precedence validation + Claude-only verdict + flagged gaps; no design proposal; no sprawl beyond the 5 questions. | COMPLIANT |
| separate-pack-ops-from-product | Report is pack-ops research (to /tmp handoff); no product-file edits; only repo reads were ops docs + memory + transcripts. | COMPLIANT |
| test-infra-self-provisioned (read-only/scratch) | All CLI inspection read-only: `claude --version`/`--help`, `ls`/`find`/`python3` parse of existing transcripts, `gh` read queries. No repo state mutated; no real repo used as a write target. | COMPLIANT |
| agents-never-commit / per-action-approval-sub-agents | No git state-changing verb run; no destructive op; sole write = this report at the named /tmp path. `git rev-parse` (read-only) only. | COMPLIANT |
| rules-applied-verification-block | This block present with quoted evidence per rule. | COMPLIANT |
