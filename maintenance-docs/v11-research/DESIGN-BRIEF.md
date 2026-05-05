# v11 Design Brief — Optional Issue-Tracker Integration

**Status.** Living scoping doc. Updated as understanding refines — open questions
resolve into decisions; surfaces clarify; constraints are added or relaxed
based on architect findings.

**Owner.** Pack maintainer (David H. Shane / Optiquity, Inc.).

**Date.** 2026-05-04. Initial version.

**Companion files in this directory:**
- `EXTERNAL-RESEARCH.md` — capabilities of GH Issues, gh CLI, GH MCP, Codex CLI, Gemini CLI, Linear, Jira, prior art.
- `INTERNAL-INVENTORY.md` — every flat-file work-tracking surface in pack and project, with format rules and OT comparison.
- `RESEARCH-AUDIT.md` — verification of external claims + 9 additional trackers (Jira, Redmine, Bugzilla, OpenProject, YouTrack, Shortcut, Notion, ClickUp, Trello) + upside features.

This brief is the contract the pack-architect designs against. **It does not propose solutions** — only problem, goals, success criteria, surface scope, constraints, open questions, and confirmed decisions.

---

## 1. Out of scope (hard exclusions, not subject to architect debate)

- **Desktop / Web PM chat surfaces.** v11 issue-tracker integration applies only to CLI-driven Pack Chat and PM Chat workflows. Desktop and Web users continue with flat-file workflows. Documented as such.
- **`/install-github-app` (Claude Code-only GitHub Actions integration).** Optional; explicitly deferred. May be in scope for a later minor release.
- **Forced migration.** Existing v10 projects on flat files are not required to opt in. Default remains flat files.
- **Required tracker.** No tracker is mandated; users may continue using flat files indefinitely.
- **Backward compatibility for v10 non-opt-ins (moot).** OT is the only existing v10 project; it migrates to v11 + GH Issues. All future projects start on v11. There is no "v10 project that pulls v11 pack updates but never opts in" case to design for.

---

## 2. Problems being solved

### 2.1 Shared (both pack repo and client projects)

- Flat-file dependency tracking decays over time. Entries fall out of sync; status is often wrong; dependencies are hard to enforce.
- The chat session bears the burden of maintaining cross-file consistency. The data store does not enforce it.
- Templates are inconsistent or sparse. Sorting/filtering is limited. Per-project anti-patterns develop.
- Reading whole flat files into chat context to reason about a single item is token-heavy.
- No native dependency graph, filtering, sorting, or first-class history.
- Multi-machine workflows depend on git push/pull as the only state-sync mechanism for work-tracking state.

### 2.2 Pack-repo–specific

- BD-NNN backlog spans across major versions (v8 → v9 → v10 → v11). Resolved-vs-active distinction is convention-only, not data-modeled.
- BD blockers / unblocks are free-form fields requiring manual updates in two places.
- External users cannot file issues against the pack today (no tracker present in the repo). The pack will be public soon; this becomes a real gap.

### 2.3 Client-project–specific

- TD-NNN entries reference phase-N, but phases live in `IMPLEMENTATION_PLAN.md`, which the chat reads in full to reason about phase-tied state.
- `STATUS.md` → `IMPLEMENTATION_PLAN.md` anchor links are programmatically constructed and break silently if a phase title text changes.
- `TD-TBD` code comments are author-time placeholders; the pack expects PM Chat to assign real TD-NNN numbers, but the assignment is manual and easy to miss.
- `PACK-FEEDBACK.md` is a per-project flat file recording defects to convey upstream — but there is no automated upstream channel today.

---

## 3. Goals

### 3.1 Shared

