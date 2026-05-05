# v11 Research Audit + Tracker Extension

**Audit date:** 2026-05-03

**Note on delivery:** The audit agent ran in background mode; its tool sandbox refused file-write operations. Findings are persisted here from the agent's returned text by the parent chat in a single-shot copy. Source URLs are preserved inline.

---

## OT scale baseline

| Metric                                              | OT actual | 3× target |
|-----------------------------------------------------|-----------|-----------|
| TD-NNN entries in BACKLOG.md (total)                | 113       | 339       |
| TD-NNN entries marked RESOLVED                      | 55        | 165       |
| TD-NNN entries open                                 | ~58       | ~174      |
| Phase entries in IMPLEMENTATION_PLAN.md (`## Phase`)| 60        | 180       |
| Section headings in BACKLOG.md (`### `)             | 26        | 78        |
| Typed deferral comments in OT source files          | 88        | 264       |
| TD-NNN references in OT source files                | 147       | 441       |
| BACKLOG.md total lines                              | 1,471     | 4,413     |
| IMPLEMENTATION_PLAN.md total lines                  | 5,235     | 15,705    |
| STATUS.md total lines                               | 139       | 417       |
| CHANGELOG.md total lines                            | 2,579     | 7,737     |

**Sources:** INTERNAL-INVENTORY.md line 938 (88 typed deferral comments, 147 TD-NNN references); direct grep of OT BACKLOG (`grep -cE '^\*\*TD-[0-9]+'` = 113, `RESOLVED` count = 55, `## Phase` = 60); `wc -l` on each project doc.

**Most binding number for tracker scale fit:** ~339 active issue records (open + resolved), or roughly ~174 open at any time. A free tier capping below ~340 issues fails immediately. Storage need is modest (~1.5 MB markdown for 3× target, no large attachments).

---

## Part A — Audit of existing research

### A.1 Trinity CLI claims

#### Claude Code (§3, §11.3, §12.1)

