# v11 Architecture — Optional Issue-Tracker Integration

**Status.** Architecture proposal. Designed against `DESIGN-BRIEF.md` (the
contract), `EXTERNAL-RESEARCH.md` (capability surface), `INTERNAL-INVENTORY.md`
(every flat-file consumer/producer), `RESEARCH-AUDIT.md` (verified claims and
nine additional trackers).

**Owner.** Pack-architect agent. Awaiting pack-maintainer review.

**Date.** 2026-04-30. Pack at v10.0; this is the v11 design.

**Scope.** Pack-repo and client-project surfaces, treated as independently
configurable. First-class GitHub Issues backend; abstraction surface designed
for Linear, Jira (Atlassian Cloud Free), Redmine, Bugzilla, OpenProject
Community, YouTrack Free, Shortcut, ClickUp, Notion, and Trello as future
implementations.

**Out of scope, do-not-revisit.** Anything in `DESIGN-BRIEF.md` §1: Desktop /
Web PM-chat surfaces; `/install-github-app`; forced migration; required
tracker. The default remains flat files.

**Naming.** Throughout this document I use:
- *Tracker mode* = pack-side or client-side opted into a backend.
- *Flat-file mode* = current v10 default.
- *Surface* = pack-repo or client-project, the two independently-configurable
  scopes.
- *Backend* = a tracker-provider implementation (e.g., GH Issues, Linear).
- *Provider* = the pack-side abstraction object that talks to a backend.
- *Trinity* = `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` as a triple.

---

## 1. Architectural overview

### 1.1 Shape

The integration adds a single new layer — the **TrackerProvider abstraction**
— between the chat (Pack Chat / PM Chat) and a backend (GitHub Issues today,
others later). Around it ship six concrete artifacts:

1. A `tracker.toml` config file (per surface) declaring backend + auth.
2. Issue-form templates per backend (`.github/ISSUE_TEMPLATE/*.yml` for GH).
3. A migration script (`scripts/tracker-migrate.sh`) with `forward` and
   `reverse` modes, idempotent in both directions.
4. A small bash command surface (`scripts/tracker.sh <op> [args]`) that
   wraps the LCD `gh` calls and exposes them to chats and skills.
5. New skill (`tracker-startup`) that mode-detects at session start; existing
   skills (`pack-startup`, `pm-startup`) gain a thin pre-step that delegates
   to it.
6. Updated trinity `## Document locations` tables that name the tracker as a
   *type* of location alongside file paths.

The design makes no other structural change. Flat-file consumers continue
to read flat files as v10 prescribes them. When tracker mode is on, the
chat keeps the flat files **as a regenerated read-only mirror** so existing
agents and skills keep working without forks.

### 1.2 Data flow

```
                        Pack Chat / PM Chat
                              │
                              │  intent: list/get/create/update/close/...
                              ▼
                    TrackerProvider (abstract)
                              │
                              │  capability flags + canonical operations
                              ▼
              ┌────────────┬──────────────┬──────────────┐
              │            │              │              │
              ▼            ▼              ▼              ▼
         GH backend   Linear backend  Jira backend  ...future...
         (gh + gh
          api graphql)
              │
              ▼
         GitHub Issues
              │
              │  webhooks + events (out of scope for chat-side)
              ▼
       optional CI / GH Actions
```

Read direction (agents and skills):

```
agent prompt
   │
   │  "read BACKLOG.md", "current phase", "issue TD-123"
   ▼
location-resolver
   │  consults trinity ## Document locations (which now lists tracker
   │  alongside file paths)
   ▼
   ├── flat-file-mode → read mirror file (regenerated)
   └── tracker-mode  → call TrackerProvider.list/get(...)
```

Write direction (Pack Chat / PM Chat only):

```
Pack Chat / PM Chat
   │
   ▼
TrackerProvider.create / update / close / comment / link / sub_issue_*
   │
   │  on success: regenerate flat-file mirror (cheap, deterministic)
   ▼
backend
```

Agents are read-only; this matches the chat-as-only-writer rule from
`DESIGN-BRIEF.md` §3.1 and `INTERNAL-INVENTORY.md` Pass A and Pass B.

### 1.3 Migration model

One mode switch flips a surface from flat-file to tracker. Migration runs
once per surface, idempotent. The reverse migration is **always available**
and produces flat files the v10 chat workflow can resume against without
modification (same anchor algorithm, same emoji set, same TD-NNN identity).

The mirror — flat files regenerated from tracker state — is the bridge that
lets the design ship without rewriting every existing skill, prompt, or
procedure. Mirrors are read-only (write attempts are pack defects);
authoritative state lives in the backend.

### 1.4 Cross-CLI strategy

LCD = `gh`. All three CLIs ship with a `Bash` / `local_shell` /
`run_shell_command` primitive (`EXTERNAL-RESEARCH.md` §4, §5, audit §A.1,
§A.8). Three things port across all three:

- `gh issue list / view / create / edit / close / comment / lock / search`.
- `gh api graphql -f query='...'` for sub-issues, dependencies, type field.
- `gh auth status` / `gh auth refresh`.

Per-CLI tuning above the LCD floor:

- **Claude Code.** MCP (GitHub MCP server) optional via
  `claude mcp add github`; agent definitions in `.claude/agents/<name>.md`.
- **Codex CLI.** MCP via `~/.codex/config.toml` `[mcp_servers.github]`;
  subagents (GA 2026-03-14) at `~/.codex/agents/<name>.toml` with
  `agents.max_depth = 1`, `max_threads = 6` (audit §A.1 corrected from "8").
- **Gemini CLI.** MCP via `~/.gemini/settings.json` with `${VAR}`
  env-expansion; subagents (`generalist`, `cli_help`,
  `codebase_investigator` built-ins; v0.41 stable lands ~2026-05-06 with
  `ContextManager` / `AgentChatHistory` refactor — audit §A.1 / §12.3).

Per-CLI tuning is **strictly additive**: the LCD always works for users
without all tools installed. `OPTIONAL-FEATURES.md` documents per-CLI
acceleration paths the way it documents Claude Code Agent Teams today.

### 1.5 What this design does NOT change

- The trinity rule. `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` remain
  in lockstep.
- `## Document locations` semantics: it remains the path-resolver authority
  consulted by `pm-startup` and prompt files. We extend its row shape, we do
  not replace it.
- Pack Chat / PM Chat exclusive write authority.
- The flat-file format. Mirrors are byte-compatible with v10 BACKLOG.md /
  STATUS.md / CHANGELOG.md grammar so downstream readers do not need
  per-mode branches.
- Forced migration. Existing v10 projects that opt out stay on flat files
  forever.

---

## 2. Tracker provider abstraction

This is the core of OQ-1. Per `EXTERNAL-RESEARCH.md` §8.5 the smallest
durable cross-tracker surface is identified; per `RESEARCH-AUDIT.md` §A.9
that surface still holds at the operation-name level but needs three
additions: (a) capability flags; (b) `link.kind` as open string with
reserved values; (c) explicit "depth ceiling" capability flag.

### 2.1 Operation set

The provider exposes exactly these operations. They are the entire
chat-side write surface and the entire agent-side read surface:

| Op | Direction | Required? | Idempotent? |
|----|-----------|-----------|-------------|
| `list(filter, page)` | read | yes | yes |
| `get(id)` | read | yes | yes |
| `search(query, page)` | read | yes | yes |
| `create(payload)` | write | yes | no (use marker for idempotent migration) |
| `update(id, patch)` | write | yes | yes (last-write-wins) |
| `close(id, reason)` | write | yes | yes |
| `reopen(id)` | write | yes | yes |
| `comment(id, body)` | write | yes | no (chat asks once) |
| `set_labels(id, set)` | write | yes | yes (set-replace) |
| `set_assignee(id, ids)` | write | yes | yes (set-replace) |
| `set_milestone(id, name)` | write | yes | yes |
| `link(id, other_id, kind)` | write | yes (or report unsupported) | yes |
| `unlink(id, other_id, kind)` | write | yes | yes |
| `sub_issue_create(parent_id, payload)` | write | conditional on capability | no |
| `sub_issue_list(parent_id)` | read | conditional | yes |
| `sub_issue_unlink(parent_id, child_id)` | write | conditional | yes |
| `capabilities()` | read | yes | yes (cached) |
| `raw(method, path, body)` | escape | yes | n/a |

`raw(...)` is the per-`EXTERNAL-RESEARCH.md` §8.6 escape hatch every
surviving multi-tracker abstraction in the wild offers. For the GH
backend this is `gh api ...` / `gh api graphql -f query='...'`. Without
this, "the abstraction will block the next backend from shipping its
distinguishing feature" (§8.6 verbatim).