- Make a tracker integration available **as an option** without breaking the flat-file default.
- The tracker (when enabled) takes over consistency-enforcement duty: dependency graphs, status transitions, schema validation. The chat orchestrates; the tracker is the system of record.
- Standardize entry templates so migration in either direction (forward to tracker; reverse to flat files) is clean.
- Architecture must allow other trackers (Linear, Jira, Redmine, OpenProject, etc.) to be added without redesign of the core. GH Issues ships first.
- All three CLIs (Claude Code, Codex CLI, Gemini CLI) work identically at the **lowest common denominator**. Per-CLI tuning is allowed where one CLI offers more capability, but the LCD must always work for users without all tools installed. Documented in `DEPENDENCIES.md`.
- Pack Chat (pack repo) and PM Chat (client projects) are the only writers when the tracker is enabled. Agents read only. External humans filing issues through GitHub UI / `gh` directly are not "pack actors" and the rule does not bind them; the chat triages those externally-filed issues as first-class items.
- One-time idempotent migration when opting in. **Reverse migration is mandatory**, not optional.
- Issue templates support effective tracking, sorting, filtering, and dependency representation.
- Felt experience is smooth and seamless in workflows.
- Token saving is observed (measurable improvement) but is **a side effect, not a design driver**. Loading more context to make better decisions is allowed.
- Failures (network unavailable / rate limit / auth expired / API reshape / pack misroute) all surface clear actionable messages to the user; the pack does not silently retry or paper over.
- Each CLI is researched separately for the best mechanism it supports. The bundle-of-three is documented in `DEPENDENCIES.md` and in `OPTIONAL-FEATURES.md`.
- Every tracker-managed entry carries a **`template_version`** field identifying which version of the entry template was used at creation. The field enables intelligent template upgrades when the pack ships new template versions; entries on old templates can be deterministically translated to current templates. Old template versions remain available for translation reference.

### 3.2 Pack-repo

- Pack Chat orchestrates the pack-development tracker (BD-NNN equivalents).
- Pack Chat maintains derived flat-file artifacts (CHANGELOG entries, README version table) from tracker state where applicable.
- External users can file issues against the pack repo with well-formed templates that the pack-side workflow knows how to triage.
- `PACK-FEEDBACK` from client projects can land directly as issues against the pack repo (with manual fallback for users without auth/tools).

### 3.3 Client-project

- PM Chat orchestrates the project tracker (TD-NNN equivalents).
- PM Chat maintains `STATUS.md` and `CHANGELOG.md` from tracker state where applicable.
- The TD-TBD code-comment workflow continues to work — assignment to a real tracker ID happens via the chat.
- `IMPLEMENTATION_PLAN.md` continues to define phases; phase-N references in tracker entries continue to resolve.
- A project can opt into a tracker independently of whether the pack itself is on a tracker (no coupling).

### 3.4 Priorities and heuristics

The priorities below are ranked. The architect designs to satisfy them alongside §3.1–§3.3 goals; conflicts resolve in favor of the priority unless §6 constraints force otherwise. Each priority is concrete enough to be testable.

**P1 — Entry lifecycle completeness.** Every entry type (BD, TD, phase epic, pack-feedback, external bug/feature, plus any new types V2 introduces) has an explicit state machine: states, allowed transitions, what each transition requires (comment, label change, assignee, link), who or what triggers it. Includes:

- Triage lifecycle (when does `needs-triage` get removed and by whom?)
- Re-labeling cadence (when does `status:open` become `status:unblocked` — manual chat action only, or signal-driven?)
- Comment-type conventions (do tracker comments carry structured prefixes — `Resolution:`, `Decision:`, `Review:` — so reverse migration round-trips cleanly?)
- Duplicate detection workflow (how does the chat detect duplicates at create time? See audit §A.10 upside-feature)
- Deprecation vs cancellation distinction (when does each apply? Does deprecation require a successor link?)
- Explicit deletion stance (forbidden, restricted, allowed-with-audit-trail?)
- Assignee workflow (default unassigned? Self-assigned by chat? Auto-assigned for agent-run issues?)

**P2 — Maintenance ergonomics.** Templates, labels, capability flags, and ID mappings stay current as the pack evolves over major and minor versions. The user knows when artifacts are stale and how to refresh:

- A documented mechanism propagates v11.x → v11.y → v12 template/label changes to opted-in projects.
- A `pack tracker update` (or equivalent) verb upgrades stale templates.
- The pack tells the user when their templates are out of date relative to the pack version (proactive surfacing, not just reactive `doctor`).
- Cadence is specified: what changes are automatic vs require user opt-in is explicit.
- The `template_version` field per entry (§3.1) is the foundation: deterministic per-entry translation when templates evolve.
- Old template versions remain accessible (for translation reference) in `maintenance-docs/v11-research/templates-archive/<version>/` or equivalent.

**P3 — Backend extensibility ergonomics.** Adding a new tracker backend has a documented contract that a contributor can follow without architect intervention:

- Where the backend implementation lives (e.g., `scripts/tracker-providers/<name>.sh` or equivalent).
- What interface methods are required (operation set from §2 of `ARCHITECTURE.md`).
- A conformance test suite that verifies a candidate backend implements the abstraction correctly.
- A sample reference backend (the GH backend documented in §2.7 serves; `ARCHITECTURE-V2.md` may add a sample second backend).
- Tier-of-support rules (first-class vs experimental vs community-maintained) and what graduation between tiers requires.
- The new backend should not require trinity changes or core abstraction changes — only the provider implementation + capability declaration.

**P4 — Auditability.** Every chat-side write produces a traceable audit trail:

- Chat-session id (or surrogate; not necessarily a long-lived ID), timestamp, intent, before/after state.
- Tracker backends provide this naturally via issue events; the design surfaces it in chat workflows ("what changed yesterday?", "show audit for TD-031").
- Flat-file mode falls back to git log; the chat resolves audit queries via `git log` + content diff.
- Audit data is queryable, not just available — provider exposes a read pattern for it.

**P5 — Cognitive load floor.** Chat user vocabulary stays bounded. The full set of tracker-related verbs the user must learn is exhaustively listed in v11 docs; no surprise verbs surface during normal use:

- Required new verbs (e.g., `pack tracker init`, `pack tracker disable`, `pack tracker doctor`, `pack tracker status`, `pack tracker update`) are exhaustively listed in user-facing docs.
- Colloquial chat phrasing is supported as an alternative ("set up the tracker", "switch back to flat files", "check tracker health"). The mapping from phrase to command is documented.
- New concepts beyond what v10 already requires must be justified by clear user value, not architectural elegance. The architect calls out any new concept that crosses this bar.

**P6 — Discoverability and proactive guidance.** A new user finds tracker commands AND all other pack functionality without reading external documentation, AND the chat (Pack Chat / PM Chat) proactively surfaces tracker mode as a good fit when project state warrants it. The full discoverability surface includes:

- A help-command path (`/help`, `pack help`, or namespaced `/pack-help` — the exact mechanism is OQ-20) surfaces the full pack verb set.
- The chat answers naturally to colloquial forms ("how do I switch to GH Issues?", "set up the tracker", "validate my setup").
- Errors recommend the next-step verb so the user learns commands as they need them.
- The chat **proactively recommends opting into a tracker when scale signals indicate it would be a good fit** (entry count, BACKLOG token cost, query-miss rate, etc.). Specific signals, thresholds, and recommendation message shape are architect decisions per OQ-19.
- Recommendations are **refusal-respecting**: after the user declines, the chat does NOT re-recommend in the same chat session. Persistent refusal ("don't ask me about this again") silences future recommendations indefinitely until the user explicitly opts back in ("remind me about the tracker again"). The chat distinguishes between "not now" (per-session) and "never" (persistent).
- **Help functionality coexists with external documentation** (QUICKSTART.md, OPTIONAL-FEATURES.md, INSTALL-PROCEDURES.md, etc.) — it does not replace them. External docs cover broader context, examples, rationale, and walk-throughs; help functionality covers verb discovery and quick reference. Both must be maintained as v11 ships and as the pack evolves.
- Onboarding cost is bounded: a user who has never seen v11 can opt into the tracker within 5 minutes of starting a chat session.
- The discoverability surface works in **both** pack repo and client repos, with content appropriate to each surface (pack-maintainer commands vs project-user commands are different sets).

---

## 4. Success criteria

### 4.1 Shared

- A user opts in with one config decision. Migration runs idempotently. No behavior regression for the chat workflow.
- Default-flat-file users see **no change** in their workflow.
- After opt-in, common queries (open items, blocked items, by phase, by area) cost measurably less in tokens than the flat-file equivalent.
- Reverse migration produces well-formed flat files the chat can keep operating from.
- All three CLIs work identically at the LCD. Failure modes (network/rate-limit/auth/API-reshape/misroute) surface clear actionable messages with diagnostic context. The pack does not retry silently or paper over.
- Architecture supports adding another tracker (Linear, Jira, Redmine, OpenProject, etc.) without redesigning the core surface. The smallest-common-cross-tracker surface is identified and documented.
- The chat proactively recommends tracker opt-in at most once per session, surfacing the recommendation when scale signals (per OQ-19) cross. The recommendation is dismissable per-session AND persistently. After persistent dismissal, no further recommendations until the user explicitly re-enables them. Verifiable by integration test.
- The help-command surface (per OQ-20) lists every pack-shipped verb (tracker verbs from V2 §22 PLUS init / migrate / validate / agent-run / any other top-level verbs). Per-surface (pack repo / client repo) help content matches each surface's verb set. Tested by reading help output and matching against the verb manifest.
- External documentation (QUICKSTART.md, OPTIONAL-FEATURES.md, INSTALL-PROCEDURES.md) covers tracker mode, opt-in workflow, and verb reference at a depth appropriate to first-time users. In-chat help functionality covers the verb-list and quick-reference use case. Both are maintained as the pack evolves; both are tested for completeness independently.