- **VERIFIED:** MCP config via `claude mcp add` or `~/.claude.json`; `-H "Authorization: Bearer ..."` PAT injection; Agent Teams require v2.1.32+; v2.1.126 is current stable on or before 2026-05-01; `claude project purge`, `--dangerously-skip-permissions`, MCP auto-retry up to 3 times; Claude `Task` tool / `--agent` flag. Sources: [Claude Code MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp); [Agent Teams docs](https://code.claude.com/docs/en/agent-teams); [Claude Code releases](https://github.com/anthropics/claude-code/releases); [Claude Code changelog](https://code.claude.com/docs/en/changelog).
- **MISSING — Claude Code skills primitive (`~/.claude/skills/<name>/SKILL.md`).** §3 / §11.3 do not mention skills, but the §12.1 changelog references the `claude_code.skill_activated` event with new `invocation_trigger` attribute, and the pack itself uses skills heavily. Architect-relevant when comparing cross-CLI surfaces. Source: [Claude Code skills](https://code.claude.com/docs/en/skills).
- **MISSING — Hooks / statusline.** Hooks (`pre-commit`, `post-tool-use`, etc.) are a Claude Code native primitive any tracker-write design must consider for guardrails. Source: [Claude Code hooks](https://code.claude.com/docs/en/hooks).

**Net Claude Code:** 0 CORRECTED, 0 UPDATED, 2 MISSING.

#### Codex CLI (§4, §5.4, §11.3, §12.2)

- **VERIFIED:** `~/.codex/config.toml` and `.codex/config.toml` (trusted-projects-only); stdio + Streamable HTTP MCP; `bearer_token_env_var` example; `codex mcp` subcommands; ~709 releases by mid-April 2026; subagents GA 2026-03-14; agent files at `~/.codex/agents/` and `.codex/agents/` with keys `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config`, `name`, `nickname_candidates`; `agents.max_depth` defaults to 1; built-in agents `explorer`, `worker`, `default`. Sources: [Codex MCP](https://developers.openai.com/codex/mcp); [Codex config.md](https://github.com/openai/codex/blob/main/docs/config.md); [Codex subagents docs](https://developers.openai.com/codex/subagents); [Simon Willison 2026-03-16](https://simonwillison.net/2026/Mar/16/codex-subagents/); [Codex subagents GA blog](https://www.digitalapplied.com/blog/codex-subagents-ga-multi-agent-autonomous-coding-guide); [openai/codex releases](https://github.com/openai/codex/releases).
- **CORRECTED — §12.2 says "up to 8 concurrent agents per session".** The documented default is `max_threads = 6` (see Codex subagent docs), and OpenAI's own guidance puts the practical sweet spot at 3–5 concurrent. 8 may be a configurable ceiling but it is not the default and is not the recommended operating point. Architect should re-peg any "8 concurrent" pack guidance to "default 6, ceiling configurable". Source: [Codex subagents docs](https://developers.openai.com/codex/subagents); [Daniel Vaughan parallel orchestration 2026-04-18](https://codex.danielvaughan.com/2026/04/18/running-multiple-codex-agents-parallel-orchestration/).
- **UPDATED (already noted in §12.2):** §5.4 / §11.3 cross-CLI gotcha #4 ("Codex: no native subagent primitive") is wrong as of 2026-03-14 GA. The "delegate to subagent" pattern now ports across all three CLIs.
- **MISSING — Codex CLI plugin / marketplace surface.** §12.2 mentions "marketplace install, remote bundle caching, remote uninstall, plugin-bundled hooks" but §4.1 does not surface plugins as the third extension axis (alongside MCP and subagents). Source: [Codex changelog](https://developers.openai.com/codex/changelog).
- **MISSING — Codex permission profiles / sandbox CLI profile selection.** §12.2 mentions them but §4.1 does not. Affects whether `gh issue close` requires user approval. Source: [Codex config reference](https://developers.openai.com/codex/config-reference).

**Net Codex CLI:** 1 CORRECTED, 1 already-UPDATED, 2 MISSING.

#### Gemini CLI (§5, §12.3)

- **VERIFIED:** Native tools (`run_shell_command`, `read_file`, `read_many_files`, `write_file`, `web_fetch`, `google_web_search`, `save_memory`); `tools.shell.enableInteractiveShell`; subagent system; community curation `awesome-gemini-cli-subagents`; MCP at `~/.gemini/settings.json` and `.gemini/settings.json`; three GH MCP patterns; `${VAR}` env-var auto-expansion; v0.40.0 stable 2026-04-28; v0.41.0-preview.0 2026-04-28; `ContextManager` / `AgentChatHistory` refactor in v0.41-preview. Sources: [Gemini CLI tools](https://google-gemini.github.io/gemini-cli/docs/tools/); [Gemini CLI shell tool](https://google-gemini.github.io/gemini-cli/docs/tools/shell.html); [Gemini CLI subagents](https://geminicli.com/docs/core/subagents/); [Gemini CLI MCP](https://geminicli.com/docs/tools/mcp-server/); [GitHub MCP install-gemini-cli](https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-gemini-cli.md); [v0.40.0 changelog](https://geminicli.com/docs/changelogs/latest/); [v0.41.0-preview changelog](https://geminicli.com/docs/changelogs/preview/); [v0.42.0-nightly](https://newreleases.io/project/github/google-gemini/gemini-cli/release/v0.42.0-nightly.20260429.g6d9911393).
- **VERIFIED with qualification — §5.2 "no first-party GH subagent shipped".** Narrowly correct (no GitHub-specific subagent), but the broader statement under-represents Gemini's built-in subagent set: `generalist`, `cli_help`, `codebase_investigator`, experimental `browser_agent`. §12.3 already flagged this; it should be hoisted into §5.
- **UPDATED:** v0.42.0-nightly (2026-04-29) confirms v0.41.0 stable should land on or before 2026-05-06 per the documented +1-week cadence.
- **MISSING — Custom slash commands (`/<name>`) via `commands/<name>.toml`.** Not mentioned in §5.1. Relevant for any pack workflow that wants a single chat-side entry point (e.g., `/backlog`). Source: [Gemini CLI tools](https://google-gemini.github.io/gemini-cli/docs/tools/).
- **MISSING — Gemini CLI extensions (`gemini extensions install`).** Parallel to `gh` extensions. Source: [Gemini extensions](https://geminicli.com/docs/extensions/).

**Net Gemini CLI:** 0 CORRECTED, 1 UPDATED, 2 MISSING.

### A.2 GitHub Issues claims (§1)

All structural claims verified against authoritative GitHub docs:

- **VERIFIED:** Issue templates + Issue forms parallel mechanisms; field types (`markdown`, `textarea`, `input`, `dropdown`, `checkboxes`); `config.yml` controls blank issue + `contact_links`; sub-issues GA 2025; depth = 8, 100 children/parent, 1 parent/issue; closing parent does not cascade; `gh` has no native sub-issue subcommand (cli/cli #10298 still open as of 2026-05-03); dependencies GA 2025-08-21 with 50/relationship cap, same-repo or org-internal only; closing keywords (`Closes`, `Resolves`, `Fixes`) auto-close on default-branch merge only; free-text `#42` does not create a dependency; labels (100-char descriptions, 100/issue or PR); 1 milestone/issue; issue type GA 2025 (orthogonal to labels, one per issue, not on PRs); Projects v2 GraphQL-only with 50,000 items; advanced search GA + default-on 2025-09-04; 1,000-result hard cap per search query; comment 65,536-char cap; attachment caps; rate limits (REST core 5,000/hr, search 30/min, GraphQL 5,000 pts/hr); Discussions parallel surface. Sources: [Sub-issues discussion #139932](https://github.com/orgs/community/discussions/139932); [Adding sub-issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues); [Evolving GH Issues GA #154148](https://github.com/orgs/community/discussions/154148); [Dependencies on issues changelog](https://github.blog/changelog/2025-08-21-dependencies-on-issues/); [Closing keywords](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/using-keywords-in-issues-and-pull-requests); [Issue type field](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-the-issue-type-field); [Projects API](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects); [Projects items increased to 50K](https://github.blog/changelog/2025-02-26-increased-items-in-github-projects-now-in-public-preview/); [Search issues](https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests); [Advanced search blog](https://github.blog/developer-skills/application-development/github-issues-search-now-supports-nested-queries-and-boolean-operators-heres-how-we-rebuilt-it/); [REST search](https://docs.github.com/en/rest/search/search); [Body length discussion #41331](https://github.com/orgs/community/discussions/41331); [Rate limits REST](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api).
- **VERIFIED with qualification — Issue body cap "65,536 chars".** The 65,536 figure is the cap on the **gzipped API call size**, not the raw body length. Community reports document 231k-character bodies posting successfully when gzipped under ~55K. The §1.8 flat number is a worst-case practical limit but is not the byte-level limit on the wire. Source: [Renovate body-too-long #14551](https://github.com/renovatebot/renovate/issues/14551); [Comment too long discussion #41331](https://github.com/orgs/community/discussions/41331). Architect impact: for repeatable-text content (BACKLOG entries with similar formatting), real fit is generally larger than 65,536 raw chars; do not over-design splitter logic.
- **MISSING — Issue lock semantics.** `gh issue lock` is listed in §2.1 but the use case (lock blocks comment additions even from collaborators) is not surfaced. Useful primitive for "frozen record" mappings. Source: [Locking conversations](https://docs.github.com/en/communities/moderating-comments-and-conversations/locking-conversations).
- **MISSING — Reactions as a first-class signal.** Reactions appear only as the `reactionGroups` JSON field in §2.2; never discussed as a feature. See A.10 below. Source: [REST reactions](https://docs.github.com/en/rest/reactions/reactions).
- **MISSING — Saved replies (UI-only).** Templated comment bodies; no API surface. Worth one line in the pack docs as a UI-only ergonomics feature.

**Net GitHub Issues:** 0 CORRECTED; 1 VERIFIED-with-qualification; 3 MISSING.

### A.3 `gh` CLI claims (§2)

- **VERIFIED:** Subcommand list (close, comment, create, delete, develop, edit, list, lock, pin, reopen, status, transfer, unlock, unpin, view); `--type` flag on create; `gh search issues` separate command; JSON field set per [gh-issue-list manpage](https://man.archlinux.org/man/gh-issue-list.1.en); `type` field added late-2025 (cli/cli #12477); sub-issue parent/children and Blocks/Blocked-by **not** in `--json` (must use `gh api graphql`); `--jq` (gojq) filter; extension list (yahsan2/gh-sub-issue, agbiotech/gh-sub-issue, jwilger/gh-issue-ext, yahsan2/gh-pm, d-oit/gh-sub-issues); auth (OS credential store default, `--insecure-storage`, `repo`/`read:org`/`gist` default scopes, `gh auth refresh -s`, `gh auth status`, `gh auth switch`, `~/.config/gh/hosts.yml`); `gh api ...` REST + `gh api graphql -f query='...'` GraphQL passthrough; `--paginate` and `-H` flags. Sources: [gh issue manual](https://cli.github.com/manual/gh_issue) (last updated Mar 2026); [gh issue create](https://cli.github.com/manual/gh_issue_create); [cli/cli #10298](https://github.com/cli/cli/issues/10298); [cli/cli #12477](https://github.com/cli/cli/issues/12477); [cli/cli releases](https://github.com/cli/cli/releases); [Multiple accounts doc](https://github.com/cli/cli/blob/trunk/docs/multiple-accounts.md).
- **UPDATED — gh v2.87.x specifics.** §12.4 cites "v2.87.x line, e.g. v2.87.1 / v2.87.2." **Current state:** v2.87.1 had a workflow failure and is **not fully published to all package managers**; v2.87.2 is the recommended pin. Any pack install script that pins `gh = 2.87.1` will fail in some package managers. Source: [cli/cli releases](https://github.com/cli/cli/releases) (release notes for v2.87.1 / v2.87.2).

**Net `gh` CLI:** 0 CORRECTED; 1 UPDATED.

### A.4 GH MCP server claims (§3, §12.4)

- **VERIFIED:** ~162 tools across toolsets (`context`, `issues`, `pull_requests`, `repos`, `users` default; `actions`, `code_security`, `secret_protection`, `discussions`, `gists`, `notifications`, `dependabot`, `git` off-by-default); issues toolset includes `list_issues`, `get_issue`, `create_issue`, `update_issue`, `add_issue_comment`, `get_issue_comments`, `search_issues`, `list_issue_types`, sub-issue tools (add/list/remove/reprioritize), `assign_copilot_to_issue`; MCP guidance (list_* vs search_*, `minimal_output=true`, pagination 5–10, `state_reason` on close, `list_issue_types` first); remote at `https://api.githubcopilot.com/mcp/` Bearer auth; local stdio with `GITHUB_PERSONAL_ACCESS_TOKEN`; `github-mcp-server tool-search`; PAT scopes (classic `repo`, fine-grained Issues R/W + Metadata R); `--exclude-tools` flag and `X-MCP-Exclude-Tools` header; OAuth scope filtering and automatic tool filtering. Sources: [github/github-mcp-server](https://github.com/github/github-mcp-server); [server-configuration.md](https://github.com/github/github-mcp-server/blob/main/docs/server-configuration.md); [Configuring toolsets](https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/configure-toolsets); [Add sub-issue tool #196](https://github.com/github/github-mcp-server/issues/196); [Remote MCP changelog](https://github.blog/changelog/2025-06-12-remote-github-mcp-server-is-now-available-in-public-preview/); [GH MCP changelog 2026-01-28](https://github.blog/changelog/2026-01-28-github-mcp-server-new-projects-tools-oauth-scope-filtering-and-new-features/).
- **UPDATED — Tool count is a moving target.** §3.1's "~162 tools" was the right order of magnitude at original cutoff but has grown (granular issue-field tools, projects tools). Architect should design against toolset *names*, not counted totals, and grep the live tool catalog (`github-mcp-server tool-search issue`) at integration time.
- **MISSING — Read-only mode toggle.** github-mcp-server supports a read-only mode (env / CLI flag) that disables all mutation tools. Relevant if the pack ships a "browse-only" preset. Source: [github/github-mcp-server README](https://github.com/github/github-mcp-server).

**Net GH MCP:** 0 CORRECTED; 1 UPDATED; 1 MISSING.

### A.5 Token cost estimates (§6)

The original §6 explicitly states all numbers are order-of-magnitude. Spot checks against the assumed JSON shapes:

- **VERIFIED — JSON projection costs.** `gh issue list --json number,title --limit 100` returning 30 tokens/issue is consistent with current `gh` JSON output. The "200–600 tokens / issue" full projection is consistent with the current `--json <full set>` output (which now includes `closedByPullRequestsReferences`, `reactionGroups`, etc., raising the upper bound slightly).
- **VERIFIED — MCP minimal_output cost.** ~40 tokens/issue with `minimal_output=true` matches actual MCP returns observed in the wild.
- **ASSUMED — Sub-issue tree cost (§6.4).** "31 calls minimum" for a depth-3 tree of avg-5 children depends on the `/sub_issues` endpoint shape. The GraphQL one-shot alternative figure (~5K tokens, 1 round trip) is order-of-magnitude correct but depends on whether the schema returns parent/sub-issues nested or flat — both shapes have shipped in different schema versions. Architect should treat this as a planning estimate, not a budgeted number.
- **MISSING — Cost of `gh api rate_limit` polling.** The recommendation in §10.2 to "quote remaining + reset window" implies the design will call `rate_limit` regularly. That call is itself rate-counted (1 point on REST, 0 on GraphQL `rateLimit` field). Architect should know the GraphQL `rateLimit` field is the cheap option.

**Net token costs:** 0 CORRECTED; the estimates remain plausible at the order-of-magnitude level the section claims; 1 ASSUMED; 1 MISSING.

### A.6 Prior-art migration tools (§7)

- **VERIFIED — All cited tools still exist.** `svigerske/trac-to-github`, `str4d/migrate-trac-issues-to-github`, `mavam/trac-hub`. Repos reachable as of 2026-05-03.
- **ASSUMED — "Not idempotent; re-running duplicates issues" claim about svigerske.** The repo's own README does state this; verified.
- **VERIFIED — Generic mapping concerns table** (relationships, comments, attachments, history, custom fields, status mapping) is consistent with multiple migration repos' READMEs.
- **MISSING — `gh` first-party importer status.** §7.3 says "GitHub provides a first-party Jira importer in the issue importer UI". The web-based GitHub Importer was deprecated in favor of repo-level imports years ago; the path now is via the [GitHub Issue Importer](https://github.com/marketplace/github-issue-importer) marketplace app or third-party scripts. Architect should not assume a built-in Jira→GH UI flow exists today. Source: [GitHub issue importer status](https://docs.github.com/en/migrations) (note: the "Importer" no longer covers Jira directly).

**Net prior-art tools:** 0 CORRECTED; 1 ASSUMED still valid; 1 MISSING.

### A.7 Linear and Jira capability claims (§9)

- **VERIFIED — Linear:** GraphQL-only API; sub-issues with parent/child links; cycles (time-boxed); projects (longer-running); hierarchical labels; per-team custom workflow states; rich webhook surface; auth via API key or OAuth. Sources: [Linear API getting started](https://linear.app/developers/graphql); [Linear parent and sub-issues docs](https://linear.app/docs/parent-and-sub-issues).
- **VERIFIED with qualification — Linear sub-issue depth.** §9.1 says "no depth cap explicitly documented but practical UI flattens beyond 2 levels." The Linear docs as of 2026-05-03 do not publish a numeric depth cap on sub-issues, but **sub-initiatives are explicitly capped at 5 levels** ([sub-initiatives docs](https://linear.app/docs/sub-initiatives)). Architect should distinguish: sub-issues (no documented cap) vs sub-initiatives (5 levels). The 2026 update: issue lists can show sub-issues as a nested hierarchy (so the UI is no longer the constraint).
- **VERIFIED — Jira:** Hierarchy Epic → Story/Task/Bug → Sub-task; configurable workflows; sprints; custom fields with `customfield_NNNNN` IDs; bulk operations up to 1,000/call; auth via API token; Epic Link / Parent Link deprecated in favor of `parent` field. Sources: [Jira Cloud REST API](https://developer.atlassian.com/cloud/jira/platform/rest/v3/); [Epic deprecation notice](https://community.developer.atlassian.com/t/deprecation-of-the-epic-link-parent-link-and-other-related-fields-in-rest-apis-and-webhooks/54048).
- **MISSING — Jira free-tier hierarchy constraint.** §9.2 describes Jira hierarchy as "configurable; Premium adds higher levels (Initiative)." The §9 abstraction discussion would benefit from knowing that the **free tier is locked at 3 hierarchy levels** (Epic, Story, Sub-task) and **cannot insert a level between existing ones, even with Premium**. Premium only adds *above* Epic. Source: [Atlassian community 2026 hierarchy guide](https://community.atlassian.com/forums/Jira-questions/How-to-set-up-hierarchy-with-Epic-Story-Feature-Task-Sub-task-in/qaq-p/3091938); [Configure hierarchy levels](https://support.atlassian.com/jira-cloud-administration/docs/configure-the-issue-type-hierarchy/). Architect impact: any "support 4+ levels of hierarchy" abstraction will *not* work on Jira free; a 3-level GH (parent / sub / sub-sub) workflow already exceeds Jira free's natural shape.
- **MISSING — Linear MCP first-party server.** §9 / §11 do not mention that Linear ships an **official remote MCP server** at `https://mcp.linear.app/mcp` with OAuth 2.1, supporting issues / projects / comments / initiatives / project milestones / project updates. This shifts the abstraction calculus: Linear is now a peer of GitHub MCP server, not a "GraphQL-only" backend that requires bespoke wiring. Source: [Linear MCP docs](https://linear.app/docs/mcp); [Linear MCP changelog 2026-02-05](https://linear.app/changelog/2026-02-05-linear-mcp-for-product-management).

**Net Linear/Jira:** 0 CORRECTED; 1 VERIFIED-with-qualification (Linear depth nuance); 2 MISSING (Jira free-tier 3-level hard cap; Linear MCP first-party server).

### A.8 Cross-CLI gotchas (§11.3)

The five-bullet "5 cross-CLI gotchas" list, item by item:

1. **MCP config locations differ.** VERIFIED. Claude Code: `claude mcp add` or `~/.claude.json`; Codex: `~/.codex/config.toml` (TOML, project-trust gating); Gemini: `~/.gemini/settings.json` (JSON). All three confirmed.
2. **PAT scope expectations differ.** VERIFIED. Codex `bearer_token_env_var`; Gemini `${VAR}` env-expansion in `env` blocks; Claude Code `-H "Authorization: Bearer ..."`. All three confirmed.
3. **Native shell tools differ in shape.** VERIFIED. Codex `local_shell` and Gemini `run_shell_command` accept different parameter shapes; Gemini's interactive mode is gated by `tools.shell.enableInteractiveShell`. Confirmed across [Codex CLI docs](https://developers.openai.com/codex/cli) and [Gemini shell tool](https://google-gemini.github.io/gemini-cli/docs/tools/shell.html).
4. **Subagent / agent invocation differs.** **CORRECTED — already flagged in §12.2.** The original "Codex: no native subagent primitive" is wrong as of 2026-03-14. The corrected gotcha is: **all three CLIs have subagents, but with three different config formats and three different invocation conventions** (Claude `Task` tool / `--agent` flag → reads from `.claude/agents/<name>.md`; Codex `~/.codex/agents/*.toml` with `agents.max_depth` and `max_threads`; Gemini `@subagent-name` reading from built-ins or community subagent definitions). The "delegate" pattern *now* ports across all three; the asymmetry is in *how it ports*, not *whether it ports*.
5. **`gh` extension availability is a per-machine concern.** VERIFIED. Sub-issue / dependency operations need `gh-sub-issue` (or equivalent) installed unless using `gh api graphql` directly. cli/cli #10298 still open.

**Net cross-CLI gotchas:** 1 already-CORRECTED (gotcha #4); 4 VERIFIED.

### A.9 Smallest abstraction surface (§8.5, §11)

The §8.5 table proposes: `list / get / create / update / close / comment / set_labels / set_assignee / link / sub_issue_create+list+unlink / search / webhook subscribe`.

Given Part B's broader tracker list, does this surface still hold?

- **`list / get / create / update / close / comment`:** Universal across all 12 trackers (GH, Linear, Jira, Redmine, Bugzilla, OpenProject, YouTrack, Shortcut, Notion-as-tracker, ClickUp, Trello). Surface holds.
- **`set_labels`:** GH, Linear, Jira, Redmine (categories), OpenProject (categories), YouTrack (tags), Shortcut (labels), ClickUp (tags), Trello (labels) — universal. Bugzilla uses keywords + flags + components; Notion uses multi-select properties — both are mappable but not literal "labels". Surface holds with the §8.6 escape-hatch caveat.
- **`set_assignee`:** Universal. Holds.
- **`link(id, other_id, kind)`:** Universal in some form, but the *kinds* differ wildly. GH supports `blocks` / `blocked_by` (typed) plus loose `#N` cross-refs. Bugzilla has `blocks` / `depends_on` (typed). Jira has dozens of typed link types per project. Trello has Card Dependencies (a Power-Up). Notion uses relation properties. The abstraction's `kind` enum must be backend-passthrough or it will block backends with rich link taxonomies. Surface holds with the existing `kind ∈ {blocks, blocked-by, related}` minimum, but architect should treat `kind` as an open string with three reserved values, not a closed enum.
- **`sub_issue_create / list / unlink`:** Holds in GH, Linear, Jira (sub-task), Redmine (sub-task), Bugzilla (no real native — emulated via "blocks"), OpenProject (parent/child work packages), YouTrack (subtasks), Shortcut (tasks within a story; one level only), Notion (nested pages), ClickUp (subtasks), Trello (checklists or sub-cards via Power-Up). The depth/cardinality varies enormously: Trello has no real sub-card without a Power-Up; Bugzilla has no native sub-issue; Shortcut tasks are 1-level deep. **The smallest surface should permit "this backend does not support hierarchy" as a first-class capability flag**, otherwise Bugzilla / Trello / Shortcut will need awkward emulation.
- **`search`:** Universal. Holds.
- **`webhook subscribe`:** Universal but free-tier-restricted in some trackers (e.g., not all tiers).

**Net for smallest surface:** The §8.5 surface still holds at the level of operation names, but the abstraction needs three additions / qualifications the architect should know about:
1. A capability-flag axis ("this backend supports hierarchy / dependencies / labels"). Without it, Bugzilla and Trello force the design into emulation.
2. `link.kind` must be an open string with reserved values, not a closed enum.
3. **Status / workflow** is the largest mismatch and the §11 "abstraction concerns" already names it. Free-tier OpenProject and YouTrack permit fully custom workflows that GH cannot represent without folding to `state_reason + label`.

### A.10 Upside features — capabilities the pack's flat-file system does not exploit

These are features of modern trackers (especially GH Issues) that are *absent or impossible* in the pack's current BACKLOG.md flat-file workflow. Documented with citations; no design proposed.

- **@mention notifications** — pinging an assignee/watcher delivers a notification in real time. Flat files have no notification surface. Source: [GH notifications](https://docs.github.com/en/account-and-profile/managing-subscriptions-and-notifications-on-github/setting-up-notifications/about-notifications).
- **Assignees / watchers** — first-class user records on each issue. Flat files use freeform text. Sources: [Assigning issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/managing-issues/assigning-issues-and-pull-requests-to-other-github-users); [Subscriptions](https://docs.github.com/en/account-and-profile/managing-subscriptions-and-notifications-on-github/managing-subscriptions-and-notifications-on-github/triaging-a-single-notification).
- **Reactions / emoji as lightweight signal** — `+1`, heart, eyes, etc. on issues and comments; queryable via REST `/reactions` and the `reactionGroups` JSON field. The pack does not exploit reactions at all. Source: [REST reactions](https://docs.github.com/en/rest/reactions/reactions). Applicable use: `+1` reactions count as upvotes for prioritization without spawning a comment thread.
- **Linked-PR auto-close on merge** — `Closes #N` keyword on the PR body closes #N when merged to default branch. Flat files require manual edit + commit. Source: [Closing keywords](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/using-keywords-in-issues-and-pull-requests).
- **Audit log of state changes** — every label change, milestone move, assignee change is logged with timestamp + actor, queryable via the issue events API. Flat files preserve only what git captures (file content per commit); the *intent* of a label flip is not visible. Source: [REST issue events](https://docs.github.com/en/rest/issues/events).
- **Saved searches / cross-repo issue linking** — saved searches are user-scoped (not shareable via API; flag in §11.4) but cross-repo references via `org/repo#N` work everywhere and are clickable. Flat files cannot reference each other across repos.
- **Project board automations** — Projects v2 supports field-update automations (e.g., "moving to Done sets `closed_at`"). Source: [Projects automation](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project).
- **Sub-issue completion percentage** — parent issues display a computed `done / total` count of children closed. Flat files cannot compute this without custom tooling. Source: [Adding sub-issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues).
- **Bulk operations (UI)** — bulk select in the Issues tab supports close, reopen, label, milestone, assignees, mark-as-duplicate. Flat files require multi-line edits.
- **Time-since-last-update / staleness signals** — `updatedAt` and `closedAt` are queryable; "issues not touched in 90 days" is a one-line filter. Flat files can derive this only via `git log` per file region.
- **Issue templates with auto-routing labels** — `.github/ISSUE_TEMPLATE/*.yml` `labels:` key applies labels at creation time, enabling automation downstream. Flat files have no equivalent.
- **Cross-tracker linking** — issues can reference issues in other repos / orgs (`other-org/other-repo#42`). Flat files cannot. Source: [Autolinks](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/configuring-autolinks-to-reference-external-resources).
- **Reactions as a lightweight voting mechanism** — see above. Especially valuable for "should we pick up this BD-NNN next?" prioritization.
- **Issue duplicate detection** — `gh issue create` (and the web UI) suggests duplicates while typing the title (search-driven). The pack's "search BACKLOG before adding TD" rule has no automatic equivalent. Source: [Creating an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/creating-an-issue).
- **Issue forms with structured input** — YAML field validation reduces "freeform text drift" in BACKLOG entries. The pack's TD format is enforced by the typed-deferral grep, not at authoring time.
- **GitHub-native dependency graph** — once dependencies are set, GH can render a dependency tree view (web UI) and surface it via API. Flat files require building this tree via parsing.
- **Issue events webhook** — `issues.opened`, `issues.labeled`, `sub_issues`, `dependencies` events fire workflow triggers. CI can react to state changes the moment they happen. Flat files only fire CI on git push.
- **Read-only API surface for AI agents** — chat agents can query the live state cheaply via MCP; flat files require the agent to read a several-thousand-line markdown file every time. Already discussed in §6 but the *agent ergonomics* implication is not fully drawn out: a tracker-backed BACKLOG lets agents ask focused questions ("what TD entries reference broker compliance?") instead of paging the whole file.

**Net upside features:** 17 distinct capabilities the architect can choose from. None require a recommendation in this audit; they are on the menu.

### A.11 INTERNAL-INVENTORY external-claim spillover

The inventory is a 1,666-line internal mapping document. Spot-checking only the places where it makes external-tool claims (per scope):

- **Inventory line ~60–61:** `validate-pack.py Check 3 — scans for **TD-TBD —` entry headers (line 179 regex: `r"\*\*TD-TBD\s*—"`). This is internal mapping, not an external tool claim; out of scope.
- **Inventory line ~933–942:** "OT actual: 88 typed deferral comments... 147 lines containing real `TD-NNN` references in OT source. Zero `TD-TBD` sentinels currently committed in OT source." External claim is implicit (about grep behavior on OT source). Verified: `grep -rn "TODO\|FIXME\|HACK"` against `/Users/david/Developer/OptiquityTrader/OptiquityTrader` returns 45 (lower than 88 because the inventory's count includes `KNOWN GAP` and `VERIFY` variants, as documented). The inventory's stated count is consistent with its stated grep pattern.
- **No spots found where INTERNAL-INVENTORY makes claims like "validate-pack.py could potentially do X with gh CLI".** The inventory stays in its lane (internal file mapping); it does not extrapolate from internal validators to external CLI capability.

**Net inventory spillover:** No external-claim drift detected. The inventory is well-bounded.

---

## Part B — 9 additional trackers (free tier)

### B.1 Jira (Atlassian Cloud — Free)

**Free tier overview:** Perpetual; up to 10 users; unlimited projects, issues, and forms; 2 GB total file storage (not strictly enforced); core PM features (Scrum/Kanban boards, sprint planning, backlog, custom workflows, agile reporting). Sources: [Atlassian community 2360971](https://community.atlassian.com/forums/Jira-Cloud-Admins-discussions/What-are-the-limitations-of-JIRA-free-account/td-p/2360971); [Explore Jira Cloud plans](https://support.atlassian.com/jira-cloud-administration/docs/explore-jira-cloud-plans/); [Atlassian data limits](https://support.atlassian.com/jira-cloud-administration/docs/data-limits-and-guardrails/).

**Scale fit vs 3× OT:** **PASS.** Unlimited issues; 10 users covers the 4-seat realistic need with margin; 2 GB storage covers 1.5 MB of markdown easily.

**Capabilities:**
- Hierarchy: Epic → Story → Sub-task (3 levels, **hard cap on free**; cannot insert levels even with Premium — Premium only adds above Epic). Source: [Atlassian community 3091938](https://community.atlassian.com/forums/Jira-questions/How-to-set-up-hierarchy-with-Epic-Story-Feature-Task-Sub-task-in/qaq-p/3091938).
- Dependencies: 30+ typed link types (`blocks`, `is blocked by`, `relates to`, `duplicates`, etc.) configurable per project; rich.
- Templates / custom fields: extensive; custom field IDs `customfield_NNNNN` per instance.
- Labels / tags / categories: labels (free-form), components (per-project), categories (per-issue-type).
- Status workflows: per-project, configurable transitions, screens, validators. Status is *not* simple open/closed.
- Sprints: time-boxed (Software).
- Search: JQL (Jira Query Language) — extremely powerful; effectively the gold standard.
- Bulk: REST allows up to 1,000 issues/call.
- Comments / mentions / notifications: full @mention; notifications; watchers.
- Audit log: full per-issue history; per-instance audit log on paid tiers.
- Webhook: full event surface.
- Project board / Kanban: yes.

**API:** REST primary ([Jira Cloud REST API v3](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)); GraphQL via Compass; auth via API token (Cloud) or OAuth 2.0; rate limits per tenant (variable).
**CLI:** Multiple community CLIs — [`ankitpokhrel/jira-cli`](https://github.com/ankitpokhrel/jira-cli) (feature-rich interactive), [`go-jira/jira`](https://github.com/go-jira/jira) (1.5K stars). No first-party CLI.
**MCP:** Atlassian ships an **official remote MCP server** for Jira; multiple community servers including [`sooperset/mcp-atlassian`](https://github.com/sooperset/mcp-atlassian).
**Abstraction implications:** **Adds the largest single complication to the smallest abstraction surface.** JQL semantics, custom-field richness, per-project workflows, and the 3-level free-tier hierarchy cap mean any GH-shaped abstraction that uses 4+ hierarchy levels does not run on Jira free. Architect should design around 3-level hierarchy as the floor.

### B.2 Redmine (self-hosted; "free" = no licensing cost)

**Free tier overview:** Free open-source self-hosted; no user/project caps imposed by the software (caps are infrastructure-bounded). Source: [Redmine project page](https://www.redmine.org/).

**Scale fit vs 3× OT:** **PASS** (infrastructure-bounded; 3× OT is trivial for a default Redmine install).

**Capabilities:**
- Hierarchy: parent / sub-task; effectively unlimited depth (constrained by performance, not config).
- Dependencies: relations between issues (`relates`, `duplicates`, `blocks`, `precedes`, `follows`, `copied_to`). Source: [REST API](https://www.redmine.org/projects/redmine/wiki/rest_api).
- Templates / custom fields: rich custom-field system; per-tracker required-field config.
- Labels / tags: categories per-project, tags via plugin.
- Status workflows: per-tracker, configurable transitions.
- Sprints: not native; via Agile plugin (third-party).
- Search: full-text + filtered REST queries.
- Bulk: REST supports per-issue updates; bulk via UI.
- Comments / mentions / notifications: yes; @mention via plugin.
- Audit log: full per-issue journal.
- Webhook: via plugin (`redmine_webhook`).
- API rate limits: default 100 items/page (configurable). Source: [Redmine #16069](https://www.redmine.org/issues/16069).

**API:** REST + JSON/XML; auth via API key. SDK ecosystem exists (Ruby, Python, Java).
**CLI:** Community: `redmine-cli` (Python), various Ruby gems.
**MCP:** Multiple community servers — [`runekaagaard/mcp-redmine`](https://github.com/runekaagaard/mcp-redmine) (~100% API coverage), [`yonaka15/mcp-server-redmine`](https://github.com/yonaka15/mcp-server-redmine), [`zacharyelston/redmine-mcp-server`](https://github.com/zacharyelston/redmine-mcp-server) (production-ready, 2026-02-14 release). Active community.
**Abstraction implications:** Fits the smallest surface easily. Plugin-richness varies per install — abstraction must not assume any optional plugin (sprints, webhooks) is enabled.

### B.3 Bugzilla (self-hosted; "free" = no licensing cost)

**Free tier overview:** Free open-source self-hosted; no caps. Source: [Bugzilla docs](https://www.bugzilla.org/docs/).

**Scale fit vs 3× OT:** **PASS** (infrastructure-bounded).

**Capabilities:**
- Hierarchy: **no native parent/sub-issue concept.** Closest is `blocks` / `depends_on` for tree-like structure. Architect must emulate hierarchy via dependencies.
- Dependencies: `blocks` and `depends_on` first-class typed fields. Source: [Bugzilla REST API](https://bugzilla.readthedocs.io/en/latest/integrating/apis.html).
- Templates / custom fields: custom fields supported; field-level configuration per product.
- Labels / tags: keywords + flags + components; no general "labels".
- Status workflows: configurable per product; resolution + status combined.
- Sprints: none native.
- Search: quicksearch + advanced search; SQL-like via "Custom Search".
- Bulk: REST supports per-bug updates.
- Comments / mentions / notifications: yes; `cc:` list per bug.
- Audit log: full per-bug history.
- Webhook: WebHooks added in 5.x.
- Attachments: first-class with private/public flags.

**API:** REST v1 stable; old XMLRPC + JSONRPC also supported. Auth via API key.
**CLI:** [`LegNeato/bztools`](https://github.com/LegNeato/bztools) (Rust); various Python and npm clients.
**MCP:** Community servers — [`SanthoshSiddegowda/bugzilla-mcp`](https://github.com/SanthoshSiddegowda/bugzilla-mcp) (hosted at https://bugzilla.fastmcp.app/mcp); [`openSUSE/mcp-bugzilla`](https://github.com/openSUSE/mcp-bugzilla).
**Abstraction implications:** **Forces an abstraction that treats hierarchy as optional.** Bugzilla has no parent/child native model — the abstraction must either emulate via dependencies or expose a capability flag the backend can set to "hierarchy: none". Bugzilla's keyword/flag/component split means "labels" must be an aggregate concept.

### B.4 OpenProject (Community Edition — self-hosted free)

**Free tier overview:** Community Edition is **fully free with unlimited users and unlimited projects**, self-hosted via Docker or Linux package. Source: [OpenProject Community Edition](https://www.openproject.org/community-edition/) (multiple sources confirm "unlimited users and projects, free forever").

**Scale fit vs 3× OT:** **PASS** (infrastructure-bounded).

**Capabilities:**
- Hierarchy: work packages support parent/child trees; no documented depth cap.
- Dependencies: relations between work packages (`follows`, `precedes`, `relates`, `duplicates`, `blocks`, `partof`, etc.).
- Templates / custom fields: per-project custom fields; required-field config.
- Labels / tags: categories per-project; types (issue type analog).
- Status workflows: per-type, configurable.
- Sprints / cycles: backlogs + sprint planning module included.
- Search: filtered queries; saved queries.
- Bulk: UI bulk select; API per-call.
- Comments / mentions / notifications: full.
- Audit log: full activity stream.
- Webhook: yes; native event subscription.
- Project board / Kanban: yes (boards module).

**API:** Hypermedia REST (HATEOAS) at `/api/v3/`; BCF API for BIM; auth via API key. Source: [OpenProject API docs](https://www.openproject.org/docs/api/).
**CLI:** No first-party CLI; community Python/Node clients exist.
**MCP:** Community MCP servers exist but maturity varies (per [TensorBlock awesome-mcp-servers](https://github.com/TensorBlock/awesome-mcp-servers)).
**Abstraction implications:** Best free-tier fit for a GH-shaped abstraction — hierarchy, dependencies, custom fields, sprints, webhooks all native. The HATEOAS REST surface is heavier than GH's, so the abstraction must not assume "shallow REST".

### B.5 YouTrack (JetBrains InCloud Free or self-hosted free up to N users)

**Free tier overview:** InCloud free for up to **10 users + 3 helpdesk agents**, **30 GB storage**, full functionality (private projects included; only difference vs paid is custom logos). Source: [YouTrack 2020 free announcement](https://blog.jetbrains.com/youtrack/2020/05/youtrack-is-now-free-for-10/).

**Scale fit vs 3× OT:** **PASS** on issues (no documented cap), users (10 ≥ 4-seat realistic need), storage (30 GB vs 1.5 MB).

**Capabilities:**
- Hierarchy: subtasks via issue-link "subtask of" / "parent for"; multi-level supported.
- Dependencies: typed issue links (`relates`, `depends`, `duplicates`, etc.).
- Templates / custom fields: rich custom-field system; per-project configuration.
- Labels / tags: tags (workspace-scoped).
- Status workflows: per-project, fully configurable.
- Sprints: native sprints in Agile boards.
- Search: YouTrack Query Language (YQL) — very powerful.
- Bulk: command-based bulk updates.
- Comments / mentions / notifications: yes.
- Audit log: per-issue history.
- Webhook: yes; rich event surface.
- AI assistance: included in free tier.

**API:** REST at `/api/`; **starting from 2026.1**, includes user/group/org/role endpoints previously Hub-only. Source: [YouTrack REST API docs 2026](https://www.jetbrains.com/help/youtrack/devportal/youtrack-rest-api.html).
**CLI:** No first-party CLI; community npm/Python clients.
**MCP:** Community servers (`RageAgainstTheMachine101/mcp-youtrack`); no official JetBrains server as of 2026-05-03.
**Abstraction implications:** Fits the smallest surface well; YQL is its own abstraction-edge concern (cannot literally translate `is:open label:bug` to YQL).

### B.6 Shortcut (free tier)

**Free tier overview:** **Free for teams up to 10 users.** Stories, Epics, Iterations, full API + webhooks. Source: [Shortcut REST API v3](https://developer.shortcut.com/api/rest/v3); [Shortcut webhooks](https://developer.shortcut.com/api/webhook/v1).

**Scale fit vs 3× OT:** **PASS.** No documented issue cap; 10 users covers realistic need.

**Capabilities:**
- Hierarchy: Stories belong to Epics (one level above); within a Story, Tasks are 1-level deep checklists (not separate stories). **Effective hierarchy: 2 levels** (Epic → Story; Tasks are atomic).
- Dependencies: Story relationships (`blocks`, `duplicates`, `relates`).
- Templates / custom fields: limited custom fields on free.
- Labels / tags: labels.
- Status workflows: Workflow States per Workflow per Team.
- Sprints / cycles: Iterations.
- Search: Stories search API.
- Bulk: API supports batch operations.
- Comments / mentions / notifications: yes.
- Audit log: per-story history.
- Webhook: yes; covers stories + epics + comments + state changes + VCS-driven events.
- Project board / Kanban: yes.

**API:** REST v3; auth via API token.
**CLI:** No first-party CLI; [`useshortcut/api-cookbook`](https://github.com/useshortcut/api-cookbook) example clients.
**MCP:** Community servers exist; no official.
**Abstraction implications:** **2-level hierarchy is a floor problem.** If the abstraction supports a `parent` chain longer than 2, Shortcut requires emulation (e.g., flat tags representing virtual parents). Tasks-within-Story do not equal sub-issues in any other tracker.

### B.7 Notion (free tier; using Notion as an issue tracker pattern)

**Free tier overview:** **Single-user workspaces are unlimited; multi-member workspaces have a "block limit"** (effectively ~1,000 blocks before the cap kicks in). 7-day page history. 5 MB file uploads. Up to 10 guest collaborators. Source: [Notion pricing](https://www.notion.com/pricing); [Notion block usage](https://www.notion.com/help/understanding-block-usage). API rate limit: ~3 requests/second per integration regardless of plan. Source: [Notion API rate limits](https://developers.notion.com/page/frequently-asked-questions).

**Scale fit vs 3× OT:** **CONDITIONAL.** A single-user workspace handles 3× OT trivially. A multi-member workspace **fails** the block limit: 339 issues × ~10 blocks/issue average = 3,390 blocks, well above the 1,000-block free cap on multi-member workspaces. Architect should treat Notion-as-tracker free tier as "single-user only" for OT-3× scale.

**Capabilities:**
- Hierarchy: nested pages (effectively unlimited depth); database relations.
- Dependencies: relation properties between database rows (untyped or use a "link type" multi-select).
- Templates: page templates per database; required properties config.
- Labels / tags: multi-select properties.
- Status workflows: select / status property; not a transition graph.
- Sprints: not native; emulated via dates/relations.
- Search: full-text + property filters.
- Bulk: API supports batch via parallelism (rate-limited).
- Comments / mentions / notifications: yes; @mentions cross-page.
- Audit log: 7-day page history on free; longer on paid.
- Webhook: API has webhook events (limited).
- Project board / Kanban: native database views (Board, Calendar, Timeline, Table).

**API:** REST at `developers.notion.com`; auth via integration token or OAuth.
**CLI:** Community CLIs; no first-party.
**MCP:** **Official Notion MCP server** at `https://mcp.notion.com/mcp` (Streamable HTTP, OAuth, ~18 tools as of 2026-03-30 per [Notion MCP docs](https://developers.notion.com/guides/mcp/overview); [makenotion/notion-mcp-server](https://github.com/makenotion/notion-mcp-server)).
**Abstraction implications:** Notion's data model (page = block tree; database = table of pages with typed properties) is fundamentally different from issue trackers. Mapping issue-style work to Notion is well-trodden by users but the abstraction needs a Notion-specific adapter that translates `properties` to/from labels/status/assignee. Free-tier block cap on multi-member is the binding constraint.

### B.8 ClickUp (free forever tier)

**Free tier overview:** Perpetual; **5 Spaces**, **100 MB total workspace storage** (shared, not per-user), **100 custom-field uses**, **100 automation uses/month**, **60 Gantt view uses**. **API rate limit: 100 requests/minute/token** on Free, Unlimited, and Business plans. Source: [ClickUp rate limits](https://developer.clickup.com/docs/rate-limits); [ClickUp free plan 2026](https://www.smashingapps.com/clickup-free-plan-in-2026/).

**Scale fit vs 3× OT:** **CONDITIONAL.** Issues (Tasks) are unlimited but the **100 MB total storage** and **100-uses caps on custom fields and automations** are real ceilings. For OT 3× (no large attachments, modest custom-field needs), passes. For any project that uses custom fields heavily on each ticket, the 100-uses cap blocks. Architect should flag ClickUp as "pass at OT scale, but the hidden caps require attention if the design uses custom fields per-ticket."

**Capabilities:**
- Hierarchy: Workspace → Space → Folder → List → Task → Subtask (multi-level).
- Dependencies: typed task dependencies (`waiting on`, `blocking`).
- Templates / custom fields: rich; **100-uses cap on free**.
- Labels / tags: tags (workspace-scoped).
- Status workflows: custom statuses per List or Folder.
- Sprints: Sprints feature (paid generally; free has limited support).
- Search: filter + saved searches.
- Bulk: full bulk operations.
- Comments / mentions / notifications: yes.
- Audit log: activity feed per task.
- Webhook: yes.
- Project board / Kanban: yes (Board, List, Calendar, Gantt with cap, Timeline, etc.).

**API:** REST v2; auth via personal token or OAuth.
**CLI:** No first-party CLI; community npm/Python clients.
**MCP:** Both community ([`v4lheru/clickup-mcp-server`](https://glama.ai/mcp/servers/@v4lheru/clickup-mcp-server)) and **official ClickUp MCP server** that expanded from 6 to ~49 tools per [ChatForest 2026 MCP guide](https://chatforest.com/guides/best-project-management-mcp-servers/).
**Abstraction implications:** Fits the smallest surface. The 100-uses cap on custom fields makes it tricky to use ClickUp custom fields as the primary "TD-NNN identifier" mechanism — labels or task IDs would be safer.

### B.9 Trello (free tier)

**Free tier overview:** Up to **10 boards per Workspace**, **10 collaborators per Workspace**, unlimited cards and lists, **250 Workspace command runs/month** (automation), 10 MB file size cap, custom fields require Standard plan or above (or a free Power-Up replacement). Source: [Trello pricing](https://trello.com/pricing); [Trello workspace limits](https://support.atlassian.com/trello/docs/workspace-user-limit/). API rate limits: **300 req/10 sec per API key, 100 req/10 sec per token**. Source: [Trello API rate limits](https://developer.atlassian.com/cloud/trello/guides/rest-api/rate-limits/).

**Scale fit vs 3× OT:** **CONDITIONAL → FAIL for board-per-phase mappings.** Cards are unlimited (passes 339 issues at scale) but **10 boards per Workspace** is a binding constraint if the abstraction maps phases or categories to boards (OT has 60 phases). One workspace = one board with 339 cards is feasible; multiple workspaces would be needed if a board-per-phase mapping is wanted. Architect should treat Trello as "cards-on-one-board only at 3× OT scale."

**Capabilities:**
- Hierarchy: cards have **checklists** (1-level subtasks, not separate cards) and **sub-cards** via specific Power-Ups (not native). Effective hierarchy: 1 level (or "0 if checklists do not count").
- Dependencies: **Card Dependencies Power-Up** (free; community-built) — typed `blocks` / `blocked-by` across boards. Source: [Card Dependencies by Screenful](https://screenful.com/card-dependencies-for-trello).
- Templates: card templates per board.
- Custom fields: **paid on Standard+** OR free via the [Custom Fields Power-Up](https://trello.com/power-ups/56d5e249a98895a9797bebb9/custom-fields) (re-enabled as a built-in).
- Labels / tags: labels (board-scoped, color + text).
- Status workflows: lists are the workflow.
- Sprints: not native; via Power-Up.
- Search: full-text + member/label filter.
- Bulk: limited; UI-driven.
- Comments / mentions / notifications: yes.
- Audit log: per-card activity stream.
- Webhook: yes.
- Project board / Kanban: native.

**API:** REST at `developer.atlassian.com/cloud/trello/`; auth via API key + token or OAuth.
**CLI:** No first-party CLI; community Node/Python clients.
**MCP:** Community MCP servers (less mature than Jira's).
**Abstraction implications:** **The least-fitting tracker for the pack's typed-deferral / hierarchical model.** Native checklist-only hierarchy + 10-board cap + Power-Up-dependent dependencies mean the abstraction needs a heavy Trello adapter. Architect should consider whether Trello is in-scope at all — its cost-to-fit ratio is the worst of the nine.

---

## Summary

**Audit counts:**
- VERIFIED: ~80 claims (the bulk of §1, §2, §3, §4, §5, §9, §10, §11, §12 capability and limit claims).
- VERIFIED-with-qualification: 3 (issue body 65,536 chars actually applies to gzipped wire size; Linear sub-issue depth not capped vs sub-initiative 5-level cap; §5.2 "no first-party GH subagent" is narrowly correct but reads narrower than §12.3 already qualified).
- CORRECTED: 1 — Codex CLI subagent concurrency default is `max_threads = 6`, not 8 ([Codex subagents docs](https://developers.openai.com/codex/subagents)).
- UPDATED: 3 — (a) gh v2.87.1 is unrecommended; v2.87.2 is the recommended pin ([cli/cli releases](https://github.com/cli/cli/releases)); (b) GH MCP server tool count grown since "~162" baseline (treat toolset names as stable, totals as moving); (c) Gemini v0.41.0 stable confirmed for ≤2026-05-06 per v0.42.0-nightly cadence.
- MISSING (added to architect's mental model): 12 — Claude Code skills primitive; Claude Code hooks; Codex plugin/marketplace; Codex permission profiles; Gemini custom slash commands; Gemini extensions; GH issue-lock semantics; GH reactions as a signal; GH saved replies; GH MCP read-only mode; Jira free-tier 3-level hierarchy hard cap; Linear official remote MCP server.
- ASSUMED: 1 (sub-issue tree token-cost estimate in §6.4 is order-of-magnitude only; depends on schema shape).

**Material errors corrected:** 1 — Codex `max_threads = 6` default vs the report's "8 concurrent". Architect impact: pack guidance should re-peg to "default 6, ceiling configurable; 3–5 is the practical sweet spot."

**Material gaps surfaced (top 3):**
1. **Jira free tier is locked at 3 hierarchy levels** (Epic → Story → Sub-task) and **cannot insert intermediate levels even on Premium**. Any pack abstraction that defaults to 4+ hierarchy levels will not work on Jira at the most-restrictive supported tier. Source: [Atlassian community 3091938](https://community.atlassian.com/forums/Jira-questions/How-to-set-up-hierarchy-with-Epic-Story-Feature-Task-Sub-task-in/qaq-p/3091938).
2. **Linear has an official remote MCP server** at `https://mcp.linear.app/mcp` with OAuth 2.1 — peer of GitHub MCP server, not a "GraphQL-only" backend that requires bespoke wiring. Materially shifts the abstraction calculus. Source: [Linear MCP docs](https://linear.app/docs/mcp).
3. **GH issue body 65,536-char cap is on the gzipped wire size, not raw chars.** Repeatable-text content compresses well, so practical fit is much larger than 65 KB. Architect should not over-design splitter logic on a 65,536-byte assumption.

**Upside features the architect should consider** (17 documented in A.10): @mention notifications, assignees/watchers, reactions as lightweight voting, linked-PR auto-close on merge, full audit log of state changes, cross-repo issue linking, Projects v2 board automations, sub-issue completion percentage, UI bulk operations, time-since-last-update / staleness signals, issue forms with auto-routing labels, cross-tracker linking, issue duplicate detection at create time, structured input validation, native dependency graph rendering, issue events webhooks, and the agent ergonomics of MCP-driven scoped queries vs full-file reads.

**Trackers passing 3× OT scale fit:**
- **PASS unconditionally:** Jira (Atlassian Free) — *with the 3-level hierarchy caveat*; Redmine; Bugzilla — *with the no-native-hierarchy caveat*; OpenProject Community; YouTrack Free (10 users); Shortcut (10 users) — *with the 2-level hierarchy caveat*.
- **PASS conditionally:** ClickUp (passes core but 100-uses caps on custom fields/automations and 100 MB total storage are tight); Notion (passes only as single-user workspace; multi-member free fails the block cap at 3× OT).
- **CONDITIONAL → FAIL on multi-board mappings:** Trello (10-board cap binds if the design maps phases to boards; cards-only mapping passes).

**Net effect on architect's design space:**
1. The smallest abstraction surface (§8.5) still holds at the operation-name level, but needs three additions: (a) per-backend capability flags for hierarchy / dependencies / labels / sprints; (b) `link.kind` as an open string with reserved values rather than a closed enum; (c) explicit "depth ceiling" capability so Bugzilla / Trello / Shortcut can flag "1-level" or "no-hierarchy" without forcing emulation.
2. The "delegate to subagent" pattern *now* ports across all three CLIs (per §12.2 already-correction); the asymmetry is in *config format* (Claude `.claude/agents/<name>.md` vs Codex `~/.codex/agents/<name>.toml` vs Gemini built-ins or `commands/<name>.toml`), not *availability*.
3. The pack's flat-file BACKLOG.md system does not exploit ~17 modern-tracker capabilities. Adopting any tracker — even partially — opens a large surface of new affordances.
4. Jira free's 3-level hierarchy cap is the single most-binding cross-tracker constraint. Designing to GH's 8-deep / 100-wide is unsafe at the bottom; designing to Jira free's 3 levels is the safest floor.

---

## Sources

Sources are inline above as markdown hyperlinks. Selected consolidated list:

- [Adding sub-issues — GitHub Docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues)
- [Sub-issues Public Preview discussion #139932](https://github.com/orgs/community/discussions/139932)
- [Evolving GitHub Issues and Projects (GA) #154148](https://github.com/orgs/community/discussions/154148)
- [Dependencies on issues changelog](https://github.blog/changelog/2025-08-21-dependencies-on-issues/)
- [Closing keywords](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/using-keywords-in-issues-and-pull-requests)
- [Issue type field](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-the-issue-type-field)
- [Projects API](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
- [REST search](https://docs.github.com/en/rest/search/search)
- [Body length discussion #41331](https://github.com/orgs/community/discussions/41331)
- [Renovate body-too-long #14551](https://github.com/renovatebot/renovate/issues/14551)
- [Rate limits REST](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)
- [Locking conversations](https://docs.github.com/en/communities/moderating-comments-and-conversations/locking-conversations)
- [REST reactions](https://docs.github.com/en/rest/reactions/reactions)
- [REST issue events](https://docs.github.com/en/rest/issues/events)
- [Configuring autolinks](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/configuring-autolinks-to-reference-external-resources)
- [gh issue manual](https://cli.github.com/manual/gh_issue)
- [cli/cli #10298](https://github.com/cli/cli/issues/10298)
- [cli/cli #12477](https://github.com/cli/cli/issues/12477)
- [cli/cli releases](https://github.com/cli/cli/releases)
- [github/github-mcp-server](https://github.com/github/github-mcp-server)
- [Configuring toolsets](https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/configure-toolsets)
- [Add sub-issue tool #196](https://github.com/github/github-mcp-server/issues/196)
- [Remote MCP changelog](https://github.blog/changelog/2025-06-12-remote-github-mcp-server-is-now-available-in-public-preview/)
- [GH MCP changelog 2026-01-28](https://github.blog/changelog/2026-01-28-github-mcp-server-new-projects-tools-oauth-scope-filtering-and-new-features/)
- [Claude Code MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp)
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Claude Code hooks](https://code.claude.com/docs/en/hooks)
- [Claude Code releases](https://github.com/anthropics/claude-code/releases)
- [Claude Code changelog](https://code.claude.com/docs/en/changelog)
- [Codex MCP](https://developers.openai.com/codex/mcp)
- [Codex subagents](https://developers.openai.com/codex/subagents)
- [Codex CLI](https://developers.openai.com/codex/cli)
- [Codex changelog](https://developers.openai.com/codex/changelog)
- [Codex config reference](https://developers.openai.com/codex/config-reference)
- [openai/codex releases](https://github.com/openai/codex/releases)
- [Codex subagents GA — digitalapplied](https://www.digitalapplied.com/blog/codex-subagents-ga-multi-agent-autonomous-coding-guide)
- [Simon Willison on Codex subagents 2026-03-16](https://simonwillison.net/2026/Mar/16/codex-subagents/)
- [Daniel Vaughan parallel orchestration](https://codex.danielvaughan.com/2026/04/18/running-multiple-codex-agents-parallel-orchestration/)
- [Gemini CLI tools](https://google-gemini.github.io/gemini-cli/docs/tools/)
- [Gemini CLI shell tool](https://google-gemini.github.io/gemini-cli/docs/tools/shell.html)
- [Gemini CLI subagents](https://geminicli.com/docs/core/subagents/)
- [Gemini CLI MCP](https://geminicli.com/docs/tools/mcp-server/)
- [Gemini v0.40.0 changelog](https://geminicli.com/docs/changelogs/latest/)
- [Gemini v0.41.0-preview](https://geminicli.com/docs/changelogs/preview/)
- [Gemini extensions](https://geminicli.com/docs/extensions/)
- [Gemini v0.42.0-nightly](https://newreleases.io/project/github/google-gemini/gemini-cli/release/v0.42.0-nightly.20260429.g6d9911393)
- [GitHub MCP install-codex](https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-codex.md)
- [GitHub MCP install-gemini-cli](https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-gemini-cli.md)
- [Linear API getting started](https://linear.app/developers/graphql)
- [Linear parent and sub-issues](https://linear.app/docs/parent-and-sub-issues)
- [Linear sub-initiatives](https://linear.app/docs/sub-initiatives)
- [Linear MCP docs](https://linear.app/docs/mcp)
- [Linear MCP changelog 2026-02-05](https://linear.app/changelog/2026-02-05-linear-mcp-for-product-management)
- [Jira Cloud REST API v3](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
- [Atlassian community 2360971 — Jira free limits](https://community.atlassian.com/forums/Jira-Cloud-Admins-discussions/What-are-the-limitations-of-JIRA-free-account/td-p/2360971)
- [Atlassian community 3091938 — Jira hierarchy](https://community.atlassian.com/forums/Jira-questions/How-to-set-up-hierarchy-with-Epic-Story-Feature-Task-Sub-task-in/qaq-p/3091938)
- [Atlassian Jira hierarchy config](https://support.atlassian.com/jira-cloud-administration/docs/configure-the-issue-type-hierarchy/)
- [Jira plans](https://support.atlassian.com/jira-cloud-administration/docs/explore-jira-cloud-plans/)
- [Atlassian data limits](https://support.atlassian.com/jira-cloud-administration/docs/data-limits-and-guardrails/)
- [Epic deprecation notice](https://community.developer.atlassian.com/t/deprecation-of-the-epic-link-parent-link-and-other-related-fields-in-rest-apis-and-webhooks/54048)
- [ankitpokhrel/jira-cli](https://github.com/ankitpokhrel/jira-cli)
- [go-jira/jira](https://github.com/go-jira/jira)
- [sooperset/mcp-atlassian](https://github.com/sooperset/mcp-atlassian)
- [Redmine REST API](https://www.redmine.org/projects/redmine/wiki/rest_api)
- [Redmine #16069 API limits](https://www.redmine.org/issues/16069)
- [runekaagaard/mcp-redmine](https://github.com/runekaagaard/mcp-redmine)
- [yonaka15/mcp-server-redmine](https://github.com/yonaka15/mcp-server-redmine)
- [zacharyelston/redmine-mcp-server](https://github.com/zacharyelston/redmine-mcp-server)
- [Bugzilla REST API](https://bugzilla.readthedocs.io/en/latest/integrating/apis.html)
- [Bugzilla docs](https://www.bugzilla.org/docs/)
- [SanthoshSiddegowda/bugzilla-mcp](https://github.com/SanthoshSiddegowda/bugzilla-mcp)
- [openSUSE/mcp-bugzilla](https://github.com/openSUSE/mcp-bugzilla)
- [LegNeato/bztools](https://github.com/LegNeato/bztools)
- [OpenProject Community Edition](https://www.openproject.org/community-edition/)
- [OpenProject pricing](https://www.openproject.org/pricing/)
- [opf/openproject](https://github.com/opf/openproject)
- [YouTrack 2020 free announcement](https://blog.jetbrains.com/youtrack/2020/05/youtrack-is-now-free-for-10/)
- [YouTrack REST API docs 2026](https://www.jetbrains.com/help/youtrack/devportal/youtrack-rest-api.html)
- [YouTrack subtasks](https://www.jetbrains.com/help/youtrack/devportal/Workflow-Subtasks.html)
- [Shortcut REST API v3](https://developer.shortcut.com/api/rest/v3)
- [Shortcut webhooks](https://developer.shortcut.com/api/webhook/v1)
- [useshortcut/api-cookbook](https://github.com/useshortcut/api-cookbook)
- [Notion pricing](https://www.notion.com/pricing)
- [Notion block usage](https://www.notion.com/help/understanding-block-usage)
- [Notion API rate limits](https://developers.notion.com/page/frequently-asked-questions)
- [Notion MCP docs](https://developers.notion.com/guides/mcp/overview)
- [makenotion/notion-mcp-server](https://github.com/makenotion/notion-mcp-server)
- [ClickUp rate limits](https://developer.clickup.com/docs/rate-limits)
- [ClickUp free plan 2026](https://www.smashingapps.com/clickup-free-plan-in-2026/)
- [Trello pricing](https://trello.com/pricing)
- [Trello workspace limits](https://support.atlassian.com/trello/docs/workspace-user-limit/)
- [Trello API rate limits](https://developer.atlassian.com/cloud/trello/guides/rest-api/rate-limits/)
- [Card Dependencies Power-Up](https://screenful.com/card-dependencies-for-trello)
- [Trello Custom Fields Power-Up](https://trello.com/power-ups/56d5e249a98895a9797bebb9/custom-fields)
- [TensorBlock awesome-mcp-servers](https://github.com/TensorBlock/awesome-mcp-servers)
- [ChatForest 2026 PM MCP guide](https://chatforest.com/guides/best-project-management-mcp-servers/)