**Operations explicitly out of scope.** Webhook subscription is **not** in
the chat-side provider surface (per `EXTERNAL-RESEARCH.md` §8.5: "out of
scope for chat-side, in scope for CI hooks"). Pin/unpin/transfer/develop
(linked-PR creation) are not in the canonical surface; they go through
`raw(...)`. Keeping the surface narrow is the design choice.

### 2.2 Argument and return shapes

All identifiers are **opaque strings**. GH `#42` is `"42"` to the provider;
Linear `ABC-123` is `"ABC-123"`; Jira `PROJ-7` is `"PROJ-7"`. The pack's
`BD-NNN` and `TD-NNN` namespaces stay internal — we map them to backend IDs
in metadata fields. (Audit §A.7: "identifiers are not numeric.")

Canonical `Issue` shape returned by `get(id)`:

```
{
  "id": "<opaque-string>",
  "number": "<opaque-string>",            // identical to id for GH; PROJ-7 for Jira
  "title": "<string>",
  "body": "<markdown-string>",
  "state": "open" | "closed",
  "state_reason": "completed" | "not_planned" | "duplicate" | null,
  "labels": ["<string>", ...],
  "assignees": ["<user-id>", ...],
  "milestone": "<string>" | null,
  "type": "<string>" | null,              // GH "issue type"; Jira issue type; Linear issue type
  "parent": "<id>" | null,
  "children": ["<id>", ...],              // opaque to depth ceiling
  "links": [{"kind": "<string>", "target": "<id>"}, ...],
  "iteration": {"name": "<string>", "start": "<iso-date>", "end": "<iso-date>"} | null,
  "priority": "low" | "medium" | "high" | "urgent" | null,
  "created_at": "<iso-datetime>",
  "updated_at": "<iso-datetime>",
  "closed_at": "<iso-datetime>" | null,
  "url": "<string>",
  "raw": { "<backend-specific>": "..." } // passthrough; not authoritative
}
```

`list(filter, page)` returns a list-of-Issue projected to a configurable
field set. The pack's default field set is
`{id, number, title, state, labels, type, milestone, parent}` to match
audit §A.5's verified ~30 tokens/issue cost.

`comment(id, body)` returns `{id, body, author, created_at}`.

`capabilities()` returns the schema in §2.3.

### 2.3 Capability-flag schema

This is the architect's answer to audit §A.9 addition (a). Every backend
exposes:

```
{
  "backend_name": "github" | "linear" | "jira" | ...,
  "hierarchy": {
    "supported": true | false,
    "depth_ceiling": <int> | "unbounded",
    "children_per_parent_ceiling": <int> | "unbounded",
    "parent_per_child_ceiling": <int>
  },
  "dependencies": {
    "supported": true | false,
    "kinds": ["<string>", ...],          // backend-typed kinds
    "per_relationship_ceiling": <int> | "unbounded",
    "cross_repo_supported": true | false
  },
  "labels": {
    "supported": true | false,
    "model": "flat" | "hierarchical",
    "per_issue_ceiling": <int> | "unbounded"
  },
  "milestone": {
    "supported": true | false,
    "per_issue_ceiling": 1 | <int>
  },
  "type_field": {
    "supported": true | false,
    "values_managed_at": "issue" | "org" | "project"
  },
  "iteration": {
    "supported": true | false,
    "where": "issue" | "project" | "team"
  },
  "custom_fields": {
    "supported": true | false,
    "passthrough_only": true | false
  },
  "search": {
    "language": "github-qualifier" | "jql" | "yql" | "free-text",
    "result_ceiling_per_query": <int> | "unbounded"
  },
  "rate_limits": {
    "writes_per_minute_recommended": <int>,
    "reads_per_minute_recommended": <int>
  },
  "raw_escape_hatch": true | false        // must be true to ship
}
```

The chat consults `capabilities()` once per session and caches the
result. The migration script consults it before forward-migrating to
fail-fast on missing capabilities (e.g., trying to migrate sub-issues
into Bugzilla, which has no native hierarchy — audit B.3).

### 2.4 link.kind shape

Audit §A.9 addition (b). `link.kind` is an **open string with reserved
values**. Reserved set:

- `blocks` — this issue blocks another.
- `blocked-by` — this issue is blocked by another.
- `related` — loose cross-reference.
- `duplicates` — this issue duplicates another.
- `parent` / `child` — hierarchy when the backend lacks first-class
  parent/child (Bugzilla emulates with `blocks`/`depends_on`).

Backends declare additional `kinds` in `capabilities().dependencies.kinds`.
Jira backends will surface its 30+ project-typed link types here. The
chat uses reserved kinds in normal operation; backend-specific kinds
appear only when a chat consults `capabilities()` and offers a wider
choice.

The pack's BACKLOG entry format already uses two kinds — `Blockers` and
`Unblocks` (METHODOLOGY § Part 7 line 994). These map to `blocked-by` and
its inverse, with `Unblocks` synthesized client-side as the inverse of
`blocked-by` (since a tracker like GH stores only one side and infers
the inverse).

### 2.5 Error model

Errors are **typed, surface-able, and never silently retried**. Per
`DESIGN-BRIEF.md` §3.1 final goal: "the pack does not silently retry
or paper over."

Error taxonomy:

| Code | Cause | UX |
|------|-------|-----|
| `network-unreachable` | DNS / connect / TLS failure | Surface with diagnostic; offer flat-file fallback if mirror is fresh enough; do not retry. |
| `rate-limit-primary` | Auth'd 5,000/hr core REST or 5,000 pts/hr GraphQL exhausted | Surface remaining + reset (`X-RateLimit-Reset`); suggest narrower query; do not retry. |
| `rate-limit-secondary` | 30/min REST search bucket exhausted (audit §1.6 verified) | Same as primary; specifically suggest moving from search to filtered list. |
| `auth-missing` | No token | Print `gh auth login` instructions inline. |
| `auth-expired` | 401 | Print `gh auth refresh` instructions inline. |
| `auth-insufficient-scope` | 403 with documented scope mismatch | Print `gh auth refresh -s <scope>` for the missing scope. |
| `not-found` | 404 | Surface; ask user if they meant a different ID. |
| `validation` | 422 | Surface backend message; do not retry. |
| `schema-reshape` | GraphQL field absent or type mismatch (audit §10.4) | Surface; instruct user to run `pack tracker doctor` (see §3) to refresh capability cache. |
| `partial-write` | Multi-step compound op succeeded partially | Surface with the per-step success/failure list; offer to resume from the failed step. Idempotent re-run supported by design. |

Every error is one of these typed codes plus a backend-specific message in
the diagnostic field. The chat translates the typed code into the
user-facing failure-mode UX described in §9.

**v11.0 additive code (post-D-1):** the implementation also carries
`not-implemented` for verbs whose v11.0 stub is wired into the
dispatcher but whose body lands in a later BD (currently `pack tracker
enable-recommendations`, BD-073). The code is additive — it does not
replace or refine any of the ten codes above — and is mapped to
`pack tracker doctor` in the V3 §27.1 Layer-2 verb table. Per V1 §2.5
the ten typed codes are a minimum surface, not an exhaustive list, so
v11.0's eleventh code does not break the §2.5 contract.

### 2.6 Pagination contract

`list` and `search` accept `page = {limit: int, cursor: string | null}` and
return `{items: [...], next_cursor: string | null}`.

Backend mapping:
- GH REST: cursor encodes `?page=N`.
- GH GraphQL: cursor is the `endCursor` from connection.
- GH `gh` CLI: `--limit N` exposed; we do not paginate inside `gh issue list`
  (its `--limit 1000` is the hard cap; for deeper queries we move to
  `gh api --paginate`).

Default limit is 30, matching `gh issue list` defaults so chat token costs
stay near §6.1's 30 tokens/issue baseline. Migration uses `limit=100`.

### 2.7 First-class GitHub Issues implementation

This section is concrete enough that the planner can break it into
commits without further research.

#### 2.7.1 Operations to commands

| Provider op | LCD shell-out | MCP equivalent (Claude/Codex/Gemini) | Auth |
|-------------|---------------|--------------------------------------|------|
| `list(filter, page)` | `gh issue list --json <fields> [--label X] [--state open] [--milestone M] [--limit N] [--search Q]` | `list_issues` with `minimal_output=true` | shared `gh auth` |
| `get(id)` | `gh issue view <id> --json <fields> [--comments]` | `get_issue` | shared |
| `search(query, page)` | `gh search issues "<query>" --json number,title,url,state,labels --limit N` | `search_issues` | shared |
| `create(payload)` | `gh issue create --title T --body-file F --label L --type T --assignee A --milestone M` | `create_issue` | shared |
| `update(id, patch)` | `gh issue edit <id> --add-label / --remove-label / --add-assignee / --remove-assignee / --milestone / --title / --body-file` | `update_issue` | shared |
| `close(id, reason)` | `gh issue close <id> --reason completed\|not_planned\|duplicate` | `update_issue` with `state` | shared |
| `reopen(id)` | `gh issue reopen <id>` | `update_issue` | shared |
| `comment(id, body)` | `gh issue comment <id> --body-file F` | `add_issue_comment` | shared |
| `set_labels(id, set)` | `gh issue edit <id> --remove-label "*" --add-label X --add-label Y` | `update_issue` | shared |
| `set_assignee(id, ids)` | `gh issue edit <id> --add-assignee X --remove-assignee Y` | `update_issue` | shared |
| `set_milestone(id, name)` | `gh issue edit <id> --milestone "name"` | `update_issue` | shared |
| `link(id, other_id, "blocks"/"blocked-by")` | `gh api graphql -f query='mutation { addBlockedBy(...)... }'` | (no MCP equivalent yet — verify per release) | shared |
| `link(id, other_id, "related")` | comment on both with `Related #other_id` (no first-class API) | same | shared |
| `unlink(...)` | `gh api graphql` removal mutation | same | shared |
| `sub_issue_create(parent, payload)` | step 1: `gh issue create ...`; step 2: `gh api graphql -f query='mutation { addSubIssue(...) }'` (or `gh sub-issue create` if extension installed) | `add_sub_issue` (audit §3.2) | shared |
| `sub_issue_list(parent)` | `gh api graphql -f query='{ ... subIssues { ... } }'` (or extension) | `list_sub_issues` | shared |
| `sub_issue_unlink(parent, child)` | `gh api graphql` removal | `remove_sub_issue` | shared |
| `capabilities()` | static (compiled in for backend = github) | n/a | n/a |
| `raw(method, path, body)` | `gh api <path> [-X METHOD] [--input -]` or `gh api graphql -f query=...` | n/a (use shell-out) | shared |

#### 2.7.2 Capability flags (GH backend, hard-coded)

Per `EXTERNAL-RESEARCH.md` §1.8 and audit §A.2 the GH backend declares:

```
backend_name = "github"
hierarchy.supported = true
hierarchy.depth_ceiling = 8
hierarchy.children_per_parent_ceiling = 100
hierarchy.parent_per_child_ceiling = 1
dependencies.supported = true
dependencies.kinds = ["blocks", "blocked-by", "duplicates", "related"]
dependencies.per_relationship_ceiling = 50
dependencies.cross_repo_supported = "same-org-internal-only"
labels.supported = true
labels.model = "flat"
labels.per_issue_ceiling = 100
milestone.supported = true
milestone.per_issue_ceiling = 1
type_field.supported = true
type_field.values_managed_at = "org"
iteration.supported = true
iteration.where = "project"  # not on issue
custom_fields.supported = true  # via Projects v2
custom_fields.passthrough_only = true
search.language = "github-qualifier"
search.result_ceiling_per_query = 1000
rate_limits.writes_per_minute_recommended = 60   # well under 900 pts/min
rate_limits.reads_per_minute_recommended = 120
raw_escape_hatch = true
```

#### 2.7.3 `gh` extension policy

The `gh-sub-issue` extension family (audit §A.3, EXTERNAL §2.3) is
**optional**. The pack does not require it. Sub-issue ops use
`gh api graphql` by default. If the extension is present, the provider
prefers its faster path (no GraphQL header overhead, slightly cheaper
output). Detection: `gh extension list | grep -q sub-issue` at provider
init.

#### 2.7.4 GraphQL preview header policy

Audit §10.4 documents the historical preview-header opt-in for sub-issues
and dependencies. Both went GA in 2025; headers are no longer required.
The provider sends them only when an env var `PACK_TRACKER_GH_PREVIEW=1`
is set, which surfaces as a manual override for users on stale `gh` /
backend versions.

---

## 3. Tracker config and detection

This is OQ-2, OQ-5, OQ-6.

### 3.1 Where tracker config lives

A single TOML file, `tracker.toml`, **per surface**:

- **Pack repo:** `/<pack-root>/tracker.toml` (next to `PACK-CHAT.md`).
- **Client project:** `/<project-root>/docs/pack/tracker.toml`.

TOML is the choice because (a) Codex already uses TOML for `~/.codex/`,
(b) it's human-editable, (c) it avoids the JSON/YAML asymmetry that the
trinity already navigates. JSON/YAML alternatives were considered;
TOML's stronger preservation of comments and intent across edits wins
when humans edit between sessions.

Schema:

```toml
# tracker.toml — pack repo or client project tracker config
schema_version = 1

[backend]
name = "github"                 # github | linear | jira | redmine | ...
repo  = "DShaneNYC/optiquity-ai-agent-config-pack"   # GH-specific
# host = "github.com" | "github.example.com"            # for GHE
# instance = "https://my-jira.atlassian.net"            # for Jira

[mode]
state = "tracker"               # tracker | flat-file
opted_in_at = "2026-05-15T12:00:00Z"
opted_in_by = "david@shane.com"

[mirror]
enabled = true
location_backlog = "BACKLOG.md" # bare names; trinity ## Document locations resolves
location_status  = "STATUS.md"
location_changelog = "CHANGELOG.md"
regenerate_on_write = true

[id_namespace]
prefix = "BD"                   # BD for pack repo, TD for client project
# the pack does NOT renumber tracker issues; it stores its prefix-N as a marker

[cli_acceleration]
prefer = "gh"                   # gh | mcp | auto
# auto = "use mcp if configured for this CLI; else gh"

[migration]
forward_complete = true
reverse_available = true
last_forward_run = "2026-05-15T12:00:00Z"
last_reverse_run = null
mapping_file = ".pack-tracker/id-map.json"
```

A surface in flat-file mode has either no `tracker.toml` (default) or
`mode.state = "flat-file"`. The presence and content of `tracker.toml` is
the **only** mode-detection signal — no env-var sniffing, no presence-of-
file probing on `.github/ISSUE_TEMPLATE/`. One place, one decision.

### 3.2 Detection

A new skill `tracker-startup` runs as the very first step in
`pack-startup` and `pm-startup`. Pseudocode:

```
def detect_mode(surface_root):
    cfg = surface_root / "tracker.toml"  # client project: docs/pack/tracker.toml
    if not cfg.exists():
        return Mode.FLAT_FILE
    parsed = toml.load(cfg)
    if parsed["mode"]["state"] != "tracker":
        return Mode.FLAT_FILE
    if not parsed.get("migration", {}).get("forward_complete"):
        return Mode.FLAT_FILE     # opted-in but migration unfinished — treat as flat
    return Mode.TRACKER
```

Cache: detection runs once per chat session. If the user reloads the
chat, or runs `pack tracker doctor`, the cache is invalidated.

### 3.3 Trinity `## Document locations` interaction

Per `INTERNAL-INVENTORY.md` Pass B note "Trinity `## Document locations`
is the path resolver" (Implicit expectations #1, p.~1497) and `DESIGN-BRIEF.md`
§5.1 final bullet, `pm-startup` reads state files by **bare name** and
trusts the trinity table to resolve the path. Tracker mode must not break
this contract.

The decision (OQ-6): the trinity table **adds a Source column**, not a
new "location type". Existing entries stay valid in flat-file mode. New
column populated only when tracker mode is on.

Before (v10):

```markdown
## Document locations

| Document | Path | Owner |
|---|---|---|
| ARCHITECTURE.md | docs/project/ARCHITECTURE.md | Architect |
| BACKLOG.md | docs/project/BACKLOG.md | PM chat |
| STATUS.md | docs/project/STATUS.md | PM chat |
| CHANGELOG.md | docs/project/CHANGELOG.md | PM chat |
| IMPLEMENTATION_PLAN.md | docs/project/IMPLEMENTATION_PLAN.md | PM chat + planner |
```

After (v11), client-project, tracker-mode-on:

```markdown
## Document locations

| Document | Path | Source | Owner |
|---|---|---|---|
| ARCHITECTURE.md | docs/project/ARCHITECTURE.md | flat | Architect |
| BACKLOG.md | docs/project/BACKLOG.md | mirror-of-tracker | PM chat |
| STATUS.md | docs/project/STATUS.md | mirror-of-tracker | PM chat |
| CHANGELOG.md | docs/project/CHANGELOG.md | mirror-of-tracker | PM chat |
| IMPLEMENTATION_PLAN.md | docs/project/IMPLEMENTATION_PLAN.md | flat | PM chat + planner |
```

`Source` values:
- `flat` — file is the authoritative record, edited directly.
- `mirror-of-tracker` — file is a regenerated read-only mirror of tracker
  state. Direct edits will be overwritten by the next mirror regeneration.
- `tracker-only` — file does not exist; consumer must call the provider
  (this row is reserved for any future "no flat mirror" mode; not used in
  v11 ship).

`pm-startup` Step 2 uses Source as routing data: when Source = `flat`, read
the file; when Source = `mirror-of-tracker`, read the file (the mirror is
fresh and cheap), but with a footer-comment annotation that the canonical
copy is in the tracker; when `tracker-only`, call `provider.list/get`.

The validate-pack `Check 18 (check_trinity_h2_parity)` already enforces H2
parity. The new Source column is an addition to a single H2 (`## Document
locations`), so all three trinity files must add it in lockstep — the
v11 migration update touches all three identically.

### 3.4 Independence axes (pack-side ⊥ client-side)

Per `DESIGN-BRIEF.md` §5.4: a pack on tracker mode can serve a client on
flat-file mode and vice versa. The tracker.toml is per-surface; nothing
in `pack-startup` consults a client project's tracker.toml, and nothing
in `pm-startup` consults the pack's tracker.toml. The only file that
crosses the boundary is `PACK-FEEDBACK.md` (see §7.5 below).

Concretely: a project on flat-file mode never sees pack-side tracker.toml
because it does not read pack repo state at runtime. A pack on
tracker mode does not require client projects to install any tracker
config; the only interaction point is Pack Chat receiving issues filed
from the public via `gh issue create` directly (§10).

---

## 4. Issue template schemas

This is OQ-4. Per `DESIGN-BRIEF.md` §6.1 and audit §A.7 the templates must
work on Jira free's 3-level hierarchy floor as the cross-tracker safe
ceiling. They use only fields backed by `capabilities()` flags.

For GH Issues, every entry type ships as a `.github/ISSUE_TEMPLATE/<name>.yml`
*issue form*. Forms (vs Markdown templates) give us validated input fields,
labels at creation time, and structured body for the migration roundtrip
(EXTERNAL §1.1).

### 4.1 BD entry (pack-repo, pack-development)

`.github/ISSUE_TEMPLATE/bd-entry.yml`:

```yaml
name: Pack development backlog item (BD-NNN)
description: Pack-development backlog. Tracked by Pack Chat.
title: "BD: <short title>"
type: Task                          # GH org-level issue type if available
labels:
  - "bd-entry"
  - "needs-triage"                  # pack-chat removes after triage
body:
  - type: dropdown
    id: bd-type
    attributes:
      label: Type
      options: [feat, fix, refactor, docs, chore, infra]
    validations:
      required: true
  - type: dropdown
    id: bd-status
    attributes:
      label: Status
      options: [Open, Unblocked, Resolved, Cancelled, Deprecated]
      default: 0
    validations:
      required: true
  - type: textarea
    id: bd-blockers
    attributes:
      label: Blockers
      description: One per line; either issue id (#N or BD-NNN) or "phase-N".
  - type: textarea
    id: bd-unblocks
    attributes:
      label: Unblocks
      description: Informational; one issue id per line.
  - type: input
    id: bd-file-symbol
    attributes:
      label: File / Symbol
      description: Affected path or symbol (free-form).
  - type: textarea
    id: bd-description
    attributes:
      label: Description
    validations:
      required: true
  - type: textarea
    id: bd-context
    attributes:
      label: Context
  - type: textarea
    id: bd-resolution
    attributes:
      label: Resolution
      description: Filled in when status flips to Resolved.
```

Fields required per `METHODOLOGY.md` Part 7 (`Type`, `Status`, `Blockers`,
`Unblocks`, `File/Symbol`, `Description`, `Context`, `Resolution`). The
mapping to GH constructs:

| BACKLOG entry key | GH location |
|---|---|
| Type | `type` field (org-level issue type if available; otherwise `type:<value>` label) |
| Status | label set: `status:open`, `status:unblocked`, `status:resolved`, `status:cancelled`, `status:deprecated` |
| Blockers | sub-issue parent links (when `phase-N` resolves to a phase epic) + `Blocks/Blocked by` first-class dependency (when `BD-NNN` references another issue) |
| Unblocks | informational; rendered in body only (per Part 7 line 994) |
| File/Symbol | body field (kept verbatim; not a GH first-class concept) |
| Description | body |
| Context | body |
| Resolution | comment on close + `state_reason: completed` |

Auto-routing: `labels` block in the YAML form sets `bd-entry` and
`needs-triage` at creation. Pack Chat moves through the triage-to-active
pipeline by removing `needs-triage`.

### 4.2 TD entry (client project)

`.github/ISSUE_TEMPLATE/td-entry.yml`:

Same shape as BD with two adaptations:

- `title: "TD: <short title>"`.
- `bd-blockers` field renamed `td-blockers`; help text adds "may be
  `phase-N` references — see PHASE-N.yml below."
- New optional dropdown `td-scope` matching the typed-deferral comment
  taxonomy (METHODOLOGY § Part 7 line 952): `phase-N`, `dependency`,
  `feature`, `perf`, `version`. This is the auto-routing label
  (`scope:phase-N`, etc.).
- New optional dropdown `td-severity` for KNOWN GAP entries:
  `critical`, `functional`, `polish`. Auto-routes
  `severity:critical/functional/polish` label.
- Auto-routing label `td-entry`, `needs-triage`.

### 4.3 Phase epic (client project)

A new entry type for tracker-mode projects: `phase-epic.yml`. One per
phase, used as the parent of TD entries that reference `phase-N`.

```yaml
name: Phase epic
title: "Phase N — <phase title>"
type: Epic                          # GH org issue type, mapped to issue type
labels:
  - "phase-epic"
  - "phase-N"                       # filled at create
body:
  - type: input
    id: phase-number
    attributes:
      label: Phase number
    validations:
      required: true
      regex: '^[0-9]+$'
  - type: input
    id: phase-anchor
    attributes:
      label: IMPLEMENTATION_PLAN anchor
      description: Generated automatically; do not edit.
```

Phase-N membership is a sub-issue link (TD-NNN child of Phase epic) when
`hierarchy.supported`. When the backend does not support hierarchy
(Bugzilla per audit B.3), phase membership is a label
(`phase-N`) plus a `link.kind = "blocks"` to the phase-epic via the
emulation rule in §5.

The phase epic's body anchors the existing
`STATUS.md → IMPLEMENTATION_PLAN.md#anchor` link algorithm: tracker mode
keeps `IMPLEMENTATION_PLAN.md` as a flat file (Source = `flat` in the
trinity table; phases are append-only narrative), and the phase-anchor
field in the epic body stores the same computed anchor. The migration
script computes it from the phase title using the v10 algorithm
(PM-CHAT.md lines 160-165).

### 4.4 Pack-feedback entry (client → pack repo upstream)

`.github/ISSUE_TEMPLATE/pack-feedback.yml`, in the **pack** repo:

```yaml
name: Pack feedback (from a client project)
description: Defect / friction observed when using the pack on a project.
title: "PF: <short title>"
type: Bug                           # default; user can change
labels:
  - "pack-feedback"
  - "needs-triage"
body:
  - type: input
    id: pack-version
    attributes:
      label: Pack version in use
      description: Read from STATUS.md "Key Metrics" section.
    validations:
      required: true
  - type: input
    id: project-id
    attributes:
      label: Project identifier (free-form)
      description: Anonymized; for the maintainer's pattern detection only.
  - type: dropdown
    id: pf-category
    attributes:
      label: Category
      options:
        - Workflow Observation
        - Prompt Variant Observation
        - Agent Performance
        - User Friction
        - Open Question
    validations:
      required: true
  - type: textarea
    id: pf-observation
    attributes:
      label: Observation
    validations:
      required: true
  - type: textarea
    id: pf-context
    attributes:
      label: Context (project state, agent, files)
```

Source identification: every pack-feedback issue carries the
`pack-feedback` label and a body field naming the pack version. The pack
repo's Pack Chat triages by `label:pack-feedback` (§10).

The PM Chat in the client project files this issue via the upstream
mechanism in §7.5 (chat command if authenticated; otherwise the manual
fallback writes to `PACK-FEEDBACK.md` as v10 does today).

### 4.5 External user issue

`.github/ISSUE_TEMPLATE/bug-report.yml` and `.github/ISSUE_TEMPLATE/feature-request.yml`,
in the **pack** repo. Standard issue forms anyone with a GH account can
file. They auto-label `external`, `needs-triage`. Pack Chat triages
externals via `label:external` (§10).

### 4.6 Cross-tracker compatibility

For each entry type, the field mapping to non-GH backends:

| Entry / Field | GH | Linear | Jira | Bugzilla | Redmine | Notion | Trello |
|---|---|---|---|---|---|---|---|
| Title | title | title | summary | summary | subject | title (page) | name |
| Body | body markdown | description | description (ADF) | comment | description | rich text | desc |
| Status | state + label | workflow-state | workflow-state | bug-status | status | select prop | list |
| Type | type field | issue type | issue type | (none — keyword) | tracker | select prop | label |
| Blockers | sub-issue + addBlockedBy | parent + relates | sub-task + link | depends_on | parent + relates | relation | Power-Up |
| Phase epic | sub-issue parent | parent | epic | (emulate) | parent | page | board+list |

For backends without first-class hierarchy (Bugzilla, Trello), the
`link.kind = "parent"` reserved value is used and the chat warns the user
at opt-in that hierarchy is emulated.

---

## 5. Dependency model and hierarchy

This is OQ-1's hierarchy / dependency portion. Audit §A.9 requires a
3-level cross-tracker safe floor; `EXTERNAL-RESEARCH.md` §1.2 caps GH at
8-deep / 100-wide / 1-parent.

### 5.1 Pack standard dependency model

The pack uses a **3-level maximum** as its standard:

- **Level 1.** Phase epic (project) or version epic (pack repo).
- **Level 2.** TD-NNN / BD-NNN entries.
- **Level 3.** Sub-tasks within a single TD/BD when needed (rare; for
  multi-step items where checklist would not capture the work).

This fits Jira free, Shortcut (with phase epic = Epic, TD = Story; tasks
become checklists per audit B.6), GH Issues, OpenProject, Linear, Redmine,
YouTrack. It does not require hierarchy on Bugzilla or Trello (capability
flag = false).

The pack does NOT use Level 3 for the v11 ship; the field is reserved.
Designing in 3 levels (vs 2) gives one buffer level for projects that need
more than `phase → TD` granularity in a future minor. Adding a level later
is harder than reserving one now.

### 5.2 Capability-flag handling

Three branches at the chat level:

1. `hierarchy.supported = true` — use sub-issues directly.
2. `hierarchy.supported = true` and depth-needed > `depth_ceiling` —
   emulate excess depth via `link.kind = "parent"` + label tag.
3. `hierarchy.supported = false` — emulate full hierarchy via
   `link.kind = "parent"` + label `parent:<id>`.

The migration script (§6) checks at forward-migration time and, if the
project's flat-file BACKLOG implies more depth than the chosen backend
supports, **fails the migration with a clear message** rather than
silently flattening. The user can opt to flatten by re-running with
`--flatten-to-depth N` flag.

### 5.3 Reserved link.kind values, operationally

- `blocks` — `provider.list(filter={blocked_by: id})` returns issues whose
  state cannot move to "in-progress" until `id` is closed. Chat enforces by
  warning before status change.
- `blocked-by` — inverse of `blocks`. Stored once (per backend semantics)
  and inverted client-side.
- `related` — informational; does not affect status transitions.
- `duplicates` — when set, target is closed with `state_reason = "duplicate"`.
- `parent` / `child` — used only as emulation when `hierarchy.supported = false`.
  Otherwise `sub_issue_*` ops are preferred.

### 5.4 TD-NNN ↔ phase-N resolution under tracker mode

Today (v10): `// TODO(phase-N): TD-NNN` comment. PM chat holds two facts in
its head: TD-NNN exists in BACKLOG.md; phase-N exists in
IMPLEMENTATION_PLAN.md.

Tracker mode (v11):
- TD-NNN is the issue's `bd-entry`/`td-entry` label suffix and is also
  encoded in the title prefix: `TD-031: <short title>`.
- phase-N resolves to a Phase epic issue (§4.3). Sub-issue parent of the
  TD issue when `hierarchy.supported`; `link.kind = "parent"` to the
  phase-epic id when not.
- The flat-file BACKLOG mirror keeps the literal `phase-N` reference in
  the `Blockers:` field for backwards compatibility with the v10 grep
  patterns (METHODOLOGY § Part 7 Procedure 1 step 2 line 1027).

The TD-NNN identity is **owned by the pack**, not assigned by GH issue
number. We carry it as a marker:

- Title prefix `TD-031:` so it's visible in `gh issue list` output and
  searchable via `gh search issues "TD-031 in:title"`.
- Body footer HTML comment `<!-- pack-id: TD-031 -->` for migration
  idempotency (per audit §7.1 prior-art convention).
- Issue body footer comment `<!-- pack-version: v11 -->` for
  schema-evolution tracking.

This decouples TD-NNN monotonicity from GH issue numbering. The `TD counter`
rule in METHODOLOGY § Part 7 line 1015 keeps working: `pack tracker next-td`
calls `provider.search(query='in:title "TD-"')` and computes max+1.

---

## 6. Migration algorithm

This is OQ-3 and OQ-8.

### 6.0 Bidirectionality contract (first-principles invariant)

The flat-file representation and the tracker representation of every
pack-managed entry (BD-NNN, TD-NNN, phase epic, pack-feedback) are
**content-equivalent for the v10 grammar**. Forward migration writes
full content to the tracker; reverse migration writes full content
back to the flat file. Neither direction summarizes, truncates,
abridges, or projects to a smaller shape. Tracker-only enrichment
the v10 grammar cannot represent (reactions, comment threads,
attachment URLs, audit logs, v11.x-introduced fields) is captured in
the reverse-migration sidecar (§6.6, §6.6.1) and re-applied on
re-forward — never dropped, never inlined into v10 fields.

**The invariant**: for every v10-grammar field of every entry,
flat-file content == tracker content. Mirrors are full regenerations,
not summaries (§6.3). `roundtrip-test` (§6.7) is the mechanical
check: forward → reverse → forward produces zero diff (whitespace-
tolerant) on v10 grammar, byte-equivalent on the tracker side. Any
claim, code, test, doc, or behavior that violates this invariant is
a defect, not a feature.

**User-facing implication.** A project can opt into the tracker, work
in tracker mode, opt out at any time, and recover flat-file state with
no manual content reconstruction. User intervention during migration
is bounded to: (a) customization-preserve conflicts on pack-template
files only (MERGE-STRATEGY A1 — trinity/settings/config; not entry
content); (b) the Phase B opt-in dialogue; (c) explicit recovery
verbs (`pack tracker reset`, `restore-from-backup.sh`). Normal
migration of entry content is automatic.

### 6.1 Trigger / command surface

A single bash script with two subcommands, distributed in
`scripts/tracker-migrate.sh` (pack-side) and copied to `scripts/` of the
project at install / migrate time:

```
scripts/tracker-migrate.sh forward       # flat-file → tracker
scripts/tracker-migrate.sh reverse       # tracker → flat-file
scripts/tracker-migrate.sh status        # report mapping freshness
scripts/tracker-migrate.sh doctor        # validate mapping integrity
```

Both subcommands are idempotent. Forward runs at opt-in; reverse runs on
opt-out, on demand for backups, or as the final step before a pack
upgrade that would break the integration.

A wrapper command `pack tracker init` (or, plain, the chat says "set up
the tracker") performs:

1. Generate `tracker.toml` from a short user dialogue (backend, repo).
2. Validate auth (`gh auth status`).
3. Create issue templates (`.github/ISSUE_TEMPLATE/*.yml`) and the labels
   (`bd-entry`, `status:open`, etc.).
4. Run forward migration.

The script is the LCD. It works on Claude Code, Codex, Gemini equally.
Per-CLI `commands/` and slash-command shortcuts are layered above as
optional acceleration in `OPTIONAL-FEATURES.md`.

### 6.2 Forward mapping algorithm

Idempotent forward:

```
1. Read flat-file source of truth (BACKLOG.md, STATUS.md, CHANGELOG.md,
   IMPLEMENTATION_PLAN.md).
2. Parse with the same grammar pm-chat.md backlog-status-update variant uses.
3. Load mapping file (.pack-tracker/id-map.json). Empty on first run.
4. For each entry in BACKLOG.md:
   a. If the pack-id (BD-NNN/TD-NNN) is already in the mapping AND the
      tracker issue body footer matches `<!-- pack-id: TD-NNN -->`, skip.
   b. Otherwise, search the tracker for `in:title "TD-NNN"` to detect
      manual creation; if found, write to mapping and skip.
   c. Otherwise, create the issue via provider.create() with:
        - title = "TD-031: <short title>"
        - body = rendered template body (description + context +
                 file/symbol + footer marker)
        - labels = ["td-entry", "status:open", "scope:phase-N", ...]
        - type = the type field value
   d. Append to mapping: { "TD-031": { "id": "<gh-number>", "url": "..." } }
5. For each phase in IMPLEMENTATION_PLAN.md:
   a. Phase epic created similarly; mapping entry { "phase-3": {...} }.
6. For each TD entry that references phase-N, add sub-issue link:
      provider.sub_issue_create(parent=mapping["phase-N"].id, ...)
   (if hierarchy.supported = false, use link.kind = "parent" + label)
7. For each TD entry with Blockers, add link.kind = "blocked-by".
8. For each Resolved entry, close via provider.close(reason="completed").
9. For each entry's Resolution, add a comment with the resolution text.
10. Regenerate flat-file mirror files (BACKLOG.md, STATUS.md mirror).
11. Write mapping file. Update tracker.toml.migration.last_forward_run.
```

Idempotency mechanism (audit §7.1 prior-art): two redundant markers.
- **Title marker**: `TD-031:` prefix is grep-able via `gh search issues`.
- **Body footer marker**: `<!-- pack-id: TD-031 -->` is hidden from human
  rendering but preserved through edits (verified that comment HTML
  survives through GH's Markdown sanitizer; if a future GH version
  strips it, we fall back to title marker only).
- **Mapping file**: `.pack-tracker/id-map.json` is the fast path; markers
  are the recovery path.

Re-running forward after partial failure: any entry without a mapping
record but with a matching title marker upstream is recovered into the
mapping; any entry already in the mapping is skipped (no double-create).

### 6.3 What happens to flat files post-forward

**Decision:** flat files become **read-only mirrors**, regenerated on
write. They are not deleted; they are not stub-with-link.

Rationale:
- Deleting them would break every non-tracker-aware consumer in the
  pack (audit §A.5: token costs at small scale; `INTERNAL-INVENTORY.md`:
  the reader graph is massive).
- Stub-with-link forces every existing skill / prompt into a tracker
  branch — too much surface to rewrite in v11.
- Keep-in-parallel (no relationship) makes the mirror authoritative-by-
  accident — the worst outcome.
- Regenerated read-only mirrors give v10 readers the v10 file shape they
  expect, with the tracker as the source of truth. The cost is a
  regeneration step on each chat-side write, which is cheap (single
  serialization pass, no API calls beyond the write itself).

A header comment is added to mirrored files:

```markdown
<!--
  This file is a read-only mirror generated from the tracker.
  Tracker: github / DShaneNYC/optiquity-ai-agent-config-pack
  Last regenerated: 2026-05-15T12:00:00Z
  Direct edits will be overwritten. Edit via Pack Chat / PM Chat.
-->
```

The chat enforces the read-only contract: any provider call that opts to
write a mirror file is the chat itself, not an agent. Agents that try to
write mirror files surface `partial-write` error code (see §9).

### 6.4 Forward failure handling

Per audit §10.5 "forward-only with idempotent retries" pattern. Failure
modes and recovery:

| Failure point | Effect | Recovery |
|---|---|---|
| Step 4c (issue create) | one issue not created | re-run; step 4a sees marker absent, retries that issue |
| Step 6 (sub-issue link) | issue exists, parent link missing | re-run; idempotency probes "is sub-issue link already present?" via provider.sub_issue_list and skips |
| Step 7 (blocked-by link) | issue exists, link missing | re-run; idempotent via provider.list-with-filter probe |
| Step 8 (close) | issue exists open | re-run; `provider.close()` is idempotent |
| Step 10 (mirror regen) | mirror stale | re-run with `--mirror-only` flag |

The script writes a checkpoint after every 25 issues into
`.pack-tracker/forward.checkpoint.json` so a partial run is exactly
resumable.

### 6.5 Reverse migration

Triggered by:
- `scripts/tracker-migrate.sh reverse` (explicit user command).
- `pack tracker disable` chat command (which runs reverse, then sets
  `tracker.toml mode.state = "flat-file"`).
- Pack upgrade preflight, when the upgrade requires it.

Algorithm:

```
1. Provider.list(filter={label: 'td-entry' OR label: 'bd-entry'}, full body).
2. Provider.search(query='type:Epic in:title "Phase"') for phase epics.
3. For each entry:
   a. Reconstruct BACKLOG entry record:
        Type ← title prefix decode + label scope: + label severity:
        Status ← label status:*
        Blockers ← provider.list_links(id, kind='blocked-by') + sub_issue_list parent
        Unblocks ← inverse of Blockers across the dataset
        File/Symbol ← body section
        Description ← body section
        Context ← body section
        Resolution ← latest comment if status=Resolved, else null
4. Sort by TD-NNN ascending and emit BACKLOG.md.
5. For each phase epic, emit `## Phase N — <title>` headings into
   IMPLEMENTATION_PLAN.md (only if it does not already exist).
6. Emit STATUS.md from phase-epic state and TD-NNN counts.
7. Emit CHANGELOG.md by walking closed-issue audit log per phase.
8. Strip mirror header comments — output is now authoritative flat files.
9. Update tracker.toml.migration.last_reverse_run.
```

**Invariant: reverse does not touch `migration.forward_complete`.** The
reverse path updates only `mode.state` (set to `"flat-file"` by
`pack tracker disable`) and `migration.last_reverse_run`. The
`migration.forward_complete = true` flag remains set after a
disable cycle. This is benign in v11.0 because `tracker_mode()`
checks `mode.state` (not the flag) to determine the active surface.
The supported re-enable path is `pack tracker init`, which
atomically rewrites both `mode.state` and `migration.forward_complete`
in `_tmr_update_tracker_toml`. **A future `pack tracker enable` verb
(not in v11.0) MUST re-validate the entry mapping rather than rely
on the lingering `forward_complete = true` value** — otherwise
post-disable customizations to flat-file state would be silently
overwritten on re-enable. Carry-forward source:
`PACK-REVIEW-BD-131-RETRO.md` F6.

### 6.6 What if tracker has data the flat-file format cannot capture?

This is a real concern for `EXTERNAL-RESEARCH.md` §1.10 reactions, sub-issue
completion percentages, comment threads, attachment URLs.

**Decision:** the reverse migration captures what the v10 grammar
captures and **emits a sidecar file** for everything else:

`.pack-tracker/reverse.sidecar.YYYY-MM-DD.md` contains, per entry:

- Reaction counts.
- Comment thread (with author and date).
- Attachment URLs.
- Audit log of state changes.

The user is told at reverse time: "Sidecar `<path>` contains tracker-only
data not representable in flat files. Keep it for reference; it does not
roundtrip." This is also where audit §A.10 upside features (reactions,
@mentions, watchers) accumulate in tracker mode and are dropped on reverse.

### 6.6.1 Template-version drift across pack minor versions

Per `DESIGN-BRIEF.md` §3.1, every tracker-managed entry carries a
`template_version` field. Between pack v11.0 and a later v11.x, the
entry templates may add fields (per V2 §19 template-upgrade flow). A
user who opted into the tracker on v11.0, upgraded to v11.x, and
later runs reverse migration would otherwise lose any v11.x-only
field — because the v10 BACKLOG grammar cannot represent fields the
v10 grammar predates.

The reverse migration captures this drift in the sidecar:

`.pack-tracker/reverse.sidecar.YYYY-MM-DD.md` gains, per entry:

- `template_version`: the value of the entry's `template_version`
  field at reverse time (e.g., `bd-v11.2.0`).
- `extra_fields`: the set of fields present on the tracker entry
  but not representable in v10 grammar — emitted as a key/value
  block under each entry's sidecar section. Field schema is
  documented in `maintenance-docs/v11-research/templates-archive/<template_version>/SCHEMA.md`
  (the template-archive directory specified in
  `DESIGN-BRIEF.md` §3.4 P2; created by v11 install as part of this
  BD entry).
- `template_archive_path`: the relative path to the template
  archive used to produce this entry, so a re-forward migration
  can re-hydrate the v11.x-only fields deterministically.

**Round-trip behavior (§6.7 extended).** Forward → reverse → forward
is a no-op for v10-grammar fields (existing guarantee). For
v11.x-introduced fields:

- Reverse: the field is captured in the sidecar's `extra_fields`
  block.
- Re-forward: the migrator reads the sidecar, sees the entry's
  `template_version` and `extra_fields`, and re-applies them to
  the new tracker issue. The re-forward result is byte-equivalent
  on tracker side to the pre-reverse state.
- If the user manually deletes the sidecar between reverse and
  re-forward, the re-forward emits a warning per affected entry:
  "TD-NNN was created on `bd-v11.2.0` template; sidecar missing;
  v11.x-only fields will be defaulted. Run `pack tracker doctor`
  after re-forward to review." The migrator does not silently lose
  data; it surfaces the loss.

**Documentation surfacing.** The user is told at reverse time, in
addition to the existing sidecar message: "Sidecar `<path>` also
contains template-version metadata. Keep it if you intend to
re-enable the tracker later; without it, re-enable will default any
pack-version-specific fields and warn for each affected entry."

**Test coverage.** `scripts/tracker-migrate.sh roundtrip-test` (§6.7)
is extended: the test fixture now includes one entry on each of
`bd-v11.0`, `bd-v11.1`, `bd-v11.2` template versions; forward →
reverse → forward must produce zero diff on the tracker side. The
extension is exercised in CI by
`scripts/tests/tracker-migrate-roundtrip-test.sh` (listed in V3
§I.1; new file in v11), which invokes `tracker-migrate.sh
roundtrip-test` with the multi-version fixture.

### 6.7 Round-trip safety

forward → reverse → forward should be a no-op or near-no-op. The
guarantee:

- Issues created by forward keep their `<!-- pack-id: TD-NNN -->` marker.
  Reverse reads the marker and emits the same TD-NNN. Re-forward sees
  the same TD-NNN with an existing tracker issue; mapping file finds
  the issue; it's a skip.
- Status transitions, label changes, milestone moves are byte-equivalent.
- Sub-issue links are reconstructed identically.
- Comments added in tracker mode are appended to the BACKLOG entry's
  Resolution / Context as a "Tracker-only comment thread" footer **only
  if the user opts in via `--include-comments` flag**. Default is to
  drop them (sidecar instead) so the round-trip is clean.

The pack provides `scripts/tracker-migrate.sh roundtrip-test` for
verification: forward → reverse → diff against original. v10 BACKLOG.md
input should diff = 0 (or only whitespace).

---

## 7. Pack Chat / PM Chat orchestration patterns

This is OQ-9, OQ-10, OQ-11. How the chat actually operates the tracker.

### 7.1 Read patterns

Tokens-budget rule: **never bulk-fetch** (audit §A.5; EXTERNAL §6.1). The
chat asks focused queries.

Read pattern catalogue (with token cost estimates per audit §A.5):

| Intent | Pattern | Approx tokens |
|---|---|---|
| "What's open and unblocked?" | `provider.list(filter={state: open, label: status:unblocked}, fields=[number,title,labels])` | ~30 / item × N hits |
| "Show me TD-031" | `provider.get("TD-031", with_comments=false)` | ~500–2000 |
| "Walk dependency tree from TD-031" | one GraphQL one-shot via `raw(...)` | ~5K |
| "Filter by phase-3" | `provider.list(filter={label: phase-3}, fields=[number,title,labels])` | ~30 / item |
| "Show me items modified this week" | `provider.search(query='updated:>=YYYY-MM-DD label:td-entry')` | ~25 / hit |

Caching: per-session in-memory; invalidated on chat-side write. The chat
does not persist a cache to disk in v11 (premature optimization).

### 7.2 Write patterns

Single operations are the default. Batched operations are surfaced when
the user asks for them (e.g., "close TD-031 through TD-040 as completed")
and require explicit user approval before execution.

Approval gates (per `DESIGN-BRIEF.md` §3.1):

- Single create: confirm with `Created issue #N for TD-031: ...` after
  success.
- Batched ops > 5 items: chat lists the operations, asks yes/no, then
  executes.
- Cross-issue link (`blocked-by`, sub-issue): chat shows what link is
  being created and asks confirmation.
- Close of an Open or Unblocked item: chat confirms `state_reason`.

Mirror regeneration is automatic and silent on every write. If
regeneration fails, the chat surfaces `partial-write` (§9).

### 7.3 Auth flow

`gh auth login` is the canonical mechanism, shared across all three
CLIs (per audit §A.8 verified). The pack does not own auth — it consumes
whatever the user's `gh` is authenticated to.

Multi-account: `gh auth switch` is the user's tool; the pack does not
intervene. `tracker.toml [backend] repo` names the canonical repo so
the user's active `gh auth` host must own access to it.

PAT rotation: the user's responsibility. The pack surfaces 401 / 403
errors clearly per §9.

### 7.4 Per-CLI tuning

All three CLIs support the LCD `gh` shell-out path. Above the floor:

- **Claude Code.** Optional MCP server install. `OPTIONAL-FEATURES.md`
  documents `claude mcp add github --transport http https://api.githubcopilot.com/mcp/ -H "Authorization: Bearer $GITHUB_PAT"`.
  When MCP is present, the provider prefers MCP for `list`, `get`,
  `search` (cheaper structured returns) and shells out for write ops
  (less mature in MCP).
- **Codex CLI.** `~/.codex/config.toml [mcp_servers.github]` block
  documented in OPTIONAL-FEATURES. Sub-agent (Codex `~/.codex/agents/`)
  for read-side tracker work like dependency-graph walks; one Codex
  TOML per agent. Per audit §A.1 corrected: `max_threads = 6` default.
- **Gemini CLI.** `~/.gemini/settings.json` for MCP. Subagent built-ins
  (`generalist`, `codebase_investigator`) reused for read-side work.
  Per audit §12.3, wait until v0.41.0 stable (~2026-05-06) for any
  design that touches subagent internal state. Our design only touches
  invocation, which is stable across v0.40 / v0.41.

The provider picks its underlying mechanism based on
`tracker.toml [cli_acceleration].prefer`: `gh` is the safe default;
`mcp` opts into the per-CLI mechanism; `auto` decides at runtime by
probing.

### 7.5 PACK-FEEDBACK upstreaming (OQ-11)

This is the cross-surface bridge. PM Chat in a client project files a
pack-feedback issue on the public pack repo.

Mechanism:

```
1. PM Chat detects friction or pack defect during work.
2. PM Chat composes the feedback as a `## Workflow Observation` etc.
   in the local PACK-FEEDBACK.md file (this still happens in tracker
   mode — it is the local audit trail).
3. PM Chat asks: "Would you like to file this upstream to the pack repo?"
4. If user says yes:
   a. PM Chat checks `gh auth status` for write access to the pack repo.
   b. If authenticated: `provider.create(...)` against the pack repo using
      the pack-feedback.yml form fields (§4.4).
   c. Append `Filed upstream: <issue-url>` to the local PACK-FEEDBACK.md
      entry.
5. If user says no, or auth fails: leave the entry in PACK-FEEDBACK.md
   only. The user can run `pack feedback upstream --since=YYYY-MM-DD`
   later to batch-upstream.
6. Manual fallback (no `gh` available, or air-gapped): copy the entry's
   text and paste it into the pack repo's "New Issue" web UI.
```

The bridge is **one-way**. The pack's own tracker (BD-NNN) is separate;
the PM Chat does not read it. Pack-feedback issues filed from clients
arrive in the pack repo's tracker as triage candidates (§10).

This holds regardless of whether the client project is on tracker mode
or flat-file mode — `gh issue create` against the pack repo works either
way, as long as the user has `gh auth`.

---

## 8. Agent read patterns

This is OQ-9 (agent-side specifically).

### 8.1 Read mechanism per CLI

Agents are read-only. They do not call `provider.create / update / close
/ comment / link / sub_issue_*`. Their permitted operations are
`provider.list / get / search / capabilities`.

LCD: `gh issue list --json ... --limit N`, `gh issue view N --json ...`,
`gh search issues "<query>"`. Identical across Claude / Codex / Gemini.

Per-CLI optional MCP: identical strategy to chats. Where MCP is available,
read-side tools like `list_issues` with `minimal_output=true` are
preferred for cheaper structured returns. The agent prompt does not
encode the mechanism — the prompt says "query the tracker for ..." and
the chat wraps a wrapper script that picks LCD or MCP at runtime.

### 8.2 Auth context

**Decision:** agents inherit Pack Chat / PM Chat auth via the shared
`gh auth` on the host. They do **not** use a separate read-only PAT.

Rationale:
- A separate read-only PAT means the user manages two credentials.
- All v10 agent prompts already assume the host has `gh auth` — adding a
  second auth context complicates the trinity rule and adds a config
  surface for marginal security gain.
- Read-only enforcement is a chat-side rule (the agent prompt does not
  call write ops), not a credential rule.

If a project's threat model requires read-only credentials for agents,
the user can rotate `gh auth` to a read-only token via `gh auth refresh`
with reduced scopes; this is documented in `OPTIONAL-FEATURES.md` rather
than baked into the design.

### 8.3 Token-budget rules for agents

Three rules in agent prompts:

1. **Filter first, fetch second.** Use `provider.list(filter=...)` or
   `provider.search(query=...)` before any `provider.get(id)`.
2. **Field projection.** Default field set is `[number, title, state,
   labels, type, parent]` unless the agent's task requires the body or
   comments.
3. **No bulk dump.** A `provider.list` with no filter is forbidden.
   Equivalent to "do not `cat BACKLOG.md`" in the v10 world.

These are encoded as required-reading bullets in every agent prompt that
touches the tracker (currently 8 of the 10 prompts in
`project-template/docs/pack/prompts/`).

### 8.4 Prompt language change

Today (v10), `coder.md` prompt line 17 reads (paraphrased):
"Read BACKLOG.md (Phase N entries)."

Tomorrow (v11), the same prompt reads:
"Read BACKLOG entries for Phase N. Use the project's location-resolver
(see `## Document locations` in the trinity); BACKLOG entries are
sourced from the tracker when one is configured, else read the flat
file."

The prompt does not branch on mode. It names the resolver, and the
resolver picks. The prompt says "BACKLOG entries" rather than
"BACKLOG.md entries" — a small semantic change that means "the data,
not the literal file."

### 8.5 Per-agent prompt adaptation strategy

Three options were considered; the choice is option (b):

(a) **Mode-switch language in every prompt.** Every prompt says "if
tracker mode, do X; else do Y." Verbose; spreads the mode-detection
logic across 10 files.

(b) **Resolver-aware language.** Prompt names data, not file. Resolver
behind `## Document locations` picks. Used by `pm-startup` already.

(c) **Separate prompt variants per mode.** Doubles the prompt count
and creates a maintenance fork.

Choice: (b). This minimizes the surface change and reuses the existing
trinity contract. Concretely:

- Replace "Read BACKLOG.md" with "Read BACKLOG entries (resolve via
  trinity Document locations)".
- Replace "Read STATUS.md" with "Read STATUS (resolve via trinity)".
- Keep "Read IMPLEMENTATION_PLAN.md" verbatim — phases stay flat.
- Keep "Read ARCHITECTURE.md" verbatim — architecture stays flat.

The triad-compliance check (validate-pack Check 10) does not look at
prompt-body text content beyond the labelled-section structure, so this
edit does not require a check change.

`pm-startup` Step 5 (grep `TD-TBD`) is unchanged — the typed-deferral
comment system is still source-code-resident regardless of tracker mode.

---

## 9. Failure-mode UX

This is OQ-7. Per `DESIGN-BRIEF.md` §3.1 final goal: clear actionable
messages, no silent retry, no paper-over.

For each failure type from §2.5, the user-facing behaviour:

### 9.1 Network unreachable

**Detection.** `gh` exit nonzero with `dial tcp` / `Could not resolve
host` on stderr. MCP transport returns connection error.

**Message shape:**
```
Tracker unreachable.
Backend: github (DShaneNYC/optiquity-ai-agent-config-pack)
Underlying: dial tcp api.github.com:443: i/o timeout
The flat-file mirror at <path> was last regenerated <relative time>;
the chat can read it for context but cannot write until the tracker is
reachable. Try `gh api rate_limit` to confirm connectivity.
```

**Auto-recovery.** None. The user fixes the network or waits.

**Manual fallback.** Read-only continued operation against the mirror.
Writes are queued only as user-visible "I'd file this when reconnected"
acknowledgements, not as a hidden write log (per "no silent retry").

### 9.2 Rate-limit hit

**Detection.** HTTP 403 with `X-RateLimit-Remaining: 0`. GraphQL `errors[].type
== "RATE_LIMITED"`. `gh search` 30/min sub-bucket separately.

**Message shape:**
```
Rate limit reached on github.
Bucket: REST search (30/min)
Reset: in 47s (at 14:23:00 UTC)
Suggestion: this query was a search; use `provider.list(filter=...)`
which uses the 5,000/hr core bucket instead. Re-run after the reset
window.
```

**Auto-recovery.** None. The chat **does not retry** (audit §10.2: rate-limit
retries amplify the outage).

### 9.3 Auth expired / missing

**Detection.** 401 / `gh auth status` reports expired or absent.

**Message shape:**
```
Tracker auth expired.
Run: gh auth login
After: re-run the operation. If you have multiple GitHub accounts
configured, use `gh auth switch` first.
```

**Auto-recovery.** None.

### 9.4 Auth scope insufficient

**Detection.** 403 with documented `X-OAuth-Scopes` mismatch.

**Message shape:**
```
Tracker auth has insufficient scope for this operation.
Required: write:issue
Current scopes: read:org, repo:public_only
Run: gh auth refresh -s write:issue
After: re-run the operation.
```

### 9.5 Schema reshape

**Detection.** GraphQL field absent, type mismatch, or "field not found"
errors. Audit §10.4 documents this for sub-issues during preview.

**Message shape:**
```
Tracker schema unexpected.
Operation: sub_issue_create
Underlying: GraphQL field 'addSubIssue' not found on type 'Mutation'.
Run: pack tracker doctor
This refreshes the capability cache and reports any backend changes.
If the doctor reports the GH API has changed the schema, file a
pack-feedback issue.
```

**Auto-recovery.** `pack tracker doctor` re-probes capabilities and
suggests a workaround (e.g., switch to extension; use raw GraphQL header
override).

### 9.6 Partial-write recovery

**Detection.** Multi-step compound op surfaces a per-step success/failure
list.

**Message shape:**
```
Operation 'create with sub-issue link' partially succeeded.
Step 1 (create): OK — issue #142 created.
Step 2 (link to phase epic #58): FAILED — addBlockedBy returned 422.
Underlying: linked issue #58 is closed; cannot block from a closed parent.
Resume options:
  (a) Re-open #58 first, then re-run.
  (b) Skip the link and finalize without phase membership.
  (c) Discard #142 (delete) and re-attempt the whole op after fixing #58.
```

**Auto-recovery.** None automatic. The user picks. The mapping file
records the partial state so re-run resumes correctly.

### 9.7 Pack misroutes a write

**Detection.** Agent attempts a write op while in tracker mode, or chat
attempts a flat-file write while in tracker mode.

**Message shape:**
```
Pack misroute.
Mode: tracker
Caller: pack-coder agent (read-only)
Attempted: write to BACKLOG.md (mirror file)
This is a pack defect: agents must not write the mirror; mirrors are
regenerated by Pack Chat / PM Chat after a tracker write.
The write was rejected. Please file a pack-feedback issue with the
agent name and the action that triggered this message.
```

**Auto-recovery.** Reject the write. Surface a pack-feedback prompt to
the user.

This catches the failure that v11 is most likely to introduce: a v10-era
agent that still writes BACKLOG.md directly. The mirror file's read-only
header (§6.3) is the static documentation; this is the runtime guard.

---

## 10. External issue triage workflow

This is OQ-14. Pack repo as receiver of external issues.

### 10.1 How external users file

Three issue forms in the pack repo (§4):

- `bug-report.yml` (`labels: external, needs-triage, type:bug`).
- `feature-request.yml` (`labels: external, needs-triage, type:feature`).
- `pack-feedback.yml` (`labels: pack-feedback, needs-triage`).

The `config.yml` for issue templates points the "blank issue" link off
to a `contact_links` entry that nudges users toward the right form.
Blank-issue creation is allowed (per `EXTERNAL-RESEARCH.md` §1.1) but
with the `needs-triage` label auto-applied via a GH Action — out of
scope for v11 chat-side; flagged in `OPTIONAL-FEATURES.md`.

### 10.2 How Pack Chat discovers / triages

Pack-startup skill gains a Step 7 in tracker mode:

```
7. Triage queue:
   provider.list(filter={label: 'needs-triage'}, fields=[number, title, labels])
   Report the first 10 by created_at desc.
```

The Pack Chat user can then say "triage external #42":

- Pack Chat reads the issue.
- Pack Chat decides:
  - **Internal pack work** → re-label `bd-entry`, remove `needs-triage`,
    set `status:open`, add to active-version mapping (BD-NNN if it
    becomes a backlog item).
  - **Pack-feedback** → re-label `pack-feedback` accept (already there
    if filed via pack-feedback.yml), remove `needs-triage`.
  - **Out of scope** → close with `state_reason: not_planned` + comment
    explaining where the user should go (Discussions, an upstream
    project, etc.).
  - **Duplicate** → close with `state_reason: duplicate` + sub-issue
    link to the existing issue.

### 10.3 Auto-routing labels at intake

Forms set initial labels:

| Form | Auto-labels |
|---|---|
| bug-report.yml | external, needs-triage, type:bug |
| feature-request.yml | external, needs-triage, type:feature |
| pack-feedback.yml | pack-feedback, needs-triage |
| bd-entry.yml | bd-entry, needs-triage |

The `needs-triage` label is uniform across all intake. It comes off
during Pack Chat triage; `external` and `pack-feedback` persist as
provenance markers.

### 10.4 Boundary between external-filed and pack-internal

Visibility:
- `external` label = filed by anyone with a GH account; visible in the
  pack-repo Issues list to all readers.
- `pack-feedback` label = filed via the upstream mechanism from a client
  project, also visible publicly.
- `bd-entry` label = pack-internal, may be filed via pack-feedback that
  was upgraded by Pack Chat.

Lifecycle:
- External / pack-feedback enters with `needs-triage`.
- Pack Chat triages within ~7 days (convention; not enforced).
- Triaged externals either become `bd-entry`, get closed, or stay as
  external advisory items the pack acknowledges but does not own.
- All three label families coexist on the same issue when relevant
  (e.g., an external bug-report that becomes pack work has
  `external + bd-entry`, no `needs-triage`).

The pack repo is intentionally permissive. The pack does not police
external content; it triages and either takes ownership or closes with
clear explanation.

---

## 11. License interaction

This is OQ-13. The new LICENSE.md §3.3 distinguishes Use from
Distribution.

### 11.1 Read of v11's design against §3.3

Cited LICENSE §3.3 (lines 86–134, fetched 2026-04-30):

- Internal use of the Pack inside an organization (employees, contractors)
  is **Use**. No public free version required.
- Operating a paid web service that exposes the Pack's behavior, content,
  or methodology to customers is **Distribution**. Public free version
  required.

### 11.2 Where v11 sits

v11 adds:
1. A tracker provider abstraction layer (code in `scripts/`).
2. Issue templates (`.github/ISSUE_TEMPLATE/*.yml`).
3. A migration script.
4. A new skill (`tracker-startup`).
5. Updates to existing skills and trinity files.

None of these are file-types that change the Use vs Distribution
boundary. A SaaS that runs Pack-driven agents already triggered §3.2 in
v10 (the SaaS exposes Pack behavior). v11 does not move the boundary.

### 11.3 Specific concerns the architect considered

- *An agent inside a paid customer-facing service reads the tracker.*
  Reading the tracker is reading data owned by the SaaS operator, not by
  the Pack. The agent is doing the same activity it does today reading
  BACKLOG.md — calling out to a different store. The Pack's role is the
  read mechanism (provider abstraction); the data is the SaaS operator's.
  No license change.
- *The pack writes a tracker on behalf of a customer.* Same conclusion:
  the data is the customer's; the Pack provides the write mechanism.
- *The pack ships issue templates that, when copied into a customer's
  GH repo, contain pack code.* The issue template YAML is a small,
  prescriptive artifact — it describes the entry shape, not the pack
  behavior. Distributing the templates as part of a SaaS already triggers
  §3.2 (any pack file in a paid product triggers the public-free-version
  requirement); the architecture does not change this.
- *The migration script reads the customer's tracker data and emits flat
  files.* The script is pack code. Running it inside a SaaS as part of a
  paid customer-facing service is the same Distribution boundary as v10's
  agent prompt files; v11 does not introduce a new license trigger.

### 11.4 Decision

v11 has **no new license interaction beyond v10**. The Use/Distribution
boundary is unchanged. The pack-feedback upstream mechanism (§7.5) creates
issues *on the pack repo*, which is public; that's reading and writing
public GH data, not Distribution.

The architecture documents nothing license-relevant in `OPTIONAL-FEATURES.md`
or in `tracker.toml`. No conditional licensing applies.

---

## 12. Token economy verification

This is OQ-15.

### 12.1 What "token cost reduction after opt-in" means

Per `DESIGN-BRIEF.md` §3.1: "Token saving is observed (measurable
improvement) but is **a side effect, not a design driver**."

