# RESEARCH-BD-241-INTERNAL — Repo-state blast-radius census

**Agent:** pack-docs-researcher (READ-ONLY, internal half of BD-241).
**Tree/HEAD (verified at runtime):** MAIN checkout
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch
`v11-dev`, HEAD `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` (`git rev-parse HEAD`).
**Graph:** `graphify-out/graph.json` (present, 19,158,499 bytes,
`.pack-refresh-status` = `ok af73ffb… 2026-06-20T15:21:11Z`).
**Scope:** internal (repo-state) inventory ONLY — NO design. The external/CLI
researcher covers Agent/SendMessage/Agent-Teams/agentId/message-id semantics.

> Note on graph use (rule `graph-first-context`): graph queried FIRST for
> discovery (proof block at end). The graph indexes section HEADINGS well but
> the spawn rules' full imperative BODIES live in large trinity + out-of-repo
> memory files; for exact rule text + counts I fell through to grep/Read per
> the G2 contract (graph for discovery, grep/Read to verify). The graph
> surfaced `maintenance-docs/v11-research/INTAKE-GROUPINGS-V11.md §5` (the
> origin record of both reconcile rules) and the memory pointers, which
> directed the grep/Read verification below.

---

## 0. The driving entry — BD-241 (verbatim scope anchors)

`/backlog/BD-241.md` (HEAD af73ffb). Key measured facts the BD itself records
(File/Symbol block, measured 2026-06-20 @ `ef8d6ff`):

- The Agent tool's `name` parameter ("Makes it addressable via
  SendMessage({to: name}) while running") is **NOT currently used as a
  discipline** — spawns carry only a `description`; `agentId` is auto-generated
  (e.g. `a7202065c22979cf5`) and recoverable only from the spawn `tool_result`
  in the session transcript.
- Two existing rules to RECONCILE (BD states "no contradiction"):
  `reference_sendmessage_uuid_addressing` (REFINE into registry + precedence)
  and `feedback_fresh_agent_default_no_sendmessage` (UNCHANGED; BD-241 gates
  under it).
- Natural home named by the BD: trinity sub-section
  **"Sub-agent behavior (Claude-only)"**.
- Project-side surfaces named by the BD: `project-template/docs/pack/
  METHODOLOGY.md` / `PM-CHAT.md` / project trinity Project-memory
  ("the architect determines exact homes").

This census verifies/locates each of those + the propagation surfaces.

---

## 1. Where the orchestrator currently constructs sub-agent spawns

### 1a. PACK-SIDE — trinity `CLAUDE.md` (pack root) is the SSOT

`CLAUDE.md ## Pack memory` is the authoritative corpus. Relevant subsections:

**(i) `### Agent invocation rules` (CLAUDE.md L242–290)** — how spawns are
constructed:
- L244–248 "Pack agent invocation": `claude --agent pack-<name>` OR Agent tool
  `subagent_type=pack-<name>`. (NO `name`/`description` discipline mentioned —
  this is the gap BD-241 fills.)
- L249–259 "Inject the graph path into every spawn prompt (BD-226,
  Claude-only)" — the existing pattern of the orchestrator INJECTING a runtime
  literal into every spawn prompt; structurally analogous to what a registry
  consult could feed.
- L260+ "Agent prompt requirements" — enumerates required prompt fields
  (context, output path, RO flags, markdown-only, problem/goal/success, chunk
  Writes). A spawn-NAME requirement would extend this list.

**(ii) `### Sub-agent behavior (Claude-only)` (CLAUDE.md L348–422)** — the
BD-named natural home. FULL inventory of its four bullets:
- L350–390 "Sub-agent isolation is keyed by agent class …" — the worktree /
  RW-vs-RO model; ends L389–390 "Trinity-exempt (Claude-only; Codex/Antigravity
  = BD-217)."
- **L391–401 "Default sub-agent spawns to background"** — `run_in_background:
  true` on every Agent-tool invocation; the default-background rule the task
  asked for. Trinity exemption stated inline.
