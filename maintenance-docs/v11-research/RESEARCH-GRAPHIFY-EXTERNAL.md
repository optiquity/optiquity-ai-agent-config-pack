# RESEARCH-GRAPHIFY-EXTERNAL

External research report on Graphify, the open-source "build a knowledge
graph from a folder" tool. Compiled 2026-05-11 to evaluate it as an
optional component of the Optiquity AI Agent Config Pack.

Primary reference:
`/Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack/How to Use Graphify.txt`
(Ana Bildea, Medium, April 2026).

This report verifies and extends that article against the actual GitHub
repo, PyPI release history, official docs, and independent third-party
reviews. Where the article's claims do not hold up, that is called out
inline with citations.

---

## 1. Current project state

**Repo / owner / license**

- Canonical repo: `safishamsi/graphify` on GitHub
  (https://github.com/safishamsi/graphify). The Ana Bildea article does
  not name the maintainer; the GitHub homepage and PyPI metadata both
  attribute ownership to Safi Shamsi.
- License: MIT (https://github.com/safishamsi/graphify).
- Repo description (verbatim, via `gh api repos/safishamsi/graphify`):
  *"AI coding assistant skill (Claude Code, Codex, OpenCode, Cursor,
  Gemini CLI, and more). Turn any folder of code, SQL schemas, R
  scripts, shell scripts, docs, papers, images, or videos into a
  queryable knowledge graph. App code + database schema + infrastructure
  in one graph."*
- Default branch: `v7` (the repo uses versioned default branches rather
  than `main`).
- Homepage in repo metadata: `https://graphifylabs.ai/` (a commercial
  landing page, see section 9). The marketing site `https://graphify.net/`
  is also active, but is currently 403'd to unauthenticated WebFetch
  from this environment, so quotations from `graphify.net` in this
  report came via search-result snippets, not direct fetches.

**Maturity metrics (snapshot 2026-05-11)**

- Stars: 46,615 (`gh api repos/safishamsi/graphify`).
- Forks: 5,059.
- Open issues: 246 (the GitHub listing API mixed PRs and issues — the
  README WebFetch reported "92 open issues, 154 PRs" separately, which
  is consistent).
- Created: 2026-04-03 — i.e. about five weeks old as of the date of
  this report.
- Last push: 2026-05-11 (same-day as this report).

**PyPI**

- Package name on PyPI is `graphifyy` (double-y), CLI is `graphify`
  (https://pypi.org/project/graphifyy/). The article's installation
  command `pip install graphifyy` is correct.
- Latest version: **0.7.14**, published 2026-05-11
  (https://pypi.org/project/graphifyy/, confirmed via the GitHub
  releases API; the previous release v0.7.13 was 2026-05-09).
- 95 total releases since the project was created in early April —
  averaging ~2 releases per day.
- Python requirement: `>= 3.10`.
- Listed maintainer on PyPI: `captainturbo` (this differs from the
  GitHub owner handle `safishamsi` — appears to be the same author with
  separate PyPI/GitHub identities; nothing in the public record
  suggests a fork or hostile maintainership).
- Note on naming: the third-party Emelia analysis explicitly flags the
  double-y PyPI name as a *"creates confusion and makes the tool harder
  to discover"* problem
  (https://emelia.io/hub/knowledge-graph-graphify-guide). There are
  unrelated PyPI packages named `graphify-leo` and `anytechie-graphify`
  that are **not** this project.

**Issue hygiene / activity signal**

- Issue tracker is actively used. Sampling the 15 most-recently-updated
  open issues on 2026-05-11 (`gh api 'repos/safishamsi/graphify/issues?
  state=open&sort=updated'`) shows feature requests (Clojure, GDScript,
  Pascal/Lazarus support, HCL/Terraform), real bug reports
  (Ollama backend silent-empty, Codex sandbox chunk writes), and a
  number of public PRs from third-party contributors.
- Issue #580 *"Graphify not improving token efficiency in Claude Code
  sessions"* (https://github.com/safishamsi/graphify/issues/580) is open
  with no maintainer reply — independent users reporting the opposite
  of the marketing claim. Discussed in section 5.

**Verdict on "alive in 2026"**

Strongly alive. The project is barely six weeks old as of this report,
has 14 minor releases in five weeks, ~46k stars, and same-day commit
activity. The risk is *youth*, not stalemate: the article's framing
suggests a mature tool, but Graphify is closer to an early-traction
open-source project that is still finding its API surface. Multiple
independent reviewers (Kevin Kinnett, Emelia, Exchangepedia) flag
"early-tool" maturity issues that are real today.

---

## 2. Architecture facts

This section walks each architectural claim from the Bildea article and
marks it Confirmed / Partly confirmed / Updated.

**Three-pass pipeline.** Confirmed, with one numerical update.

- The article says three passes; the official `docs/how-it-works.md`
  on the `v7` branch matches exactly: Pass 1 deterministic tree-sitter
  parsing, Pass 2 local faster-whisper transcription for audio/video,
  Pass 3 parallel LLM extraction via the host coding-CLI's subagents
  (https://github.com/safishamsi/graphify/blob/v7/docs/how-it-works.md).
- Update: the v7 how-it-works document now says tree-sitter parses
  **25 languages** rather than 20 (it lists more — see "languages"
  below). The Bildea article snapshot of "20" was likely accurate at
  v0.3.x and is now out of date.
- Pass 3 is dispatched by the host CLI's parallel-subagent mechanism
  (Claude's `Task` tool / Codex `multi_agent` / Factory Droid `Task`
  tool / Trae `Agent` tool, see translations
  README.zh-CN.md / README.ja-JP.md / README.ko-KR.md). Graphify
  intentionally outsources orchestration; it is "a skill, not a
  standalone orchestrator", which matches the article.

**Provenance labels.** Confirmed.

- `docs/how-it-works.md` confirms three labels: EXTRACTED (confidence
  1.0), INFERRED (discrete confidence buckets 0.95 / 0.85 / 0.75 / 0.65
  / 0.55), AMBIGUOUS (flagged for human review)
  (https://github.com/safishamsi/graphify/blob/v7/docs/how-it-works.md).
- The Bildea article's claim that INFERRED has "confidence <1.0" is
  correct but a coarse summary — the actual scoring is bucketed, not
  continuous.

**Outputs.** Confirmed and extended.

- Bildea article lists: `GRAPH_REPORT.md`, `graph.json`, `graph.html`,
  optional `--obsidian` Vault. All four are confirmed by the README
  (https://github.com/safishamsi/graphify/blob/v7/README.md).
- The output directory is `graphify-out/`, also containing a `cache/`
  subdirectory for incremental cache (per the README).
- Additional outputs not mentioned in the article:
  - `--wiki` for an agent-crawlable markdown wiki.
  - `export callflow-html` for a Mermaid call-flow architecture page
    (added v0.7.13, see CHANGELOG).
  - `--neo4j` for Cypher export.
  - A `manifest.json` tracking file hashes for incremental rebuilds
    (added in early v0.6.x and stabilized v0.7.5,
    https://github.com/safishamsi/graphify/blob/v7/CHANGELOG.md).
  - A global cross-project graph at `~/.graphify/global.json` (v0.7.7+).

**Graph schema.**

- Per `docs/how-it-works.md`, nodes carry `id`, `label`, `file_type`
  (one of `code`, `document`, `paper`, `image`, `rationale`), and
  `source_file`. Edges carry `source`, `target`, `relation` (verb
  phrase like "calls" or "imports"), `confidence` status,
  `confidence_score` (INFERRED only), and `source_file`.
- The CHANGELOG records at least one breaking shape change already:
  `edges` was renamed to `links` in `graph.json` (NetworkX convention),
  with a v0.7.10 patch to read older `edges`-shaped files
  (https://github.com/safishamsi/graphify/blob/v7/CHANGELOG.md).
- There is **no explicit `schema_version` field** documented in
  `graph.json`. This is a real concern for long-running projects
  consuming the graph (see section 6).

**Hook integration.** Partly confirmed. The Bildea article calls this
out only for Claude Code. Reality is more nuanced:

- Claude Code: `graphify install` writes a `PreToolUse` hook into
  `settings.json` (fires before every `Glob` / `Grep` tool call) AND
  injects a `CLAUDE.md` directive. Confirmed
  (https://github.com/safishamsi/graphify/blob/v7/docs/translations/README.ja-JP.md
  and the Claude Code integration page).
- Codex: writes a `PreToolUse` hook to `.codex/hooks.json` (confirmed
  by reading `graphify/__main__.py` via `gh search code` —
  `_install_codex_hook` function exists). Earlier docs said Codex
  "did not support PreToolUse" — that was an older version. As of v7,
  Codex hooks are supported but had a Windows / Conda regression
  fixed in v0.7.x (CHANGELOG #651, #522).
- Codex additionally requires `multi_agent = true` in
  `~/.codex/config.toml` for parallel extraction
  (README translations).
- Gemini CLI: uses a `BeforeTool` hook (different name from Claude's
  `PreToolUse`). v0.7.x fixed a cross-platform issue where the hook
  used a bash-only `[ -f ... ] && echo` test that broke on Windows
  CMD and Git Bash; the fix uses inline `python -c` with `json.dumps`
  (CHANGELOG #681).
- Cursor: uses a rules file at `.cursor/rules/graphify.mdc` with
  `alwaysApply: true` — not a hook.
- Aider, OpenClaw, Factory Droid, Trae: **do NOT support hook
  injection**; Graphify falls back to writing an `AGENTS.md` at the
  project root that those CLIs read at session start (README
  translations).
- Therefore the article's "PreToolUse hook" framing is *correct only
  for Claude Code* (and now Codex). For the other supported CLIs the
  mechanism is either a different hook name, a rules file, or a
  passive `AGENTS.md`.

**"Supports 10 platforms".** Updated.

- Bildea article (April 2026): Claude Code, Codex, OpenCode, Cursor,
  Gemini CLI, GitHub Copilot CLI, Aider, OpenClaw, Factory Droid, Trae.
- Current README (v7 branch): **16 platforms** — adds VS Code Copilot
  Chat, Hermes, Kimi Code, Kiro IDE/CLI, Pi, and Google Antigravity.
  The repo `topics` already include `antigravity`. The article's
  count is roughly right for late April; today the project bills "15+".

**"71.5x token reduction".** This is the single most important claim
to interrogate, and the answer is: real-but-narrow.

- The 71.5x figure comes from Graphify's own benchmark corpus, not a
  general measurement. The corpus is documented in the repo at
  `worked/karpathy-repos/` and consists of "Karpathy repos
  (nanoGPT, minGPT, micrograd) + 5 papers + 4 images, 52 files" — a
  *mixed* corpus where PDFs and images inflate the raw baseline
  dramatically (https://github.com/safishamsi/graphify/tree/v5/worked/karpathy-repos).
- On pure-code workloads, multiple independent benchmarks land much
  lower:
  - Kevin Kinnett's review on a mid-sized TS/Node/React/Postgres app
    found *no* measured token reduction and reverted to "brute-force
    navigation"
    (https://www.kevinkinnett.com/posts/graphify-review-claude-code-knowledge-graph/).
  - Exchangepedia's "honest benchmark" found 7.3x on a real Python
    codebase, with per-question variance of 6.5x to 8.1x
    (https://exchangepedia.com/articles/graphify-honest-benchmark-real-codebase.html
    — surfaced via search; site not directly fetchable).
  - Manav Ghosh on Medium reported 71x on a 20k-line Python project,
    but his measurement was navigation overhead over weeks, not a
    single per-query ratio, and he noted polyglot / cross-cutting
    concern complexity drove most of the gain
    (https://medium.com/@manavghosh/graphify-claude-code-how-i-cut-token-usage-by-71x-on-a-50k-line-codebase-74868ac67fd1).
  - CLSkills' setup guide quotes "6.8x for code review, up to 49x for
    daily coding" — the 6.8x number matches the in-repo benchmark for
    code-review tasks (https://clskillshub.com/blog/graphify-claude-code-integration).
- Realistic envelope to plan against: **5–10x for pure code, up to
  ~70x only when the corpus is dominated by PDFs/images/transcripts**.
  Treat the headline figure as marketing-true, not as expected.

**Languages supported.**

- README v7 enumerates extensions covering Python, TypeScript,
  JavaScript (+ JSX/TSX/MJS), Go, Rust, Java, C/C++, Ruby, C#, Kotlin,
  Scala, PHP, Swift, Lua/Luau, Zig, PowerShell, Elixir, Objective-C,
  Julia, Vue, Svelte, Groovy/Gradle, Dart, Verilog, SystemVerilog,
  SQL, Fortran (.f/.f90/.f95/.f03/.f08), Pascal/Lazarus
  (.pas/.pp/.dpr/.dpk/.lpr/.inc/.dfm/.lfm/.lpk).
- That's ~29 file extensions / ~25 distinct languages, depending on
  how you count Fortran / Pascal variants. The article's "20" was
  accurate in April but is now out of date.
- Languages explicitly *requested but not yet supported* per recent
  open issues: Clojure (#816), GDScript (#697), HCL/Terraform (#416 —
  PR open).

---

## 3. Cost model

**Direct cost of Graphify itself.** None — MIT license, no
subscription. README explicitly states "No telemetry, no usage
tracking, no analytics."
(https://github.com/safishamsi/graphify/blob/v7/README.md).

**Indirect cost — Pass 3 LLM calls.** This is the dominant cost line.

- Pass 3 dispatches subagents through the *host* coding CLI. So if
  you're on Claude Code, the LLM calls bill against your Claude API
  budget. On Codex, your OpenAI budget. On Gemini CLI, your Gemini
  budget. On Cursor with subscription seats, the calls count against
  your seat's quota.
- Confirmed: Graphify's headless extraction path (`graphify extract`)
  accepts `--backend` flags for `gemini`, `ollama` (local, no API
  key), `bedrock` (AWS), `openai`, `kimi`. The Ollama backend is
  explicitly free / on-device (README + CHANGELOG v0.7.7).
- Cost is amortized via the manifest+SHA256 content cache: re-runs on
  unchanged files cost zero LLM tokens (CHANGELOG v0.7.5
  "Incremental Extraction").

**Cloud / subscription tier.** None for `graphify` itself.

- The author maintains a separate commercial product called
  **Penpax** (https://graphify.net mentions a "free trial launching
  soon"), described as the "always-on layer built on top of graphify"
  for meetings/emails/browser history. Penpax is positioned as
  enterprise / on-device but is essentially the upsell. Graphify
  itself is free to use forever.
- The repo also references a Gumroad book "The Memory Layer" as a
  monetization channel (README via WebFetch).

**Practical guidance.** For a multi-CLI agent pack, Pass-3 cost is a
real concern only on large unstructured-content corpora (lots of
PDFs/docs/recordings). Pure-code Pass-1 is free; Pass-2 transcription
is local-only; Pass-3 only fires on docs/PDFs/images/transcripts and
caches by content hash. For a typical Swift/Python/gRPC codebase
without thousands of PDFs, total cost should be small and *one-time*
on first run, then near-zero on incremental rebuilds.

---

## 4. Privacy / data flow

**Code (Pass 1).** Local-only. Tree-sitter parsing runs in-process; no
file content is sent anywhere
(https://github.com/safishamsi/graphify/blob/v7/docs/how-it-works.md).

**Audio/video (Pass 2).** Local-only. faster-whisper runs on the host
machine, transcripts are SHA256-cached on disk, audio bytes never
leave the device. Bildea article's claim confirmed.

**Docs / PDFs / images / transcripts (Pass 3).** **Sent to whatever
LLM the host CLI is configured to use.** This is the critical privacy
nuance the Bildea article understates:

- Default routing: through the user's coding CLI's configured model
  endpoint. So Claude Code routes to Anthropic, Codex to OpenAI, etc.
  Your data-handling terms with that vendor apply.
- Local-only alternative: `graphify extract --backend ollama` uses a
  local Ollama model — no data leaves the host.
- AWS-only alternative: `graphify extract --backend bedrock` uses AWS
  Bedrock — data stays within your AWS account, no Graphify-author
  third party.

**graphify.com / graphify.net / graphifylabs.ai.** No telemetry, no
analytics, no callback. The repo states "No telemetry, no usage
tracking, no analytics." The domains are marketing/landing pages,
not runtime endpoints.

**Penpax (the upsell).** Marketed as "on-device, fully local, no cloud
upload, no training your data." Not relevant to free Graphify.

**Net.** For a pack that emphasizes user data sovereignty: Graphify
with `--backend ollama` is genuinely 100% local. With any other
backend, you've delegated Pass-3 privacy to your existing CLI's
vendor. That's typically acceptable — you were going to send the
files to that vendor anyway — but it should be called out clearly to
pack users.

---

## 5. What it's good at

**Cross-file structural queries.** This is the strongest claim and it
holds up. The tree-sitter Pass 1 produces real call graphs, import
graphs, class-hierarchy edges. Queries like "what calls
`UserService.authenticate`?", "shortest path from `RateLimiter` to
`DatabasePool`", or "which modules are god nodes?" are exactly what
the graph is shaped to answer
(https://github.com/safishamsi/graphify and Emelia analysis).

**Mixed-content corpora.** Strong. The 71.5x headline benchmark is on
a corpus that's 30% code, 30% papers, 40% other — and that's
specifically where Graphify wins big. A repo that has architectural
ADRs, design PDFs, meeting recordings, screenshots-of-whiteboards,
and code all in one place is the sweet spot. Plain MCP local-rag
indexes one of those modalities well; Graphify indexes all of them
into the same graph. Kevin Kinnett's review (mixed result) was on a
*pure-code* repo and that's exactly the case Graphify is least
differentiated on.

**Token-budget-constrained workflows.** Real but only on large
projects. The CLSkills guide explicitly says "Graphify shows limited
value for projects under 30 files or those composed primarily of
configuration files (YAML/JSON)"
(https://clskillshub.com/blog/graphify-claude-code-integration). The
Manav Ghosh review claims navigation tokens drop from
80–150k/hour to <2k/hour on a 200-file repo. The break-even point is
roughly "more files than the agent can hold in its context window."

**Long-running projects with compounding context.** The persistent
`graph.json` is committed to git and merge-driven (CHANGELOG v0.7.0
"union-merge[d]" driver). The Leiden community-detection is now
deterministically seeded (`seed=42`, CHANGELOG v0.7.0) to reduce diff
churn across devs. The global cross-project registry at
`~/.graphify/global.json` lets one machine reason across many repos.
This is a real win for the "config pack across many projects"
scenario.

**Concrete sweet spots for an agent config pack.**

- "Why does X exist?" / design-rationale questions that pull from
  `# WHY:`, `# NOTE:`, `# HACK:` comments and rationale labels.
- "What's central to this codebase?" — god-node detection.
- "Where does change Y propagate?" — graph traversal from a node.
- Onboarding a new agent or human into a repo where their context
  budget is too small for the full source tree.
- Cross-cutting concerns that span code + docs + meeting notes.

---

## 6. What it's bad at / limits

**Update model.** Incremental, but not seamless.

- Code files: post-commit hook auto-rebuilds AST (deterministic, fast,
  detached via `nohup & disown` — CHANGELOG v0.6.3). Good.
- Non-code files (docs, PDFs, images, transcripts): watcher only sets
  a `needs_update` flag — it does *not* re-extract. Real-world
  failure mode documented in Issue #483: a 21,625-node graph went
  7+ hours stale on an actively-edited doc corpus despite the
  watcher running
  (https://github.com/safishamsi/graphify/issues/483). User must run
  `graphify --update` manually or schedule it. Maintainer's stated
  reason: avoid surprise LLM costs.

**File deletions / renames.** Partially handled.

- The manifest tracks content hashes, and v0.6.2 explicitly fixed a
  bug where the manifest wasn't being persisted after each rebuild
  (CHANGELOG).
- Issue #222: post-commit hook gates rebuilds on a hardcoded
  `CODE_EXTS` allowlist that had drifted from the canonical
  `CODE_EXTENSIONS` — silently skipping `.tsx`/`.jsx` and other
  valid code changes, producing a stale graph with no error
  (https://github.com/safishamsi/graphify/issues/222). Indicates the
  rebuild trigger surface is brittle.
- No explicit "I deleted this file" handling beyond
  "manifest no longer lists the hash" — orphan nodes from deleted
  files may persist until a full rebuild.

**Graph staleness on fast-moving codebases.** This is the dominant
practical complaint. The graph is a point-in-time snapshot. Heavy
refactors require a full re-extract, which on a doc-heavy corpus
costs real LLM tokens. The CLSkills guide explicitly recommends
"CI automation" for production environments — i.e. you have to build
your own freshness pipeline.

**Languages outside the supported set.** No fallback to anything
useful. For Clojure, GDScript, HCL/Terraform, Nix, Haskell, OCaml,
and similar, Graphify can index docs/comments but won't produce a
call graph. Open PRs and issues show the maintainer accepting
community-contributed language extractors but the surface is closed
to whatever the v7 tree-sitter set includes today.

**LLM-inference cost on large doc corpora.** Pass 3 is a real money
sink for first-time builds against a many-thousand-PDF library.
Manifest caching makes re-runs free, but the upfront extraction is
unbounded by default. The CHANGELOG v0.7.5 entry "adaptive token
budgeting" and CHANGELOG v0.7.7 Ollama backend addition both
acknowledge this.

**Schema drift.** Active and undocumented.

- `edges` → `links` rename is a confirmed breaking shape change in
  the JSON, with v0.7.10 adding read-side compat
  (CHANGELOG).
- No `schema_version` field documented in `graph.json`. Any
  downstream consumer (MCP server, custom tooling, pack
  introspection) must handle schema drift defensively.
- 95 releases in five weeks plus active node-ID normalization changes
  (v0.7.14 NFKC + casefold) means the on-disk format is still
  moving. Pin to a specific version before consuming the graph
  programmatically.

**Monorepo / multi-repo.** Real but early.

- `graphify merge-graphs a.json b.json` unions two graphs (CHANGELOG
  v0.7.0).
- `graphify global add` registers cross-project graphs with
  `<repo>::<id>` prefix-relabeling to avoid silent ID collisions
  (CHANGELOG v0.7.7).
- For a single monorepo, you run `graphify .` at the root and let
  it scan everything — there is no documented per-package
  partitioning. On a 10-million-line monorepo this is likely to be
  painful (no benchmark public).

**Bot / generated noise.** Not addressed. There's no documented
generated-file filter (e.g. `*.pb.go` for gRPC, `Generated.swift`
for SwiftGen, `node_modules/`). README ignores `.gitignore`-listed
files implicitly via the file discovery layer, but no first-class
"this is generated, summarize don't deep-extract" flag exists. For
the Optiquity pack's gRPC + Swift use case this is a meaningful
gap.

**Independent maturity assessment.**

- Kevin Kinnett: graph generation succeeded (369 nodes, 505 edges,
  57 communities), but `GRAPH_REPORT.md` came out blank; PreToolUse
  hook fired but Claude reverted to grep anyway; concluded "real
  idea, early-tool problem, not production-ready"
  (https://www.kevinkinnett.com/posts/graphify-review-claude-code-knowledge-graph/).
- Issue #580 — open with no maintainer reply — shows another user
  with same complaint: Graphify *increased* tokens because the
  hook-prompt + report-read added overhead the agent didn't recoup.
- Emelia analysis: "v0.4.2 codebase is barely a week old, API and
  output formats may still change between versions."

**Net.** The technical claims hold; the operational maturity does
not yet. Plan for: defensive schema-drift handling, manual or
CI-driven freshness, pinned versions, and an opt-out path if a user
sees no benefit.

---

## 7. Competitive landscape

This section is structural, not "who wins" — knowing where Graphify
overlaps vs differs lets the pack place it correctly.

**Plain MCP local-RAG (the pack's current doc-reconciliation
approach).**

- MCP local-RAG embeds chunks of text and retrieves by similarity.
  Graphify builds a typed graph and retrieves by topology.
- For "find docs that mention auth" → local-RAG wins.
- For "trace auth from the HTTP handler down to the DB connection
  pool" → Graphify wins.
- For "summarize the rationale comments across 200 files" → either
  works but Graphify preserves source-file provenance more
  honestly via EXTRACTED/INFERRED labels.
- Overlap is real but partial. Within a pack that already uses
  local-RAG for docs, Graphify is **additive** for code/structure,
  not a replacement.

**Cursor's repo indexing.**

- Cursor maintains an internal embedding-based index of your repo
  for its own retrieval. It's a black box, proprietary, and tightly
  coupled to Cursor's editor.
- Graphify is explicit, queryable, and outputs a portable
  `graph.json`. Different layer entirely. Graphify ships a Cursor
  integration via `.cursor/rules/graphify.mdc` to *augment* (not
  replace) Cursor's indexing
  (https://graphify.net/graphify-vs-alternatives.html — via search).

**Aider's repo map.**

- Aider builds a heuristic ranked map of repo files to keep in the
  prompt (no AST). Cheap, fast, lossy.
- Graphify produces structured nodes/edges. More accurate, much more
  expensive to build, slower on first run.
- Aider is supported as a Graphify target via passive `AGENTS.md`
  (no hook). The two coexist; they don't compete.

**Sourcegraph.**

- Sourcegraph: cross-repo grep + symbol search at scale, hosted or
  self-hosted, indexed continuously.
- Graphify: in-repo typed graph including non-code modalities.
- The maintainer's own positioning (graphify.net/graphify-vs-
  alternatives.html via search) says "complementary tools: use
  Sourcegraph for cross-repo grep, Graphify for structural
  understanding within a repo." That's accurate.

**Cody.**

- Cody is a Sourcegraph-backed agent; its retrieval leans on
  Sourcegraph's symbol index. Graphify's typed-edge graph is a
  different shape (call/import/uses relations are explicit; rationale
  comments are first-class nodes).

**GitHub Copilot's symbol index.**

- Proprietary, IDE-bound. Not portable.

**Vector DBs (Chroma, pgvector) + a hand-rolled AST parser.**

- This is what you'd build if you wanted Graphify-like behavior with
  full control. Graphify is essentially "the opinionated pre-built
  version of that, with a CLI and Leiden clustering thrown in."
- For a pack, the build-vs-buy question is: do you want to ship a
  bespoke graph pipeline (high control, high maintenance burden) or
  adopt Graphify and accept its schema drift / early-tool risk?

**Other graph-style tools.**

- **GitNexus** (https://www.marktechpost.com/2026/04/24/meet-gitnexus-
  an-open-source-mcp-native-knowledge-graph-engine...) — MCP-native
  knowledge graph engine, similar pitch, different architecture (MCP
  server as primary surface). Newer (April 2026).
- **code-review-graph** (https://github.com/tirth8205/code-review-
  graph) — narrower, Claude-Code-only, focused on PR review,
  reports "6.8x fewer tokens on reviews and up to 49x on daily
  coding tasks" — same numbers as Graphify because it was inspired
  by it.

**Where Graphify is structurally unique.**

- Multi-modal (code + docs + audio/video transcripts + images) in
  one graph.
- Provenance labels (EXTRACTED / INFERRED / AMBIGUOUS) — epistemic
  honesty most competitors don't ship.
- Persistent, git-committable `graph.json` with a real merge driver.
- Cross-platform CLI install across ~16 coding CLIs.

**Where Graphify overlaps with existing pack components.**

- Doc reconciliation (vs MCP local-RAG): overlap on docs, distinct
  on code structure.
- Codebase navigation (vs the host CLI's built-in Glob/Grep): direct
  competitor — the whole point of Graphify is to *displace* the
  host CLI's blind file scans.

---

## 8. Integration surface for a multi-CLI agent pack

**Install command per CLI.**

| CLI | Install command | Mechanism |
|-----|-----------------|-----------|
| Claude Code | `graphify install` | `~/.claude/skills/`, `CLAUDE.md` directive, `settings.json` PreToolUse hook |
| Codex | `graphify install --platform codex` | `.codex/hooks.json` PreToolUse hook, plus `multi_agent = true` in `~/.codex/config.toml` |
| Gemini CLI | `graphify install --platform gemini` | `BeforeTool` hook (different name from Claude) |
| Cursor | `graphify cursor install` | `.cursor/rules/graphify.mdc` with `alwaysApply: true` |
| Aider | `graphify install --platform aider` | `AGENTS.md` at project root, no hook |
| OpenCode | `graphify install --platform opencode` | `AGENTS.md`, no hook |
| OpenClaw | similar | `AGENTS.md`, no hook |
| Factory Droid | similar | `AGENTS.md`, no hook |
| Trae | similar | `AGENTS.md`, no hook |
| Windows variants | `graphify install --platform windows` etc. | various |

Source: README v7 + translation READMEs (zh-CN, ja-JP, ko-KR).

**Per-project vs global.**

- Skill manifests install to user-global paths (`~/.claude/skills/`,
  `.codex/`, `~/.config/...` etc).
- The graph itself (`graphify-out/`) lives per-project at the repo
  root, by design — it goes in git with the code.
- The `CLAUDE.md` / `AGENTS.md` / `.cursor/rules/` injections are
  per-project.
- Cross-project federation via `~/.graphify/global.json` is opt-in
  (`graphify global add ...`).

**Where graph.json lives.**

- `<repo>/graphify-out/graph.json` — committable. Plus
  `graphify-out/manifest.json` for incremental cache, and
  `graphify-out/cache/` for hashed extracts.
- Recommended in repo with a git merge driver registered (CHANGELOG
  v0.7.0). Without the merge driver, two devs running `graphify
  update` in parallel will conflict on `graph.json`.

**Concurrent agents.**

- v0.7.12 added a per-repo `fcntl.flock` non-blocking lock plus a
  `GRAPHIFY_REBUILD_TIMEOUT` watchdog to prevent unbounded parallel
  rebuilds (CHANGELOG). This was a real bug in earlier versions
  where multiple Claude sessions could trigger overlapping rebuilds
  and race on `graph.json`.
- Leiden community IDs are now deterministic (`seed=42`, v0.7.0) so
  parallel rebuilds don't churn community labels in the JSON diff.
- For a multi-CLI pack where Claude Code + Codex + Gemini might all
  run in the same repo concurrently, this is the right shape — but
  it's *new* (v0.7.12, two weeks old at time of writing). Verify
  before depending on it.

**Risk for a multi-CLI pack specifically.**

- The hook names diverge across CLIs (`PreToolUse` for Claude/Codex,
  `BeforeTool` for Gemini, rules for Cursor, `AGENTS.md` fallback
  for the rest). Graphify abstracts this behind `graphify install
  --platform X`, but the pack maintainer still has to track per-CLI
  install state.
- The pack's existing `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`
  trinity will be edited by `graphify install` on each platform.
  This creates a write-conflict surface with the pack's own
  template directives — order-of-operations matters. Recommended:
  run `graphify install` after pack init, not before, and commit
  the resulting diff to the pack template if you want Graphify on
  by default.

---

## 9. Anything I haven't asked

**Penpax upsell.** The author maintains a commercial product called
Penpax positioned as "the always-on layer on top of graphify"
(https://graphify.net/, surfaced via search snippets). It targets
lawyers/consultants/executives/researchers, claims fully on-device
operation, and is in "free trial launching soon" status as of May
2026. This is the obvious revenue model behind otherwise-free
Graphify. There's no evidence the free Graphify is being
deliberately limited to drive Penpax sales — but the
commercial-sustainability question is real for an MIT tool with
one named maintainer.

**Author identity wrinkle.** PyPI maintainer is `captainturbo`,
GitHub owner is `safishamsi`, marketing site is
`graphify.net` / `graphifylabs.ai`. No public statement clarifying
whether this is one person under multiple handles or a small team.
Not a red flag — projects often have this — but worth noting.

**The "graphify is a skill, not an orchestrator" framing.** This is
the most under-appreciated architectural choice in the Bildea
article. Graphify deliberately does NOT ship its own orchestration
runtime. It piggybacks on whatever parallel-subagent primitive the
host CLI offers (Claude `Task`, Codex `multi_agent`, Factory
Droid `Task`, Trae `Agent`). Pros: zero new infra for the user,
inherits the host's rate limiting and quota. Cons: behavior varies
across hosts (OpenClaw uses sequential extraction because parallel
agents are "still early"; Trae has a different agent surface
entirely). For a pack that targets feature-parity across CLIs,
this means Graphify will behave subtly differently per CLI even
on the same repo.

**"19 vs 20 vs 25 vs 29 languages" inconsistency in the docs.**
Different pages of the official docs disagree on the count.
how-it-works.md (v7) says 25. README.md (v7) lists ~29 extensions.
graphify.net (search snippet) says 19. Bildea article says 20.
None of these are wrong — they reflect rapid version drift over
the project's six-week life and different ways of counting
extensions vs languages. Pin a version if you need a stable claim.

**Penpax + Karpathy framing.** The marketing leans heavily on
Andrej Karpathy's "I dump everything in a folder and have an LLM
compile it into a wiki" tweet (Bildea article quotes it
verbatim). The author has even shipped `worked/karpathy-repos/`
as a benchmark corpus
(https://github.com/safishamsi/graphify/tree/v5/worked/karpathy-repos).
The intellectual pedigree is genuine; the marketing is heavy. Make
your own call on whether that matters.

**Recent (last-7-days) issue themes.** Reading the most-recently-
updated open issues shows three recurring concerns:

1. Windows / cross-platform brittleness (issues #287, #651, #522 —
   wrong python launcher, JSON escaping in PowerShell, hook command
   resolution).
2. Sandbox / agent-write-path issues on Claude Code (#812 — chunk
   writes failing in Claude Code sandbox, routed through `/tmp`).
3. Incremental-update gaps (#483 — non-code files, #222 — extension
   gating, #580 — token efficiency not realized).

None of these are project-killers; all of them are "still maturing"
signal.

**Roadmap themes from open PRs.** AST call handoff + LSP enrichment
(#809), `--publish` flag for an "understand-quickly" registry
(#802), HCL/Terraform extractor (#416), GDScript (#697),
Pascal/Lazarus stabilization (#682), Clojure (#816). Direction is
"more languages, deeper static analysis, more registry/marketplace
features."

**Adoption signal.** 46k stars, 5k forks, 95 releases in five
weeks. Whether stars are organic or marketing-driven is impossible
to know, but the release cadence is real and a third-party Medium
review ecosystem (Bildea, Ghosh, Pankaj, Mustafa Genc, Kinnett,
Mindstudio, Analytics Vidhya, OpenClaw API docs) is real.

---

## Bottom-line evaluation for the pack

**Why add it.**

- Genuine differentiator for cross-file structural queries and
  mixed-content (code + docs + recordings) corpora.
- MIT, no telemetry, no subscription, optional fully-local Pass 3
  via Ollama.
- One install command per CLI; coexists with the pack's existing
  `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` trinity.
- Real third-party validation on the right workloads
  (Manav Ghosh's 71x on a 20k-line polyglot project is the kind of
  case the pack's target users have).

**Why be cautious.**

- Project is six weeks old. 95 releases is impressive cadence and
  also a sign the surface is still moving. Pin a version.
- The 71.5x headline is real-but-narrow; expect 5–10x on pure code,
  more on doc-heavy workloads.
- Independent reviews (Kinnett, Issue #580) show real cases where
  the PreToolUse-hook-plus-blank-report overhead exceeds the
  saving. The pack should ship Graphify as **opt-in**, not
  default-on.
- Schema drift is active (`edges`→`links`, no `schema_version`
  field). Any pack-side consumer of `graph.json` needs defensive
  parsing.
- Incremental update for non-code files is manual (Issue #483).
  Pack should provide a wrapper for "graphify update + commit on
  CI."
- Windows / cross-platform install path has had recurring bugs in
  the last two release cycles. Test the Windows install path
  explicitly before recommending it.

**Recommended pack integration shape (not implemented, just
proposed).**

- Opt-in template `project-template/graphify/` directory with:
  - A pre-pinned version constraint (`graphifyy==0.7.14`, not
    floating).
  - A `graphify install` step *after* the pack's own
    CLAUDE.md/AGENTS.md/GEMINI.md are written, so Graphify's
    directives append rather than collide.
  - A `.gitignore` exception for `graphify-out/cache/` (cache is
    machine-local) while committing `graphify-out/graph.json` and
    `GRAPH_REPORT.md`.
  - The git merge driver for `graph.json` registered in
    `.gitattributes`.
  - A CI step that runs `graphify update --force` on doc changes
    and commits the result.
  - A doc page in `supporting-docs/` describing the privacy
    boundary (Pass 1/2 local, Pass 3 routes through host CLI's
    vendor unless `--backend ollama`).

EXTERNAL-RESEARCH-COMPLETE: 2026-05-11 — Graphify is a real, MIT, no-telemetry knowledge-graph skill that delivers genuine 5-10x (and occasionally 70x) token savings on mixed-content corpora but is still a six-week-old project with active schema drift, manual non-code freshness, and independent reports where the hook overhead exceeds the savings on pure-code repos — adopt as a pinned, opt-in pack component, not a default.