Therefore the verification is a **post-shipping measurement**, not a
gating criterion. It establishes the side-effect was observed, not that
the design depends on it.

### 12.2 Test fixture design

Two snapshots:

1. **Pre-opt-in baseline (flat-file mode).**
   - Project at OT scale (~340 active TD-NNN, ~60 phases).
   - Run a fixed task list through PM Chat:
     - "What's open and unblocked?"
     - "Show me TD-031 and its blockers."
     - "List items affecting phase-3."
     - "What was resolved last week?"
     - "Walk dependency tree from TD-031 to leaves."
   - Record per-task input + output token counts (Anthropic / OpenAI /
     Google APIs all expose per-call token counts).

2. **Post-opt-in tracker mode.**
   - Same fixture, same tasks, same prompts.
   - Provider routes through GH Issues.
   - Mirror files exist but the tasks call provider directly via
     resolver.

### 12.3 What "passing" looks like

A passing measurement (loose; this is a side-effect verification):

- Median token cost across the 5 tasks reduced by ≥ 30% in tracker mode.
- No task in tracker mode is more than 1.2× the flat-file token cost
  (the upper guardrail prevents the design from regressing on small
  scale).
- Per-task latency in tracker mode is ≤ 3× flat-file (acknowledging
  network round-trip cost).