- **L402–417 "Agent-team stage lifecycle + per-commit fresh-coder"** — the
  agent-team stage-lifecycle rule. Verbatim L404–408: "sub-agents spawned for
  a stage … stay alive within the stage; Pack Chat uses SendMessage for
  follow-ups against the same instance — including the sanctioned rule-4
  post-review-clean patch step (SendMessage-ing the most-recent read-write
  agent …)." This is the bullet `feedback_fresh_agent_default_no_sendmessage`
  subordinates and BD-241 must reconcile against.
- L418–422 "Trinity exemption" — the whole sub-section is Claude-specific, "not
  mirrored in AGENTS.md / GEMINI.md … none of which have equivalents in Codex
  CLI or Antigravity CLI per research §2.5 / §2.7 / §3.5 / §3.7." THIS is the
  existing trinity-exemption EXPRESSION a new Claude-only registry/naming rule
  would join.

### 1b. PACK-SIDE — `pack-ops/PACK-CHAT.md` spawn mechanics

`## In-session sub-agent spawn + merge-back (worktree isolation)` (L239+):
- L255 "### How Pack Chat spawns"; L258 `isolation:"worktree"` parameter;
  L287–296 "Name the handoff dir in the prompt" + graph-literal injection;
  L327 "the work CLEAN, Pack Chat re-engages (SendMessage) the most-recent RW
  agent". (PACK-CHAT.md restates the trinity rules as one-line refs per the
  anti-restate contract — it is a reference surface, not a second SSOT.)

### 1c. PACK-SIDE — `pack-ops/PACK-AGENTS.md`

`## Agent permission rules` (L130). L163 "the orchestrator SendMessage-s the
most-recent RW agent to produce its `git diff` patch" — the re-engagement
mechanism reference (one-line, anti-restate-collapsed).

### 1d. PACK-SIDE — `pack-ops/OPTIONAL-FEATURES.md` + `supporting-docs/METHODOLOGY.md`

- `pack-ops/OPTIONAL-FEATURES.md` L19 "## Claude Code — Agent Teams"; L126
  "after the reviewer confirms the work clean: Pack Chat SendMessage-s …".
- `supporting-docs/METHODOLOGY.md` L84–101 — a Claude-only blockquote
  convention "Agent Teams stage lifecycle" (the pack-side methodology doc's
  Claude-only-exemption PATTERN; mirrors the trinity bullet for the
  methodology-doc audience).

### GAP FLAG (1): no naming/registry guidance exists anywhere
`grep -rniE "addressable via SendMessage|name parameter|name.*at spawn|
uniquely named|spawn.*registry|spawn registry"` over `pack-ops/`,
`project-template/docs/pack/`, all trinity files, and
`supporting-docs/METHODOLOGY.md` returned **ZERO hits**. BD-241 is
greenfield discipline — there is no prior unique-naming or registry
convention to amend; it is net-new.

---

## 2. The TWO rules to RECONCILE — exact locations + wording

### CRITICAL STRUCTURAL FACT (measured): both rules live ONLY in out-of-repo memory

Neither rule is a trinity `## Pack memory` CORPUS imperative, and neither has a
`[rationale: <slug>]` slug in `CLAUDE.md` or `pack-ops/PACK-MEMORY-RATIONALE.md`.

- `grep -nE "sendmessage|fresh-agent|fresh_agent|uuid" CLAUDE.md` → **0 hits**.
- `pack-ops/PACK-MEMORY-RATIONALE.md` `^## ` headings (full list captured) →
  no `sendmessage`/`fresh-agent` slug (closest hits are body mentions of
  SendMessage at L38/L188/L193 describing OTHER rules; no slug section).

**Implication for the architect (factual, no design):** these two rules are
out-of-repo memory pointers, NOT corpus rules. BD-241's acceptance criteria
nonetheless require `validate-pack` green on "rule↔rationale bijection,
anti-restate, trinity parity, spawn-rule manifest" — which only engage when a
rule is elevated INTO the trinity corpus. So whether BD-241 authors a NEW
trinity corpus rule (engaging §5 propagation) vs. refines only the out-of-repo
memory (no validator gate) is a design fork — FLAGGED, not decided.

### 2a. `reference_sendmessage_uuid_addressing` (out-of-repo memory)

