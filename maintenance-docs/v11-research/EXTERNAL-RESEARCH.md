# v11 External Research: Tracker-Backend Capability Survey

**Scope.** Read-only external survey of GitHub Issues, the `gh` CLI, the GitHub
MCP server, Codex CLI, and Gemini CLI capabilities relevant to an *optional*
v11 tracker integration. Linear and Jira surfaces appear only as abstraction
references. **No solutions or designs proposed** — this catalogues what is
possible, what it costs, and where the gaps are.

**Date of research.** 2026-04-30. CLI tools and GitHub Issues evolved
materially through 2025; cite sources rather than relying on training data.

**Status of "preview" features.** Sub-issues, issue types, advanced search,
and increased project item limits all reached general availability in 2025
([Evolving GitHub Issues and Projects (GA), Discussion #154148](https://github.com/orgs/community/discussions/154148)).
Issue dependencies (`Blocks` / `Blocked by`) reached GA in August 2025
([Dependencies on issues, GitHub Changelog 2025-08-21](https://github.blog/changelog/2025-08-21-dependencies-on-issues/)).

---

## 1. GitHub Issues — full capability surface

### 1.1 Issue templates and issue forms

Two parallel mechanisms ship today:

- **Markdown templates** (`.github/ISSUE_TEMPLATE/*.md`). Frontmatter keys:
  `name`, `about`, `title`, `labels`, `assignees`, `type`. Body is free-form
  Markdown. Less structured.
- **Issue forms** (`.github/ISSUE_TEMPLATE/*.yml`). YAML form definition with
  validated field types, structured input. Rendered as a web form before
  creating the issue body.

**Issue form field types** ([Syntax for issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms),
[Syntax for GitHub's form schema](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema)):

| Type           | Use                                     | Validation                          |
|----------------|-----------------------------------------|-------------------------------------|
| `markdown`     | Static helper text, not in body         | n/a (display only)                  |
| `textarea`     | Multi-line free text, optional language | `required`                          |
| `input`        | Single-line text                        | `required`, regex via `value`       |
| `dropdown`     | Single (or multi) select                | `required`, `multiple`, `default`   |
| `checkboxes`   | List of opt-in checkboxes               | `required` per option               |

Top-level keys: `name`, `description`, `title`, `body` (the array of fields),
plus optional `labels`, `assignees`, `projects`, `type` (issue type field).

**Config file**: `.github/ISSUE_TEMPLATE/config.yml` controls "blank issue"
visibility and adds `contact_links` (off-platform routing). Defaults are
applied automatically when the user picks a template
([Configuring issue templates for your repository](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)).

### 1.2 Sub-issues (parent / child)

GA in 2025 ([Evolving GitHub Issues and Projects (GA), Discussion #154148](https://github.com/orgs/community/discussions/154148);
backstory in [How GitHub Built Sub-Issues, InfoQ 2025-04](https://www.infoq.com/news/2025/04/github-subissues-journey/)).

**Hard limits**:
- **Depth**: 8 levels.
- **Sub-issues per parent**: 100.
- **Parents per issue**: 1 (a child has exactly one parent).

API surfaces:
- **REST**: `/repos/{owner}/{repo}/issues/{issue_number}/sub_issues` — `GET`
  list, `POST` add, `DELETE` remove, plus a reprioritize endpoint
  ([REST API endpoints for sub-issues](https://docs.github.com/en/rest/issues/sub-issues)).
- **GraphQL**: requires `GraphQL-Features: sub_issues` header during preview;
  by GA the schema includes parent / sub-issues fields directly.

Closing the parent does **not** auto-close children (and vice versa); the
relationship is a link, not a cascade.

**`gh` CLI** does **not** have a built-in `gh issue sub-issue` subcommand as
of late 2025 ([cli/cli #10298](https://github.com/cli/cli/issues/10298)).
Third-party extensions fill the gap ([yahsan2/gh-sub-issue](https://github.com/yahsan2/gh-sub-issue),
[agbiotech/gh-sub-issue](https://github.com/agbiotech/gh-sub-issue),
[jwilger/gh-issue-ext](https://github.com/jwilger/gh-issue-ext)).

### 1.3 Issue dependencies (Blocks / Blocked by)

GA 2025-08-21 ([Dependencies on issues](https://github.blog/changelog/2025-08-21-dependencies-on-issues/)).

- **Cap**: 50 issues per relationship type per issue (50 "blocks", 50 "blocked
  by").
- **Cross-repo**: same-repository or same-organization internal repos only;
  external repos not supported as of GA.
- **API**: GraphQL mutations including `addBlockedBy` / removal; full webhook
  events. EMU users can hit `FORBIDDEN: Unauthorized; path: addBlockedBy` for
  cross-enterprise links.
- **Distinct from closing keywords.** `Closes #N` / `Resolves #N` / `Fixes #N`
  in PR bodies auto-close issues on merge to default branch only
  ([Using keywords in issues and pull requests](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/using-keywords-in-issues-and-pull-requests)).
  These keywords are **not** dependency markers; they are merge-time close
  triggers. Free-text `#42` references do not create dependencies — they only
  cross-link.

### 1.4 Labels, milestones, issue type

**Labels**:
- Description: max 100 chars ([Managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels)).
- Up to 100 labels per issue or PR.
- No documented hard cap on labels per repo (community discussions
  consistently report no enforced number).
- Color is a 6-char hex.

**Milestones**:
- One per issue (single-milestone constraint).
- Optional due date; percent complete is computed from open vs closed issues.
- No documented hard cap on milestones per repo.

**Issue type** (GA 2025) — a separate first-class field, not a label
([About the issue type field](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-the-issue-type-field),
[Issue Types Public Preview, Discussion #148715](https://github.com/orgs/community/discussions/148715)):
- One type per issue (mutually exclusive with itself; can coexist with labels).
- Defined at organization level, applied at issue level.
- Not available for PRs (issues only). This is the main reason teams keep
  using labels for parity.
- Settable via issue forms YAML (`type:` key), via REST/GraphQL, and via
  `gh` (`--type` flag in recent gh versions; check `gh issue create --help`
  on the target machine).

### 1.5 Projects (Projects v2)

GraphQL-only API ([Using the API to manage Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)).
Field types: `text`, `number`, `date`, `single_select`, `iteration`. Update
mutation is `updateProjectV2ItemFieldValue`.

**Hard limits**:
- **Items per project**: 50,000 (raised from 1,200 during 2025;
  [Increased items in GitHub Projects, 2025-02-26](https://github.blog/changelog/2025-02-26-increased-items-in-github-projects-now-in-public-preview/)).
- **Views**: table, board, roadmap.
- Single-select option editing programmatically is awkward — adding new
  options to an existing single-select field via the API has historically
  required workarounds ([Discussion #76762](https://github.com/orgs/community/discussions/76762),
  [Discussion #35922](https://github.com/orgs/community/discussions/35922)).

`gh project` is GA as a built-in `gh` subcommand
([GitHub CLI project command is now generally available](https://github.blog/developer-skills/github/github-cli-project-command-is-now-generally-available/)).
The `gh-projects` extension is archived in favor of the built-in.

### 1.6 Search and filter

**Search qualifiers** ([Filtering and searching issues and PRs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/filtering-and-searching-issues-and-pull-requests),
[Searching issues and pull requests](https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests)):
`is:`, `state:`, `type:`, `author:`, `assignee:`, `mentions:`, `team:`,
`commenter:`, `involves:`, `linked:`, `label:`, `milestone:`, `project:`,
`status:`, `head:`, `base:`, `comments:`, `interactions:`, `reactions:`,
`draft:`, `created:`, `updated:`, `closed:`, `merged:`, `archived:`, plus
exclusion via `-qualifier:value`.

**Advanced search (GA 2025)** — boolean `AND` / `OR` operators with
parenthesized nesting ([Issues search now supports nested queries and
boolean operators](https://github.blog/developer-skills/application-development/github-issues-search-now-supports-nested-queries-and-boolean-operators-heres-how-we-rebuilt-it/);
default-on for all queries from 2025-09-04 per
[Discussion #154148](https://github.com/orgs/community/discussions/154148)).
Pre-advanced behavior: spaces meant `AND`; same-key qualifiers meant `OR`
(`label:bug,wip`). Advanced syntax accepts explicit operators:
`is:issue state:open author:rileybroughten (type:Bug OR type:Epic)`.

**Search hard limit**: 1,000 results per query, irrespective of pagination,
on both REST and GraphQL search endpoints
([REST API endpoints for search](https://docs.github.com/en/rest/search/search)).
Use date-range or label slicing to walk past 1,000.

### 1.7 Bulk operations

- `gh issue list --label x | xargs -n1 gh issue edit ...` — script-driven
  bulk via the CLI.
- REST has no native "close 100 issues in one call". Each is a separate
  `PATCH`.
- GraphQL allows batched mutations in one query, but each mutation still
  consumes its share of points.
- **GitHub UI**: bulk select on the Issues tab supports close, reopen,
  label, milestone, assignees, mark-as-duplicate.

### 1.8 Hard limits summary (Issues / repo)

| Item                            | Limit                                | Source |
|---------------------------------|--------------------------------------|--------|
| Issues per repo                 | No documented cap                    | [Repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits) |
| Issue body                      | 65,536 chars (256 KB mediumblob)     | [Discussion #27190](https://github.com/orgs/community/discussions/27190), [Discussion #41331](https://github.com/orgs/community/discussions/41331) |
| Comment body                    | 65,536 chars                         | same |
| Release body                    | 125,000 chars                        | same |
| Labels per issue/PR             | 100                                  | [Discussion #76832](https://github.com/orgs/community/discussions/76832) |
| Label description               | 100 chars                            | [Managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels) |
| Sub-issue depth                 | 8                                    | [Discussion #154148](https://github.com/orgs/community/discussions/154148) |
| Sub-issues per parent           | 100                                  | same |
| Parents per issue               | 1                                    | same |
| Blocks/blocked-by per issue     | 50 each                              | [Changelog 2025-08-21](https://github.blog/changelog/2025-08-21-dependencies-on-issues/) |
| Project items                   | 50,000                               | [Changelog 2025-02-26](https://github.blog/changelog/2025-02-26-increased-items-in-github-projects-now-in-public-preview/) |
| Search results                  | 1,000 per query                      | [REST search](https://docs.github.com/en/rest/search/search) |
| Image/GIF attachment            | 10 MB                                | [Attaching files](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files) |
| Video attachment (free)         | 10 MB                                | same |
| Video attachment (paid)         | 100 MB                               | same |
| Other file attachment           | 25 MB                                | same |

### 1.9 Rate limits

[Rate limits for the REST API](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api),
[Rate limits and query limits for the GraphQL API](https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api),
[Discussion #163553](https://github.com/orgs/community/discussions/163553).

| API           | Authenticated primary  | Secondary                  |
|---------------|------------------------|----------------------------|
| REST core     | 5,000 req/hr/user      | ≤ 900 points/min           |
| REST search   | 30 req/min             | (folds into core 5k/hr)    |
| GraphQL       | 5,000 points/hr/user   | ≤ 2,000 points/min         |
| Unauth        | 60 req/hr per IP       | (do not use for chat)      |

Detection: `X-RateLimit-Remaining`, `X-RateLimit-Reset` (REST);
`rateLimit { remaining, resetAt, cost }` field (GraphQL). `gh api
rate_limit` reports current state.

GraphQL "points" are roughly request complexity — one carefully-shaped query
fetching 100 issues with comments, labels, sub-issues, and assignees can
cost <10 points. The same fetch via REST is N+1 calls.

### 1.10 Discussions (parallel to Issues)

[Quickstart for GitHub Discussions](https://docs.github.com/en/discussions/quickstart),
community comparison: [Discussion #190823](https://github.com/orgs/community/discussions/190823).

- Distinct API surface from Issues; uses GraphQL primarily.
- Categories rather than labels.
- No close lifecycle (mark-as-answered for Q&A category only).
- Discussions ↔ Issues conversion is supported in the UI (and via API).
- Suitable for community Q&A; **not** suitable for tracking work.


---

## 2. `gh` CLI for issue management

### 2.1 Subcommand surface

`gh issue` subcommands ([gh issue manual](https://cli.github.com/manual/gh_issue),
[gh issue list](https://cli.github.com/manual/gh_issue_list),
[gh issue view](https://cli.github.com/manual/gh_issue_view)):

| Command         | Purpose                                              |
|-----------------|------------------------------------------------------|
| `create`        | Create a new issue (`--title`, `--body`, `--body-file`, `--label`, `--assignee`, `--milestone`, `--project`, `--type`) |
| `list`          | List & filter (`--label`, `--state`, `--assignee`, `--author`, `--milestone`, `--search`, `--limit`, `--json`) |
| `view`          | Show one issue (with comments via `--comments`)      |
| `edit`          | Mutate (`--add-label`, `--remove-label`, `--add-assignee`, `--remove-assignee`, `--milestone`, `--add-project`, `--remove-project`, `--title`, `--body`, `--body-file`) |
| `close`         | `--reason completed|not_planned|duplicate`           |
| `reopen`        |                                                      |
| `comment`       | Add a comment (`--body`, `--body-file`, `--edit-last`) |
| `delete`        | Hard delete (admin scope)                            |
| `develop`       | Create a linked branch / PR                          |
| `lock` / `unlock` |                                                    |
| `pin` / `unpin` |                                                      |
| `transfer`      | Move issue to another repo                           |
| `status`        | Issues across repos relevant to me                   |

`gh search issues` is a separate command using the search API; takes
qualifier-style queries directly.

### 2.2 JSON output fields

Empty `--json` flag lists available fields (or invalid name gives error
listing valid names). For `gh issue list --json`, the field set is
([gh-issue-list manpage](https://man.archlinux.org/man/gh-issue-list.1.en),
[Discussion #5902](https://github.com/cli/cli/discussions/5902)):

`assignees, author, body, closed, closedAt, closedByPullRequestsReferences,
comments, createdAt, id, isPinned, labels, milestone, number, projectCards,
projectItems, reactionGroups, state, stateReason, title, updatedAt, url`.

Notable gaps:
- **`type`** field for the GA issue type was added in late-2025 gh
  releases ([cli/cli #12477](https://github.com/cli/cli/issues/12477));
  version-pin sensitive — older `gh` will reject `--json type` and
  `--type` flag on create.
- **Sub-issue parent / children** not exposed via `--json`. Must shell
  to `gh api graphql` or use the `gh-sub-issue` extension.
- **Blocks / blocked-by** not exposed via `--json`. Same workaround.

`--jq` flag accepts gojq expressions and is the documented filter mechanism.

### 2.3 Useful extensions

| Extension                                         | Adds                                            |
|---------------------------------------------------|-------------------------------------------------|
| [yahsan2/gh-sub-issue](https://github.com/yahsan2/gh-sub-issue)     | `gh sub-issue create / list / add / remove`       |
| [agbiotech/gh-sub-issue](https://github.com/agbiotech/gh-sub-issue) | Alt sub-issue extension                         |
| [jwilger/gh-issue-ext](https://github.com/jwilger/gh-issue-ext)     | Sub-issues + blocking + linked branches          |
| [yahsan2/gh-pm](https://github.com/yahsan2/gh-pm)                   | PM-flavored project management with Projects v2 |
| [d-oit/gh-sub-issues](https://github.com/d-oit/gh-sub-issues)       | Hierarchy-with-Projects management              |

Extensions are installed per-user via `gh extension install <repo>`. They
share `gh`'s auth and config.

### 2.4 Authentication

[gh auth login](https://cli.github.com/manual/gh_auth_login),
[Multiple accounts](https://github.com/cli/cli/blob/trunk/docs/multiple-accounts.md):

- Default flow: web browser OAuth.
- Token stored in OS credential store (Keychain on macOS, etc.) by default;
  fallback is plain text. `--insecure-storage` forces plain text.
- Default scopes: `repo`, `read:org`, `gist`, plus `workflow` if requested
  during login.
- `gh auth refresh -s <scope>` adds scopes.
- `gh auth status` displays active host(s), user, scopes, token storage
  location.
- Multi-account: `gh auth login` can stack multiple accounts; `gh auth
  switch` toggles. Per-host config in `~/.config/gh/hosts.yml`.

### 2.5 Direct `gh api` escape hatch

`gh api repos/{o}/{r}/issues` — REST passthrough with auth handled.
`gh api graphql -f query='...'` — GraphQL passthrough. Both honor `--jq`,
pagination via `--paginate`, and `-H` for custom headers (e.g.,
`GraphQL-Features: sub_issues` during preview windows).

This is the canonical pattern when `gh issue` lacks the operation.

---

## 3. GitHub MCP server

### 3.1 Repository and toolsets

[github/github-mcp-server](https://github.com/github/github-mcp-server),
configuration docs at
[server-configuration.md](https://github.com/github/github-mcp-server/blob/main/docs/server-configuration.md),
[Configuring toolsets](https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/configure-toolsets).

GitHub's official MCP server exposes ~162 tools organized into **toolsets**
that can be enabled or disabled with `--toolsets` (or `GITHUB_TOOLSETS` env).
Default toolsets: `context`, `issues`, `pull_requests`, `repos`, `users`.
Additional toolsets (`actions`, `code_security`, `secret_protection`,
`discussions`, `gists`, `notifications`, `dependabot`, `git`) are off by
default.

### 3.2 Issues toolset (relevant tools)

Confirmed in the README and changelog:

| Tool                  | Purpose                                       |
|-----------------------|-----------------------------------------------|
| `list_issues`         | List with filtering, paginated                |
| `get_issue`           | Single issue                                  |
| `create_issue`        | Create                                        |
| `update_issue`        | Mutate state, title, body, labels, milestone, type |
| `add_issue_comment`   | Append comment                                |
| `get_issue_comments`  | List comments                                 |
| `search_issues`       | Free-text + qualifier search                  |
| `list_issue_types`    | (org-level) discover defined types             |
| `add_sub_issue` / `list_sub_issues` / `remove_sub_issue` / `reprioritize_sub_issue` | Sub-issue mgmt ([Issue #196](https://github.com/github/github-mcp-server/issues/196)) |
| `assign_copilot_to_issue` | Hand off to Copilot agent                  |

The MCP guidance text shipped with the server reminds clients:

- Use `list_*` for bulk pagination, `search_*` for targeted criteria.
- Pass `minimal_output=true` to trim returns when full bodies aren't needed.
- Paginate in batches of 5–10.
- Always set `state_reason` when closing.
- Call `list_issue_types` first before applying types.

### 3.3 Where MCP wins vs `gh`

- **Structured returns** — every tool yields typed objects the LLM can
  navigate without re-parsing CLI output.
- **`minimal_output` mode** — token-trimmed responses; significant on
  bulk lists.
- **Token-budget-aware design** — list pagination defaults are smaller
  than `gh`'s default 30 to be context-friendly.
- **Composability** — sub-issue tools chain with create/update without
  shell glue.

### 3.4 Where `gh` wins vs MCP

- **Coverage**. `gh` + `gh api graphql` is total. MCP toolsets ship a
  curated subset — historically the MCP server has shipped fewer tools
  than its README implies ([modelcontextprotocol/servers #541](https://github.com/modelcontextprotocol/servers/issues/541),
  [vscode #272530](https://github.com/microsoft/vscode/issues/272530)).
- **Determinism / scriptability**. `gh` outputs are stable; MCP tool
  shapes evolve between releases.
- **No protocol overhead**. `gh` is one syscall; MCP requires a running
  server process and JSON-RPC round trips.
- **Auth**. `gh` authenticates once and reuses across CLIs. MCP needs a
  PAT injected into each host's MCP config.

### 3.5 Hosting modes

[Remote GitHub MCP server, 2025-06-12](https://github.blog/changelog/2025-06-12-remote-github-mcp-server-is-now-available-in-public-preview/),
[Using the GitHub MCP Server in your IDE](https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/use-the-github-mcp-server).

- **Remote (HTTP)**: `https://api.githubcopilot.com/mcp/` — Streamable
  HTTP, Bearer auth via PAT or OAuth. No local install.
- **Local stdio**: `github-mcp-server stdio` with
  `GITHUB_PERSONAL_ACCESS_TOKEN`. Built from the Go source or installed
  via Docker. Useful for offline or stricter firewall environments.
- **Debug**: the binary exposes `github-mcp-server tool-search <q>` for
  introspecting tools and inputs.

### 3.6 Auth requirements

PAT scopes vary by toolset. For issues-only:

- Classic PAT: `repo` (full), or `public_repo` for public-only writes.
- Fine-grained PAT: repository access + `Issues: Read and write`,
  `Metadata: Read`. PRs and Projects v2 require their own scopes.


---

## 4. Codex CLI's GitHub integration story

[Codex CLI features](https://developers.openai.com/codex/cli/features),
[Codex MCP docs](https://developers.openai.com/codex/mcp),
[codex/docs/config.md](https://github.com/openai/codex/blob/main/docs/config.md),
[install-codex.md (github-mcp-server)](https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-codex.md).

### 4.1 Native tool surface

Codex CLI ships with a small native tool kit:

- **Shell** (`exec` / `local_shell`) — runs commands within sandbox &
  approval policy. This is the universal escape hatch and how `gh` would
  be invoked.
- **File read / patch** — apply patches, write files within working tree.
- **Built-in git worktree support** — parallel changesets isolated from
  the main checkout.

There is **no native GitHub-specific tool** in stock Codex. GitHub
operations are reached via either:

1. Shell-out to `gh` (the dominant pattern).
2. The GitHub MCP server (since Codex supports MCP).

### 4.2 MCP support

Configured in `~/.codex/config.toml` (user) or `.codex/config.toml`
(project, trusted projects only). Both **stdio** and **Streamable HTTP**
transports are supported.

GitHub MCP example from GitHub's installation guide:

```toml
[mcp_servers.github]
url = "https://api.githubcopilot.com/mcp/"
bearer_token_env_var = "GITHUB_PAT_TOKEN"
```

`codex mcp` provides add/list/remove subcommands. Project-scoped MCP
configs require the project to be marked trusted — Codex's "trusted
projects" gate is meaningful for any tracker-write configuration we
might ship.

### 4.3 Recommended pattern

For chat-time work (read-mostly, occasional write):

1. Shell-out to `gh` if it's installed and authenticated. Lowest
   friction, no extra config.
2. GitHub MCP if the project specifically wires it into
   `.codex/config.toml` and ranks tracker access as a primary chat
   capability.
3. `gh api graphql` for sub-issues / blocks / type field operations not
   yet covered by `gh issue`.

---

## 5. Gemini CLI's GitHub integration story

[Gemini CLI repo](https://github.com/google-gemini/gemini-cli),
[gemini-cli/docs/tools/](https://google-gemini.github.io/gemini-cli/docs/tools/),
[MCP servers with Gemini CLI](https://geminicli.com/docs/tools/mcp-server/),
[install-gemini-cli.md (github-mcp-server)](https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-gemini-cli.md),
[Subagents docs](https://geminicli.com/docs/core/subagents/).

### 5.1 Native tool surface

- `run_shell_command` — shell with optional interactive support
  (`tools.shell.enableInteractiveShell`).
- `read_file` / `read_many_files` — file ops.
- `write_file` / patch tools.
- `web_fetch` — URL retrieval.
- `google_web_search` — search grounding.
- `save_memory` — cross-session memory hint.

No native GitHub tool. Same shell-or-MCP story as Codex.

### 5.2 Subagents

Specialized agents within a Gemini session that scope a task and its
toolset ([Subagents](https://geminicli.com/docs/core/subagents/)). The
community curates 100+ subagent definitions
([awesome-gemini-cli-subagents](https://github.com/ankitmundada/awesome-gemini-cli-subagents)).
There is **no first-party GH subagent** shipped with Gemini CLI — any
GH-flavored subagent would need to be added by the project.

### 5.3 MCP support

Configured in `~/.gemini/settings.json` (global) or `.gemini/settings.json`
(project). Three documented patterns for the GitHub MCP server:

- Hosted HTTP MCP at `https://api.githubcopilot.com/mcp/` with
  `Authorization` header.
- Docker-launched local MCP container.
- Local binary launched as stdio process.

Gemini auto-expands env-var references inside MCP `env` blocks, so PATs
can be referenced via `${GITHUB_PAT}` rather than hardcoded.

### 5.4 Recommended pattern

Same hierarchy as Codex: shell → MCP → direct API. Gemini's interactive
shell mode adds a small advantage when scripting `gh` confirmations
during chat.

---

## 6. Token cost characteristics

Estimates assume ~3 chars/token English, gh CLI returning compact JSON,
GitHub MCP returning JSON-RPC results with `minimal_output=true` where
supported. **All numbers are order-of-magnitude.**

### 6.1 List all open issues

| Mechanism                                            | Round trips | Approx tokens |
|------------------------------------------------------|-------------|---------------|
| `gh issue list --state open --json number,title --limit 100` | 1           | 30 / issue    |
| `gh issue list --state open --json <full set>`       | 1           | 200–600 / issue |
| MCP `list_issues` (minimal)                          | 1           | 40 / issue    |
| MCP `list_issues` (full)                             | 1           | 250 / issue   |
| REST `/issues?state=open&per_page=100`               | ⌈N/100⌉     | 250 / issue (no projection) |
| Flat-file `cat BACKLOG.md` (500–2,000 lines)         | 0           | 5K–20K total  |

**Inflection point**: at ~50–100 open items, projected JSON
(`number,title,labels,state` only) ties or beats the flat file. Below
that, the flat file is cheaper. Above ~500 items, the flat file becomes
unwieldy for full reads but still wins for grep-level scans.

### 6.2 Filtered list (`label:X milestone:Y`)

`gh issue list --label X --milestone Y --json number,title,state` — 1
trip, ~30 tokens per matching issue. Negligible vs full-file read for
small filter sets.

### 6.3 Get one issue (full body + comments)

`gh issue view N --comments --json number,title,body,comments` — 1 trip;
size dominated by body + comment count. A typical 5–10 comment issue
runs 2K–8K tokens. The flat-file analog is grep + cat the BACKLOG entry
(~500 tokens).

### 6.4 Walk dependency tree from issue X

Sub-issue tree of depth 3 with avg 5 children at each level (5+25+125 =
155 nodes):

- REST: 1 + 5 + 25 = 31 calls minimum (one per parent at each level via
  `/sub_issues`); each ~200 tokens → ~6K tokens + 31 round trips.
- GraphQL: 1 carefully-shaped query can return the whole tree.
  ~5K tokens, 1 round trip.
- MCP: ~depends on tool granularity; typically per-parent calls.

### 6.5 Free-text search

`gh search issues "<query>" --json number,title,url --limit 50` — 1 trip,
~25 tokens / hit. Hard cap of 1,000 hits per search query regardless of
pagination ([REST search](https://docs.github.com/en/rest/search/search)).

### 6.6 Comparative summary

The flat-file approach has near-zero per-item cost up to ~50–100 items
and ~5–20 KB total. Tracker-backed approaches scale better past ~200
items (selective queries) but introduce per-call latency (50–500 ms),
auth overhead, and rate-limit exposure.

---

## 7. Prior art — flat-file → tracker migration

### 7.1 Trac → GitHub Issues

Long-standing migration path with several open-source tools:

- [svigerske/trac-to-github](https://github.com/svigerske/trac-to-github)
  — migrates milestones, issues, wiki pages. **Not idempotent**;
  re-running duplicates issues. Maintainers suggest one-shot use.
- [str4d/migrate-trac-issues-to-github](https://github.com/str4d/migrate-trac-issues-to-github)
  — supports username mapping, custom GitHub API URLs (Enterprise
  Server), token auth.
- [mavam/trac-hub](https://github.com/mavam/trac-hub) — YAML
  configuration, recommends migrating into a test repo first.

**Common idempotency conventions when authors implement them**:

- **Title marker**: prefix or suffix the GH issue title with
  `[TRAC-1234]` or similar. Re-runs check for the marker before
  creating.
- **Mapping file**: a JSON or CSV that records `source_id → gh_number`.
  The migration script consults the mapping before creating, and writes
  back the new GH number.
- **Body fingerprint**: SHA of source content stored as a hidden
  HTML comment in the GH body. Re-runs detect drift and update vs
  create.
- **Label conventions**: a synthetic label (e.g., `migrated:trac`)
  marks migrated issues for cleanup or re-runs.

### 7.2 GitLab → GitHub

GitLab has a built-in importer to GitHub direction (and reverse).
Patterns mirror the Trac ones — title markers, mapping JSON. Comments
and attachments transfer with caveats (image proxying, author
attribution falls back to the migrating user).

### 7.3 Jira → GitHub Issues

GitHub provides a first-party Jira importer in the issue importer UI;
script-based migrations are documented in many community repos. Common
findings:

- Custom fields are the largest source of fidelity loss (Jira's are
  rich; GH labels + Projects v2 fields are the primary mapping).
- Status workflow mapping: Jira's per-project workflows collapse to
  open / closed + state_reason + labels.
- Comments preserve order; author attribution falls back to migrator;
  internal Jira-only comments can be marked with a label or footer.

### 7.4 Generic mapping concerns

| Element            | Mapping concern                                                  |
|--------------------|------------------------------------------------------------------|
| Relationships      | `Blocks`/`Blocked by` (post-Aug 2025); fall back to `#N` cross-ref |
| Comments           | Preserve order; author attribution lossy without app integration |
| Attachments        | Re-upload required (signed URLs in source ≠ destination); size caps differ |
| History            | Read-only in GH; emulate via a single "Imported history" comment |
| Custom fields      | → labels, milestone, issue type, or Projects v2 custom field    |
| Status mapping     | open/closed only; nuance via state_reason + label              |


---

## 8. Tracker abstraction patterns from real OSS projects

Surveyed projects with tracker abstractions or multi-backend support:

### 8.1 Octobox (now archived, formerly octoboxio/octobox)

GitHub-only notifications dashboard; no tracker abstraction layer per
se, but its **notification → action** mapping is instructive: actions
collapse to "open in source", "comment", "mark done", "reassign". The
common-denominator surface is small.

### 8.2 Gitea (gitea/gitea)

Implements a GH-Issues-compatible API surface as a parallel to its
native one. Their approach: define a thin model (Issue, Comment,
Label, Milestone, Reaction), then **two adapter layers** — one for
gitea-native, one for the GH-compatible facade. Demonstrates the
"ship the model; adapt at the edges" pattern.

### 8.3 Synchronization tools (e.g.,
[olaaustine/github-issues-linear](https://github.com/olaaustine/github-issues-linear),
[GitHub ↔ Linear sync via Linear's official integration](https://linear.app/integrations/github))

These do not abstract; they replicate. A canonical issue lives in one
backend; the other backend gets a mirror plus a back-reference URL.
Useful pattern: **a sync-id field** stored on both sides (e.g., GH
issue body footer `<!-- linear-id: ABC-123 -->`, Linear field
`github_issue_number`). Conflict resolution is "source of truth" per
record, not whole-database.

### 8.4 Backstage (backstage/backstage)

Plugin-based. Each tracker has a separate plugin; users compose. The
abstraction is the plugin API contract (lifecycle hooks, query schema)
rather than a unified data model. Demonstrates a different posture:
don't try to unify the model; unify the integration *interface*.

### 8.5 Common abstraction interface (operations exposed)

Across these projects, the smallest stable surface is:

| Operation              | Required for v11?                                  |
|------------------------|----------------------------------------------------|
| `list(filter, page)`   | Yes — list backlog                                 |
| `get(id)`              | Yes — read one                                     |
| `create(payload)`      | Yes — file new work                                |
| `update(id, patch)`    | Yes — change status, labels                        |
| `close(id, reason)`    | Yes — resolve                                      |
| `comment(id, body)`    | Yes — discussion                                   |
| `set_labels(id, set)`  | Yes — categorization                               |
| `set_assignee(id, ids)`| Often                                              |
| `link(id, other_id, kind)` | Yes if dependencies modeled                    |
| `sub_issue_create / list / unlink` | Yes if hierarchy modeled               |
| `search(query)`        | Often                                              |
| `webhook subscribe`    | Out of scope for chat-side, in scope for CI hooks  |

### 8.6 Escape hatches

Every survived OSS abstraction provides a "raw API" escape — Backstage's
`apiRef`, Gitea's direct DB, sync tools' "set arbitrary field" — for
features the abstraction can't model. **An abstraction without an
escape hatch will block the next backend from shipping its
distinguishing feature.**

---

## 9. Linear and Jira — feature surface for abstraction reference

### 9.1 Linear

[Linear Developers — Getting Started](https://linear.app/developers/graphql),
[API and Webhooks](https://linear.app/docs/api-and-webhooks),
[Advanced usage](https://linear.app/developers/advanced-usage).

GraphQL-only public API. Notable concepts:

- **Issues** with **state** (workflow state from a per-team workflow,
  not a global open/closed) and **priority** (0–4).
- **Sub-issues**: parent/child links on Issue. Different from GH —
  Linear's are first-class, no depth cap explicitly documented but
  practical UI flattens beyond 2 levels.
- **Cycles**: time-boxed iterations (akin to sprints). No GH analog;
  closest mapping is iteration custom fields in Projects v2.
- **Projects**: longer-running than cycles; group of issues with
  status & target date. Distinct from Projects v2 — Linear's project
  is a first-class object on the issue.
- **Labels**: hierarchical (parent labels with children).
- **Custom workflows** per team: states are not just open/closed.
- **Webhooks**: rich event surface — issue CRUD, comments, labels,
  reactions, projects, project updates, cycles, SLA, etc.

Auth: API key (workspace-scope) or OAuth.

### 9.2 Jira (Cloud)

[Jira Cloud platform REST API](https://developer.atlassian.com/cloud/jira/platform/rest/v3/),
[Jira Software REST API — Epics](https://developer.atlassian.com/cloud/jira/software/rest/api-group-epic/).

REST primary; GraphQL via Compass. Concepts:

- **Hierarchy**: Epic → Story / Task / Bug → Sub-task. Levels are
  configurable; Premium adds higher levels (Initiative).
- **Workflow**: per-project, configurable transitions, screens, and
  validators. **Status** is not a simple open/closed.
- **Sprints**: time-boxed (Software).
- **Custom fields**: extensive; field IDs (`customfield_10001`) must
  be discovered per-instance.
- **Bulk operations**: up to 1,000 issues per call (REST).
- **Auth**: API token (cloud), basic auth deprecated, OAuth 2.0 for
  apps.
- **Epic Link / Parent Link** legacy fields are deprecated in favor of
  the newer `parent` field — version-pinning matters
  ([deprecation announcement](https://community.developer.atlassian.com/t/deprecation-of-the-epic-link-parent-link-and-other-related-fields-in-rest-apis-and-webhooks/54048)).

### 9.3 Smallest common surface

For an abstraction to support all three (GH, Linear, Jira) without
crippling any:

| Concept            | Common form                                                |
|--------------------|------------------------------------------------------------|
| Identifier         | Opaque string (GH `#42`, Linear `ABC-123`, Jira `PROJ-7`)  |
| Status             | `{open, closed}` + `state_reason` enum + per-backend raw   |
| Priority           | `null | low | medium | high | urgent` (4 levels)            |
| Hierarchy          | One parent per item; many children; depth not enforced     |
| Dependencies       | Untyped link list with `kind ∈ {blocks, blocked-by, related}` |
| Labels             | Flat list of strings (Linear hierarchy collapses)          |
| Iteration          | Optional `{name, start, end}` (Jira sprint, Linear cycle, GH iteration field) |
| Assignees          | List of user identifiers                                   |
| Milestone / Project| Optional single string (Jira fix-version, GH milestone, Linear project) |
| Custom fields      | Free-form key/value bag, backend-passthrough               |

Anything richer than this requires per-backend code paths. Anything
smaller loses fidelity.

---

## 10. Failure modes and operational concerns

### 10.1 Network unreachable

`gh` returns nonzero exit with message on stderr; offers no automatic
retry. MCP transport will fail the tool call; LLM sees an error
payload. Recommended pattern: **fail fast and tell the user** rather
than block the chat.

### 10.2 Rate limit hit

REST: HTTP 403 with `X-RateLimit-Remaining: 0` and `X-RateLimit-Reset`.
Search: HTTP 403 separately for the 30/min sub-bucket. GraphQL: `errors`
array with `RATE_LIMITED` type. Recommended exposure to the user:

- Quote remaining + reset window.
- Suggest the cheaper alternative (e.g., flat-file scan of BACKLOG.md
  if available).
- Do not silently retry; rate-limit retries amplify the outage.

`gh api rate_limit` polls current state cheaply.

### 10.3 Auth expired / 401

`gh` reports `gh: To get started with GitHub CLI, please run: gh auth
login`. MCP: tool call fails with auth-error payload. **Both leak the
exact failure mode in plain text** which is fine for chat recovery.

### 10.4 Schema reshape

Sub-issue and dependency features required GraphQL header opt-ins
during preview ([REST API for sub-issues](https://docs.github.com/en/rest/issues/sub-issues));
those headers stop being needed at GA but old tooling that always sets
them keeps working. Planning principle: **pin the GraphQL feature
header conditionally**, fall back, and never assume a field exists in
the schema without a probe.

GraphQL Explorer was retired 2025-11
([Changelog 2025-11-07](https://github.blog/changelog/2025-11-07-graphql-explorer-removal-from-api-documentation-on-november-7-2025/)),
which means schema introspection moves to local tools.

### 10.5 Partial-write recovery

Multi-step writes are not transactional. Sequence (create issue → add
sub-issue link → set type) can fail at any step. Patterns observed:

- **Forward-only with idempotent retries** — each step probes its
  desired state before writing. Re-runnable from any failure point.
- **Compensating undo** — if step 3 fails, delete what step 1 created.
  Adds blast radius; rarely worth it for tracker writes.
- **Mark with a draft label** — write all steps with `status:in-flight`,
  remove the label only when the multi-step completes. A reaper job
  cleans up stale drafts.

---

## 11. Lesser-known features that may fit

### 11.1 GraphQL one-shot fetches

A single GraphQL query can retrieve issue + comments + sub-issues +
linked PRs + project field values in one round trip. REST equivalent
is N+1. For "summarize this backlog item" chat operations, GraphQL is
materially cheaper.

### 11.2 Issue type field (GA 2025)

A dedicated typed dimension orthogonal to labels, settable in issue
forms via `type:` and on `gh issue create --type` (recent gh).
Limitation: issues only — PRs do not get a type field
([About the issue type field](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-the-issue-type-field)).

### 11.3 Projects v2 custom fields

Single-select, iteration, and date fields offer richer slicing than
labels and milestones — useful for `phase`, `severity`, `eta`. GraphQL
mutations exist; option creation has historical rough edges.

### 11.4 Saved searches

GitHub.com persists saved searches per user; not exposed in the API.
Don't depend on saved searches as a sharable artifact — encode the
filter in code.

### 11.5 GitHub Actions hooks (out of scope but adjacent)

Issue events (`opened`, `labeled`, `closed`, `sub_issues`,
`dependencies`) fire workflow triggers. Out of scope for chat-side
work, but a natural extension point for the pack — e.g., "moving an
issue to `phase:done` triggers a STATUS.md regen Action."

### 11.6 Discussions / PR / Codespaces relationships

- Discussion → Issue conversion is a single API call; useful when
  community-feedback maturation reaches "this is now work".
- PR ↔ Issue links via closing keywords on the default branch only.
- Codespaces auto-creation from issues exists in some plans but is
  not API-stable enough to script against.

---

## Executive summary

### 5 capabilities the architect should consider but might not know about

1. **Issue dependencies (`blocks` / `blocked by`) are now first-class as
   of Aug 2025**, with API + webhook support. Cap is 50 per relationship
   per issue, same/internal repos only. Distinct from closing keywords.
2. **Issue type is a separate typed field**, not a label, GA 2025.
   Settable in issue forms YAML, in `gh issue create --type` (recent
   gh), and via REST/GraphQL. Issues-only — PRs still need labels for
   parity.
3. **Advanced search with boolean AND/OR and parenthesized nesting**
   went default-on for all queries 2025-09-04. Existing label/milestone
   filters still work; new queries can use richer syntax.
4. **GitHub MCP server's `minimal_output=true` flag** trims responses
   to LLM-essential fields, materially cheaper than verbose returns.
5. **`gh api graphql -f query='...'`** is the canonical escape hatch
   for any operation `gh issue` can't express (sub-issues, blocks,
   Projects v2 fields, batched mutations).

### 5 hard limits the architect should design around

1. **Sub-issue depth = 8, 100 children per parent, 1 parent per child.**
2. **Blocks / blocked-by = 50 per relationship per issue, same-repo or
   internal-org only.**
3. **Issue/comment body = 65,536 chars.** PACK-FEEDBACK.md or
   IMPLEMENTATION_PLAN.md content cannot be pasted whole into one
   issue body past this.
4. **Search results capped at 1,000 per query** regardless of pagination.
   Use date-range slicing or label slicing for backlogs of any real size.
5. **REST search rate limit = 30 req/min**, far stricter than the
   5,000 req/hr core. Bulk search-driven workflows hit this first.

### 5 cross-CLI gotchas (Claude / Codex / Gemini asymmetries)

1. **MCP config locations differ.** Claude Code: `claude mcp add` or
   `~/.claude.json`; Codex: `~/.codex/config.toml` (TOML, with project
   trust gating); Gemini: `~/.gemini/settings.json` (JSON). No shared
   format.
2. **PAT scope expectations differ.** Codex docs prefer
   `bearer_token_env_var`; Gemini auto-expands `${VAR}` in `env`
   blocks; Claude Code accepts `-H "Authorization: Bearer ..."`. The
   pack must document three patterns, not one.
3. **Native shell tools differ in shape.** Codex's `local_shell` and
   Gemini's `run_shell_command` accept different parameter shapes,
   different sandbox semantics, and Gemini's interactive mode is
   gated by `tools.shell.enableInteractiveShell`.
4. **Subagent / agent invocation differs.** Claude Code: `Task` tool
   (programmatic) or `--agent` flag (CLI); Codex: no native subagent
   primitive; Gemini: `@subagent-name` invocation. A pack pattern of
   "delegate tracker work to a sub-agent" only ports cleanly between
   Claude and Gemini.
5. **`gh` extension availability is a per-machine concern**, not a
   per-CLI concern. Sub-issue and dependency operations need
   `gh-sub-issue` (or equivalent) installed unless the design uses
   `gh api graphql` directly. The pack must either bootstrap the
   extension or instruct via raw GraphQL.

### 5 abstraction concerns (where wider tracker compatibility constrains design)

1. **Status is the largest mismatch.** GH = open/closed + state_reason;
   Linear = per-team workflow states; Jira = per-project workflows.
   Any abstraction must accept "status" as a backend-defined string
   and not encode the GH binary as the canonical model.
2. **Hierarchy semantics differ.** GH sub-issue caps depth at 8 and
   children at 100; Linear has no documented depth cap; Jira's
   hierarchy is configurable. Designing to GH's caps would be safest;
   designing to Jira's could be unsafe at the bottom.
3. **Identifiers are not numeric.** Linear and Jira use
   `TEAM-NUMBER`. The pack's BD-NNN convention can stay internal, but
   the abstraction's `id` field must be an opaque string, not an int.
4. **Iteration fields are everywhere but spelled differently.**
   Cycles (Linear) ↔ sprints (Jira) ↔ Projects v2 iteration fields
   (GH). All map to a `{name, start, end}` triple, but only Jira and
   Linear surface them on the issue itself; on GH they live on the
   project, not the issue, which means a single-tracker GH design
   may not generalize without a project-aware code path.
5. **Custom fields are a passthrough requirement.** Jira's
   `customfield_10001` style is unavoidable for any Jira-backed
   workflow, and Projects v2 introduces a similar dimension on GH.
   The abstraction needs a free-form key/value bag with passthrough
   semantics, or it will block the next backend.

---

## Source index

All sources cited inline above. Selected anchor references:

- GitHub Docs:
  - [Adding sub-issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues)
  - [REST API endpoints for sub-issues](https://docs.github.com/en/rest/issues/sub-issues)
  - [About the issue type field](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-the-issue-type-field)
  - [Using keywords in issues and PRs](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/using-keywords-in-issues-and-pull-requests)
  - [Filtering and searching issues and PRs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/filtering-and-searching-issues-and-pull-requests)
  - [Searching issues and pull requests](https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests)
  - [REST search](https://docs.github.com/en/rest/search/search)
  - [Rate limits for REST API](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)
  - [Rate limits for GraphQL API](https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api)
  - [Configuring issue templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)
  - [Syntax for issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)
  - [Syntax for GitHub's form schema](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema)
  - [Using the API to manage Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
  - [Managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels)
  - [Attaching files](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files)
  - [Quickstart for GitHub Discussions](https://docs.github.com/en/discussions/quickstart)
  - [Repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits)
  - [Using pagination in the REST API](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)
- GitHub Changelog:
  - [Dependencies on issues (2025-08-21)](https://github.blog/changelog/2025-08-21-dependencies-on-issues/)
  - [Increased items in GitHub Projects (2025-02-26)](https://github.blog/changelog/2025-02-26-increased-items-in-github-projects-now-in-public-preview/)
  - [API support for issues advanced search (2025-03-06)](https://github.blog/changelog/2025-03-06-github-issues-projects-api-support-for-issues-advanced-search-and-more/)
  - [Remote GitHub MCP server (2025-06-12)](https://github.blog/changelog/2025-06-12-remote-github-mcp-server-is-now-available-in-public-preview/)
  - [GraphQL API resource limits (2025-09-01)](https://github.blog/changelog/2025-09-01-graphql-api-resource-limits/)
  - [Evolving GitHub Issues (public preview)](https://github.blog/changelog/2025-01-13-evolving-github-issues-public-preview/)
- GitHub Blog:
  - [Issues search now supports nested queries and boolean operators](https://github.blog/developer-skills/application-development/github-issues-search-now-supports-nested-queries-and-boolean-operators-heres-how-we-rebuilt-it/)
  - [GitHub CLI project command is now generally available](https://github.blog/developer-skills/github/github-cli-project-command-is-now-generally-available/)
- GitHub Community Discussions:
  - [Evolving GitHub Issues and Projects (GA) #154148](https://github.com/orgs/community/discussions/154148)
  - [Issue Dependencies feedback #165749](https://github.com/orgs/community/discussions/165749)
  - [Issue Types Public Preview #148715](https://github.com/orgs/community/discussions/148715)
  - [Advanced Search for Issues #148716](https://github.com/orgs/community/discussions/148716)
  - [Increased Project Item Limits Full Public Preview #152407](https://github.com/orgs/community/discussions/152407)
  - [Issue body / comment max length #27190](https://github.com/orgs/community/discussions/27190)
  - [Cannot create issue, comment too long #41331](https://github.com/orgs/community/discussions/41331)
  - [Understanding GitHub API Rate Limits #163553](https://github.com/orgs/community/discussions/163553)
- `gh` CLI:
  - [gh issue manual](https://cli.github.com/manual/gh_issue)
  - [gh issue list](https://cli.github.com/manual/gh_issue_list)
  - [gh issue view](https://cli.github.com/manual/gh_issue_view)
  - [gh search issues](https://cli.github.com/manual/gh_search_issues)
  - [gh auth login](https://cli.github.com/manual/gh_auth_login)
  - [Multiple accounts in cli/cli](https://github.com/cli/cli/blob/trunk/docs/multiple-accounts.md)
  - [Add gh issue support for parent / sub-tasks #10298](https://github.com/cli/cli/issues/10298)
  - [JSON type field support #12477](https://github.com/cli/cli/issues/12477)
- `gh` extensions:
  - [yahsan2/gh-sub-issue](https://github.com/yahsan2/gh-sub-issue)
  - [agbiotech/gh-sub-issue](https://github.com/agbiotech/gh-sub-issue)
  - [jwilger/gh-issue-ext](https://github.com/jwilger/gh-issue-ext)
  - [yahsan2/gh-pm](https://github.com/yahsan2/gh-pm)
  - [d-oit/gh-sub-issues](https://github.com/d-oit/gh-sub-issues)
- GitHub MCP server:
  - [github/github-mcp-server](https://github.com/github/github-mcp-server)
  - [server-configuration.md](https://github.com/github/github-mcp-server/blob/main/docs/server-configuration.md)
  - [install-codex.md](https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-codex.md)
  - [install-gemini-cli.md](https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-gemini-cli.md)
  - [install-claude.md](https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-claude.md)
  - [Add tool add_sub_issue #196](https://github.com/github/github-mcp-server/issues/196)
  - [Configuring toolsets](https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/configure-toolsets)
- Codex CLI:
  - [Codex CLI features](https://developers.openai.com/codex/cli/features)
  - [Codex CLI reference](https://developers.openai.com/codex/cli/reference)
  - [Codex MCP](https://developers.openai.com/codex/mcp)
  - [codex/docs/config.md](https://github.com/openai/codex/blob/main/docs/config.md)
- Gemini CLI:
  - [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli)
  - [Gemini CLI tools](https://google-gemini.github.io/gemini-cli/docs/tools/)
  - [Shell Tool](https://google-gemini.github.io/gemini-cli/docs/tools/shell.html)
  - [MCP servers with Gemini CLI](https://geminicli.com/docs/tools/mcp-server/)
  - [Subagents](https://geminicli.com/docs/core/subagents/)
- Linear:
  - [Linear Developers — Getting Started](https://linear.app/developers/graphql)
  - [API and Webhooks](https://linear.app/docs/api-and-webhooks)
  - [Advanced usage](https://linear.app/developers/advanced-usage)
- Jira:
  - [Jira Cloud platform REST API](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
  - [Jira Software Cloud REST API — Epics](https://developer.atlassian.com/cloud/jira/software/rest/api-group-epic/)
  - [Deprecation of Epic Link / Parent Link](https://community.developer.atlassian.com/t/deprecation-of-the-epic-link-parent-link-and-other-related-fields-in-rest-apis-and-webhooks/54048)
- Migration tools:
  - [svigerske/trac-to-github](https://github.com/svigerske/trac-to-github)
  - [str4d/migrate-trac-issues-to-github](https://github.com/str4d/migrate-trac-issues-to-github)
  - [mavam/trac-hub](https://github.com/mavam/trac-hub)
  - [olaaustine/github-issues-linear](https://github.com/olaaustine/github-issues-linear)
  - [Linear's GitHub integration](https://linear.app/integrations/github)
- Other:
  - [How GitHub Built Sub-Issues, InfoQ 2025-04](https://www.infoq.com/news/2025/04/github-subissues-journey/)

---

## 12. Recency verification (2026-05-03)

**Verified date:** 2026-05-03 (3 days after original research date of 2026-04-30).
Scope: confirm latest stable / preview versions of each CLI, surface
deltas since 2026-04-30, distinguish "materially wrong" from "merely
missing" against the existing 11 sections. No design recommendations.

### 12.1 Claude Code CLI

**Latest stable:** v2.1.126, released on or before 2026-05-01
([Claude Code release notes — May 2026, Releasebot](https://releasebot.io/updates/anthropic/claude-code);
[Claude Code Changelog](https://code.claude.com/docs/en/changelog);
[anthropics/claude-code releases](https://github.com/anthropics/claude-code/releases)).
The original report does not cite a specific Claude Code version; it
references Agent Teams as requiring v2.1.32+ which remains accurate
([Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams)).

**Recent notable changes (post-2026-04-30):**

- v2.1.126 adds `claude project purge [path]` for deleting all Claude
  Code state for a project (transcripts, tasks, file history, config
  entry); flags `--dry-run`, `-y/--yes`, `-i/--interactive`, `--all`.
- `--dangerously-skip-permissions` flag added — bypasses prompts for
  writes to common project directories but retains prompts for
  catastrophic removals.
- `/model` picker now lists models from a gateway's `/v1/models`
  endpoint when `ANTHROPIC_BASE_URL` points at an
  Anthropic-compatible gateway.
- `claude auth login` accepts OAuth codes pasted into the terminal.
- `claude_code.skill_activated` event now includes an
  `invocation_trigger` attribute (relevant if §3 / §11 designs hook
  into skill activation telemetry).
- MCP servers that hit a transient error during startup auto-retry
  up to 3 times.
- Pasting a PR URL into `/resume` finds the session that created the
  PR (GitHub, GHE, GitLab, Bitbucket).

**Corrections to original report:** None material. The original
report (§3, §5, §11.1) does not name specific Claude Code versions
beyond Agent Teams' v2.1.32+ floor, which is unchanged.

**Impact on architect's design space:** Marginal. The new
`invocation_trigger` field on `skill_activated` and the auto-retry
behavior on MCP startup are quality-of-life. `--dangerously-skip-permissions`
is worth flagging in any pack guidance that touches permission
prompts.

### 12.2 Codex CLI

**Latest:** Codex CLI ships on a near-daily cadence (mid-April 2026
release count was ~709)
([openai/codex releases](https://github.com/openai/codex/releases);
[Codex changelog](https://developers.openai.com/codex/changelog)).
Subagents shipped to **GA on 2026-03-14**
([digitalapplied — Codex Subagents GA](https://www.digitalapplied.com/blog/codex-subagents-ga-multi-agent-autonomous-coding-guide);
[OpenAI Codex Subagents docs](https://developers.openai.com/codex/subagents);
[Simon Willison — codex-subagents, 2026-03-16](https://simonwillison.net/2026/Mar/16/codex-subagents/)).

**Recent notable changes (post-2026-04-30 and prior weeks):**

- Persisted `/goal` workflows with app-server APIs, model tools,
  runtime continuation, and TUI controls (create, pause, resume,
  clear); `codex update` self-updater; configurable TUI keymaps;
  plan-mode nudges; `/statusline` and `/title` edits during active
  turns.
- Permission profiles expanded with built-in defaults, sandbox CLI
  profile selection, cwd controls, active-profile metadata for
  clients.
- Plugin workflows: marketplace install, remote bundle caching,
  remote uninstall, plugin-bundled hooks, hook enablement state,
  external-agent config import.
- `codex exec --json` now reports reasoning-token usage for
  programmatic consumers.
- GPT-5.5 available in the Codex app via composer model selector.

**Corrections to original report (MATERIAL):**

- **§5.4 / §11.3 (cross-CLI gotcha #4) is now wrong.** The report
  states: "Codex: no native subagent primitive" and "A pack pattern
  of 'delegate tracker work to a sub-agent' only ports cleanly
  between Claude and Gemini." This was true at the original cutoff
  the author appears to have used but is **incorrect as of
  2026-03-14**. Codex CLI now has a native subagent primitive:
  - Custom agents are defined as standalone TOML files at
    `~/.codex/agents/` (user) or `.codex/agents/` (project).
  - Each agent file supports keys including `model`,
    `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`,
    `skills.config`, `name`, `nickname_candidates`.
  - Global subagent settings live under `[agents]` in
    `config.toml`; `agents.max_depth` defaults to 1 (one level of
    spawning, no deeper nesting).
  - Built-in agents include `explorer`, `worker`, `default`; up to
    8 concurrent agents per session.
  - Citation: [Subagents — Codex docs](https://developers.openai.com/codex/subagents);
    [Codex Subagents GA — digitalapplied](https://www.digitalapplied.com/blog/codex-subagents-ga-multi-agent-autonomous-coding-guide);
    [Subagents and custom agents in Codex — Simon Willison](https://simonwillison.net/2026/Mar/16/codex-subagents/).
  - **Architect impact:** The "delegate to subagent" pattern now
    ports across all three CLIs, with three different config
    formats and three different invocation conventions. The §11.3
    bullet recommending this pattern only port between Claude and
    Gemini should be updated.

**Other corrections:** None material. §4's MCP coverage
(`~/.codex/config.toml`, stdio + Streamable HTTP, `codex mcp`
subcommands, project-trust gating) remains accurate.

**Impact on architect's design space:** Significant. Any v11
design that contemplates "delegate tracker work to a sub-agent"
can now assume Codex has a viable native target. The cost is one
more config schema (`~/.codex/agents/<name>.toml`) and one more
invocation convention (Codex's spawning model rather than Claude
`Task` / `--agent` or Gemini `@subagent`). The "trinity asymmetry"
in pack docs grows by one row.

### 12.3 Gemini CLI

**Latest stable:** **v0.40.0**, released 2026-04-28
([Latest stable release: v0.40.0](https://geminicli.com/docs/changelogs/latest/);
[google-gemini/gemini-cli releases](https://github.com/google-gemini/gemini-cli/releases)).
**Latest preview:** **v0.41.0-preview.0**, also released 2026-04-28
([Preview release: v0.41.0-preview.0](https://geminicli.com/docs/changelogs/preview/)).
Per the documented release schedule (preview cuts each Tuesday ~20:00
UTC, ≤1 week on main → preview, +1 week → stable), v0.41.0 stable is
expected ~2026-05-05/06.

**Recent notable changes (post-2026-04-30 and v0.40 / v0.41-preview):**

v0.40.0 stable:
- Topic-update narration enabled by default; **topic updates
  disabled for subagents** (subagents don't emit topic-update
  narration to keep parent context lean).
- Fix for missing OAuth fields in subagent parsing — subagents now
  inherit OAuth config correctly.
- Simplified `gemini gemma` command for setting up Gemma models
  locally.
- Replaced legacy `MemoryManagerAgent` with prompt-driven memory
  editing system (skill-creator integration).

v0.41.0-preview.0 (architecture additions, not breaking):
- Wired up new `ContextManager` and `AgentChatHistory` for state
  management — fundamental refactor of how agent conversation
  state is held (PR #25409 by @joshualitt).
- Output redirection for CLI commands.
- Manual session UUIDs via command-line arguments.
- Persistent auto-memory scratchpad for skill extraction
  (skill-creator integrated into skill extraction workflow).
- Boot performance: experiments and quota fetched asynchronously.

**Built-in subagents (currently shipped):**
`generalist`, `cli_help`, `codebase_investigator`, plus
experimental `browser_agent`
([Subagents — Gemini CLI docs](https://geminicli.com/docs/core/subagents/);
[Subagents have arrived — Google Developers Blog](https://developers.googleblog.com/subagents-have-arrived-in-gemini-cli/)).
The original report's §5.2 says "no first-party GH subagent" —
still accurate, no GitHub-flavored built-in shipped.

**Corrections to original report:**

- **§5.2 is incomplete, not wrong.** It does not mention the
  built-in subagents (`generalist`, `cli_help`,
  `codebase_investigator`, experimental `browser_agent`) that
  Gemini ships out of the box. The line "There is **no first-party
  GH subagent** shipped with Gemini CLI" is correct on its narrow
  point (no GitHub-specific subagent), but the broader claim that
  the pack must add subagents from scratch is over-stated — the
  built-ins exist and may be reusable for read-side tracker work
  (e.g., `codebase_investigator` for cross-referencing).
- **§5.2 should be qualified** with the v0.41-preview architecture
  addition: subagent state management is in flux
  (`ContextManager` / `AgentChatHistory`), so any pack code that
  introspects subagent conversation state directly may break
  between v0.40 and v0.41. Subagent **invocation** (`@subagent-name`)
  is unchanged.

**Impact on architect's design space:**

- The `@subagent-name` invocation pattern remains the stable
  surface; design against it.
- If the architect's design touches subagent internals (state
  inspection, history rewriting, custom memory hooks), wait for
  v0.41.0 stable — it's days away (~2026-05-05/06) and the
  refactor lands then.
- OAuth-in-subagents fix (v0.40) is relevant for any design that
  has a subagent talk to GitHub MCP via OAuth rather than PAT.

### 12.4 GitHub Issues / gh CLI / GH MCP server

**`gh` CLI:** Current stable is in the v2.87.x line (e.g., v2.87.1 /
v2.87.2 per [cli/cli releases](https://github.com/cli/cli/releases)).
The original report cites [cli/cli #10298](https://github.com/cli/cli/issues/10298)
saying `gh` has no built-in `gh issue sub-issue` subcommand "as of
late 2025." That issue remains open as of 2026-05-03; no native
sub-issue subcommand has shipped. §1.2 / §2.1 are still accurate.

**GitHub MCP server:** Continues active development. Recent additions
visible in the public release stream
([github/github-mcp-server releases](https://github.com/github/github-mcp-server/releases)):
- Granular tools to set issue field values (issue type, status, etc.).
- `--exclude-tools` flag (and `X-MCP-Exclude-Tools` header) to
  selectively disable tools — relevant to §3.1 toolset gating.
- MCP Apps support migrated from insiders mode to feature-flag with
  insiders opt-in.
- OAuth token caching fix when multiple servers share a URL but use
  different static OAuth client IDs.
- MCP tool-name sanitization for names with dots / invalid chars.
- Earlier January 2026 changelog entry: new Projects tools, OAuth
  scope filtering, automatic tool filtering based on token
  permissions
  ([GH Changelog 2026-01-28](https://github.blog/changelog/2026-01-28-github-mcp-server-new-projects-tools-oauth-scope-filtering-and-new-features/)).

**Corrections to original report:**

- **§3.1 / §3.2 is still substantively correct** but slightly
  understated. The "~162 tools" count and listed default toolsets
  remain in the right range; granular issue-field tools have been
  added since, so the issues toolset surface area has grown. No
  hard count changes that affect design.
- **§3.5 / §3.6 unchanged.**

**Impact on architect's design space:** Low. The `--exclude-tools`
flag is the only addition that meaningfully affects how a pack
might recommend gating MCP exposure (it lets the pack ship a
"deny-list" rather than build a custom allow-list config).

### 12.5 Summary

**Materially wrong in original report:**

1. **§5.4 cross-CLI gotcha #4 — Codex subagent claim.** The report
   states Codex has no native subagent primitive and that the
   "delegate to subagent" pattern only ports between Claude and
   Gemini. As of 2026-03-14 GA, Codex has subagents
   (`~/.codex/agents/*.toml`, `[agents]` block, built-in
   `explorer` / `worker` / `default`, up to 8 concurrent, depth 1
   by default). The pattern now ports to all three CLIs.
   Citation: [Codex subagents docs](https://developers.openai.com/codex/subagents).

**Materially missing in original report:**

2. **§5.2 omits Gemini's built-in subagents** (`generalist`,
   `cli_help`, `codebase_investigator`, experimental
   `browser_agent`). Architects designing read-side tracker
   delegation may want to layer on top of `codebase_investigator`
   rather than build from scratch.
3. **§5.2 omits the v0.41-preview `ContextManager` /
   `AgentChatHistory` refactor.** Stable lands ~2026-05-05/06.
   Designs that read subagent history directly may break.
4. **§3 omits `--exclude-tools`** as a config gating mechanism for
   the GitHub MCP server.

**Net impact on architect's design space:**

The §11 cross-CLI summary needs one update (Codex now has
subagents) and two qualifications (Gemini ships built-in subagents;
Gemini's subagent state management is in active refactor). None of
these change the **shape** of the recommended cross-CLI patterns —
they expand the design surface (more places where the "delegate"
pattern works) and add one near-term timing question.

**Should the architect proceed now or wait?**

Proceed now for design work that touches subagent **invocation**
(stable surfaces in all three CLIs). Wait ~3–4 days
(target 2026-05-06/07) before locking any design that reads or
manipulates Gemini subagent **internal state**, since v0.41.0
stable lands in that window and includes the `ContextManager` /
`AgentChatHistory` refactor. The Codex subagent surface is GA and
stable; design against `~/.codex/agents/*.toml` today is safe.