If the measurement fails the 30% median goal, the v11 ship still
proceeds — the side-effect was not realized this version, but the
correctness goals (consistency, dependency graph, agent ergonomics,
external user issue filing) were the design drivers.

### 12.4 Ongoing measurement

The fixture is committed to `maintenance-docs/v11-token-fixture/` and
re-run at every minor version bump (v11.1, v11.2, ...). Drift across
versions surfaces in CHANGELOG with the measurement delta.

---

## 13. Per-CLI capability matrix

For each backend × CLI, what's available where. Citations to
`EXTERNAL-RESEARCH.md` §11 / §12 and `RESEARCH-AUDIT.md` §A.8.

### 13.1 GitHub Issues

| Capability | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| LCD `gh` shell-out | yes (Bash tool) | yes (`local_shell`) | yes (`run_shell_command`) |
| MCP server config location | `~/.claude.json` or `claude mcp add github` | `~/.codex/config.toml [mcp_servers.github]` | `~/.gemini/settings.json` |
| MCP server PAT injection | `-H "Authorization: Bearer ..."` | `bearer_token_env_var = "VAR"` | `${VAR}` env-expansion in `env` block |
| Native subagent for tracker reads | `.claude/agents/<name>.md` (e.g., pack-tracker-reader) | `~/.codex/agents/<name>.toml` (GA 2026-03-14, audit §12.2 corrected) | `@codebase_investigator` built-in or community subagent |
| `gh-sub-issue` extension | install once per machine | install once per machine | install once per machine |
| Hooks / pre-write guardrail | `~/.claude/hooks/` (audit §A.1 missing) | `[hooks]` in plugin bundle (audit §12.2) | not yet stable |
| Read-only MCP toggle | via `--exclude-tools` (audit §A.4) | same | same |