Path: `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/reference_sendmessage_uuid_addressing.md`
(2093 bytes; memory-age reminder: 21 days — verify against live CLI; that is
the EXTERNAL researcher's job). Frontmatter `name: reference-sendmessage-uuid-addressing`,
`type: reference`. Verbatim core:

> "The SendMessage tool's `to` parameter accepts agent UUIDs in addition to
> teammate names. The tool's own description text says 'Refer to teammates by
> name, never by UUID' — but the actual behavior allows UUID addressing.
> Confirmed empirically 2026-05-21 …"

How-to-apply bullets (L16–19): a sub-agent spawned WITHOUT `name` can still be
SendMessage'd by the UUID printed at spawn; "Still PREFER spawning agents WITH
a `name` parameter for ergonomics … easier to reference … survive in mental
models better than 17-character UUIDs." (This already gestures at naming
preference — BD-241 REFINES it into a registry + a documented precedence.)

The pack-side index pointer for it: `MEMORY.md` (the curated index) →
`[SendMessage UUID addressing](reference_sendmessage_uuid_addressing.md) — `to`
accepts UUIDs despite the tool description; prefer naming at spawn.`

### 2b. `feedback_fresh_agent_default_no_sendmessage` (out-of-repo memory)

Path: `…/memory/feedback_fresh_agent_default_no_sendmessage.md` (2309 bytes;
memory-age 9 days). Frontmatter `name: fresh-agent-default-no-sendmessage`,
`type: feedback`. Verbatim rule (L10–16):

> "For every agent task, the default is a NEW agent spawn. Pack Chat may NOT
> use SendMessage to continue, redirect, or supplement an existing agent —
> including an in-flight one — unless the option is discussed with the user and
> the user EXPLICITLY decides to message the same agent. Verbatim: 'For every
> agent spawned, the default is a new agent unless we discuss and I explicitly
> decide to send a message to the same agent as before.'"

L33–34: "Trinity's 'Agent-team stage lifecycle' bullet (SendMessage for
follow-ups within a stage) is SUBORDINATE to this rule." Pack-side index
pointer: `MEMORY.md` → `[Fresh agent default; SendMessage = explicit
decision] … every task = NEW spawn by default; messaging an existing agent
needs user approval.`

### 2c. How a registry + precedence REFINES (2a) while leaving (2b) UNCHANGED (factual framing)

- (2a) answers "HOW do I address a still-warm agent?" — name OR UUID. BD-241
  layers a durable REGISTRY (name→agentId→message-id record) + a documented
  lookup PRECEDENCE on top; (2a)'s "prefer naming at spawn" already points the
  same direction, so the registry is an EXTENSION, not a contradiction.
- (2b) answers "WHEN may I re-engage instead of spawning fresh?" — only with
  explicit user decision. BD-241 changes nothing here; the registry merely
  makes the *find* mechanism reliable once the user HAS decided to re-engage.
  The BD itself states this ("fixes HOW-to-find, not WHEN-to-reengage").
- These are orthogonal axes (HOW-to-address vs WHEN-to-reengage) — no
  contradiction to resolve, only a SEQUENCING note that the precedence is
  consulted only after the (2b) gate is passed. (Stated as fact; the
  architect designs the exact wording.)

### Origin record (graph-discovered)
`maintenance-docs/v11-research/INTAKE-GROUPINGS-V11.md §5` (L191–213) records
the establishment of BOTH rules' neighbors during BD-186 work — L207–209
"Default sub-agent run_in_background", L211–213 "SendMessage UUID worked across
spawn boundary" ("Agent had no active task; resumed from transcript in the
background with your message"). This is provenance context, not a live rule
surface.

---

## 3. Where a durable spawn REGISTRY could live (pack side) — OPTIONS, not a pick

The task asks for an OPTIONS inventory of existing dot-state conventions. Two
families exist in the repo.

### 3a. TRACKED, committed pack-ops dot-state MANIFEST files (precedent A)

`ls -la pack-ops/` shows four committed manifest/allowlist dot-files:

| File | Bytes | Tracked? | Purpose |
|---|---|---|---|
| `pack-ops/.spawn-rule-manifest.txt` | 3633 | YES (`git ls-files` confirms) | slug→canonical+references for spawn-relevant rules (BD-196 C5) |
| `pack-ops/.boundary-pointer-manifest.txt` | 5340 | YES | boundary-rule reference manifest |
| `pack-ops/.concision-allowlist.txt` | 3950 | YES | concision-gate allowlist |
| `pack-ops/.boundary-exempt-root.txt` | 290 | YES | boundary-exempt roots |

These are human/CI-readable, committed, validator-gated text manifests. A
durable registry modeled on this family would be COMMITTED — but a spawn
registry is per-SESSION runtime state, which sits uneasily with committed
content (it would churn the tree). FLAGGED as a tension, not resolved.

### 3b. GITIGNORED, per-clone runtime dot-state (precedent B)

`.gitignore` (verified L1–76) ignores per-clone/local-runtime state:
- L12 `.pack-tracker/` — "Mapping file, migration checkpoints … Never
  committed: contains local paths and is regenerable" (BD-061). This is the
  closest precedent for a regenerable, per-clone, never-committed state DIR.
- L76 `graphify-out/` — per-clone build artifact (BD-225); contains
  `graphify-out/.pack-refresh-status` (65 bytes: `ok <sha> <iso8601>`) — a
  tiny gitignored STATUS file the orchestrator reads/writes. This is the
  closest precedent for a small, gitignored, orchestrator-maintained status
  file (the exact shape a runtime spawn registry would take).
- L3 `.claude/settings.local.json`, L7 `.mcp.json` — machine-local config
  (different category: config, not runtime ledger).

### 3c. JSON-schema state precedent (precedent C)
`scripts/tests/recommendation-state-schema-test.sh` + validate-pack Check 30
("Recommendation-state JSON schema (BD-079)") show the repo already validates a
structured JSON state file by schema — a precedent for a SCHEMA-validated
registry if the architect wants one. (The recommendation-state file itself is
a tracker/recommendation artifact, not a spawn ledger.)

### Registry-location OPTIONS inventoried (architect chooses; I do NOT)
1. **Committed pack-ops text manifest** (precedent 3a) — durable, CI-gated,
   but churns on every spawn; fits 
   author-once-conventions, not runtime ledgers.
2. **Gitignored per-clone runtime file** (precedent 3b) — e.g. a
   `.pack-spawn-registry.*` (root or `pack-ops/`) modeled on
   `graphify-out/.pack-refresh-status`; never committed, regenerable,
   session-scoped. Closest natural fit for per-session spawn state.
3. **Gitignored dir under an existing ignored root** (precedent 3b) — e.g.
   inside `.pack-tracker/`-style or `graphify-out/`-style ignored space.
4. **Schema-validated JSON** (precedent 3c) — structured (name, agentId,
   purpose, status) with a validate-pack schema check, if durability +
   validation are wanted.
5. **Out-of-repo memory dir** (`~/.claude/projects/<slug>/memory/`) — where
   the two reconcile rules already live; Pack-Chat-maintained, no tree churn,
   but not a structured ledger and Claude-only by construction.

NO OPTION CHOSEN — this is the architect's call. The two operative
tensions to surface: (a) committed vs gitignored (tree churn vs durability
across clones); (b) the `agents-never-commit` rule (CLAUDE.md `### Workflow`)
means a sub-agent cannot itself write a committed registry — only the
orchestrator can — so a runtime ledger written mid-task strongly implies a
GITIGNORED location.

### GAP FLAG (3): `.spawn-rule-manifest.txt` does NOT cover either reconcile rule
`grep "^slug:" pack-ops/.spawn-rule-manifest.txt` → 7 slugs:
`agents-never-commit, role-write-scope, preflight-stop-means-stop,
presents-triage-before-fix-coder, triage-all-fix-all, bounded-review-fix-cycle,
pack-chat-minor-edits-only`. NEITHER `reference_sendmessage_uuid_addressing`
NOR `feedback_fresh_agent_default_no_sendmessage` appears (they are out-of-repo
memory, not corpus rules — consistent with §2). NOTE the name collision risk:
`.spawn-rule-manifest.txt` is a RULE-reference manifest, NOT a spawn REGISTRY —
a new "spawn registry" must not be confused with it; per the
filename-uniqueness heuristic the architect should pick a distinct name.