### 4.2 Pack-repo

- Pack adoption (eating own dog food) ships first.
- Pack-repo tracker integration is independently usable. A client project on flat files works against a pack on tracker, and vice versa, with no coupling.
- External pack defects observed by a project user can be filed upstream with one chat command (with manual fallback if auth/tools are unavailable on the user's machine).

### 4.3 Client-project

- Client adoption is independently usable on a pack still on flat files.
- A project's tracker choice (GH Issues, Linear, Jira, Redmine, OpenProject, …) does not constrain the pack's tracker choice.

---

## 5. Surface map

### 5.1 Concerns shared by both surfaces

These are the abstractions and requirements that touch both the pack repo and client projects:

- **BACKLOG-shaped item store.** BD-NNN in the pack; TD-NNN in clients. Same `METHODOLOGY.md` Part 7 entry format (`Type:`, `Status:`, `Blockers:`, `Unblocks:`, `File/Symbol:`, `Description:`, `Context:`, `Resolution:`).
- **Chat-as-only-writer rule.** Pack Chat / PM Chat are the only pack-workflow actors that write. Agents read only.
- **Migration script + reverse-migration script.** One-shot idempotent forward; mandatory reverse.
- **Issue templates** with custom fields, labels, dependencies, sort/filter capability.
- **Cross-CLI parity** at the LCD, with per-CLI tuning permitted above the floor.
- **Failure-mode handling** with clear actionable user messages.
- **Token-economy improvement** as a side effect.
- **The trinity `## Document locations` runtime path-resolver** (per `INTERNAL-INVENTORY.md`) — `pm-startup` Step 2 reads state files by *bare name* and uses the trinity table to resolve paths. A tracker integration that moves a file's canonical location must update the trinity in the same atomic change, or every CLI silently mis-locates state.

### 5.2 Pack-repo–specific

- `BD-NNN` namespace (pack development).
- `README.md` version table (today: hand-maintained; possibly: derived from tracker).
- `CHANGELOG.md` (today: hand-maintained pack-version history; possibly: derived).
- `PACK-CHAT.md` (Pack Chat operating instructions; would reference tracker patterns when enabled).
- `PACK-AGENTS.md` (pack agent routing; agents read tracker when enabled).
- Pack-side trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at pack root) — pack-development rules, BD-NNN format mention, optional tracker mention.
- The pack repo as **receiver** of external user issues.
- `pack-startup` skill (reads pack-side state files; expectations would extend to tracker queries when enabled).

### 5.3 Client-project–specific

- `TD-NNN` namespace (project work).
- `STATUS.md` (today: chat-maintained; possibly: derived from tracker).
- `IMPLEMENTATION_PLAN.md` (phase definitions; the tracker links to phase anchors via the existing anchor algorithm).
- `ARCHITECTURE.md` (project architecture; not tracker-managed).
- `CHANGELOG.md` (project release history; possibly derived).
- `PACK-FEEDBACK.md` or upstream-issue mechanism (project as **sender** of upstream defects to pack repo).
- `project-template/docs/pack/PM-CHAT.md` (PM Chat operating instructions; would reference tracker patterns when enabled).
- Project-side trinity templates (`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`).
- `project-template/skills/pm-startup/SKILL.md`.
- `TD-TBD` code-comment workflow + assignment to real TD-NNN numbers.
- Per-agent prompts (`project-template/docs/pack/prompts/*.md`) that reference required-reading flat files; would shift to tracker queries when enabled.

### 5.4 Independence axes (must NOT couple)