Per audit §A.8 gotcha #4: subagent invocation differs across all three
(Claude `Task` tool / `--agent`; Codex spawning model with
`agents.max_depth = 1`, `max_threads = 6`; Gemini `@subagent-name`).
The provider abstraction does not call subagents directly — it calls
`gh` or MCP. Subagents are an optional acceleration the chat may use
to delegate read-side work.

### 13.2 Linear (future)

| Capability | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| Linear MCP server (official, audit §A.7) | `claude mcp add linear --transport http https://mcp.linear.app/mcp` | `[mcp_servers.linear] url = "https://mcp.linear.app/mcp"` | `~/.gemini/settings.json` mcp block |
| LCD CLI | community Linear CLIs (none first-party) | same | same |
| Auth | OAuth 2.1 via MCP | OAuth 2.1 | OAuth 2.1 |

Linear is the easiest second backend per audit §A.7: official remote MCP
with OAuth 2.1; sub-issue and link operations are first-class.

### 13.3 Jira / Redmine / Bugzilla / OpenProject / YouTrack / Shortcut / ClickUp / Notion / Trello (future)

These are not v11 ship targets but the abstraction supports them. Per
audit Part B each has at least one community MCP server; LCD is
community CLI or `curl`-equivalent. The provider for each lives in
`scripts/tracker-providers/<name>.sh` (LCD) plus optional `.mcp.json`
(per CLI). Implementation is a planner concern post-v11.

