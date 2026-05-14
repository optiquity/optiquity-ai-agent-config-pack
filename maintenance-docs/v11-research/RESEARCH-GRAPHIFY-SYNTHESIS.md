# RESEARCH-GRAPHIFY-SYNTHESIS

**Date:** 2026-05-11
**Scope:** Synthesize the two background research reports into a decision-ready summary covering: (a) what Graphify is and does, (b) value to pack development, (c) value to client-project development, (d) what it takes to add as an optional pack feature, (e) ongoing maintenance burden, (f) things to be aware of.

**Source reports** (full evidence, citations, file:line references):
- `maintenance-docs/RESEARCH-GRAPHIFY-EXTERNAL.md` (794 lines) — verifies the Medium article against the actual repo / PyPI / third-party reviews.
- `maintenance-docs/RESEARCH-GRAPHIFY-PACK-INTEGRATION.md` (677 lines) — analyzes pack-internal integration surfaces against v11-dev.

---

## Executive verdict

**Graphify is a real, MIT-licensed, no-telemetry tool that adds genuine value for cross-cutting structural code queries and mixed-format research corpora — but it is six weeks old, ships ~15 releases per week (active schema drift), and independent benchmarks show occasional cases where the hook overhead exceeds the token savings on pure-code repos.**

**Recommendation:** ship as an **opt-in, version-pinned pack feature** that mirrors the existing tracker-opt-in pattern. Do **not** make it default. Do **not** replace `mcp-local-rag` — they solve different problems and should coexist.

---

## 1. What Graphify provides (general)

**Three-pass pipeline producing a queryable knowledge graph:**