- A pack on tracker mode can serve a client on flat-file mode, and vice versa. The two surfaces are independently configurable.
- The pack repo's tracker (e.g., GH Issues at the public optiquity-ai-agent-config-pack repo) is separate from any client project's tracker. Cross-references between trackers are loose (URLs / IDs in fields), not architectural.
- A client project's tracker choice (GH / Linear / Jira / Redmine / OpenProject / Shortcut / YouTrack / ClickUp / Notion / flat) does not constrain the pack's tracker choice.

---

## 6. Constraints from research (architect must respect)

These are findings from `EXTERNAL-RESEARCH.md` and `RESEARCH-AUDIT.md`. They constrain the design space.

### 6.1 Hard limits to design around

- **Jira free tier is locked at 3 hierarchy levels** (Epic → Story → Sub-task) and cannot insert intermediate levels even with Premium. Designing the pack's default to deeper than 3 disqualifies Jira free as a supported backend. **3 levels is the cross-tracker safe floor.**
- **GH Issues sub-issue depth = 8, 100 children/parent, 1 parent/child.** Sub-issue parent-close does not cascade.
- **GH `Blocks` / `Blocked by`** capped at 50 per relationship; same-repo or org-internal only.
- **GH search results capped at 1,000 per query.** REST search rate limit 30/min (vs 5,000/hr core).
- **Trello free workspace caps at 10 boards.** A "board-per-phase" design fails for any project with more than 10 phases (OT has 60 today).
- **Notion free multi-member workspaces cap at ~1,000 blocks.** Multi-user Notion-as-tracker fails 3× OT scale.
- **GH issue body 65,536-char cap is on the gzipped wire size**, not raw chars. Repeatable-text content compresses well; do not over-design splitter logic on a 65 KB raw assumption.

### 6.2 Cross-CLI parity floors

- All three CLIs have native subagent primitives (Codex GA 2026-03-14). The "delegate to subagent" pattern ports across all three; config formats differ (`.claude/agents/<name>.md` vs `~/.codex/agents/<name>.toml` vs Gemini `commands/` + built-ins).
- `gh` CLI is the LCD write mechanism. MCP servers are per-CLI accelerators, not requirements.
- Codex `max_threads` defaults to 6 (sweet spot 3–5).
- Gemini CLI v0.41 stable lands ~2026-05-06 and includes `ContextManager` / `AgentChatHistory` refactor; architect should treat that as a near-term floor.

### 6.3 Tracker abstraction floors

The smallest cross-tracker abstraction surface that supports GH + Linear + Jira + free-tier alternatives requires:

- Operations: `list / get / create / update / close / comment / set_labels / set_assignee / link / sub_issue_create+list+unlink / search`.
- Per-backend **capability flags** (hierarchy/dependencies/labels/sprints supported?). Without these, Bugzilla and Trello force the design into emulation; Shortcut's 2-level hierarchy and Trello's 1-level fail an "always 4-level" assumption.
- `link.kind` as an **open string** with reserved values (`blocks`, `blocked-by`, `related`), not a closed enum.
- Explicit **depth-ceiling capability** so backends can declare "1-level" / "no-hierarchy" / "8-deep" without forcing emulation.
- A **raw-API escape hatch** per backend (every surviving multi-tracker abstraction in the wild offers this).
- **Status / workflow** is the largest mismatch across trackers. GH `state + state_reason` vs Jira's per-project workflows vs OpenProject's per-type configurable transitions vs Trello's "lists are the workflow" — abstraction must let backends declare a custom status taxonomy.

### 6.4 Trackers passing 3× OT scale fit (research-confirmed)

Reference set the architect can target. Not all need first-class implementations; this is the eligibility list.

- **PASS unconditionally:** Jira (Atlassian Free, with 3-level cap caveat); Redmine; Bugzilla (no-native-hierarchy caveat); OpenProject Community; YouTrack Free (10 users); Shortcut (10 users, 2-level hierarchy caveat).
- **PASS conditionally:** ClickUp (100-uses caps on custom fields/automations); Notion (single-user only at 3× OT scale).
- **CONDITIONAL → fail on multi-board mappings:** Trello (10-board cap; cards-only design passes).
- **First class:** GitHub Issues (the v11 ship target).

### 6.5 Naming convention for new artifacts