---

## 14. Tracker compatibility matrix

Per supported tracker × required capability. Ranges from "PASS" to
"FAIL via emulation" to "FAIL hard."

| Backend | Hierarchy | Dependencies | Labels | Sprints | Custom fields | OT-3× scale | First-class in v11? |
|---|---|---|---|---|---|---|---|
| GitHub Issues | PASS (8/100/1) | PASS (50/rel) | PASS (100/issue) | via Projects v2 | via Projects v2 (passthrough) | PASS | **YES** |
| Linear | PASS (no documented depth cap) | PASS (typed) | PASS (hierarchical) | PASS (cycles) | PASS | PASS | NO (next minor candidate) |
| Jira (Atlassian Free) | PASS at ≤3 levels (audit B.1 hard cap) | PASS (30+ types) | PASS | PASS | PASS (passthrough) | PASS | NO |
| Redmine | PASS (unbounded) | PASS | partial (categories) | via plugin | PASS | PASS | NO |
| Bugzilla | EMULATE (no native; via depends_on) | PASS (typed) | PASS (keywords) | none | PASS | PASS | NO |
| OpenProject Community | PASS | PASS | PASS | PASS | PASS | PASS | NO |
| YouTrack Free | PASS | PASS | PASS (tags) | PASS | PASS | PASS (10 users) | NO |
| Shortcut | PASS at ≤2 levels (audit B.6 cap) | PASS | PASS | PASS (Iterations) | limited on free | PASS (10 users) | NO |
| ClickUp Free | PASS | PASS | PASS | limited | PASS (100-uses cap) | CONDITIONAL | NO |
| Notion (single-user) | nested pages | relation props | multi-select | none | PASS | PASS (single-user) | NO |
| Trello Free | EMULATE (Power-Up) | EMULATE (Power-Up) | PASS (board-scoped) | none | EMULATE | CONDITIONAL (10-board cap) | NO |