---

## 4. Project-side orchestrator surfaces (mechanism Claude-only)

### GAP FLAG (4 — corrects a BD assumption): `project-template/docs/pack/METHODOLOGY.md` does NOT exist
`find . -name METHODOLOGY.md` → only `supporting-docs/METHODOLOGY.md`
(pack-side) + five `test-fixtures/**/docs/pack/METHODOLOGY.md` (generated
fixtures). There is **no `project-template/docs/pack/METHODOLOGY.md` source
file** in the tree. The project trinity's "Document locations" table DOES list
`METHODOLOGY.md` as a `docs/pack/` file, so it must be staged at install time
from a source — but the source under `project-template/` is NOT present at this
HEAD under that path. The BD-241 entry names
`project-template/docs/pack/METHODOLOGY.md` as a project-side home; the
architect MUST resolve where the project-side METHODOLOGY source actually lives
(candidate: `supporting-docs/METHODOLOGY.md` is the pack-side methodology doc;
its relation to a shipped project `docs/pack/METHODOLOGY.md` needs the
install-map checked — I could not fully enumerate the staging source from the
tree alone). FLAGGED.

### 4a. `project-template/docs/pack/PM-CHAT.md` — the live project-side orchestrator doc
This IS the project-side orchestrator SSOT for spawning. Surfaces:
- `### In-session agent spawning` (L454–510): two spawn paths (Agent/Task tool
  PRIMARY; `agent-run.sh` SECONDARY); isolation-by-class; "Spawn in the
  background" (L506–510, CLI-agnostic wording — "use whatever your CLI offers
  for asynchronous agent execution").
- `### Merge-back …` (L512–548): L533–541 re-engagement — "produces the patch
  by re-engaging the most-recent read-write agent … in Claude Code, via the
  Agent-team peer-message path; if your CLI offers no peer-messaging, re-spawn
  a fresh `coder`". This is the project-side analog of the pack re-engagement
  path — where a name→agentId lookup discipline would attach.
- **L897–909 "Per-project Claude memory cache (Claude-only)"** — a blockquote
  using EXACTLY the project-side Claude-only-exemption EXPRESSION: "Claude Code
  projects may use per-project memory at `~/.claude/projects/<slug>/memory/` …
  Codex CLI and Antigravity CLI have no equivalent per-project memory
  mechanism; PM chat sessions running under those CLIs read trinity / PM-CHAT.md
  / METHODOLOGY.md directly." THIS is the template a project-side
  Claude-only registry/naming note would follow.

### 4b. Project trinity `## Project memory` (project-template/CLAUDE.md L349)
The project trinity has a `## Project memory` section but **NO "Sub-agent
behavior (Claude-only)" sub-section** — `grep -niE "claude.only|sub-agent|
SendMessage|spawn|trinity exempt|run_in_background|agent.team"
project-template/CLAUDE.md` returns only L435 (Antigravity subagent mechanism,
in phase-routing prose). The project trinity carries universal collaboration
rules (Trinity rule, no-destructive-git, PM-chat-does-not-architect, Project
SSOT-first); it does NOT carry the Claude-only spawn-runtime model — that lives
in PM-CHAT.md (§4a). So the project-side Claude-only exemption is expressed via
PM-CHAT.md blockquotes (§4a L897) + `supporting-docs/METHODOLOGY.md` L84–101,
NOT via a project-trinity sub-section. The architect must decide whether a
project-side BD-241 note lands in PM-CHAT.md (precedent fit) and/or
METHODOLOGY.md, and whether anything reaches the project trinity at all.

### 4c. `project-template/docs/pack/OPTIONAL-FEATURES.md` (project-side)
L19 "## Claude Code — Agent Teams"; L31 official docs link; L113 "Claude Code,
via the Agent-team peer-message path; if your CLI offers no peer-messaging …";
L153–171 "BASE (REQUIRED setting) — `worktree.baseRef`" (`worktree.baseRef:
"head"`). This is the project-side Claude-only feature doc — another candidate
home for the Claude-only registry/precedence mechanism on the project side.

### Pack-vs-project + Claude-only delineation (explicit, per separate-pack-ops rule)
- PACK side (pack-self-management): `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`
  `## Pack memory` (trinity), `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`,
  `pack-ops/OPTIONAL-FEATURES.md`, `supporting-docs/METHODOLOGY.md`, the
  pack-ops dot-state manifests, out-of-repo Pack-Chat memory.
