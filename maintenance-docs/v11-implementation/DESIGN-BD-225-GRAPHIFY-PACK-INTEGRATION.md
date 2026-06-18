# DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION

**PRELIMINARY architect design — options + pros/cons + evidence-based recommendations + OPEN QUESTIONS for the user.** This is NOT a plan and NOT an implementation. Nothing here mutates the repo. Every recommendation is grounded in the Empirical-Evidence Blocks below or in cited doc facts; where I cannot ground a recommendation I present options and ASK.

- **Author role:** pack-architect (read-only; Read/Grep/Glob/Bash + this one Write).
- **Date:** 2026-06-18 · **HEAD SHA:** `47d8f600f376ce24e1c36a0e241f182529ad4fd6` · **branch:** `v11-dev`
- **Target:** Graphify CLI `0.8.39` (verified installed) on this macOS env; extras present = `[pdf,svg,watch]`; absent = `[neo4j,falkordb,video]`.
- **Primary inputs read in full:** `backlog/BD-225.md`; `RESEARCH-BD-225-GRAPHIFY-INCLUSION.md`; `REPO-QUICKSTART.md`; `PLAN.md`; `SKILL.md` + all 8 `references/*.md`; `graphify.net` (curl, HTTP 200).
- **Sources I could not access:** none. (`WebFetch` is unavailable to me; I used `curl -sL` for graphify.net and it returned HTTP 200.)