For backends marked EMULATE, the provider declares
`hierarchy.supported = false` (or `dependencies.supported = false`), and
the chat / migration uses `link.kind = "parent"` + label as the
fallback. The pack does not pretend a backend has a feature it doesn't.

For Trello and Notion-multi-user, the user gets a clear "this backend
does not pass scale fit at OT-3×" message at `pack tracker init` time
(per audit `RESEARCH-AUDIT.md` §B.7 / §B.9).

---

## 15. Pre-existing tracker integration

This is OQ-12. Whether/how the pack interacts with a project's
existing Linear / Jira if it's already in use.

### 15.1 The decision

**Decision: defer to a post-v11 minor release.**

Rationale:
- v11's core scope is large enough already. Cross-tracker abstraction +
  GH first-class + bidirectional migration + cross-CLI parity is the
  primary work.
- Adding "co-existence with pre-existing trackers" doubles the surface:
  the pack would need to read a pre-existing tracker without managing
  it, which is a different set of guarantees than "managed tracker with
  migration."
- The user-facing question "do you want the pack to manage your existing
  Linear?" has at least three answers (yes, integrate; no, ignore;
  no, but mirror). The architect's bias per `DESIGN-BRIEF.md` OQ-12 is
  to make this work — but not in v11.

### 15.2 What v11 does instead

v11 supports:
- A project that is using Linear / Jira independently of the pack stays
  on flat-file mode with the pack. The pack does not interact with
  Linear / Jira at all.
- A project can opt in to GH Issues for the pack-managed work (BD/TD
  flow) and continue to use Linear / Jira separately for product work.
  The two trackers do not communicate.

This is a clean default. It avoids the worst outcome — a half-integrated
state where the pack has a partial view of the user's Linear and the
chat behaves inconsistently.

### 15.3 What a future minor would add

A `[external_trackers]` block in `tracker.toml`:

```toml
[external_trackers]
[external_trackers.linear]
enabled = true
mode = "read-only"          # or "two-way-link"
workspace = "..."
```

The pack would read external-tracker issues for cross-reference (e.g.,
"a TD-031 entry can name `LIN-123` as related") but not author them. A
two-way-link mode would file pack issues with a `<!-- linear-id: LIN-123 -->`
back-reference in the body, mirroring the sync-tool pattern from
`EXTERNAL-RESEARCH.md` §8.3.

Concrete BD entries for this feature are out of scope for the planner's
v11 work.

---

## 16. Decisions

One row per OQ from `DESIGN-BRIEF.md` §7. Each decision references the
architecture sections that argue it.

| ID | Date | Decision | Rationale | Resolves | Sections |
|---|---|---|---|---|---|
| D-1 | 2026-04-30 | Provider abstraction surface = the 18 ops in §2.1 (`list / get / search / create / update / close / reopen / comment / set_labels / set_assignee / set_milestone / link / unlink / sub_issue_create / sub_issue_list / sub_issue_unlink / capabilities / raw`) with `Issue` shape in §2.2, capability flags in §2.3, error model in §2.5, pagination in §2.6. | Smallest surface that supports GH + Linear + Jira free without crippling any (audit §A.9, EXTERNAL §8.5). Adds the three audit-required additions: capability flags, open-string `link.kind`, depth-ceiling capability. Per `EXTERNAL-RESEARCH.md` §8.6, ships with `raw(...)` escape hatch. | OQ-1 | §2 |
| D-2 | 2026-04-30 | Tracker config = single `tracker.toml` per surface (`/<pack-root>/tracker.toml`; `/<project-root>/docs/pack/tracker.toml`). TOML chosen over JSON/YAML for human-edit hygiene and Codex parity. | One file = one decision. Pack-side and client-side are independently configured per `DESIGN-BRIEF.md` §5.4. | OQ-2 | §3.1 |
| D-3 | 2026-04-30 | Migration command surface = bash script `scripts/tracker-migrate.sh forward / reverse / status / doctor`. Wrapper command `pack tracker init` orchestrates first-time setup. Per-CLI slash-commands documented as optional acceleration in `OPTIONAL-FEATURES.md`. | LCD bash works on all three CLIs. Avoids per-CLI subcommand sprawl. | OQ-3 | §6.1 |
| D-4 | 2026-04-30 | Issue templates = GH issue forms (YAML) for BD-entry, TD-entry, phase-epic, pack-feedback, bug-report, feature-request. All required-field validation lives in the form. Cross-tracker fidelity matrix in §4.6. Auto-routing labels (`needs-triage`, `bd-entry`/`td-entry`, `external`, `pack-feedback`) at intake. | Issue forms (vs Markdown templates) give validated input + structured roundtrip (EXTERNAL §1.1). The 3-level hierarchy floor (audit B.1, EXTERNAL §6.1) is honored; the design uses 3 levels max (Phase epic → TD → optional sub-task). | OQ-4 | §4 |
| D-5 | 2026-04-30 | Mode detection = presence and content of `tracker.toml`. `mode.state = "tracker"` AND `migration.forward_complete = true` ⇒ tracker mode; else flat-file mode. No env-var sniffing, no file-presence probing. Cached per chat session; invalidated by `pack tracker doctor`. | One signal, one place. Avoids drift between multiple sources of mode-truth. | OQ-5 | §3.2 |
| D-6 | 2026-04-30 | Trinity `## Document locations` table gains a `Source` column (`flat` / `mirror-of-tracker` / `tracker-only`). The table remains the path-resolver authority. Tracker mode does not introduce a new "location type"; it tags rows. All three trinity files update in lockstep per the trinity rule. | Per `INTERNAL-INVENTORY.md` Implicit expectations #1, the trinity is the resolver. Adding a column is the smallest change that signals mode to all consumers without breaking v10 readers. | OQ-6 | §3.3 |
| D-7 | 2026-04-30 | Failure-mode UX = typed error codes (§2.5) with verbose surface to user, no silent retry, mirror remains readable as fallback during network/auth failures. Specific message shapes in §9. | `DESIGN-BRIEF.md` §3.1 final goal: clear actionable messages, no silent retry. | OQ-7 | §9 |
| D-8 | 2026-04-30 | Reverse migration = same script (`tracker-migrate.sh reverse`); also triggered by `pack tracker disable`. Reconstructs BACKLOG.md / STATUS.md / IMPLEMENTATION_PLAN.md / CHANGELOG.md to v10 grammar. Tracker-only data (reactions, attachments) → sidecar file `.pack-tracker/reverse.sidecar.YYYY-MM-DD.md`. Round-trip verified by `roundtrip-test`. | Per `DESIGN-BRIEF.md` §3.1: "Reverse migration is mandatory." Sidecar avoids data loss while keeping the v10 grammar pristine. | OQ-8 | §6.5 / §6.6 / §6.7 |
| D-9 | 2026-04-30 | Agent reads = LCD `gh` shell-out is universal. MCP per-CLI is optional and used when configured. Same answer for pack repo and client projects. Read-only enforcement is a chat-side rule, not a credential rule. | LCD works without per-CLI tooling install. MCP is the optional acceleration documented in `OPTIONAL-FEATURES.md`. | OQ-9 | §8 |
| D-10 | 2026-04-30 | Auth = single `gh auth` per machine, shared across CLIs and Pack/PM Chat / agents. PAT vs OAuth = whatever `gh auth login` chose (browser OAuth default, PAT supported). Multi-account via `gh auth switch` is the user's tool. | Per audit §A.8, all three CLIs accept `gh`-managed auth. One credential surface is simpler than two and matches existing v10 conventions. | OQ-10 | §7.3 |
| D-11 | 2026-04-30 | PACK-FEEDBACK upstream = chat command (when `gh auth` allows write to pack repo); manual fallback (web UI paste) when not. PACK-FEEDBACK.md remains the local audit trail in both modes. The bridge is one-way (client → pack repo); no cross-tracker subscription. | `DESIGN-BRIEF.md` §3.2: "with a manual fallback if auth/tools are unavailable." Avoids coupling the two surfaces (independence axes). | OQ-11 | §7.5 |
| D-12 | 2026-04-30 | Pre-existing tracker integration = **deferred to a post-v11 minor**. v11 ships GH Issues only as the pack-managed tracker; projects continue using Linear / Jira independently with the pack on flat-file mode. | Cross-tracker integration is a different problem (read-only mirror vs managed) and would double the v11 scope. The architect's `DESIGN-BRIEF.md` OQ-12 bias is to defer rather than ship half-integrated. | OQ-12 | §15 |
| D-13 | 2026-04-30 | License interaction = none new in v11 vs v10. The Use vs Distribution boundary in LICENSE §3.3 is unchanged: a SaaS exposing pack behavior already triggers §3.2 in v10; v11 does not introduce a new trigger. The pack-feedback upstream is public-data activity, not Distribution. | Reading customer tracker data is reading customer's data; the Pack provides the mechanism. No new file-types relevant to §3.2 trigger. | OQ-13 | §11 |
| D-14 | 2026-04-30 | External-issue triage = `needs-triage` label intake + Pack Chat triage queue (pack-startup Step 7 in tracker mode). Labels `external` / `pack-feedback` persist as provenance. | Single triage label (`needs-triage`) is the agent-readable shape. Lifecycle and label families documented in §10. | OQ-14 | §10 |
| D-15 | 2026-04-30 | Token measurement = post-shipping side-effect verification, not gating. Test fixture in `maintenance-docs/v11-token-fixture/` with 5 canonical tasks at OT-3× scale. Median ≥30% reduction is a passing observation; no task >1.2× flat-file is the upper guardrail. Re-run at every minor. | Per `DESIGN-BRIEF.md` §3.1: token saving is a side-effect, not a design driver. Verification establishes the side-effect; failure does not block the ship. | OQ-15 | §12 |

---

## 17. Risks and open trade-offs

### 17.1 Risks

**R1. Mirror staleness.** If the chat fails between a tracker write and the
mirror regeneration, the mirror is stale. Detection: the mirror header
comment carries a `Last regenerated` timestamp; `pack tracker doctor`
compares it against the tracker's most recent `updatedAt`. Recovery:
`pack tracker mirror-rebuild`. The risk is real but bounded — every chat
write is followed by mirror regen; the failure window is one operation.

**R2. v10 agents writing the mirror.** A coder agent that follows v10
prompt language ("write to BACKLOG.md") will hit the §9.7 misroute guard
in tracker mode. We catch it; we surface a pack-feedback prompt;
the user files an upstream issue. But the user-experience cost is real
during the v11 transition window. Mitigation: the v11 ship updates all
10 agent prompts to use resolver-aware language (§8.4). Coder prompts in
particular need a careful rewrite.

**R3. Flat-file consumers that bypass the resolver.** `INTERNAL-INVENTORY.md`
documents some consumers (validate-pack Check 3, reviewer.md grep) that
read flat files directly without consulting `## Document locations`.
Most of these are pack-side validators / reviewer greps that target the
pack's own BACKLOG.md (always flat) or the source-code TD-TBD literals
(unrelated to tracker mode). Audit them at planner time.

**R4. GH issue-body 65,536-char gzipped wire size.** Audit §A.2's verified-
with-qualification finding: one BD entry with a very large IMPLEMENTATION_PLAN.md
narrative could blow this. The mitigation: BACKLOG entry bodies are short
by design (Description, Context, Resolution); the long-form lives in
ARCHITECTURE.md or IMPLEMENTATION_PLAN.md, both of which stay flat.
If a future entry-shape change makes bodies grow, the splitter logic
becomes necessary; we do not pre-build it.

**R5. Capability drift.** Backend providers cache `capabilities()` at chat
session start. If the backend grows new fields (audit §12.4: GH MCP
tool surface is growing), the cache misses them. Mitigation:
`pack tracker doctor` re-probes; planner wires a "capabilities cache
TTL" of 24 hours for the chat-side cache.

**R6. Sub-issue / dependency depending on `gh-sub-issue` extension.**
Audit §A.3: cli/cli #10298 is still open. Until `gh issue sub-issue`
ships natively, the provider depends on `gh api graphql` paths. Risk:
the GraphQL schema changes in a way that breaks the query.
Mitigation: §2.7.4 preview-header policy; capability cache; doctor
command. Long-term: when native `gh issue sub-issue` ships, the provider
prefers it.

**R7. Codex `max_threads = 6` default vs documented "8 concurrent".**
Audit §A.1 corrected: 6 is default, 3–5 is the practical sweet spot.
v11 design does not depend on subagent concurrency for correctness; it
only matters if the planner's BDs use parallel subagents. Flagging for
the planner.