- PROJECT side (shipped to clients): `project-template/docs/pack/PM-CHAT.md`,
  `…/METHODOLOGY.md` (staging source TBD — GAP 4), `…/OPTIONAL-FEATURES.md`,
  project trinity `project-template/{CLAUDE,AGENTS,GEMINI}.md`.
- Claude-only on BOTH sides: the SendMessage/Agent-Teams/agentId/resume
  mechanism is Claude-Code-specific. Pack side expresses the exemption via the
  trinity "Sub-agent behavior (Claude-only)" sub-section + its "Trinity
  exemption" bullet (NOT mirrored in AGENTS.md/GEMINI.md). Project side
  expresses it via PM-CHAT.md "(Claude-only)" blockquotes + METHODOLOGY.md
  "Claude-only operating convention" blockquote. The unique-NAMING discipline
  (vs the find/re-engage MECHANISM) may apply wherever agents spawn — the BD
  says "the architect determines Codex/Antigravity applicability — likely
  deferred to BD-217."

---

## 5. Propagation surfaces for a NEW trinity rule + the validate-pack gates

If BD-241 authors a NEW trinity `## Pack memory` corpus rule (the BD-named
natural home), the propagation procedure in `pack-ops/PACK-CHAT.md` §
"Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current" engages.

### 5a. The ordered propagation table (PACK-CHAT.md L495–509, verbatim surfaces)