> **How to read this doc.** Sections 1–8 map 1:1 to the eight user aspects; section 9 covers the two knob sets; section 10 is the consolidated OPEN-QUESTIONS list (the user's decision queue); section 11 is the Empirical-Evidence Blocks (every state-claim); section 12 is the Rules-Applied Verification Block. Recommendations are marked **REC**; user-decisions are marked **OQ-n** and restated in section 10.

---

## 0. The two facts that drive the whole design

Two independently-verified facts dominate every downstream choice. Read these first; the rest of the doc keeps returning to them.

### 0.1 The corpus TRIPS both of Graphify's "narrow to a subfolder" gates (EE-1, EE-7)

The indexable corpus (all 1,645 tracked files **minus** the 272 under the two archive dirs = **1,373 files**) is **2.7× over** Graphify's 500-file gate, and the `.md` files alone total **~2.65M words** — **over** the 2,000,000-word gate. SKILL.md Step 2 says when `total_words > 2,000,000 OR total_files > 500`, the skill **shows a warning, computes the top-5 first-level subdirs, and asks the user which subfolder to run on — and waits.** So a naive `/graphify .` on this repo does **not** silently index everything; it stops and asks you to narrow. This is the single biggest design consequence and it reshapes aspect 2 (scope) and aspect 4 (seamlessness).

### 0.2 All five pack agents ALREADY have `Bash` (EE-6) — so "which agents get Bash" is largely moot

The QuickStart's headline subagent-wiring step ("add `Bash` to graph-using agents; read-only auditors/reviewers are the usual offenders") is a **no-op here**: every pack agent (`pack-architect`, `pack-coder`, `pack-docs-researcher`, `pack-planner`, `pack-reviewer`) already declares `Bash` in its `.claude/agents/*.md` frontmatter. So agent-enablement collapses from "edit tools: frontmatter on N agents" to "add ONE graph-first rule to the pack-root trinity" — far smaller blast radius than the QuickStart implies. (Codex `.toml` / Antigravity-plugin parity is a separate question — OQ-9.)

---

## 1. Aspect 1 — Usage: the three cases (human / Pack Chat / spawned agents)

All three cases share the same underlying truth (REPO-QUICKSTART top + EE-2): **query/path/explain/affected are a plain deterministic local CLI, no LLM, ~0 tokens**; only **building/refreshing** the doc layer costs subscription tokens. So usage is cheap; freshness is the only cost center (aspect 3). The cases differ only in *who* runs the query and *how the graph-first instinct gets installed*.

### 1a. Human questions & prompts

- **Mechanism:** Once `graphify-out/graph.json` exists, the installed user-level skill makes the *interactive Pack Chat session* treat codebase questions as graph queries first (SKILL.md "Fast path"); the human can also run `!graphify query "..."` inline to see the raw subgraph.
- **Settings/limits — REC:** Accept defaults for human-initiated queries (`--budget 2000`). Rationale: the human is in an interactive session where more context is usually better, and the human can re-ask with a higher budget if truncated. No per-query tuning recommended for the human case.
- **One caveat to surface to the human (REC):** the query matcher is **literal** — case-folded substring + IDF, no stemming/synonyms (EE-2, references/query.md). The vocab-expansion step (pick ≤12 tokens from the graph's own vocab before traversal) is mandatory for good answers. This is already baked into the skill's query flow, so the human gets it for free *in the interactive session* — but it is the reason raw `graphify query` from a cold shell can return noise.

### 1b. Pack Chat using the graph (a) to get info AND (b) to construct agent prompts

This is the highest-value case and deserves the most care, because Pack Chat is the orchestrator that re-reads the tree most.

- **(a) Pack Chat getting info:** identical to the human interactive path — the skill auto-routes. **REC:** defaults.
- **(b) Pack Chat constructing prompts for spawned agents:** Pack Chat can run `graphify query`/`affected`/`path` to decide *which few files* an agent needs, then name those exact files in the agent prompt — instead of telling the agent to "read the tree." **REC:** for this prompt-construction use, run queries with a **tighter budget** (`--budget 1000`) because the output is being distilled into a prompt, not consumed whole; lower budget = tighter, more decision-oriented subgraph. Evidence: REPO-QUICKSTART §Querying ("Lower it to keep subagent context tight").
- **Boundary note (REC, load-bearing):** the graph indexes `project-template/` too (BD-225 permits this), so Pack Chat can use the graph to orient on *deliverables the agents maintain* — but the graph-first **rule** and any setup artifact stay pack-side. Using the graph to answer a `project-template/` question is fine; that is *consumption*, not a setup artifact.

### 1c. Spawned agents using the graph for their work

- **Mechanism:** a spawned sub-agent is a **fresh context** that does NOT inherit the session's loaded skill or proactive triggering (EE-2 / QuickStart §"Why not automatic?"). It must be told to use the **CLI** (no skill needed for querying). Two parts make this durable: (1) the graph-first rule in the pack-root trinity, which auto-loads into custom subagents (aspect 5); (2) `Bash` on the agent — already present (0.2).
- **Absolute-path requirement (REC, non-negotiable):** a sub-agent may start in a different cwd, so its `--graph` argument MUST be absolute. The QuickStart's portable form is `--graph "$(git rev-parse --show-toplevel)/graphify-out/graph.json"`. Evidence: REPO-QUICKSTART §c + §Wiring.
- **Role-specific phrasing (OPTIONAL, REC = adopt lightly):** the QuickStart suggests auditors→`affected`, architects→`path`/`explain`, coders→`query`. This maps cleanly onto the pack roles: `pack-reviewer`→`affected` (blast radius), `pack-architect`→`path`/`explain` (structure), `pack-coder`→`query` then open only cited files, `pack-docs-researcher`→`query`. **REC:** add this as ONE optional line per role in the trinity's graph-first block rather than editing each agent file — keeps it in the single auto-loaded rule (smaller surface, per design-elegance).
- **Budget for agents — REC:** `--budget 1500` default for agent queries (between the human 2000 and the prompt-construction 1000): agents need enough context to act but their context window is precious. Evidence/logic: QuickStart explicitly frames budget as the subagent-context-tightening knob.
- **DO NOT preload the skill (REC, hard):** never add graphify to an agent's `skills:` frontmatter — SKILL.md is ~32KB and build-oriented; it wastes context and the CLI needs no skill to query. Evidence: REPO-QUICKSTART §Wiring "Do not preload."

---

## 2. Aspect 2 — Ignore list (`.graphifyignore`) + the gitignored-content decision

### 2.1 Why a `.graphifyignore` is unavoidable here

The archive dirs are **tracked**, not gitignored (EE-3). The `.gitignore` fallback therefore would NOT exclude them. The user's HARD RULE ("exclude every dir whose name contains 'archive'") forces an explicit `.graphifyignore`. But the one-file-or-the-other rule (EE-4, REPO-QUICKSTART §interaction) means: **the moment `.graphifyignore` exists, Graphify stops reading `.gitignore` entirely for indexing.** So adding it for the archive dirs forces a deliberate decision about every gitignored category.

### 2.2 The two archive exclusions (measured — EE-3)

Exactly two archive **directories** exist at HEAD: `maintenance-docs/archive/` and `maintenance-docs/v11-research/templates-archive/`. No others. **REC:** both go in `.graphifyignore`.

### 2.3 The archive-named FILE ambiguity (OQ-1)

One **file** carries "ARCHIVE" in its name but lives outside any archive dir: `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-BATCH-ARCHIVE.md` (EE-3). The user's rule is scoped to **directories**. **REC:** index it (it is a live implementation report, not archived content; its name is descriptive). But this is the user's call — **OQ-1**.

### 2.4 The gitignored-category decision (per category, doc-cited)

Because `.graphifyignore` disables the `.gitignore` fallback, I evaluated every `.gitignore` category (EE-5) under the user's principle "gitignored ≠ irrelevant; an agent may need local-only files; decide per category." Graphify ALSO has a built-in always-pruned set (`graphify-out`, `node_modules`, `.git`, `.venv`, `build`, `dist`, `.next`, `target`, caches) that applies on top of whichever ignore file is active (EE-4) — so those need no re-listing.

| `.gitignore` category | Built-in pruned? | Present locally now? (EE-5) | Privacy/value | **REC: in `.graphifyignore`?** |
|---|---|---|---|---|
| `.claude/settings.local.json` | no | absent | may hold local paths/tokens | **EXCLUDE** (secrets-adjacent; no agent value) |
| `.mcp.json` | no | absent | may hold API keys | **EXCLUDE** (secrets) |
| `.pack-tracker/`, `/tracker.toml` | no | absent | local paths; regenerable | **EXCLUDE** (local state, no graph value) |
| `generated/`, `**/generated/{swift,python}/` | no (`build`/`dist` are, `generated/` is not) | absent | regenerated proto output; noise | **EXCLUDE** (derived; pollutes graph with generated symbols) |
| `shared-docs/ios26/` | no | absent | read from Xcode bundle | **EXCLUDE** (not present; external) |
| `.env` | no | tracked fixture `.env` are NEGATED→committed (4 files) | the *committed* fixtures are synthetic, no real secrets | **see 2.5** |
| `__pycache__/`, `*.pyc`, `*.egg-info/`, `.venv/`, `dist/`, `build/` | YES (most) | 2 `__pycache__` dirs | derived | no entry needed (built-in) |
| macOS junk (`.DS_Store`, `._*`, …) | no | present (`.DS_Store`) | noise | **EXCLUDE** (noise; not code/docs anyway, but cheap to list) |
| editor (`.vscode/`, `.idea/`, `*.swp`) | no | n/a | noise | **EXCLUDE** |
| `scripts/.bd119-pre-refactor-monolith.sh.snapshot` | no | absent | working-tree only | **EXCLUDE** |

### 2.5 The `.env` secrets-adjacency decision (OQ-2 — the sharp one)

The repo deliberately **commits** synthetic `.env` fixtures (4 files under `scripts/tests/fixtures/**/.env`, via a `.gitignore` negation — BD-096) so a fresh clone reproduces tests (EE-5). These are **tracked**, so a `.graphifyignore` based on the `.gitignore` `.env` pattern would NOT cover them anyway, and Graphify's semantic pass would send their *contents* to the model. They are synthetic (no real secrets), but they ARE secrets-*shaped* text, and the semantic pass "sends non-code text to the model" (EE-2). Two options:

- **Option A — index them:** they are part of the deliverable test surface; agents maintaining fixtures benefit; content is synthetic. Con: trains the graph on secret-shaped tokens; mild privacy-optics cost.
- **Option B — exclude `**/.env` and `**/.env.*` in `.graphifyignore`:** zero secret-shaped text in the graph; defends the "no secrets to the model" posture by default. Con: agents lose graph visibility into fixture `.env` structure (they can still Read the 4 files directly — tiny set).
- **REC:** **Option B (exclude all `.env`).** Logic: the privacy default should be conservative; the agent-value of 4 synthetic env files in the graph is negligible (an agent can Read 4 files), and excluding them removes the only secrets-shaped semantic-pass input. But this is a judgment call on synthetic-vs-real risk — **OQ-2** (user decides A vs B).

### 2.6 Secrets-adjacency / auto-mode-classifier refusal (OQ-3)

PLAN.md intentionally SKIPS the dotfiles repo because the auto-mode classifier refuses to run on secrets-adjacent repos, and "don't blindly override it" (EE-2). This pack repo is **less** secrets-adjacent than dotfiles (no `private_*`, no real keys; only synthetic fixtures + `.example` files), and the prior `/graphify` run on `optiquity-site` (also docs-heavy, also has `FRAMER_API_KEY` *name* references) succeeded with no secret exposure (PLAN.md "First real run"). **REC:** proceed with a build; if the classifier refuses on first `/graphify .`, that is a signal to investigate (not override). The `.env` exclusion (2.5 Option B) reduces refusal risk. This interaction is worth an explicit privacy-delta note in `pack-ops/OPTIONAL-FEATURES.md` (aspect 8). **OQ-3:** does the user want me to design that note now, or defer to the planner?

### 2.7 `.graphifyinclude`?

Not needed: nothing hidden that we want re-included overrides a sensitive/dep skip. **REC:** no `.graphifyinclude`.

---

## 3. Aspect 3 — Maintenance / freshness (the cost center)

User's chosen direction: **automated SEMANTIC refresh via the `claude-cli` post-commit hook** (`graphify extract . --backend claude-cli`, subscription, no key) — NOT code-only hook (C) alone. I design the cadence/mechanism with logic, accounting for: docs-heavy (1,348 `.md`), the QuickStart's own cost caveat, and the pack's unusual commit flow.

### 3.1 The cost reality (EE-2 + QuickStart caveats)

The QuickStart is explicit and points the opposite way for a repo like this one:
- "**It spends subscription usage on every commit** … on a frequently-committed repo that adds up and can hit limits."
- "Slow + serial → post-commit only" (parallel `claude -p` conflict).
- "**For content/docs-heavy repos, manual `/graphify . --update` is usually better** — faster, and you choose when to spend the usage."

This repo is the *exact* profile the QuickStart warns against: docs-heavy, and committed in bursts (multi-commit batches). A naive `extract . --backend claude-cli` on EVERY commit would re-run the semantic pass across a 1,373-file / 2.65M-word corpus on every one of ~50 commits in a batch — burning subscription quota and (because serial) lagging behind a fast commit cadence.

### 3.2 The pack-commit-flow interaction (load-bearing)

Two pack-specific facts reshape the hook:
1. **agents-never-commit:** only Pack Chat (the orchestrator) ever commits. So a post-commit hook fires only on Pack-Chat commits — agents never trigger it. Good: no agent-side surprise.
2. **worktree-isolation (BD-226/197):** when a sub-agent runs in an isolated worktree, the orchestrator applies the patch and commits in the PARENT tree. A `.git/hooks/post-commit` lives per-clone; in worktree mode the hook must fire in the tree where the commit actually lands (the parent). This needs verification at implement time (which tree's `.git/hooks` runs). **This is a real open question — OQ-4.**

### 3.3 Cadence options (the user asked for options + a recommendation + to ASK)

All options use the Claude subscription (no API key). The split that matters: **code-only refresh is free and can be frequent; semantic refresh costs quota and should be gated.**

- **Option 1 — semantic on EVERY commit (literal user direction, naive form).** Post-commit `graphify extract . --backend claude-cli`, backgrounded. *Pro:* graph's doc layer always current; zero discipline. *Con:* the QuickStart's anti-pattern for docs-heavy repos — quota burn, serial lag across batch commits, redundant re-extraction when consecutive commits touch the same docs.
- **Option 2 — DOC-GATED semantic refresh (REC).** Post-commit hook that first checks `git diff --name-only HEAD~1 HEAD` for changed **doc-layer** files (`.md`, `.pdf`, or comment-bearing code) under the indexable set; runs `graphify extract . --backend claude-cli` (backgrounded) ONLY if a doc-layer file changed; otherwise runs the free `graphify update .` (code-only). *Pro:* spends quota only when the semantic layer actually changed — which on a docs-heavy repo is the right trigger, and on code-only commits costs ~0; honors the user's "automated semantic refresh" intent while respecting the cost caveat. *Con:* a doc-touching commit still fires a full-corpus semantic pass (incremental, but still quota); slightly more hook logic.
- **Option 3 — code-only auto (C/B) + semantic on a SCHEDULE or session-end.** Auto `graphify update .` per commit (free); semantic `extract . --backend claude-cli` run once per work session (e.g. Pack-Chat end-of-session, or a daily `launchd`/cron via `check-update` to detect a pending semantic re-extraction). *Pro:* cheapest; decouples quota spend from commit frequency; `check-update` exists exactly for "is semantic pending?" (EE-2). *Con:* graph's doc layer can lag within a session; "session-end" needs a trigger the pack defines.
- **Option 4 — manual `/graphify . --update` (QuickStart's actual REC for docs-heavy).** *Pro:* fastest (interactive subagents parallelize; the `claude-cli` hook is serial), full control of quota timing. *Con:* not automated → violates the user's "automated, seamless" constraint; easy to forget.

**REC: Option 2 (doc-gated semantic post-commit), with Option 3's `check-update` as a safety net.** It is the closest automated honoring of the user's stated direction that does NOT walk into the QuickStart's documented docs-heavy anti-pattern. But because the user explicitly named "semantic on the post-commit hook" AND explicitly asked me to present cadence options if per-commit semantic is too costly, **this is OQ-5** — I am recommending the gate, not overriding the user. The sub-decision OQ-4 (which tree's hook fires under worktree isolation) must be resolved before any hook is designed concretely.

### 3.4 Initial BUILD (separate from refresh)

The first `/graphify .` is a one-time interactive main-session job (semantic pass parallelizes; faster than the serial hook). **REC:** the initial build is a manual `/graphify .` run by the human/Pack-Chat session, NOT automated — it is one-time, it will hit the narrow-to-subfolder gate (0.1), and that gate REQUIRES an interactive decision (aspect 4 unavoidable-manual point #1). **OQ-6:** at first build, do we (a) answer the narrow-gate by pointing at the whole repo anyway (the gate is a warning, not a hard stop — but on 1,373 files / 2.65M words the semantic pass is large and slow), (b) build a doc-scoped subgraph (e.g. `pack-ops/` + trinity + `backlog/` + `maintenance-docs` non-archive), or (c) build per-area graphs? This is the scope decision the corpus size forces.

---

## 4. Aspect 4 — Seamless/invisible: maximize automation; enumerate every unavoidable manual/permission point

The design target is "manual only where Graphify offers no automated alternative." Here is the complete list of points that CANNOT be fully automated, each with why:

1. **Initial build narrow-gate decision (EE-1/EE-7).** The first `/graphify .` trips the >500-file / >2M-word gate and the skill *waits for a subfolder choice*. No automated bypass within the skill flow. (A headless `graphify extract .` would skip the interactive narrow-prompt but still process the full corpus.) → one-time manual decision (OQ-6).
2. **Headless `claude -p` first-run permission prompt (EE-2 / QuickStart caveat).** "Confirm headless `claude -p` runs without a permission prompt the first time (the auto-mode classifier can stop unattended LLM runs)." → one-time manual confirm per machine before the post-commit semantic hook is trustworthy.
3. **Secrets-adjacent classifier refusal (EE-2).** If the auto-mode classifier refuses the build, that is a *correct safety stop* — must be investigated, not auto-overridden (2.6). → potential one-time manual gate.
4. **Per-clone / per-machine hook + graph install (EE-2).** `graphify-out/`, git hooks, and the global graph are not synced; each machine builds its own. → one-time manual setup per machine (cannot be committed because `.git/hooks` and `graphify-out/` are per-clone/gitignored).
5. **GEMINI/OPENAI key assertion (aspect 6).** Guarding against the auto-route foot-gun can be automated as an assertion *inside* the hook, but verifying the shell environment is clean is a one-time check.

Everything else (query, code-refresh, doc-gated semantic refresh) is automatable. **REC:** accept these five as the irreducible manual/permission points; document them in the pack-ops setup note (aspect 8) so a maintainer on a new machine knows the one-time steps.

---

## 5. Aspect 5 — Graph-first rule: home (pack-root trinity) + the "better tool" exceptions

### 5.1 Home (boundary-absolute, EE-8)

The graph-first rule lives in the **pack-root trinity** — `CLAUDE.md` + `AGENTS.md` + `GEMINI.md` at repo root — per the trinity rule, and **NEVER** in `project-template/` (P-missed-7; BD-225 boundary). Pack-root `CLAUDE.md` auto-loads into custom Claude subagents (QuickStart §Wiring step 3), so a single rule reaches every pack agent. There are currently **no graphify refs in the trinity** (EE-8) and **none in `project-template/`** (EE-9) — clean slate, clean boundary.

- **Trinity parity caveat (REC):** the rule must be expressed in all three files per the trinity rule, BUT the *invocation* differs per CLI: the Claude file references the Claude session/skill behavior; AGENTS.md (Codex) and GEMINI.md must use the audience-correct invocation (cross-CLI reference normalization). The CORE rule (graph-first, query before broad reads, absolute `--graph` path) is identical; the CLI-specific phrasing is normalized, not byte-copied. This is the standard pack trinity pattern — flag to planner.
- **`graphify claude install` vs hand-authoring (OQ-7):** `graphify claude install` writes a `## graphify` section to `CLAUDE.md` AND a **PreToolUse hook** into `settings.json` (EE-2, hooks.md). Two concerns: (1) it writes only the Claude file, breaking trinity symmetry (would need manual AGENTS.md/GEMINI.md parity); (2) the PreToolUse hook is an extra always-on mechanism the pack may not want. **REC:** hand-author the graph-first rule into the trinity (full control, trinity-symmetric, no surprise hook); do NOT use `graphify claude install`. **OQ-7:** confirm the user does not want the `graphify claude install` PreToolUse hook.

### 5.2 The "better tool" exceptions (graph-first UNLESS a better tool fits)

Graph-first is the default, but these cases are genuinely better served by other tools — each with reasoning:

| Exception | Use instead of graph | Why (evidence/logic) |
|---|---|---|
| **Exact-string / token search** (a literal symbol, a commit-message keyword, a CI check number) | `grep`/`Grep` | Graph matcher is case-folded substring + IDF, no exact-anchor guarantee (EE-2); grep is exact and complete. |
| **Authoritative SSOT lookups** (a BD entry's exact Status, the README version table, a `_rules.md` contract) | direct `Read` of the SSOT file | The graph is a *compressed* view; SSOT fields (Status flips, version rows) must be read from source — the graph may lag freshness (aspect 3) and never claims to be SSOT. |
| **Freshly-changed / uncommitted files** | `git diff` / `Read` | The graph reflects the last refresh, not the working tree; for in-flight edits the working tree wins. |
| **Whole-file exact content** (applying an edit, quoting verbatim) | `Read` | Graph returns *subgraphs*, not file bytes; any edit/quote needs the real file. |
| **Files in archive dirs / excluded categories** (aspect 2) | `Read`/`grep` | They are deliberately NOT in the graph; the graph cannot answer about them. |
| **Cross-file structural queries, "what relates to X", blast radius, "where does Y live"** | **graph (default)** | This is exactly the graph's strength (`query`/`path`/`affected`); ~0 tokens vs full-tree reads — the BD-225 win. |

**REC:** encode the rule as "**graph FIRST for orientation/relationship/blast-radius questions; fall through to grep/Read for exact-string, SSOT-field, working-tree, whole-file, and excluded-content lookups.**" Logic: the graph's literal-matcher limitation and its compressed/lagging nature define the exceptions precisely.

---

## 6. Aspect 6 — Backend = Claude subscription ONLY; guard the auto-route foot-gun

### 6.1 The constraint (EE-2, PLAN.md, SKILL.md)

Two subscription paths, both no-key: the **Claude session** (interactive `/graphify`, parallel subagents) and **`claude-cli`** (headless `claude -p`, serial — the hook backend). The foot-gun: if `GEMINI_API_KEY` / `GOOGLE_API_KEY` / `OPENAI_API_KEY` is set in the shell, Graphify **auto-routes the semantic pass to that paid API** (EE-2). The headless `extract --backend` ALSO defaults to "whichever API key is set" (EE — top-level `--help` line: `default: whichever API key is set`).

### 6.2 Guard design (measure-then-bound, REC)

- **Always pass `--backend claude-cli` explicitly** on every headless run (never rely on the default). This pins the subscription path regardless of env.
- **Assert the keys are unset INSIDE the hook** before extraction, e.g. the hook refuses (or unsets for its own subshell) if `GEMINI_API_KEY`/`GOOGLE_API_KEY`/`OPENAI_API_KEY` is present. Logic: `--backend claude-cli` is explicit, but a defense-in-depth assert protects against a future flag drift and makes the intent auditable. **Measured baseline:** I did NOT inspect the user's live shell env (out of scope for a read-only architect; doing so could surface a secret). The assert is designed against the *documented* auto-route variables (EE-2), which is the complete known set.
- **Do NOT set any API key anywhere in pack config.** The `.example`/fixture files must not introduce a real key (they don't today).

### 6.3 The SKILL.md GEMINI "tip" (EE — SKILL.md Step 3)

The interactive skill prints a one-liner "Tip: set `GEMINI_API_KEY` … to use Gemini" when no Gemini key is set. This is benign (informational), but a maintainer must NOT act on it. **REC:** note in the setup doc: "ignore the Gemini tip; we are subscription-only by policy." (This is a doc note, not a code change.)

### 6.4 Ollama (aspect 7)

Not proposed. There IS an alternative (the Claude subscription backend works), so the user's "no Ollama unless no alternative" condition is not triggered. **REC:** do not use Ollama. (No justification needed because the alternative exists and is the chosen default.)

---

## 7. Aspect 7 — Ollama

Covered in 6.4: **not used; not needed.** The Claude subscription (`claude-cli`) is a working, no-key alternative for every semantic-pass need, so Ollama is never required.

---

## 8. Aspect 8 — Anything else that should be designed

### 8.1 Git hygiene: `graphify-out/` must never be committed (CI guard — measure-then-bound)

`graphify-out/` is a regenerated, gitignored build artifact (EE-2). Currently it does NOT exist in the repo and is NOT in `.gitignore` (EE-3/EE-5 — the `.gitignore` has no `graphify-out/` entry yet).

- **Step 1 — add `graphify-out/` to `.gitignore`** (pack-ops change; the file is pack-root, not project-template).
- **Step 2 — optional CI guard (OQ-8).** A validate-pack check "`graphify-out/` is never tracked" would be CHEAP: a single `git ls-files graphify-out/` (must be empty) — O(1), not a tree scan, so it satisfies the CI-runtime-compounding rule (the ~155× battery pays ~0). **Measure-then-bound:** at HEAD, `git ls-files graphify-out/` is empty (nothing to strip; the guard runs clean against current state). Allowlist sized to exactly zero tracked graph artifacts. **REC:** add the guard IF the user wants belt-and-suspenders; the `.gitignore` entry alone is usually sufficient. **OQ-8.**
- **Manifest interaction (EE):** `test-fixtures/manifest.txt` (Check 62) is unaffected — `graphify-out/` is gitignored, never a fixture input. N/A.

### 8.2 Supersede the stale 2026-05-11 graphify research docs

Three docs (`RESEARCH-GRAPHIFY-EXTERNAL.md`, `-PACK-INTEGRATION.md`, `-SYNTHESIS.md`, all dated 2026-05-11, EE-10) frame Graphify as a **client-feature deferred to v12** AND as pack-dev, against an **older version**. BD-225 reframes it as **pack-side, v11.0**. Per `feedback_fail_loud_delete_old_source` (delete superseded docs entirely) vs a lighter superseding note: these docs contain real external-research evidence (PyPI history, third-party reviews) that may still have reference value, but their *posture* (client-feature/v12) is now wrong and could mislead a future reader. **OQ-10:** does the user want (a) a one-line superseding banner at the top of each pointing to BD-225/this design + the new RESEARCH-BD-225 census, or (b) deletion (the new census + this design supersede them), or (c) move them into an archive dir (which would then auto-exclude them from the graph too)? **REC:** option (a) superseding banner — cheapest, preserves the external-research evidence, corrects the posture. Note: these docs live OUTSIDE the archive dirs so they WILL be indexed; an incorrect-posture doc in the graph is an argument for at least the banner.

### 8.3 Uninstalled extras (neo4j / falkordb / video) (EE-11)

Verified absent: `import neo4j`, `import falkordb`, `import faster_whisper` all fail; `matplotlib`(svg) and `pypdf`(pdf) present. **REC:** none of neo4j/falkordb/video are in scope for BD-225 — the pack has no Neo4j/FalkorDB target and no audio/video corpus. Do NOT install those extras. If a future export need arises it is a separate decision (install change). Flag to planner: any design that references `export neo4j/falkordb` or video transcription would `ModuleNotFoundError` on this machine.

### 8.4 MCP path (dormant) (EE-2)

`graphify-mcp` is installed but dormant (PLAN.md decision); MCP is a skill flag / module path, not a first-class CLI verb on 0.8.39 (research §4d). The plain query-CLI is sufficient for all three usage cases (aspect 1). **REC:** keep MCP dormant; not in scope. **OQ-9 (folds the cross-CLI question):** Codex `.toml` agents and the Antigravity plugin — do they get the graph-first rule too (trinity says the rule lives in all three root files; but Codex/Antigravity agent *invocation* of the CLI is platform-native)? This parallels BD-217's "Codex/Antigravity worktree" deferral. **REC:** put the rule in all three trinity files (parity) but treat Codex/Antigravity agent-side graph-querying as a confirm-with-user item, since I have not verified those agents inherit AGENTS.md/GEMINI.md the way Claude subagents inherit CLAUDE.md.

### 8.5 Global graph (cross-repo)?

PLAN.md describes a `~/.graphify/global-graph.json` merging several repos. **REC:** out of scope for BD-225 (which is THIS repo, pack-side). Not designed here.

---

## 9. Knob settings (query + build/perf) — each with logic

### 9.1 Query tuning knobs

| Knob | Default | **REC** | Logic |
|---|---|---|---|
| `--budget` | 2000 | **2000 human; 1500 agent; 1000 prompt-construction** | Bigger context helps interactive humans; agents/prompt-construction want tight subgraphs (REPO-QUICKSTART: "Lower it to keep subagent context tight"). |
| `--dfs` | off (BFS) | **default BFS; `--dfs` only for "how does X reach Y?" path-tracing** | references/query.md: BFS = broad neighbors (most pack questions); DFS = trace a specific chain. Per-question, not a global default. |
| `--context` | none | **accept default (none) unless an edge-context filter is clearly needed** | Filtering edge contexts is an advanced narrowing; premature filtering risks dropping relevant edges. Use only when a query is noisy. |
| `--depth` (affected) | 2 | **accept default 2** | Blast-radius depth 2 (direct + one hop) is the documented default and matches "what depends on X" without over-broadening. Raise to 3 only for a deep-impact audit. |
| `--relation` (affected) | all | **accept default (all) initially; constrain once edge-relation vocab is known** | Constraining relations needs knowledge of the actual edge types in THIS graph (only knowable post-build). Start broad. |
| `--graph` | `graphify-out/graph.json` | **ALWAYS absolute for agents/hooks: `$(git rev-parse --show-toplevel)/graphify-out/graph.json`** | Sub-agents/hooks may run from a different cwd (EE-2, non-negotiable). |

### 9.2 Build / perf knobs

| Knob | Default | **REC** | Logic |
|---|---|---|---|
| `--mode deep` | off | **OFF (accept default)** | Deep = more inferred edges, more tokens/time. On a 2.65M-word docs-heavy corpus, deep mode multiplies quota burn for marginal inferred-edge gain. Reserve for a one-off rich build if ever needed. |
| `--no-viz` | off | **ON for any full-repo build** | HTML viz refuses >5,000 nodes anyway and is wasteful (EE-2). We query `graph.json` directly; nobody opens the HTML in an agent flow. Skips a slow render. |
| `--max-workers` | cpu_count | **accept default** | AST subprocess count; CPU-bound, default is fine; only lower if the machine is contended. |
| `--no-cluster` | off | **OFF for the build that agents query; consider ON for fast intermediate refreshes** | Clustering (Leiden) powers community labels / god-nodes that make `query`/`explain` useful (EE-2). Keep it for the queried graph. Logic: the whole value is the clustered graph. |
| `GRAPHIFY_FORCE` | 0 | **0 (default); set only after a large deletion refactor** | Forces overwrite even when the rebuild has fewer nodes — only correct after intentional code/doc deletion, else it masks a broken extraction. |
| `GRAPHIFY_NO_BACKUP` | 0 | **0 (keep backups)** | The auto-backup of `graph.json` is cheap insurance against a bad rebuild; disabling it saves negligible space. |
| `GRAPHIFY_VIZ_NODE_LIMIT` | 5000 | **accept default (moot if `--no-viz`)** | We skip viz; the cap is irrelevant. |
| `GRAPHIFY_CLAUDE_CLI_PARALLEL` | 0 (off) | **0 / off — keep serial for the `claude-cli` hook** | The QuickStart says the `claude-cli` path is serial because parallel `claude -p` processes CONFLICT (EE-2). Enabling parallel risks corruption/quota spikes. Keep off. |
| `--token-budget` (extract) | 60000 | **accept default 60000** | Per-chunk semantic cap; default is tuned by the tool; no evidence a different value helps a docs-heavy repo. |
| `--max-concurrency` (extract) | 4 | **accept default 4** (NOT relevant to serial `claude-cli`) | This governs parallel semantic chunks; for the serial `claude-cli` backend it is effectively bounded by serialization. Leave default. |
| `--api-timeout` (extract) | 600 | **accept default 600s** | 10-minute per-request timeout is generous; large doc chunks can be slow. No reason to lower; lowering risks truncation. |

**Net build recipe (REC, pending OQ-6 scope):** initial build interactive `/graphify .` (parallel, faster) with `--no-viz`; refreshes via the doc-gated post-commit `graphify extract . --backend claude-cli` (serial, `GRAPHIFY_CLAUDE_CLI_PARALLEL` off, `--no-viz` implied for the headless refresh). All other knobs at default.

---

## 10. OPEN QUESTIONS (the user's decision queue — one at a time, full context)

Each is restated from its in-context home above so the user need not look elsewhere. My recommendation is given where evidence supports one; where it doesn't, I ask plainly.

- **OQ-1 — archive-named FILE.** Exclude `…/IMPLEMENTATION-REPORT-BD-175-BATCH-ARCHIVE.md` (archive in filename, not in an archive dir)? The hard rule is dir-scoped. **REC: index it** (live report; descriptive name). [§2.3]
- **OQ-2 — synthetic `.env` fixtures.** Index the 4 tracked synthetic `.env` fixtures, or exclude all `**/.env`? **REC: exclude** (conservative privacy default; negligible graph value; agents can Read 4 files). User decides A(index)/B(exclude). [§2.5]
- **OQ-3 — privacy-delta note.** Design the secrets-adjacency / classifier-refusal privacy note for `pack-ops/OPTIONAL-FEATURES.md` now (architect), or defer to planner? [§2.6/§8]
- **OQ-4 — worktree-hook tree.** Under worktree-isolation (BD-226/197), the orchestrator commits in the PARENT tree; which clone's `.git/hooks/post-commit` fires must be verified before any hook design. (Blocks concrete hook design.) [§3.2]
- **OQ-5 — semantic-refresh cadence.** Literal user direction = semantic on the post-commit hook. The QuickStart's documented anti-pattern for docs-heavy repos says that burns quota. **REC: doc-gated semantic refresh (Option 2)** + `check-update` safety net — automated, honors intent, avoids the anti-pattern. Confirm Option 1 (every commit) vs 2 (doc-gated) vs 3 (code-only auto + scheduled semantic) vs 4 (manual). [§3.3]
- **OQ-6 — initial-build scope (forced by corpus size).** The corpus trips both narrow-gates (1,373 files / 2.65M words). Build (a) whole repo anyway (large/slow semantic pass), (b) doc-scoped subgraph, or (c) per-area graphs? This is THE scope decision. **No REC without the user's value call on coverage-vs-cost.** [§0.1/§3.4]
- **OQ-7 — `graphify claude install`?** It writes a `## graphify` section + a PreToolUse hook into `settings.json`, Claude-file-only (breaks trinity symmetry). **REC: hand-author the trinity rule; do NOT run `graphify claude install`** (no surprise hook, trinity-symmetric). Confirm. [§5.1]
- **OQ-8 — CI guard for `graphify-out/`.** Add a cheap validate-pack check "`graphify-out/` never tracked" (O(1), battery-safe), or rely on `.gitignore` alone? **REC: `.gitignore` entry is sufficient; guard optional.** [§8.1]
- **OQ-9 — Codex/Antigravity parity.** Put the graph-first rule in all three trinity files (parity, REC yes), but confirm whether Codex `.toml` agents / the Antigravity plugin actually consume AGENTS.md/GEMINI.md the way Claude subagents consume CLAUDE.md (I have not verified). Parallels BD-217. [§8.4]
- **OQ-10 — stale 2026-05-11 research docs.** (a) superseding banner, (b) delete, or (c) move to an archive dir (also auto-excludes from graph)? **REC: (a) banner** (preserves external-research evidence, corrects the client-feature/v12 posture). [§8.2]

---

## 11. Empirical-Evidence Blocks (every state-claim)

> All commands run read-only at HEAD `47d8f600f376ce24e1c36a0e241f182529ad4fd6`, branch `v11-dev`, on 2026-06-18. No graph was built; no `.graphify*` config written; no repo file mutated.

**EE-1 — Indexable corpus trips the >500-file gate.**
- Cmd: `git ls-files | wc -l` → `1645`; `git ls-files 'maintenance-docs/archive/*' 'maintenance-docs/v11-research/templates-archive/*' | wc -l` → `272`. Indexable = 1645 − 272 = **1373**.
- Interpretation: 1373 > 500 → SKILL.md Step 2 narrow-gate fires. **SUPPORTED.**

**EE-2 — Graphify capability/constraint facts (CLI 0.8.39).**
- Cmd: `graphify --version` → `graphify 0.8.39`; `which graphify` → `/Users/david/.local/bin/graphify`; `graphify --help` (full surface captured) confirms `query --budget N (default 2000)`, `affected --depth N (default 2)`, `extract --backend ... (default: whichever API key is set)`, `extract --token-budget 60000 --max-concurrency 4 --api-timeout 600`, `hook install`, `claude install (… + PreToolUse hook)`. QuickStart/PLAN/SKILL/references read in full for: query=~0 tokens/literal matcher; semantic=subscription; auto-route foot-gun (`GEMINI_API_KEY`/`GOOGLE_API_KEY`/`OPENAI_API_KEY`); `claude-cli` serial; per-clone hooks/graph; absolute `--graph`; subagents don't inherit skills; "do not preload skill"; "docs-heavy → manual `--update` usually better"; secrets-adjacent classifier refusal; built-in always-pruned set; one-file-or-the-other.
- Interpretation: all load-bearing capability claims verified against the installed binary + read sources. **SUPPORTED.**

**EE-3 — Archive dirs/files at HEAD.**
- Cmd: `find . -type d -iname '*archive*' -not -path './.git/*'` → `./maintenance-docs/archive`, `./maintenance-docs/v11-research/templates-archive` (exactly 2). `git ls-files | grep -i archive | grep -v '/archive/' | grep -v 'templates-archive/'` → `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-BATCH-ARCHIVE.md` (1 archive-named file outside an archive dir).
- Interpretation: 2 archive dirs (HARD-RULE excludes), 1 ambiguous file (OQ-1). **SUPPORTED.**

**EE-4 — `.graphifyignore` disables `.gitignore` fallback; built-in prune set.**
- Source: REPO-QUICKSTART §"How `.graphifyignore` and `.gitignore` interact" (read in full): absent→uses `.gitignore`; present→uses ONLY `.graphifyignore`, never reads `.gitignore`; built-in always-pruned set (`graphify-out`,`node_modules`,`.git`,`.venv`,`build`,`dist`,`.next`,`target`,caches) applies on top of either.
- Interpretation: adding `.graphifyignore` for the archive dirs forces an explicit per-category gitignored decision. **SUPPORTED.**

**EE-5 — `.gitignore` categories + local presence.**
- Cmd: `cat .gitignore` (full, read); `git status --ignored --short`; presence checks: `.mcp.json` absent, `.claude/settings.local.json` absent, `.pack-tracker/` absent, `tracker.toml` absent, `generated/` dir absent, `__pycache__` ×2 present, `.DS_Store` present; `git ls-files | grep -E '/\.env$'` → 4 tracked synthetic fixture `.env` (negated by `!scripts/tests/fixtures/**/.env`); `graphify-out/` NOT present in `.gitignore`.
- Interpretation: drives the §2.4 per-category table and §8.1 (`graphify-out/` needs a `.gitignore` entry). **SUPPORTED.**

**EE-6 — All five pack agents already have `Bash`.**
- Cmd: grep of `tools:` in `.claude/agents/*.md` → architect `Read, Grep, Glob, Bash`; coder `Read, Grep, Glob, Bash, Write, Edit`; docs-researcher `Read, Grep, Glob, WebSearch, Bash`; planner `Read, Grep, Glob, Bash`; reviewer `Read, Grep, Glob, Bash, Write, Edit`.
- Interpretation: no agent needs a `tools:` change to query the graph; enablement = one trinity rule. **SUPPORTED.**

**EE-7 — `.md` word count over the 2M-word gate.**
- Cmd: `git ls-files '*.md' | grep -v archive-dirs | xargs wc -w | tail -1` → `2652681 total`.
- Interpretation: 2.65M words (`.md` alone, excl. archive) > 2,000,000 → word gate fires too. **SUPPORTED.**

**EE-8 — No graphify refs in pack-root trinity yet; sizes.**
- Cmd: `grep -l graphify CLAUDE.md AGENTS.md GEMINI.md` → none; `wc -l` → CLAUDE.md 602, AGENTS.md 561, GEMINI.md 550.
- Interpretation: clean slate for the graph-first rule. **SUPPORTED.**

**EE-9 — No graphify refs in `project-template/` (boundary clean).**
- Cmd: `git grep -in graphify -- 'project-template/'` → empty.
- Interpretation: boundary uncontaminated; design must keep it so. **SUPPORTED.**

**EE-10 — Stale 2026-05-11 research docs frame Graphify as client-feature/pack-dev, older version.**
- Cmd: `git ls-files | grep -i graphify` → `RESEARCH-GRAPHIFY-EXTERNAL.md`, `-PACK-INTEGRATION.md`, `-SYNTHESIS.md`; `head -12` of each → dated 2026-05-11; "optional component," "client project development," "deferred"-posture content.
- Interpretation: posture superseded by BD-225 (pack-side, v11.0); OQ-10. **SUPPORTED.**

**EE-11 — Extras: svg/pdf present; neo4j/falkordb/video absent.**
- Cmd: interp `/Users/david/.local/share/uv/tools/graphifyy/bin/python` → `import matplotlib` OK 3.11.0; `import pypdf` present; `import neo4j` / `import falkordb` / `import faster_whisper` → Traceback (absent).
- Interpretation: neo4j/falkordb/video out of scope (would `ModuleNotFoundError`); confirms research §4f. **SUPPORTED.**

**EE-12 — Output filename unique; CI invokes validate-pack as a battery.**
- Cmd: `find . -name DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md -not -path './.git/*'` → empty (unique). `.github/workflows/validate-pack.yml`: `python3 scripts/validate-pack.py` + `PACK_VALIDATE_DEEP=1 …`; comments reference the "151× battery path" → any new check must be O(1).
- Interpretation: safe to write; §8.1 guard must be cheap. **SUPPORTED.**

---

## 12. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Only read-only git run: `git rev-parse HEAD`, `git ls-files`, `git grep`, `git status --ignored`, `git branch --show-current`. No add/commit/push/checkout/etc. Sole write = this design doc via heredoc to the caller-specified path. | COMPLIANT |
| 2 | per-action-approval-sub-agents | No destructive op. No graph built, no `.graphify*` config written into the pack repo, no file mutated. All mutating actions surfaced as OQ-1…OQ-10 for the user. | COMPLIANT |
| 3 | agents-read-rule-docs-in-full | Read in full: `backlog/BD-225.md`, `RESEARCH-BD-225-GRAPHIFY-INCLUSION.md`, `REPO-QUICKSTART.md` (367 lines), `PLAN.md` (93), `SKILL.md` (~32KB), all 8 `references/*.md`; `CLAUDE.md` provided in full in context (incl. ## Pack memory); graphify.net via `curl -sL` (HTTP 200). | COMPLIANT |
| 4 | architect-planner-empirical-evidence | §11 carries 12 Empirical-Evidence Blocks (EE-1…EE-12), each with command + verbatim output + HEAD-SHA `47d8f60` + date 2026-06-18 + interpretation + SUPPORTED. Every state-claim in §0–§9 cites an EE-n or a read source. | COMPLIANT |
| 5 | ci-guard-design-measure-then-bound | §8.1: measured current state (`git ls-files graphify-out/` empty → nothing to strip; allowlist sized to zero tracked artifacts; guard runs clean against projected post-`.gitignore` state). §6.2 assert designed against the documented complete auto-route variable set. | COMPLIANT |
| 6 | ci-check-runtime-compounding | §8.1 guard bounded to O(1) `git ls-files graphify-out/` (no tree scan, no subprocess-per-entry); §11 EE-12 confirms the 151× battery path; explicitly "pays ~0." | COMPLIANT |
| 7 | pattern-matching-out-of-context-anti-pattern | §3.3 rejects the literal "semantic on every commit" pattern because the QuickStart documents it as a docs-heavy ANTI-pattern; recommends the doc-gated variant fitted to THIS repo's measured properties (1373 files / 2.65M words). §5.1 rejects `graphify claude install` despite its existence (trinity-asymmetry + surprise hook). | COMPLIANT |
| 8 | verify-availability-not-just-existence | EE-2 (`graphify --version` 0.8.39, `--help` surface), EE-11 (neo4j/falkordb/video import = Traceback; matplotlib/pypdf present) verify features on the actual installed target, not doc claims. | COMPLIANT |
| 9 | bd-pack-only / pack-project-separation | §1b/§5.1/§8 keep the boundary: graph MAY index `project-template/` (consumption) but every setup artifact (`.graphifyignore`, `.gitignore` entry, trinity rule, hook) is PACK-SIDE; graph-first rule in pack-root trinity, NEVER `project-template/` (EE-9 confirms currently clean). | COMPLIANT |
| 10 | user-prescriptive-authority | User constraints (subscription-only, no keys, no Ollama, archive-dir exclusion, claude-cli semantic refresh) treated as constraints; where a constraint (per-commit semantic) collides with evidence (docs-heavy anti-pattern) I surfaced it as OQ-5 with evidence, did not override. | COMPLIANT |
| 11 | triage-workflow-protocol | §10 lists OQ-1…OQ-10 each with full inline context (restated from its home), an evidence-based REC where supported, and a clear question; none guessed (OQ-6 explicitly carries NO rec pending the user's value call). | COMPLIANT |
| 12 | scope-deliverables-to-the-ask | Doc sections map 1:1 to the 8 aspects + both knob sets; no out-of-scope sprawl (global graph / MCP / extras explicitly scoped OUT in §8). | COMPLIANT |
| 13 | agent-output-rules-applied-block | This block: one row per in-force rule, quoted evidence, terminal conclusion (no AMBIGUOUS). | COMPLIANT |
| 14 | filename-uniqueness-heuristic | EE-12: `find . -name DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md -not -path './.git/*'` → empty before write. | COMPLIANT |