1. **Pass 1 — tree-sitter AST extraction** of code in ~25–29 languages (the article's "20" is outdated). Deterministic, local, every edge tagged `EXTRACTED` with confidence 1.0.
2. **Pass 2 — `faster-whisper` transcription** of audio/video files. Local, SHA256-cached.
3. **Pass 3 — LLM extraction** of unstructured content (docs/PDFs/images + Pass-2 transcripts). Routes through the *host CLI's vendor* (Anthropic for Claude Code, OpenAI for Codex, etc.) — your API budget, your data policy. Optional `--backend ollama` for fully-local. Every edge tagged `INFERRED` with a discrete confidence bucket (0.95/0.85/0.75/0.65/0.55), or `AMBIGUOUS`.

**Outputs:** `GRAPH_REPORT.md` (human-readable audit), `graph.json` (machine), `graph.html` (interactive), optional `--obsidian` Vault.

**Query mechanism:** a `PreToolUse` hook (Claude Code + Codex; `BeforeTool` for Gemini; `.cursor/rules` for Cursor; passive `AGENTS.md` for Aider et al.) fires before file-grep, reads the graph map, returns a focused subgraph instead of letting the agent slurp raw files.

**Real benefit:** instead of dumping 52 files into the context window, the agent receives a 300-token subgraph. Article claims **71.5×** token reduction. Independent benchmarks land at:
- **7.3×** on pure Python code (Exchangepedia)
- **6.8×** for code review (CLSkills)
- **~0** measurable savings on a TS/React app (Kevin Kinnett)
- **71.5×** is real but came from a mixed corpus (Karpathy repos + papers + images) where PDFs inflate the raw baseline

**Plan for 5–10× on pure code, 50–70× on mixed-content research corpora.**

**Privacy/cost facts:** MIT, no telemetry, no subscription. Pass 1 + Pass 2 entirely local. Pass 3 routes through your CLI's vendor (or local Ollama if configured). The author's commercial upsell is `Penpax`, a separate product, not part of Graphify.

---

## 2. Benefits in **pack development**

**The pack's current context strategy is intentionally minimal** — `mcp-local-rag` ingests exactly one file by default (`docs/pack/METHODOLOGY.md`), the rest is direct-read. There is no cross-file structural index today. Graphify would add a different layer entirely.

**Concrete pack-side wins** (per integration analysis §3 + §11):

- **`pack-architect`** — cross-cutting design queries ("where does the migrator surface get extended in v11?", "which docs reference Procedure 5-S?"). Today these are grep + read; a graph compresses the answer.
- **`pack-reviewer`** — finds call-sites and references across `scripts/lib/*.sh`, `project-template/.claude/`, `.codex/`, `.gemini/` in one query. Particularly useful for trinity-symmetry reviews where you ask "show me everywhere this concept appears across all three CLIs."
- **`pack-auditor` + 7 variants** — pattern-detection queries ("find every place an agent prompt includes options/recommendations" — that's the kind of cross-cutting structural audit a graph helps with).
- **`pack-docs-researcher`** — the natural Graphify customer. Mixed-format corpora (Markdown specs + PDFs + research notes in `__external-docs/`) become one queryable graph.

**Pack agents that get little/no benefit:** `pack-coder`, `pack-repo-ops`, `pack-grpc-schema`. They write code in narrow paths; the graph adds overhead without payoff.

**Negative case to be honest about:** the pack churns multiple commits per day during active development. A graph rebuilt at 10am is partially stale by lunch. The integration analysis recommends **no post-commit rebuild** — only `/pm-startup` + `/pack-startup` detect-and-report freshness, plus a manual `pack graphify rebuild` verb. Even with that cadence, expect the graph to lag commits by hours.

---

## 3. Benefits in **client project development**

This is where Graphify shines more brightly than in pack-dev, because client projects are typically:

- Larger and slower-churning than the pack itself
- Multi-language (Swift app + Python server + gRPC schemas in the same repo)
- More likely to have mixed-content corpora (architecture docs, design briefs, meeting recordings, customer-research PDFs)

**Per-agent value in a client project:**

- **`architect`** — cross-language structural queries (which Swift call sites depend on which gRPC services, which Python handlers).
- **`reviewer`** — change-impact analysis across language boundaries.
- **`auditor`** (and the 7 variants) — particularly **auditor-architecture** and **auditor-code** benefit from a structural index that spans the whole repo.
- **`docs-researcher`** — when the project has a real research backlog (design docs, vendor-spec PDFs, recorded design reviews), Graphify's mixed-content ingestion is the killer feature. This is where the 50–70× token savings get realized in practice.
- **`coder`** — minor benefit. A coder edit on a single file doesn't need the whole graph.
- **`tester`** — picks up the test-to-code-under-test edges if Pass 1 traces them; useful for coverage-shaped queries.

**Interaction with v11 GH-issue mode:** Graphify operates on files, not on GitHub issues, so the tracker side is unaffected. *However*, when a project's BACKLOG.md is empty (forward-migrated to issues), Graphify won't see the BACKLOG content unless you opt into ingesting GH-issue exports — an optional follow-on the integration analysis flags (§4) but doesn't bake into the v1 design.

**Flat-file projects** (small projects, BACKLOG.md still authoritative): Graphify works the same way — it just ingests the file like any other doc. No special accommodation needed.

---

## 4. What it takes to include in the pack (concrete deliverable list)

Adopt the **tracker opt-in pattern** that already exists in v11. The integration analysis lays out the surface in §9:

**New files:**
- `scripts/pack-graphify.sh` — dispatcher with verbs `init` / `rebuild` / `status` / `disable` (parallel to `scripts/pack-tracker.sh`).
- `supporting-docs/CLI-GRAPHIFY-SETUP.md` — companion doc to `CLI-PM-SETUP.md`. Documents per-CLI install (`graphify install --platform claude-code` / `--platform codex` / `--platform gemini-cli`), version pin, opt-in command, opt-out command.
- `project-template/.claude/skills/graph-query/SKILL.md` (canonical) + trinity peers in `.codex/skills/` and `.gemini/commands/` — a new optional skill that documents how an agent should query the graph when one is present.
- Update to `OPTIONAL-FEATURES.md` (lines ~215–228 are the template) — full entry following the established Status / What it is / When it matters / How to enable / Caveats / When to skip shape.
- `.gitignore` block ignoring `.pack-graph/` (and/or `graphify-out/` — the external research notes Graphify defaults to `graphify-out/`; pack convention is `.pack-*/` so add a `--output-dir` flag on the dispatcher to align).
- `HELP-FRAGMENT-PACK.md` row for `pack-graphify.sh`.

**Modifications:**
- Trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, both pack-root and `project-template/`) — add a one-line pointer to `OPTIONAL-FEATURES.md § Graphify` and a *trinity-exemption* note for the per-CLI hook registration (each CLI's hook syntax is different; this is the same pattern as the v11-dev `Sub-agent isolation (Claude-only)` rule at root `CLAUDE.md:139-153`).
- `project-template/skills/pm-startup/SKILL.md` + 3 per-CLI surfaces — add a `Graphify:` line to the Step 6 startup summary, parallel to the existing `RAG:` line. Detect-only (graph exists? freshness vs. last rebuild?), never auto-rebuild on `/pm-startup`.
- `scripts/validate-pack.py` — extend to cover `.pack-graph/` skip-list, optional version-pin check, freshness sentinel (warning, not failure).
- `migrate-vN-to-vN+1.sh` (when v11→v12 ships) — pick up Graphify version pin and re-init the hook for the new version, like the tracker mid-migration logic.

**Permission profile:** the new `graph-query` skill should be loadable by **read-only** agents (architect/reviewer/auditor/planner/docs-researcher/tester) — it only queries the graph; it doesn't mutate.

**Don't introduce a new agent.** The graph-query work fits as a skill loaded by existing agents. The integration analysis explicitly recommends against a `graph-agent`.

**Estimated effort:** if we were to plan this as v12 scope, BD count would be roughly 4–6 BDs:
- BD-X1: scripts/pack-graphify.sh dispatcher + verbs
- BD-X2: CLI-GRAPHIFY-SETUP.md + OPTIONAL-FEATURES.md entry
- BD-X3: graph-query skill (canonical + 3 per-CLI surfaces) + trinity pointer
- BD-X4: pm-startup Graphify: line + validate-pack.py extensions
- BD-X5: migration handling
- BD-X6: HELP-FRAGMENT row + roster updates + tests + dog-food

---

## 5. Ongoing maintenance burden

This is where I'd push back hardest. Graphify is six weeks old and shipping ~15 PyPI releases per week. The pack convention values stability above novelty. Specific risks:

- **Schema drift.** `graph.json` already had an `edges`→`links` rename mid-flight; no `schema_version` field exists. A pinned version is the floor — the pack must own the un-pin / re-pin decision, not auto-upgrade.
- **Hook API drift.** Each CLI's hook surface (`PreToolUse`, `BeforeTool`, `.cursor/rules`) evolves on its own cadence. Graphify wraps these — when one upstream changes, the wrapper breaks. Pack validator can detect a broken hook via the `Graphify:` `/pm-startup` line, but the fix is upstream.
- **Stale-graph false-positive risk.** Issue #483 (open): non-code-file freshness is manual, doc graphs sit 7+ hours stale even when manually rebuilt. Agents trusting a stale graph will produce confidently-wrong answers. The pack's mitigation should be: `Graphify:` line in `/pm-startup` summary reports the *graph age* (mtime of `graph.json`), and agents in their hard rules note "graph age > 24h ⇒ use as a hint, not a source of truth."
- **Hook overhead exceeds savings on some pure-code repos** (Issue #580, currently no maintainer reply). On a small Swift app with no PDFs/recordings, Graphify may *increase* token usage. The opt-in flow should include a "measure once, decide" step — try it for a week, compare token bills, opt in or out.
- **Doc currency.** Pack docs reference Graphify behavior. If Graphify changes that behavior in 0.8.0, the pack's `CLI-GRAPHIFY-SETUP.md` rots silently. Mitigation: include a "validated against Graphify v0.7.14" version marker in the setup doc, and a quarterly review checklist item.
- **Multi-agent file locking** only landed in Graphify v0.7.12 (~2 weeks before this report). The pack runs concurrent agents in some flows. Worth pinning to v0.7.12+ as the floor and watching for regression.

**Maintenance cadence to plan for:**
- Quarterly: re-validate version pin against latest Graphify release; check for breaking schema changes; refresh `CLI-GRAPHIFY-SETUP.md` validated-against marker.
- Per-major-pack-release: re-dogfood Graphify against the new pack version (this is where the BD-102 dogfood pattern extends).
- Ad-hoc: when an upstream CLI (Claude Code / Codex / Gemini) ships a hook-API change, regression-test the Graphify install path.

---

## 6. Things you may have missed

**(a) Privacy delta from current pack baseline.** The pack today is local-first by design: `mcp-local-rag` is local-only embedding, agents read files directly. Graphify's Pass 3 sends doc/PDF/image content to the host CLI's vendor (Anthropic / OpenAI / Google). For Optiquity Trader and similar projects where IP sensitivity matters, this is a *real* change in data flow. The opt-in flow must say so loudly. The `--backend ollama` escape hatch exists; document it.

**(b) Default branch on Graphify is `v7`, not `main`.** The repo uses versioned default branches. This affects how the pack's pinning syntax reads in docs. Mention this in `CLI-GRAPHIFY-SETUP.md` so new readers don't get confused.

**(c) Graphify's own `AGENTS.md` mutation.** Graphify's `graphify install` command edits the project's `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` to add its hook registration. This is a *write* into the pack's trinity files. The pack's install order must be: pack init first (trinity files exist), Graphify install second (Graphify reads existing trinity and appends its hook block). Document this explicitly. The pack's trinity-parity validator (`scripts/validate-pack.py` Check 18) must skip the Graphify-managed blocks.

**(d) Generated-file noise (gRPC).** Graphify has no generated-file filter today (open complaint in upstream issues). gRPC projects generate large amounts of `*_pb2.py` / `*.pb.swift` etc. Without a filter, these inflate the graph and clutter `auditor-code` queries. The pack-graphify dispatcher should ship a default `--exclude` list covering `*_pb2.py`, `*.pb.swift`, `*.pb.go`, `.build/`, `.swiftpm/`, `__pycache__/`, etc.

**(e) Commit the graph or not?** The external research notes Graphify can ship a git merge driver for `graph.json`. Committing the graph makes it portable across machines but creates large noisy diffs. Pack recommendation: **don't commit** — list it in `.gitignore` (the integration analysis already specifies this in §9). Each developer rebuilds locally. The graph is a cache, not a source of truth.

**(f) Interaction with `__external-docs/`.** The user keeps research docs under `/Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack/`. That tree is *outside* the pack repo. Graphify can index it with `graphify --path /Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack`, but the graph would live in that external directory. Worth thinking about whether a single graph spanning pack + external docs is desired, or two separate graphs.

**(g) Adoption asymmetry across CLIs.** Hook API is most mature for Claude Code + Codex. Gemini CLI's `BeforeTool` is newer. Aider / OpenClaw / Factory Droid / Trae use *passive* `AGENTS.md` integration (no real-time hook — the graph guidance is just prose in the agent file). If the pack pushes for full per-CLI parity, the Gemini side will be the weakest leg. Acceptable, but flag it in `CLI-GRAPHIFY-SETUP.md`.

**(h) The 16+ platforms claim.** The Medium article says 10; the actual list on the Graphify repo is 16+ as of 2026-05-11. This means more pack-relevant integrations than the article implies, including OpenCode and OpenClaw which the pack doesn't currently target. Worth noting but not acting on.

---

## 7. Recommendation

**Defer to v12.0 scope**, not v11.0. Reasons:

1. v11 is already in active development with a substantial BACKLOG (BD-119/121/124/126/127 just landed; BD-114/120/122/123/125/128/129/130/131/132/133/134 in flight). Adding Graphify expands the v11 surface unnecessarily.
2. Graphify upstream is six weeks old. Letting it season three months before pack adoption is prudent.
3. v12 can take a clean BD cluster (BD-X1..BD-X6 above) and ship as a single coherent feature.

**Before v12 scope decision, do these now:**

1. **Run a personal pilot.** `pip install graphifyy==0.7.14 && graphify install --platform claude-code` against the v11-dev tree (in a throwaway worktree). Use it for a week. Measure token bills. Note rough-edge cases.
2. **Track an upstream marker.** Open a BD-NNN in v11-dev BACKLOG.md as `Status: Investigating`, `Type: TODO(future)` for "Graphify pack integration — v12 candidate." Cross-reference both research reports. This holds the slot without committing scope.
3. **Watch issue #580** (hook overhead vs. savings on pure-code repos) and #483 (non-code-file freshness). If the maintainer addresses these in 0.8.x, the v12 case strengthens. If they don't, the case weakens.

---

## 8. Reading order

For full detail:

1. This synthesis (start here).
2. `RESEARCH-GRAPHIFY-EXTERNAL.md` if you want evidence on Graphify itself — adoption metrics, license, benchmark fidelity, known issues, competitive landscape.
3. `RESEARCH-GRAPHIFY-PACK-INTEGRATION.md` if you want file:line-cited pack-internal integration shape — what to change, where, how to validate.

Both source reports include final-line summaries you can grep for: `EXTERNAL-RESEARCH-COMPLETE:` and `INTEGRATION-ANALYSIS-COMPLETE:`.