**R8. Linear official MCP server (audit §A.7 missing) shifts the
abstraction calculus for the future Linear backend.** No v11 risk; v11
does not ship Linear. The planner of the next minor that adds Linear
should re-read audit §A.7 and §13.2.

**R9. Trinity `## Document locations` table-shape change is a breaking
change for v9-era projects.** The Source column is new in v11. Projects
that migrate v9 → v10 already had a `## Document locations` table without
Source; v11's migration script must add the Source column to all three
trinity files. Scoped migration step: the v10 → v11 migration is a
separate BD that the planner sequences ahead of tracker-mode opt-in.

**R10. The pack's own validate-pack.py Checks 16 / 18 / 19 must pass on
the v11 trinity changes.** Specifically: Check 16
(`check_trinity_addenda_h2`), Check 18 (`check_trinity_h2_parity`),
and Check 19 (`check_trinity_no_scaffolding_comments`). Check 18's
H2-parity check passes (we add a
column to the same H2 across three files), but the addition of Source as
a column is parser-text-equivalent on all three files; the H2 list is
unchanged. The planner verifies validate-pack passes after the trinity
column edit.

### 17.2 Open trade-offs

**T1. Mirror file vs no mirror.** I chose to keep a regenerated mirror
(§6.3). The cost is a regen on every chat-side write and the risk of
mirror staleness (R1). The benefit is that v10's massive consumer graph
keeps working. Alternative: no mirror; force every consumer to call the
provider via resolver. Rejected because the v11 surface change would be
too large; the cost outweighs the elegance.

**T2. Title prefix `TD-031:` vs body-only marker.** I chose both (title +
body footer + mapping file) for redundancy. The cost is title-grep noise
in `gh issue list`. The benefit is migration idempotency under partial
failure. Could consider title-only in a future minor, but the redundancy
is cheap.

**T3. Sub-issue link via `gh api graphql` vs `gh-sub-issue` extension.**
I chose `gh api graphql` as the default and prefer the extension when
present. The cost is GraphQL header overhead. The benefit is no install
requirement on the user's machine. The pack does not bootstrap the
extension.

**T4. Read-only enforcement = chat-side rule vs separate read-only PAT.**
I chose chat-side (§8.2). The cost is "the agent could in principle
write but the prompt forbids it." The benefit is one credential, no
additional config. A future minor could add a `[auth.agents]` config
block for users who want hardware-enforced read-only.

**T5. `pack tracker doctor` as a recovery tool vs auto-recovery.**
I chose explicit `doctor` command and no auto-recovery. The cost is
one more verb the user must learn. The benefit is `DESIGN-BRIEF.md` §3.1
final goal: no silent papering-over. The user always sees the
diagnostic before taking action.

**T6. Flat-file mode is the default forever vs eventual tracker-default.**
I chose flat-file default. v11 does not preview a future where tracker
becomes default. If, in a v13 or later, the pack maintainer wants
tracker-default, the migration design supports it: the absence of
`tracker.toml` would simply trigger a one-time prompt at first chat
session. Out of scope for v11.

### 17.3 Things the planner / reviewer should challenge

The pack-reviewer should specifically test:

1. **Trinity rule compliance.** The `## Document locations` Source column
   addition must propagate to all three files; the H2 parity check still
   passes; validate-pack 16/17/18 still pass.
2. **Round-trip safety on OT.** The roundtrip-test against OT's
   `/Users/david/Developer/OptiquityTrader` BACKLOG.md must produce a
   diff = 0 (or whitespace-only) result. If it fails, find the entry-
   shape detail being lost and fix the migration grammar.
3. **Token-budget cost on 5 canonical queries.** Per §12.3. If the
   measurement comes in below 30% median reduction, that's an
   architectural signal: either the provider is over-fetching or the
   field projection isn't aggressive enough. Adjust before ship.
4. **Failure-mode UX correctness.** Each of §9.1–§9.7 has a message
   shape; the reviewer should run a fault-injection harness that forces
   each error type and verify the message is the exact shape
   prescribed.
5. **Backend capability declaration.** The GH backend's hard-coded
   capability flags (§2.7.2) must match the live GH API. The reviewer
   should compare them against `gh api meta` and the published
   GH changelog at review time.
6. **Mirror file write-protection.** A v10 coder agent that runs
   `Edit BACKLOG.md` in tracker mode must hit the §9.7 guard. The
   reviewer's fault-injection harness must verify this.
7. **Pre-existing tracker non-interference.** A project that uses Linear
   for product work and the pack on flat-file mode must observe zero
   interaction between the two; the pack does not call Linear at all.
   Verify with a dry-run.

The pack-planner should specifically:

1. Sequence the BDs so that v10 → v11 trinity column addition lands
   before tracker-mode opt-in is exposed in any chat command.
2. Carve the migration script (`tracker-migrate.sh`) into its own BD,
   not bundled with the provider abstraction BDs. Migration touches
   v10 grammar parsers; provider abstraction touches new code.
3. Treat `OPTIONAL-FEATURES.md` updates as a separate BD per CLI
   (Claude MCP, Codex MCP, Gemini MCP) so each can ship and be tested
   independently.
4. Plan a separate BD for the `## Document locations` Source-column
   trinity edit, since it is a v10 → v11 incompatible change for
   downstream projects.

### 17.4 What I deferred

- **OQ-12 (pre-existing tracker integration).** Deferred to a future
  minor with rationale in §15. The decision row is D-12.
- **`gh issue sub-issue` native subcommand.** Out of pack control;
  watching cli/cli #10298. Provider uses `gh api graphql` until the
  native subcommand ships.
- **Webhook-driven CI hooks.** `EXTERNAL-RESEARCH.md` §11.5 names
  these as adjacent extension points. Not in v11 chat-side scope.
- **Notion-as-tracker for multi-user free-tier projects.** Audit §B.7
  shows it fails the 1,000-block cap at OT-3× scale. Documented in §14;
  not in v11.
- **`/install-github-app`** per `DESIGN-BRIEF.md` §1. Not architected.
- **A separate `[auth.agents]` config block** for hardware-enforced
  agent read-only. Trade-off T4. Not in v11.

---

## Appendix A — Skill, prompt, and script changes summary

This is the surface the planner will break into BDs. Not a plan; a
checklist for the planner to validate the design touches what it
should.

### A.1 New artifacts (v11 introduces)

- `tracker.toml` schema and writer.
- `scripts/tracker-migrate.sh` (forward / reverse / status / doctor /
  roundtrip-test).
- `scripts/tracker.sh` (provider wrapper used by chats and skills).
- `scripts/tracker-providers/github.sh` (LCD GH backend).
- `.github/ISSUE_TEMPLATE/{bd-entry,td-entry,phase-epic,pack-feedback,bug-report,feature-request}.yml`
  (in pack-template for client copy + in pack root).
- `.github/ISSUE_TEMPLATE/config.yml` (blank-issue routing + contact-links).
- `project-template/skills/tracker-startup/SKILL.md` and the parallel
  `.claude` / `.codex` / `.gemini` copies (per audit §R9 the trio rule
  applies).
- Updates to `OPTIONAL-FEATURES.md` for per-CLI MCP acceleration.
- Updates to `LICENSE.md` if the pack-feedback upstream surface needs
  any clarification (per §11.4 not expected; planner re-checks).

### A.2 Modified artifacts (v11 alters)

- `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`: add Source
  column to `## Document locations` table; add tracker-mode note in
  `## Skill loading`. (Trinity rule.)
- Pack-side `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`: same.
- `PACK-CHAT.md`: add tracker orchestration patterns (§7) to "File
  access strategy" table.
- `project-template/docs/pack/PM-CHAT.md`: same.
- `project-template/skills/pm-startup/SKILL.md`: pre-step delegating to
  `tracker-startup`; Step 2 routes via resolver; Step 6 resolves
  `Open BACKLOG items` via provider when in tracker mode.
- `.claude/skills/pack-startup/SKILL.md`: same shape, plus Step 7
  triage queue (§10.2).
- `project-template/docs/pack/prompts/*.md`: replace "Read BACKLOG.md"
  language with "Read BACKLOG entries (resolve via trinity)" per §8.4.
  All 10 prompts touched (architect, auditor, coder, docs-researcher,
  grpc-schema, planner, pm-chat, repo-ops, reviewer, tester).
- `supporting-docs/METHODOLOGY.md`: Part 7 Procedure annotations noting
  that BACKLOG ops route through the provider when tracker mode is
  active. The procedural shape does not change; only the read/write
  mechanism.
- `supporting-docs/INSTALL-PROCEDURES.md`: new Procedure 8 — "Tracker
  opt-in" with steps for forward migration, capability check, and
  trinity column update. Procedure 5-S (post-migration housekeeping)
  gains a note for the v10 → v11 trinity column add.
- `scripts/validate-pack.py`: add Check 19 (`check_tracker_config`) that
  validates `tracker.toml` schema if present and warns if mode tracker
  but mirror files have stale `Last regenerated` timestamps relative
  to `tracker.toml.migration.last_forward_run`.

### A.3 Out-of-scope artifacts

- v10's existing `BACKLOG.md` (pack and project) format. Unchanged.
- `IMPLEMENTATION_PLAN.md` format. Unchanged (stays flat).
- `ARCHITECTURE.md` format. Unchanged.
- `STATUS.md` format. Unchanged grammar; mirror header added when
  tracker mode is on.
- v10's typed-deferral comment system. Unchanged.

---

## Appendix B — Citation index

All claims trace to one of the four input docs. Selected pointers:

- §1.4 cross-CLI strategy: `EXTERNAL-RESEARCH.md` §4, §5; `RESEARCH-AUDIT.md`
  §A.1, §A.8, §12.1–§12.3.
- §2.1 operation set: `EXTERNAL-RESEARCH.md` §8.5; `RESEARCH-AUDIT.md` §A.9.
- §2.3 capability flags: `RESEARCH-AUDIT.md` §A.9; `EXTERNAL-RESEARCH.md`
  §6.1 / §1.8 (caps); audit Part B (per-tracker capability matrix).
- §2.4 link.kind: `EXTERNAL-RESEARCH.md` §1.3 (50 cap, GA 2025-08-21);
  `RESEARCH-AUDIT.md` §A.9 (open-string mandate).
- §2.5 error model: `EXTERNAL-RESEARCH.md` §10; `RESEARCH-AUDIT.md` §10.1–§10.5.
- §2.7 GH backend: `EXTERNAL-RESEARCH.md` §1, §2, §3; `RESEARCH-AUDIT.md`
  §A.2, §A.3, §A.4.
- §3.3 trinity column: `INTERNAL-INVENTORY.md` Pass B "Implicit
  expectations the architect must preserve" #1.
- §4 issue templates: `EXTERNAL-RESEARCH.md` §1.1, §1.4; `RESEARCH-AUDIT.md`
  §A.2 (issue forms verified).
- §5.1 3-level model: `RESEARCH-AUDIT.md` §A.7 / §B.1 (Jira free 3-level
  hard cap); `EXTERNAL-RESEARCH.md` §1.2 (GH 8-deep / 100-wide).
- §6 migration: `EXTERNAL-RESEARCH.md` §7 (prior-art idempotency
  conventions); `RESEARCH-AUDIT.md` §A.6.
- §7 orchestration: `EXTERNAL-RESEARCH.md` §6 (token cost); §11.3
  (per-CLI gotchas); `RESEARCH-AUDIT.md` §A.5, §A.8.
- §8 agent reads: `EXTERNAL-RESEARCH.md` §6.1 (token cost), §11.3;
  `RESEARCH-AUDIT.md` §A.1, §A.5.
- §9 failure UX: `EXTERNAL-RESEARCH.md` §10; `RESEARCH-AUDIT.md` §A.3
  (`gh` exit codes verified).
- §10 external triage: `EXTERNAL-RESEARCH.md` §1.1 (templates), §1.4
  (labels at intake); `RESEARCH-AUDIT.md` §A.2.
- §11 license: pack repo `LICENSE.md` §3.1, §3.2, §3.3 (read 2026-04-30).
- §12 token economy: `EXTERNAL-RESEARCH.md` §6; `RESEARCH-AUDIT.md` §A.5.
- §13 per-CLI matrix: `EXTERNAL-RESEARCH.md` §3, §4, §5, §11.3;
  `RESEARCH-AUDIT.md` §A.1, §A.8, §12.1–§12.4.
- §14 tracker compatibility: `RESEARCH-AUDIT.md` Part B (B.1–B.9) and §A.7.
- §15 pre-existing tracker: `RESEARCH-AUDIT.md` §A.7 (Linear MCP);
  `EXTERNAL-RESEARCH.md` §8.3 (sync-tool prior art).
- §17 risks: `INTERNAL-INVENTORY.md` Pass B "Risks for migration to a
  tracker integration" R1–R10; `RESEARCH-AUDIT.md` §A.3 (gh v2.87.x
  pin), §A.7 (Jira 3-level cap), §A.2 (gzipped body cap).

---

End of architecture proposal. The pack-reviewer audits next; the
pack-planner breaks this into BD-NNN entries for v11 implementation.