All new top-level Markdown files in the pack repo follow the existing pack convention: **all-caps with hyphens, `.md` extension** (e.g., `BACKLOG.md`, `PACK-CHAT.md`, `OPTIONAL-FEATURES.md`, `INSTALL-PROCEDURES.md`). Suffixes that distinguish surface or scope are also all-caps (e.g., `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`). Mixed-case suffixes (e.g., `HELP-FRAGMENT-pack.md`) are **non-conforming**; the planner translates any architecture or design-doc reference using mixed case to the all-caps form when implementing.

The disambiguation rule: any two `.md` files in the pack repo (regardless of path) must have different filenames. The same filename may appear in pack-repo and client-project trees because the client tree is downstream of the pack — but within the pack repo's own working tree (including `project-template/`), every `.md` file is uniquely named.

This convention applies to v11 artifacts and any future additions. Pre-v11 files retain their existing names.

---

## 7. Open questions for the architect

These resolve into decisions during architecture. The architect addresses each in `ARCHITECTURE.md` (next phase). Numbering is stable so decisions can reference original question IDs.

- **OQ-1.** Exact shape of the tracker-abstraction interface (operations, return shapes, error model, capability-flag schema).
- **OQ-2.** Where tracker config lives. Pack-side: settings file, env var, both? Client-side: same, or different?
- **OQ-3.** Migration command surface. `pack tracker init` / `pack tracker migrate`? Per-CLI subcommands? LCD shell scripts?
- **OQ-4.** Canonical issue template schema. Fields per BD/TD; required vs optional; auto-routing labels; cross-tracker compatibility of the template shape.
- **OQ-5.** How the chat detects "tracker enabled" vs "flat-file" mode. One config key, file presence, or env var? How is the detection cached / refreshed?
- **OQ-6.** How tracker mode interacts with the trinity `## Document locations` runtime path-resolver. Are tracker queries a new "location" type? Does the trinity table change shape?
- **OQ-7.** Failure-mode UX. Network down → flat-file fallback, or fail-stop with diagnostic? Rate limit hit → backoff or surface? Auth expired → prompt or quit?
- **OQ-8.** Reverse-migration trigger and shape. User command, automatic on opt-out, both? What gets reconstructed (entries, dependencies, comments, status)?
- **OQ-9.** Agent read mechanism. `gh` only (LCD), or per-CLI MCP when available? Same answer for pack repo and client projects?
- **OQ-10.** Auth surface. One auth per machine via `gh auth`; multi-account; PAT vs OAuth; token rotation?
- **OQ-11.** PACK-FEEDBACK upstreaming wiring. Direct issue creation via authenticated `gh`, project-tracker queue with manual hand-off, or both?
- **OQ-12.** Pre-existing-tracker integration. Does the pack interact with a project's existing Linear / Jira if it's already in use, or require its own tracker for pack-managed work? Architect decides; bias toward making this work but acceptable to defer to a minor release if too large.
- **OQ-13.** How the agent-side reads handle the SaaS / customer-visible boundary in the new pack license (LICENSE.md §3.3). Tracker access by an agent operating inside a paid customer-facing service is *use*; the tracker integration design should not accidentally make it *distribution*.
- **OQ-14.** External-issue triage workflow. Pack Chat triages issues filed by anyone with a GH account; what's the agent-readable shape? Auto-routing labels at intake?
- **OQ-15.** Token-economy measurement. How is "token cost reduction" verified post-opt-in (test fixture, measured pre/post, etc.)?
- **OQ-16. Multi-template vs single-template strategy.** `ARCHITECTURE.md` §4 chose six separate `.github/ISSUE_TEMPLATE/*.yml` forms, one per entry type. Defend this explicitly against the alternative — a single template with a type dropdown that drives conditional fields. The defense covers, with real reasoning (not preference): token economy (cost per entry, cost per filter/sort/search query), API and GraphQL behavior (how the choice interacts with the GH Issues API surface and other backends' APIs), search/sort/filter ergonomics (which strategy gives better default and advanced query support), cross-tracker portability (does the choice add or reduce porting work for the next backend?), maintenance ergonomics (P2 — what happens as fields evolve over pack versions?), future enhancements (e.g., new entry types in v12), and user-facing UX (the New Issue dropdown experience). The architect may revise D-4 if the defense leads there.
- **OQ-17. Structure vs free-text line in entry templates.** Defend the chosen split between dropdowns/inputs (structured) and textareas (free text) based on real optimizations and limitations of GH Issues, the cross-tracker abstraction, and the chat workflow: where structure pays rent (label routing, state-machine transitions, search/filter), where structure costs more than it gives (rigidity for fields with no enumerated values, harder migration of free-form data), API/GraphQL implications, migration implications (forward and reverse), and how the choice interacts with capability flags for backends with less or more native structure (Linear's custom fields, Bugzilla's keyword/flag/component split). The architect may revise structure choices from V1 if priorities (especially P1 lifecycle and P2 maintenance) warrant.
- **OQ-18. Where does `template_version` live in each entry type?** Options: a dedicated body field, an HTML comment marker (similar to the `<!-- pack-id: TD-NNN -->` marker in V1 §6.2), a label (`template:bd-v11.0.0`), or a Projects v2 custom field. The choice must: (a) survive forward and reverse migration round-trips; (b) not consume one of the limited 100 labels per issue if labels are precious for other axes; (c) be queryable for `pack tracker update-templates` to find stale entries; (d) apply consistently to all entry types.
- **OQ-19. Inflection-point signals and thresholds.** Per P6, the chat must observe signals and proactively recommend opt-in when thresholds cross. The architect designs:
  - The signal set per surface (pack repo signals may differ from client repo signals — entry count, BACKLOG file size in tokens, query-miss rate, time-since-last-tracker-mention, file-line-count growth, etc.).
  - Where signals are tracked (in-session memory, on-disk state file, derived at every session start, all of the above).
  - Threshold values with rationale tied to research data (e.g., audit §A.5 token-cost crossover at ~50–100 issues; OT scale baseline at 339 entries).
  - Per-session-dismissal vs persistent-refusal mechanism, including how the user re-enables recommendations after persistent refusal.
  - Recommendation surface — what the chat says, how the user accepts / declines / dismisses persistently.

  The architect may revise V2 §23.1's static "Tracker mode: flat-file... to enable issue tracking, say 'set up the tracker'" prompt if dynamic detection makes it redundant or if a hybrid (static at first session, dynamic at threshold crossings) makes more sense.
- **OQ-20. Help-verb scope, naming, and discoverability across surfaces.** V2's §23.2–§23.3 designed `/help` augmentation (per-CLI) plus a `pack help` shell verb, both scoped to tracker only. The architect resolves:
  - **Scope**: extend `pack help` (and any `/help` augmentation) to cover the *entire* pack functionality (init-project, migrate, validate, agent-run, tracker, etc.) — the asymmetry of "only tracker has discoverability" is unjustified.
  - **Naming and pattern**: choose between two patterns, with rigorous defense:
    - **(a) Augment each CLI's native `/help`** with pack content. Must be defended as a documented best practice with citations to each CLI's official docs (Claude Code, Codex CLI, Gemini CLI). If best-practice citations exist across all three, this is the simpler choice.
    - **(b) Namespaced `/pack-help`** (or `/pack` with sub-verbs) that is itself discoverable via the chat's first-session greeting (P6 first-session design). Cleaner separation; one more verb to learn.
    - **The choice depends on whether (a) is a documented best practice across all three CLIs.** If yes, augment. If not, prefer (b).
  - **Per-surface content**: pack repo and client repos each have their own help content. The architect designs the content split, where each version lives, and how the trinity rule applies (since trinity files document available commands).
  - **Self-discoverability**: whichever help name is chosen, the chat's first-session greeting must surface it. The user must not need external docs to find help.

---

## 8. Decisions

(Initially empty. Populated as the architect's decisions are reviewed and approved by the pack maintainer. Each entry: ID, date, decision, rationale, supersedes if any. New decisions reference Open Questions by number where applicable.)

| ID | Date | Decision | Rationale | Resolves |
|---|---|---|---|---|
| _no decisions yet_ | | | | |

---

## 9. Living-doc rules

- This file is updated as the v11 process progresses.
- **Open questions** move from §7 to §8 (Decisions) when the architect proposes and the pack maintainer accepts a resolution.
- **New constraints** surfaced by the architect's design get added to §6.
- **Surface map** (§5) is refined as the architect's abstraction takes shape.
- **Out-of-scope** (§1) is not changed without explicit pack-maintainer approval.
- **Problems / goals / success criteria** (§2 / §3 / §4) are stable inputs and should change rarely. If they change, note the change date and rationale inline.
- The brief is **not** the architecture, the plan, or the implementation. It is the contract those three are checked against.