| # | Surface to touch | Enforcing check |
|---|---|---|
| 1 | Corpus imperative line ×3 trinity (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` `## Pack memory`), incl. `[roles:]` tag + `[rationale: slug]` | trinity-parity + role-tag controlled-vocab |
| 2 | `pack-ops/PACK-MEMORY-RATIONALE.md` — add/edit/remove the `## <slug>` entry | C3 bijection (slug-set equality) |
| 3 | Thin memory-cache pointer (out-of-repo) | Pack-Chat upkeep; trinity-wins (no validator gate) |
| 4 | Any reference surface (`PACK-AGENTS.md`/`PACK-CHAT.md` one-line refs) | anti-restate scan + reference-resolution |
| 5 | `pack-ops/.spawn-rule-manifest.txt` slug→canonical+references | reference-resolution |
| 6 | `test-fixtures/manifest.txt` — NOT a propagation step; regen at push via `scripts/manifest-sync.sh` | CI `build.sh --verify` + validate-pack Check 62 |

Order (L508): corpus(1) → rationale(2) → references(4)+spawn-rule-manifest(5)
in the SAME commit → cache(3) as upkeep. Verified by END-STATE checks, not
gate-sequenced (L509).

**Note re Claude-only:** a Claude-only rule is NOT mirrored in
`AGENTS.md`/`GEMINI.md` (the existing "Sub-agent behavior (Claude-only)"
sub-section is Claude-only and lives only in CLAUDE.md). So step (1)'s
"×3 trinity" parity does NOT apply to a Claude-only rule — the existing
sub-section is the precedent that a Claude-only rule is single-surface. The
architect must confirm how the trinity-parity check (Check 18) treats this
(below).

### 5b. validate-pack checks that would GATE a new rule (measured in scripts/validate-pack.py)

| Check | Def / location | What it gates (relevant to BD-241) |
|---|---|---|
| **Check 45** — pack-memory rule↔rationale bijection | `check_pack_memory_rationale_bijection()` @ L7312 | set-equality between `[rationale:]` slugs in `CLAUDE.md ## Pack memory` and `## <slug>` headings in `PACK-MEMORY-RATIONALE.md`. A new corpus rule with a slug MUST add a matching rationale section or Check 45 fails (orphan-corpus or orphan-rationale). |
| **Check 46** — boundary + spawn-rule pointer manifests | `check_boundary_and_spawn_pointer_manifests()` @ L7559 | (a) reference-resolution: every named reference surface in `.spawn-rule-manifest.txt` carries a resolving pointer; (b) anti-restate: the canonical `## Pack memory` imperative BODY must NOT reappear verbatim in any spawn-rule reference surface (`PACK-AGENTS.md`/`PACK-CHAT.md`). If BD-241's rule gets a manifest record, both legs apply. |
| **Check 18** — Trinity H2 structure parity | `check_trinity_h2_parity()` @ L1577 | parity WITHIN each trinity location only (L1605–1606: "There is NO cross-location parity gate — pack-root and project-template trinity carry different rules"). Runs per-location (pack-root + project-template — two invocations). The architect must confirm a Claude-only single-surface rule does not trip H2 parity (the existing Claude-only sub-section is the precedent it does not). |
| **Check 30** — Recommendation-state JSON schema | `check…` @ L2841 | precedent for schema-validating a structured state JSON, IF a JSON registry is chosen (§3c). |
| **Check 62** — manifest (push-time) | (BD-228) | `test-fixtures/manifest.txt` reconciled at push via `scripts/manifest-sync.sh`; NOT a per-commit propagation step (per the regenerate-manifest memory). If a new fixture input is added, the push-time manifest regen + Check 62 + `build.sh --verify` apply. |

Also relevant: `check_destructive_git_verb_parity()` @ L9341 (pack) /
`check_project_destructive_git_verb_parity()` @ L9801 (project) — the
git-verb-ban parity checks; not directly gating a naming/registry rule but they
confirm trinity-parity machinery exists per surface.

### GAP FLAG (5): I did not exhaustively read Check 45/46 BODIES for edge cases
I located each check's `def` + docstring and the manifest format, but did not
line-by-line trace whether a Claude-only rule (single-surface, no
`AGENTS.md`/`GEMINI.md` mirror) is fully exempt from every leg of Check 45/46
parity logic. The architect/planner should confirm against the check bodies
(L7312–7430 for 45, L7559–7740 for 46) before committing to "add a corpus rule"
vs "refine memory only." FLAGGED.

---

## 6. Blast-radius map (one-line per surface, by side)

PACK side:
- `CLAUDE.md` `### Sub-agent behavior (Claude-only)` L348–422 — BD-named home;
  natural insertion point for naming + registry + precedence (Claude-only).
- `CLAUDE.md` `### Agent invocation rules` L242–290 — spawn-construction +
  "Agent prompt requirements" (where a name requirement extends).
- `pack-ops/PACK-CHAT.md` L239+ (spawn mechanics) + L485–509 (propagation
  procedure) — reference surface + the propagation owner.
- `pack-ops/PACK-AGENTS.md` `## Agent permission rules` L130/L163 — re-engage
  reference.
- `pack-ops/OPTIONAL-FEATURES.md` L19/L126 — Agent-Teams + re-engage.
- `supporting-docs/METHODOLOGY.md` L84–101 — Claude-only convention blockquote.
- `pack-ops/PACK-MEMORY-RATIONALE.md` — IF a new corpus slug (Check 45).
- `pack-ops/.spawn-rule-manifest.txt` — IF a new corpus rule needs a manifest
  record (Check 46). (Do NOT confuse with a NEW spawn-REGISTRY file.)
- Registry location: see §3 OPTIONS (committed manifest vs gitignored runtime
  vs JSON-schema vs out-of-repo memory) — UNCHOSEN.
- Out-of-repo memory: `reference_sendmessage_uuid_addressing.md` (refine) +
  `feedback_fresh_agent_default_no_sendmessage.md` (unchanged) + `MEMORY.md`
  index pointers.

PROJECT side (Claude-only mechanism; shipped):
- `project-template/docs/pack/PM-CHAT.md` — `### In-session agent spawning`
  L454+, `### Merge-back` L512–548, "(Claude-only)" blockquote L897–909.
- `project-template/docs/pack/OPTIONAL-FEATURES.md` L19/L113/L153 — Claude-only
  feature doc.
- `project-template/docs/pack/METHODOLOGY.md` — **NAMED by BD but ABSENT under
  that path** (GAP 4); staging source TBD.
- `project-template/{CLAUDE,AGENTS,GEMINI}.md` `## Project memory` — universal
  rules only; no Claude-only spawn sub-section exists (architect decides if one
  is warranted).
- Test fixtures: `test-fixtures/**/docs/pack/METHODOLOGY.md` (5 copies) +
  `manifest.txt` — regenerated; touched only if the project methodology source
  changes (push-time, Check 62).

---

## 7. Areas I could NOT fully enumerate (consolidated gap list)

1. **GAP 1** — no existing naming/registry guidance (greenfield); confirmed by
   zero-hit grep. (Not a gap in MY enumeration; a fact the architect needs.)
2. **GAP 3** — `.spawn-rule-manifest.txt` covers neither reconcile rule
   (they are out-of-repo, not corpus). Architect must decide corpus-vs-memory.
3. **GAP 4** — `project-template/docs/pack/METHODOLOGY.md` source is ABSENT
   under the BD-named path; only `supporting-docs/METHODOLOGY.md` + fixtures
   exist. The install/staging source for the shipped project METHODOLOGY.md was
   NOT determinable from the tree alone; needs install-map verification.
4. **GAP 5** — Check 45/46 BODIES not line-by-line traced for Claude-only
   single-surface exemption; architect should confirm before choosing
   corpus-vs-memory.
5. **External-half boundary** — agentId/message-id/`name`/resume LIVENESS
   semantics against the actual CLI are explicitly the EXTERNAL researcher's
   scope; I verified only the repo's RECORDED claims (the 21-day-old memory
   carries a "verify against live code" reminder).
6. **Install-map (`scripts/init-project.sh`)** — I did not trace which staging
   function emits the shipped `docs/pack/METHODOLOGY.md`/`PM-CHAT.md`; relevant
   to GAP 4 but out of this census's grep/Read budget.

---

## 8. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| graph-first-context | Ran `graphify query` FIRST (7 discovery queries) before any grep. Proof — `graphify query "spawn-rule-manifest reference manifest" --graph …/graph.json --backend claude-cli --budget 1000` → `Traversal: BFS depth=2 \| Start: ['Manifest','Manifest','Reference'] \| 45 nodes found`. Earlier query surfaced `maintenance-docs/v11-research/INTAKE-GROUPINGS-V11.md §5` (SendMessage/run_in_background origin) which directed grep/Read. G2 fallback to grep/Read used for full rule BODIES (graph indexes headings, not large rule bodies). | COMPLIANT |
| researcher-maps-blast-radius | §1–6 enumerate every located surface with path/line; §7 consolidates 6 explicit gaps (including 3 corrections to the BD's own assumptions). Exhaustive census attempted; un-enumerated areas FLAGGED, not silently dropped. | COMPLIANT |
| verify-availability-not-just-existence | Every claim carries measured evidence: `git ls-files` (manifest TRACKED), `git check-ignore` (`.pack-tracker/`/`graphify-out/` ignored), `grep "^slug:"` (7 slugs, neither reconcile rule), `find -name METHODOLOGY.md` (no project-template source), `grep -nE … CLAUDE.md` (0 sendmessage hits), check `def` line numbers in validate-pack.py. | COMPLIANT |
| separate-pack-ops-from-product | §4c + §6 explicitly split PACK side (pack-self-management) vs PROJECT side (shipped deliverables) vs Claude-only-on-both; delineation stated as its own subsection. | COMPLIANT |
| scope-deliverables-to-the-ask | Inventory only; NO design, NO option chosen (§3 lists 5 options + tensions, explicitly defers choice to architect); answered exactly the 5 task items. | COMPLIANT |
| agents-never-commit | Only git verbs run: `rev-parse`, `branch --show-current`, `ls-files`, `check-ignore`, `status`-free read-only inspection. ZERO state-changing git verbs. | COMPLIANT |
| per-action-approval-sub-agents | No destructive ops attempted; sole write = this report to the caller-specified `/tmp` path via `cat >>` heredoc chunks. | COMPLIANT |
| rules-applied-verification-block | This table (per-rule, quoted evidence, conclusion; includes the graph-proof row above). No empty-evidence rows. | COMPLIANT |
