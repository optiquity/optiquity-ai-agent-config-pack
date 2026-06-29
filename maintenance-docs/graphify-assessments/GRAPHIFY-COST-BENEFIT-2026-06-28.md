<!-- maintenance-doc (REFERENCE; history-exempt per BD-243 taxonomy). Canonical TRACKED Graphify cost/benefit assessment snapshot. Provenance: user-requested feasibility/data report (not a BD), 2026-06-28; HEAD 17d5ec4; graphify v0.8.39; graph FRESH. Reproduce via §9 Methodology. Related: BD-225 (graphify added), BD-237 (freshness-mechanism fix), BD-234 (graph cost/cadence assessment). -->

# Graphify — Cost vs Benefit Report

**Subject:** Graphify knowledge-graph tool (`graphify` v0.8.39) as used by the
AI Agent Config Pack repo.
**Prepared by:** pack-docs-researcher (read-only investigation; no rebuild, no commit).
**Date:** 2026-06-28 · **Repo HEAD at measurement:** `17d5ec4` · **Graph:** FRESH.
**Method:** all numbers are grounded in a command run or a file/field, and labeled
**MEASURED** / **ESTIMATED** / **QUALITATIVE**. No recall/precision benchmark was
run (the user asked for qualitative accuracy only); no graph rebuild was performed.

---

## 1. BOTTOM LINE — 30-second read

| Dimension | Figure | Label | Source |
|---|---|---|---|
| **Token reduction per query (avg)** | **56.0×** (~1,315,733 naive → ~23,499 graph) | MEASURED | `graphify benchmark` |
| **Realized per-query context (pack budget)** | ~**1,500–2,000 tokens** capped → ~**660–880×** vs naive | MEASURED (cap) + ESTIMATED (ratio) | pack `--budget` + benchmark corpus |
| **Model cost per query** | **~0** (deterministic BFS, no LLM call) | MEASURED | `--help` (query = BFS, no backend used) |
| **Build cost — code-only change** | **0 LLM tokens** (AST path) | MEASURED | `GRAPH_REPORT.md` "Token cost: 0 input · 0 output"; `update.md` |
| **Build cost — doc/markdown change (semantic)** | ~**10.5k–68.5k output tok/refresh** (recent); **2.04M** on each initial full build | MEASURED (per-build markers) | `.graphify_semantic_marker` ×8 snapshots |
| **Most-recent semantic refresh cost** | **99,101 input / 13,986 output tokens** | MEASURED | `.graphify_analysis.json` `tokens` field |
| **Build backend** | `claude-cli` subscription path (no API $ — costs subscription usage) | MEASURED | pack convention + `--help` backends |
| **Build/refresh cadence** | 8 semantic snapshots over ~10 days + per-push hook | MEASURED | dated snapshot dirs + `.pack-refresh-status` |
| **Query speed** | sub-second, deterministic | MEASURED | observed during this assessment |
| **Accuracy (recall/precision)** | **Graphify does NOT measure this** — qualitative read below: good for blast-radius/relationship discovery; recall is degraded when agents skip the required vocab-expansion step | QUALITATIVE | live `query`/`affected`/`path`/`explain` runs |
| **Realized-vs-potential gap** | Large. Feedback loop (`memory/`) **never used**; cross-repo `global` graph **never used**; cumulative `cost.json` tracker **never created**; staleness forced frequent grep fallback | MEASURED (absence) + QUALITATIVE | `memory/` absent, `~/.graphify` absent, `cost.json` absent |
| **Process health (freshness + instructions)** | Update process: reliable + fail-loud but **push-cadence** (graph STALE between pushes → mid-task grep fallback). Instructions: clear/correct on orchestration but **omit vocab-expansion** (recall) and **the feedback loop**. See §8. | QUALITATIVE | BD-237; pre-push hook; `graph-first-context` rule; `references/query.md` |

### Has it helped, and how much?

**Yes, on token economy — measurably and substantially.** A graph query answers a
"what-relates-to-X / blast-radius" question for **~1.5–2k tokens** instead of reading
a large slice of a ~1.3M-token corpus, at **~zero model cost** (the query is a
deterministic graph walk, not an LLM call). That is a real, repeatable saving on
every discovery-class question. The graph's *god nodes* and *INFERRED "surprise"
cross-links* (e.g. it auto-surfaced `Check 62 ↔ test-fixtures/manifest.txt` and
`manifest-sync.sh ↔ manifest.txt` as cross-file relationships) are genuine
blast-radius value you would not get from a single grep.

**But the realized benefit is well below the potential**, for three honest reasons:
1. **Staleness → grep fallback.** During heavy work the graph was often stale between
   pushes, so agents fell back to grep/Read (the rule's G2 path). A correct fallback,
   but it means the token saving was *not* banked on many real questions.
2. **Query quality was left on the table.** The tool's own docs require a
   *constrained vocab-expansion step* before each `query` (the binary does
   case-folded substring + IDF only — no stemming/synonyms). The pack's agents call
   `graphify query "<raw question>"` directly, which **degrades recall** (demonstrated
   below — a worktree-isolation question returned the agent-roster table, not the rule).
3. **Three free value-multipliers are unused:** the `save-result → memory/` feedback
   loop (never used), the `global` cross-repo graph (never used), and the cumulative
   `cost.json` tracker (never created — so there is no all-time spend ledger).

**Net:** Graphify has helped on token cost and on discovery quality where it was
queried well and fresh; the costs are modest and mostly one-time (initial builds) plus
small per-refresh; the biggest opportunity is *operational* (freshness + vocab
expansion + turning on the unused loops), not a tool deficiency.

### Low-effort recommendations (ranked)
1. **Adopt the vocab-expansion query flow** (`references/query.md` Step 0) in the pack
   agents' graph-query path — biggest recall win, zero token cost.
2. **Use the `save-result` feedback loop** — every good agent answer should
   `graphify save-result …` so the next refresh extracts it; `memory/` is empty today.
3. **Tighten freshness** — the per-push hook leaves the graph stale mid-session; a
   `graphify update .` (AST-only, **0 LLM tokens**) on code-only changes is free and
   would cut grep fallback.
4. **Create/keep `cost.json`** (or periodically snapshot the semantic markers) so spend
   is tracked going forward — today there is no cumulative ledger.
5. **Regenerate `GRAPH_REPORT.md` on refresh** — it is stale (built from `103cca8e`,
   dated 2026-06-22) while `graph.json` is at `17d5ec4`.

---

## 2. What information is available / possible to get (data-source inventory)

Two categories: **CLI verbs that emit data on demand**, and **local artifacts** in
`<repo>/graphify-out/`. For each I state what it yields *for a cost/benefit decision*,
and — per the "verify availability, not just existence" rule — what it does **NOT** give.

### 2a. CLI verbs (read-only, deterministic, ~0 model cost)

| Verb | Emits | Bears on cost/benefit |
|---|---|---|
| `benchmark [graph.json]` | corpus tokens, node/edge counts, avg query cost, **reduction ratio**, 5 per-question ratios | **The headline benefit number.** §3 below. |
| `query "<q>"` | BFS subgraph (nodes+edges) under a `--budget` token cap | The benefit *mechanism* — bounded context vs whole-file reads. |
| `affected "X"` | reverse-traversal blast radius of a node | Recall/precision evidence (§6). Requires exact node label. |
| `explain "X"` | plain-language node + neighbors | Recall evidence. Requires exact node label. |
| `path "A" "B"` | shortest path between two nodes | Relationship discovery (worked well, §6). |
| `diagnose multigraph` | edge-collapse/duplication health, suppression sites | Graph *quality/health*, not cost. Clean here (0 collapsed). |
| `global list` / `global path` | repos in the cross-repo graph | Reveals the `global` feature is **unused** (empty). |
| `check-update <path>` | sets/notifies a `needs_update` flag (cron-safe) | Freshness signal. Returned EXIT=0 silent here (graph fresh). |
| `tree` | D3 collapsible-tree HTML | Visualization, not cost data. |

**NOT available from any verb:** there is **no per-query invocation log** and **no
per-query timing/token meter**. `benchmark` reports an *average/representative* query
cost, not a record of the queries actually run by pack agents. So we can quantify
*potential* per-query saving precisely, but we **cannot reconstruct realized
cumulative query saving** from logs — that gap is called out honestly in §4.

### 2b. Local artifacts in `graphify-out/`

| Artifact | Size/state | What it contains that bears on cost/benefit | Limit / NOT-available |
|---|---|---|---|
| `graph.json` | ~20 MB, FRESH `17d5ec4` | the graph itself: **19,736 nodes / 27,357 edges**; `built_at_commit` | no token-cost field |
| `.graphify_analysis.json` | ~1.8 MB | **`tokens: {input: 99,101, output: 13,986}`** (last semantic build cost); 10 god nodes; 5 INFERRED "surprises"; per-community cohesion | reflects only the **latest** build, not cumulative |
| `.graphify_semantic_marker` | tiny, **per snapshot** | **`output_tokens` per build** — the surviving per-build cost trail (§3) | output tokens only; input only in analysis.json |
| `manifest.json` | ~296 KB | per-file `mtime + ast_hash + semantic_hash` — drives **incremental** rebuild (only changed files re-extracted) | not a cost log; explains *why* refreshes are cheap |
| `GRAPH_REPORT.md` | ~619 KB | corpus size, node/edge/community counts, **"Token cost: 0 input · 0 output"** (the AST/update path), god nodes, freshness note | **STALE** (built `103cca8e`, 2026-06-22) vs graph `17d5ec4` |
| 8 dated snapshot dirs | `2026-06-18`…`-28` (missing 21/25/26) | **the cadence + cost history** — each carries its own graph.json + semantic marker | snapshots are a side-effect of the pack hook, not a graphify feature |
| `cache/ast/` + `cache/semantic/` | 1,711 semantic + AST cache files | content-addressed extraction cache — the reuse that keeps refresh cheap | per-file extracted subgraph, not token counts |
| `.pack-refresh-status` | 65 B | `ok <SHA> <ISO-timestamp>` — last successful refresh | one line; no history (the snapshots are the history) |
| `memory/` | **ABSENT** | (would hold `save-result` Q&A for the feedback loop) | **never created → feedback loop never used** |
| `cost.json` | **ABSENT** | (the SKILL's Step 9 cumulative token tracker: per-run input/output/files + all-time totals) | **never created → no all-time spend ledger** (the pack hook bypasses the skill's Step 9) |
| `~/.graphify/global-graph.json` | **ABSENT** (dir doesn't exist) | (cross-repo merged graph) | **global feature never used** |

**Key availability finding:** the richest cost ledger the tool *can* keep
(`cost.json`, cumulative) was **never written**, because the pack refreshes via a
custom pre-push hook rather than the skill's full Step-9 pipeline. The **only**
surviving per-build cost data is the `output_tokens` in the 8 `.graphify_semantic_marker`
files plus the single `input/output` pair in the current `.graphify_analysis.json`.

---

## 3. BENEFIT — token reduction (MEASURED)

`graphify benchmark` on the fresh graph reported (verbatim):

```
  Corpus:          986,800 words → ~1,315,733 tokens (naive)
  Graph:           19,736 nodes, 27,357 edges
  Avg query cost:  ~23,499 tokens
  Reduction:       56.0x fewer tokens per query
  Per question:
    [537.9x] how does authentication work
    [361.7x] what is the main entry point
    [14.5x] how are errors handled
    [123.6x] what connects the data layer to the api
    [128.2x] what are the core abstractions
```

### What the 56× actually means (and its caveats)
- **Definition (verified via graphify docs):** the benchmark runs a BFS (default depth
  3) from the top-3 nodes matching each sample question, sizes that subgraph's tokens,
  and divides the **whole-corpus token estimate** by the **per-query subgraph tokens**.
  So "56×" = *naive read-the-whole-corpus* ÷ *graph-query subgraph*. **MEASURED.**
- **Caveat 1 — the baseline is the worst case.** "Naive" = reading the entire 1.3M-token
  corpus. A human/agent rarely reads the *whole* corpus; they grep a few files. So 56×
  is the ceiling vs the most wasteful baseline, **not** vs a skilled grep. Treat it as
  "graph vs brute force," which is the honest framing for *agent* context-loading
  (where brute-force whole-tree reads are the failure mode the graph-first rule exists
  to prevent).
- **Caveat 2 — the per-question spread is huge (14.5×–537.9×).** A focused, well-named
  question ("authentication") compresses enormously; a diffuse one ("how are errors
  handled," 14.5×) touches many nodes and compresses little. **Your mileage depends on
  question shape.** MEASURED.
- **Caveat 3 — the sample questions are graphify's generic defaults**, not pack
  questions. The pack's real questions ("blast radius of validate-pack.py," "where does
  the manifest get regenerated") are the relevant ones; §6 runs those qualitatively.
- **Caveat 4 — these are *generic-corpus* numbers; external write-ups cite 71.5×–79×**
  on other corpora. Our pack measures **56×**. Corpus-specific; do not import an
  external number.

### Realized per-query context is even smaller (MEASURED cap + ESTIMATED ratio)
The benchmark's "~23,499 avg query" uses graphify's **default 2000-token budget per the
BFS sizing**, but reports the *uncapped representative subgraph*. The **pack actually
caps queries at `--budget 1500–2000`** (per the graph-first rule). At a hard 2000-token
cap, the per-query context delivered to the agent is **≤ 2,000 tokens**, i.e.:

- vs the 1,315,733-token naive corpus → **~658× (at 2000) to ~877× (at 1500)** fewer
  tokens. **ESTIMATED** (cap is MEASURED; the ratio is naive-corpus ÷ cap).
- The trade-off: a tighter budget truncates the BFS (the tool literally printed
  *"truncated — N more nodes cut by ~2000-token budget; narrow with context_filter"*),
  so a too-tight budget can drop relevant nodes. Recall vs token-cost is a tunable.

### Query model cost ≈ 0 (MEASURED)
`query`/`affected`/`path`/`explain` are **deterministic graph traversals** — the
`--help` shows no LLM backend is consumed by these verbs (the `--backend` on the pack's
query invocation is inert for read verbs; backends are for *build/label*). So the
benefit is asymmetric: **near-zero marginal cost per query, paid for once at build.**

---

## 4. COST — token / Claude (build & refresh)

The cost is **all on the build/refresh side**; queries are ~free (§3). The build splits
into two paths with very different cost:

### (a) AST `update` path — code-only changes — **0 LLM tokens** (MEASURED)
`graphify update` re-extracts code structurally via AST with **no LLM call**. Evidence:
- `GRAPH_REPORT.md` Summary line: **"Token cost: 0 input · 0 output"** (this report was
  produced on an update/AST pass). MEASURED.
- `references/update.md`: *"If `code_only` is True: skip semantic extraction (no LLM
  needed)."* MEASURED (doc).

So any refresh whose changed files are **all code** is **free** in tokens. The pack,
however, is markdown-heavy (backlog/changelog/maintenance-docs), so most refreshes are
**not** code-only and hit the semantic path below.

### (b) Semantic `extract` path — doc/markdown changes — the real token cost (MEASURED per build)
Doc/markdown/image changes trigger LLM **semantic extraction** (`--backend`, default
`--token-budget 60000`/chunk). Per-build cost survives in `.graphify_semantic_marker`
(`output_tokens`) across the 8 snapshots:

| Snapshot | output_tokens | nodes | edges | built_at_commit |
|---|---:|---:|---:|---|
| 2026-06-18 | **2,040,684** | 3,135 | 7,782 | `ae9c4fa` |
| 2026-06-19 | **2,040,684** | 20,612 | 24,284 | `fd22afb` |
| 2026-06-20 | 12,463 | 19,506 | 25,756 | `3b3a774` |
| 2026-06-22 | 68,523 | 19,401 | 25,756 | `2780ada` |
| 2026-06-23 | 26,926 | 19,702 | 26,793 | `79179b1` |
| 2026-06-24 | 12,995 | 19,665 | 27,001 | `995d611` |
| 2026-06-27 | 10,584 | 19,654 | 26,995 | `79d8aa3` |
| 2026-06-28 | 13,683 | 19,733 | 27,325 | `eef7f11` |
| current root | 13,986 | 19,736 | 27,357 | `17d5ec4` |

Current `.graphify_analysis.json` `tokens` field (the matching input side):
**`input: 99,101 · output: 13,986`** — the most recent semantic refresh. MEASURED.

**Reading the table:**
- **Two ~2.04M-output initial full builds (6/18–6/19).** These are the one-time
  "stand up the graph" cost. The 6/18 build is the small first pass (3,135 nodes); 6/19
  is the first *full* corpus build (20,612 nodes). Together they dominate all spend.
- **Incremental refreshes (6/20 onward) are cheap: ~10.5k–68.5k output tokens each**,
  because `manifest.json`'s per-file `semantic_hash` lets graphify re-extract **only
  changed files** (the 1,711-file `cache/semantic/` is the reuse store). MEASURED.
- **Order-of-magnitude all-time semantic output (the 8 snapshots):**
  2,040,684 + 2,040,684 + 12,463 + 68,523 + 26,926 + 12,995 + 10,584 + 13,683
  ≈ **4.23M output tokens** across ~10 days. **MEASURED (sum of markers).**
  Caveat: snapshots are a *sample* (21/25/26 missing; intra-day pushes not snapshotted),
  so this is a **floor**, not a complete ledger — and the true all-time ledger
  (`cost.json`) was never written (§2b).
- **Input tokens** are only recorded for the *latest* build (99,101). Per-build input
  for the historical snapshots is **not available** (the marker stores output only).
  So an all-time *input* total cannot be reconstructed. Stated honestly.

### Cost framing — subscription, not API dollars (MEASURED context)
The pack builds with **`--backend claude-cli`**, the no-API-key **subscription** path.
So the cost is **subscription usage/quota**, not metered API $. The right mental model:
*the two ~2M-token initial builds were a one-time subscription-usage hit; ongoing
refreshes are small (~10–70k output tokens each).* For a Claude subscription this is a
minor recurring draw, front-loaded at setup. **No dollar figure is derivable** (no
per-token price on a subscription) — and the report deliberately does not invent one.

### Cadence (MEASURED)
8 semantic snapshots over 2026-06-18→28 (≈0.8/day average; bursty), **plus** a
per-push refresh via the pre-push hook (`.pack-refresh-status` last:
`ok 17d5ec4 2026-06-29T02:18:48Z`). Multiplying cadence × per-build cost: after the
one-time ~4M-token initial outlay, ongoing cost ≈ **(#doc-touching pushes) × ~10–70k
output tokens**; code-only pushes add ~0.

---

## 5. TIME — cost & savings

### Build/refresh time (ESTIMATED from snapshot timestamps)
No explicit build-duration field is recorded. Inferring from file mtimes within a
snapshot dir (extraction → graph.json → report):
- **Initial full build (6/19):** spans from `.graphify_semantic_marker` to graph.json
  write — a full 20k-node semantic extraction over a 1.3M-token corpus. With the
  default `--max-concurrency 4` and 60k-token chunks, a full build of this corpus is
  reasonably **minutes (order ~5–20 min)**. ESTIMATED (no duration logged; bounded by
  chunk-count × per-chunk latency).
- **Incremental refresh:** only changed files re-extract (often a handful of markdown
  files → ~10–14k output tokens), so **seconds-to-low-minutes**. ESTIMATED.
- **Pre-push latency:** the refresh runs in the **pre-push git hook**, so it adds the
  refresh time to **every push that touched indexed files**. For a doc-touching push
  that is a real, if modest, per-push tax; for code-only pushes the AST path is fast.
  This is the main *time cost* of the current setup. MEASURED (mechanism) + ESTIMATED
  (magnitude).

### Query time (MEASURED)
Every `query`/`affected`/`path`/`explain`/`diagnose` run in this assessment returned in
**sub-second to low single-digit seconds** — deterministic graph walks over a 20 MB
JSON. Effectively negligible.

### Time *savings* (ESTIMATED — clearly labeled)
The saving is **agent context-assembly time + the human/agent reading time** that a
graph query replaces. A discovery-class question answered by one ~2k-token graph query
replaces, conservatively, **several file Reads + greps** (each a tool round-trip the
agent must issue, receive, and parse). Rough estimate: **a graph query saves on the
order of 3–8 file-read/grep round-trips per discovery question**, i.e. seconds of
wall-clock and — more importantly — **thousands of context tokens** the agent does not
have to hold. This is **ESTIMATED**; there is no per-query timing log to measure it
(see §2a "NOT available"). The honest caveat: this saving is only banked **when the
agent actually queries the graph instead of grepping** — which, given the staleness
reality (§7), did not happen on every question.

---

## 6. ACCURACY (recall / precision) — QUALITATIVE

**Graphify does not measure accuracy.** `benchmark` measures *token reduction* only;
there is no recall/precision metric anywhere in the tool. This section is a **rigorous
qualitative read** from running **real pack questions** through the read-only verbs.
**No recall/precision percentages are fabricated.**

### What hard numbers would require (and why none are given)
A real recall/precision score needs a **controlled, labeled benchmark**: a set of pack
questions, a human-labeled gold set of the *correct* surfaces for each, then graph
output scored against that gold set (recall = found/should-find; precision =
relevant/returned). That experiment was **not** run (out of scope per the ask). Below is
evidence-based judgement, not measurement.

### Evidence — real queries run (verbatim observations)
1. **`path "init-project.sh" "detect.sh"` → STRONG.** Returned a real 2-hop path:
   `init-project.sh <--references-- PACK-REVIEW-C6 (BD-221) --references--> detect.sh`.
   Correct, useful, precise. (It warned the source match was *ambiguous* — a name-match
   caveat, below.)
2. **`affected "validate-pack.py"` / `affected "validate-pack"` → FAILED:**
   *"No unique node match."* `explain "manifest-sync.sh"` → *"No node matching … found."*
   **Precision/usability caveat:** `affected`/`explain` need the **exact node label**,
   not a file path or partial name. validate-pack.py *is* in the graph (it is a **god
   node** — see below), but the verb wouldn't resolve the bare filename. Agents must
   know the label, which is friction.
3. **`query "how does test-fixtures manifest get regenerated"` → MIXED.** Matched start
   nodes `['Manifest','Manifest']` and returned 27 nodes — but mostly **maintenance-docs
   section headings** (IMPL-REPORT-BD-211-C2, PACK-REVIEW-BD-214). It surfaced *related*
   docs but **not** the actual mechanism file (`manifest-sync.sh`) at the top — the
   literal "Manifest" matched a *doc heading*, not the script. **Moderate recall, noisy
   precision** for this phrasing.
4. **`query "worktree isolation rule coder reviewer cycle"` → RECALL MISS (instructive).**
   Matched on tokens `['reviewer','coder']` and returned the **PACK-FEEDBACK agent-roster
   table** (`project-template/docs/pack/PACK-FEEDBACK.md`) — **not** the actual
   worktree-isolation rule in `CLAUDE.md ## Pack memory`. The literal matcher latched on
   the wrong "reviewer/coder" occurrence. **This is the clearest precision/recall defect
   — and it is caused by skipping the required vocab-expansion step (below), not by a bad
   graph.**

### The root cause of the recall misses (verified in the tool's own docs)
`references/query.md` is explicit: the `query` binary matches nodes by **case-folded
substring + IDF only — no stemming, no synonyms, no cross-language match**. The
documented correct flow has a **mandatory Step 0: constrained vocab-expansion** — extract
the graph's actual label vocabulary, map the user's question onto up-to-12 *real* vocab
tokens, then query with the expanded string. **The pack's agents query with the raw
question and skip this step**, which is exactly why questions 3–4 above mismatched. This
is an **operational** gap, not a graph-quality gap — and it is the single biggest lever
on realized recall.

### Where the graph is genuinely accurate and valuable (positive evidence)
- **God nodes are right:** `.graphify_analysis.json` lists `validate-pack.py`,
  `validate-pack.py — CI structural validation`, the backlog/changelog TOCs, and key
  IMPL-REPORTs as the highest-degree hubs — these *are* the pack's real centers of
  gravity. Good precision on "what matters."
- **INFERRED "surprises" are real cross-links you'd miss with grep:** the analysis
  surfaced `Check 62 (manifest screen) ↔ test-fixtures/manifest.txt`,
  `manifest-inputs.sh ↔ manifest.txt`, and `manifest-sync.sh ↔ manifest.txt` as
  cross-file relationships (the exact manifest blast-radius). This is the
  discovery-class value the graph-first rule is for.
- **Graph health is clean:** `diagnose multigraph` → **0 collapsed / 0 duplicate / 0
  dangling / 0 self-loop edges** across 19,736 nodes / 27,357 edges. The structure is
  sound; the accuracy issues are query-phrasing, not corruption.

### Honest qualitative verdict
- **Relationship & blast-radius discovery (path / affected-by-label / god nodes /
  INFERRED links): GOOD** — surfaces the right + complete surfaces, low noise.
- **Natural-language `query` as the pack uses it (raw question, no vocab expansion):
  MODERATE-to-WEAK recall, variable precision** — it works for well-named concepts and
  misfires on diffuse or differently-worded ones.
- **Net:** the graph *contains* the right knowledge (verified via god nodes + surprises +
  clean diagnose); the **realized** accuracy is gated by **how it is queried** and **how
  fresh it is** — both fixable operationally (§7), neither a tool defect.

---

## 7. Anything else Graphify offers / recommends

Features present in v0.8.39 (verified via `--help` and the installed `SKILL.md`),
flagged by **whether the pack uses them**:

| Capability | What it does | Pack status | Note / graphify's own stance |
|---|---|---|---|
| `save-result` → `memory/` **feedback loop** | saves a Q&A back so the next refresh extracts it as a node — the graph learns from use | **UNUSED** (`memory/` never created) | `references/query.md` says to call it **after every** query/path/explain. Biggest free improvement. |
| `global` **cross-repo graph** | merge multiple repos into one queryable graph (`~/.graphify/global-graph.json`) | **UNUSED** (`global list` empty; `~/.graphify` absent) | Useful if you want pack + a project graph queried together. |
| `watch <path>` | foreground daemon, auto-rebuilds on file change | **UNUSED** | Per BD-237 capability census: a **foreground daemon** — not a fit for the pack's push-driven flow. |
| `check-update` | cron-safe staleness flag (`needs_update`) | available; ran EXIT=0 silent | Per BD-237: tracks pending **non-code** changes only — **not** "graph behind HEAD." Don't rely on it for freshness. |
| `diagnose multigraph` | edge-collapse/health audit | available (ran clean) | Good periodic health check; 0 issues today. |
| `tree` / `explain` / `path` | D3 viz / node explainer / shortest-path | path used well; tree/explain available | `path` is the strongest read verb observed. |
| `GRAPH_REPORT.md` | human report: god nodes, communities, freshness | present but **STALE** | Regenerate on refresh; currently from `103cca8e` (2026-06-22). |
| `cost.json` tracker | cumulative per-run input/output/files ledger | **never created** | The SKILL's Step 9 writes it; the pack's custom hook bypasses Step 9. |
| Vocab-expansion query flow | required pre-step for good `query` recall | **not adopted** | `references/query.md` Step 0 — the recall lever (§6). |
| `--mode deep`, exports (neo4j/graphml/svg/wiki/mcp) | richer inference / external tooling | unused | Out of scope for the pack's needs. |

**graphify's own recommendations (from docs / SKILL / upstream):**
- *Use the feedback loop* — newer upstream versions (v7/v8) extend `save-result` with
  outcome flags (`useful`/`dead_end`/`corrected`) + a `reflect` → `LESSONS.md` pass and
  time-decayed source scoring. **These are NOT in the installed v0.8.39** (its
  `save-result --help` has no outcome flags; no `reflect` verb) — a version-delta the
  pack should note before relying on them. **MEASURED (verb absence)** + WebSearch.
- *Keep it fresh between sessions* — upstream frames the post-commit/push hook as a
  freshness *optimization*, and notes `--watch` does **not** trigger semantic
  re-extraction for doc changes (issue #483) — consistent with BD-237's finding that the
  pack needed a deliberate semantic refresh path.
- *Support the project* if it saved you time (sponsor link in SKILL Step 9).

---

## 8. How well the PROCESS worked + how to improve it

This section assesses the *operational* layer — how the graph is **kept fresh** and how
agents are **told to use it** — since (per §1, §6) the realized benefit is gated more by
process than by the tool. **IDENTIFY + RECOMMEND only; no design, no implementation.**

### 8a. Graph-update process (freshness / refresh)

**Mechanism (MEASURED).** The graph is refreshed by a **tracked, self-installed,
non-blocking `pre-push` git hook** (`scripts/hooks/graphify-pre-push.sh`, installed via
`scripts/install-graphify-hook.sh`), per `pack-ops/OPTIONAL-FEATURES.md` §"How to keep
it fresh." On `git push` it derives a doc-gate, takes an atomic skip-lock, and runs a
**background-detached** refresh (semantic `extract` for a doc change, else the free
code-only `update`) then **unconditionally `exit 0`** so a refresh problem never blocks
the push. Freshness is judged locally by `graph.json` `built_at_commit` vs
`git rev-parse HEAD` (the pack-startup readiness line + the hook's next-run consult).

**History (MEASURED, from BD-237).** This is a *fixed* mechanism. BD-225 originally
shipped a **hand-installed `post-commit` recipe that was never installed → the graph
froze at its first build (2026-06-18 22:56)** and every 2026-06-19 commit was newer than
the graph. The user halted all v11.0 work ("everything immediately stops until this is
solved"); BD-237 redesigned it into the current tracked pre-push hook + freshness check.
So the *current* mechanism is materially better than what shipped — it cannot rot from
"nobody copied the recipe," and it fails loud on staleness at pack-startup.

**Judgement (QUALITATIVE).** The pre-push design is **sound for correctness but
structurally leaves a freshness window mid-task**:
- **Refresh only at push** means the graph is **STALE for the entire span between
  pushes** — exactly the heavy-work windows where agents ask the most discovery
  questions. The user observed `git push` printing *"graphify: graph is STALE …
  refreshing,"* and the 8 dated snapshots (≈0.8 builds/day, bursty, gaps on 6/21/25/26)
  confirm refresh is **push-cadence**, not work-cadence.
- The graph-first rule's **G2 fallback** (`grep/Read` when the graph "errors or returns
  nothing useful") and the **G1 degradation** clause ("a fresh clone has no graph, so the
  rule degrades with zero friction") mean a stale graph **silently routes agents to
  grep** — correct behavior, but it means **the token saving is not banked** on those
  questions. This is the single largest driver of the realized-vs-potential gap.
- The **semantic refresh is deliberately push-gated and main-session-scoped** (cost
  discipline: only the free code-only `update` is safe to automate unattended; the
  subscription `extract` is a deliberate action). That is the *right* cost trade-off —
  but it is *why* mid-session freshness is hard to improve without spending subscription
  tokens more often.
- **Non-blocking + background-detached** is good (push is never slowed meaningfully), but
  it also means a failed refresh is easy to not notice between pack-startup checks.

**Verdict (QUALITATIVE):** the update process is **reliable and correctly fail-loud, but
push-cadence freshness erodes mid-task benefit.** It keeps the graph *eventually* fresh,
not *continuously* fresh.

### 8b. Agent prompts / instructions process

**What agents are told (MEASURED).** The `graph-first-context` rule lives in the
pack-root trinity (`CLAUDE.md ## Pack memory`, with `AGENTS.md`/`GEMINI.md` variants).
It is **detailed and well-structured**: G1 existence guard, G2 fallback, an explicit
**two-phase** model (DISCOVERY/RECALL is graph-FIRST and mandatory when a graph exists;
VERIFICATION/PRECISION is grep/Read's job), a precise list of 5 legitimate
grep-fall-through cases, the **worktree path-injection contract** (the orchestrator
evaluates `$(git rev-parse --show-toplevel)/graphify-out/graph.json` at runtime and
**injects the absolute `--graph` literal** into every spawn prompt — the agent never
recomputes it from its own toplevel), and the invocation params (`--budget`
2000/1500/1000 by caller tier; **always** `--backend claude-cli`; never preload the
32KB skill). This is **clear, correct, and unusually rigorous.**

**Where it breaks down (QUALITATIVE, evidence-based):**
1. **The required vocab-expansion step is NOT in the pack's instructions.** The rule
   tells agents *when* to query and *how to inject the path/budget/backend*, but it does
   **not** carry `references/query.md`'s mandatory **Step 0 vocab-expansion**. So agents
   issue `graphify query "<raw question>"` — which (§6, questions 3–4) **mismatches on
   literal substrings** (the worktree-isolation question returned the agent-roster
   table). The instruction is correct about *orchestration* but **omits the single step
   that most affects recall.**
2. **Theory-vs-practice adherence gap.** Even with a clear rule, during recent heavy work
   agents **frequently fell back to grep/Read** for two legitimate reasons: (a) the graph
   was **stale** between pushes (8a), and (b) many surfaces were **already named** in the
   prompt (a P2/verification need, a sanctioned fall-through). Both are *rule-compliant*,
   but the net effect is the graph was **consulted less in practice than the rule implies
   in theory** — so the discovery-widening benefit (catching surfaces you didn't think to
   grep for) was under-realized.
3. **No feedback-loop instruction.** Nothing tells agents to `save-result` after a good
   answer, so `memory/` stays empty and the graph never learns from use (§7).
4. **`--backend claude-cli` on read verbs is inert but harmless** — the rule mandates it
   for safety (avoid an accidental API-key path), which is correct defense-in-depth even
   though read verbs don't call a model.

**Verdict (QUALITATIVE):** the instructions are **clear, correct, and well-engineered on
orchestration** (path injection, budget tiers, two-phase discovery), but have **two real
gaps** — no vocab-expansion guidance (hurts recall) and no feedback-loop guidance (graph
never learns) — and their **realized adherence is throttled by staleness**, so the graph
is consulted less than designed.

### 8c. Improvement opportunities (IDENTIFY-ONLY — a menu, not a decision)

For each: what it addresses, rough effort/risk, and whether graphify recommends it.
**None is chosen or designed here** — any pick becomes its own architect/BD later.

**Freshness / update process:**

| Option | Addresses | Effort / Risk | graphify's stance |
|---|---|---|---|
| Free **code-only `update` on a more frequent trigger** (e.g. post-commit, or a pack-startup/session-start refresh) | mid-task staleness for code changes at **0 LLM tokens** | Low effort / low risk (AST path is free + fast) | Recommended — `update` is the zero-cost path graphify itself promotes |
| **Deliberate semantic refresh at session start** (main-session `extract`) when docs changed | staleness for the markdown-heavy pack where most changes are docs | Medium effort / **subscription-token cost** (must stay a deliberate main-session action per BD-237 cost discipline) | Partially — graphify supports it; the *cost* makes it a judgement call |
| **`check-update` as a periodic signal** to prompt a refresh | surfacing pending non-code staleness | Low effort / low risk | graphify ships it cron-safe — but note it does **not** detect "graph behind HEAD" (BD-237) |
| **`watch` mode** | continuous auto-rebuild | Low-medium / **runs a foreground daemon; does not semantic-re-extract docs** (issue #483) | graphify ships it but it is a poor fit for push-driven pack flow (BD-237) |
| **Regenerate `GRAPH_REPORT.md` on each refresh** | the stale human report (2026-06-22) | Low / low | Implicit in the full pipeline |
| **Start writing `cost.json`** (or snapshot semantic markers) | no cumulative spend ledger today | Low / low | The SKILL's Step 9 writes it; the pack's custom hook bypasses it |

**Instruction / query process:**

| Option | Addresses | Effort / Risk | graphify's stance |
|---|---|---|---|
| **Add the vocab-expansion Step 0** to the pack's query guidance | the #1 recall driver (§6 misses) | Low-medium / low (it's the documented correct flow) | **Strongly recommended** — `references/query.md` makes it mandatory |
| **Adopt the `save-result` feedback loop** in agent post-answer flow | empty `memory/`; graph never learns | Medium / low (must keep it agent-`save`, build still main-session) | **Recommended** — the loop is graphify's growth mechanism |
| **Clearer "query-by-label" guidance for `affected`/`explain`** | the "no unique node match" failures (§6) | Low / low | Implicit (verbs need labels, not paths) |
| **Freshness-gated query guidance** (when the graph is stale, prefer grep — already the de-facto behavior; make it explicit + cheap to check) | makes the theory-vs-practice gap explicit & auditable | Low / low | Aligns with G1/G2 |
| **Consider the upstream v7/v8 `save-result` outcome flags + `reflect`/`LESSONS.md`** | self-improving work-memory | Higher / **requires a graphify upgrade** from 0.8.39 | graphify is actively building this; verify before relying |

---

## 9. Methodology — how to reproduce this report (apples-to-apples over time)

This section is a concrete, ordered recipe so a **future run produces a directly
comparable report** for tracking Graphify cost/benefit over time. Every step uses only
**read-only, deterministic** verbs and file reads — **reproduction never costs a build.**
Each figure keeps its **MEASURED / ESTIMATED / QUALITATIVE** label so trends compare
like-for-like.

### 9.0 Constraints (read-only — never costs a build)
- **Allowed:** `graphify benchmark`, `query`, `affected`, `explain`, `path`,
  `diagnose multigraph`, `global list/path`, `check-update`; plus reading
  `graphify-out/` artifacts, `git` read verbs, and WebSearch for upstream docs.
- **FORBIDDEN (would cost subscription tokens/time + change the graph):** `extract`,
  `update`, `watch`, `label`, `cluster-only`, `add`, `hook install`, any build/refresh,
  any state-changing git verb. Do NOT run these in an assessment.
- **Pin the run context first** (record these in the new report's header):
  ```bash
  graphify --version                 # confirm the binary version (was 0.8.39)
  git rev-parse HEAD                  # repo HEAD at measurement
  cat graphify-out/.pack-refresh-status   # last refresh: "ok <SHA> <ISO-time>"
  python3 -c "import json;d=json.load(open('graphify-out/graph.json'));print('built_at_commit=',d.get('built_at_commit'))"
  ```
  **Freshness gate:** if `built_at_commit` != `git rev-parse HEAD`, the graph is STALE —
  note it (it affects the realized-vs-potential read), but DO NOT rebuild to "fix" it.

### 9.1 BENEFIT — token reduction (MEASURED)
```bash
graphify benchmark graphify-out/graph.json
```
Record verbatim: **Corpus** (words → ~tokens naive), **Graph** (nodes, edges),
**Avg query cost** (~tokens), **Reduction** (×), and the **5 per-question ratios**.
- The headline "N×" = naive-corpus-tokens ÷ avg-query-subgraph-tokens (BFS depth-3 from
  top-3 matching nodes — graphify's fixed methodology). MEASURED.
- **Realized cap ratio (MEASURED cap + ESTIMATED ratio):** divide the naive-corpus
  tokens by the pack's query budget (1500–2000) for the "what the agent actually
  receives" ratio.

### 9.2 COST — build/refresh tokens (MEASURED)
- **Latest semantic build cost (input+output):**
  ```bash
  python3 -c "import json;print(json.load(open('graphify-out/.graphify_analysis.json'))['tokens'])"
  # -> {'input': N, 'output': M}
  ```
- **Per-build output-token history (the cost trail across refreshes):**
  ```bash
  for d in graphify-out/2026-*; do printf "%s : " "$d"; cat "$d/.graphify_semantic_marker"; echo; done
  cat graphify-out/.graphify_semantic_marker   # current root build
  ```
  Each `{"output_tokens": N}` is one build's semantic LLM output cost. The initial full
  builds are the ~2M-token outliers; incrementals are ~10–70k. MEASURED.
  Caveat to repeat each run: the marker stores **output only** (no per-build input);
  all-time **input** is not reconstructable. Snapshots are a **sample** (gaps exist) →
  the summed total is a **floor**, label it MEASURED (floor).
- **Free AST path confirmation (MEASURED):** `GRAPH_REPORT.md` Summary line
  `Token cost: 0 input · 0 output` confirms code-only `update` is zero-token.
- **Backend / cost framing (MEASURED context):** the pack builds with
  `--backend claude-cli` (subscription, no API $). Report cost as subscription usage,
  not dollars — do NOT invent a $ figure.

### 9.3 CADENCE (MEASURED)
```bash
ls -d graphify-out/2026-* | wc -l           # number of dated semantic snapshots
ls -d graphify-out/2026-*                    # the dates (note gaps = missed days)
cat graphify-out/.pack-refresh-status        # last push-refresh timestamp
```
Count snapshots over the date span for builds/day; note the per-push hook adds
push-time refreshes on top. MEASURED.

### 9.4 TIME (MEASURED query / ESTIMATED build+savings)
- **Query time:** observe wall-clock of the §9.5 verbs (sub-second/low-seconds).
  MEASURED.
- **Build duration:** not logged — infer from snapshot-dir file mtimes (extraction →
  graph.json → report). Label ESTIMATED; state "no duration field."
- **Savings:** ESTIMATED only (no per-query log exists). Express as "one ~2k-token graph
  query replaces ~3–8 file-read/grep round-trips" and label ESTIMATED.

### 9.5 ACCURACY — QUALITATIVE (fixed probes + rubric)
Run the **same probe set** each time so the qualitative read is comparable. These are
read-only and ~0-cost. (If the pack's surfaces change materially, keep these AND add new
probes, noting the addition.)

**Fixed probe set (run verbatim):**
```bash
G=graphify-out/graph.json
graphify query "how does test-fixtures manifest get regenerated" --graph $G --budget 2000 --backend claude-cli
graphify query "worktree isolation rule coder reviewer cycle"     --graph $G --budget 1500 --backend claude-cli
graphify query "graph-first context rule for spawned agents"      --graph $G --budget 1500 --backend claude-cli
graphify affected "validate-pack"                                  --graph $G --depth 2   --backend claude-cli
graphify explain  "manifest-sync.sh"                              --graph $G             --backend claude-cli
graphify path     "init-project.sh" "detect.sh"                  --graph $G             --backend claude-cli
graphify diagnose multigraph --graph $G        # health: expect 0 collapsed/dup/dangling/self-loop
```
Also capture the structural-quality signals (god nodes + INFERRED "surprises"):
```bash
python3 -c "import json;d=json.load(open('graphify-out/.graphify_analysis.json'));print('GODS',[ (g.get('label') or g) if isinstance(g,dict) else g for g in d.get('gods',[])[:10]]);print('SURPRISES',len(d.get('surprises',[])))"
```

**Judging rubric (apply identically each run — QUALITATIVE):**
- **Relevance / recall:** did the result surface the RIGHT and COMPLETE surfaces the
  question targets? Score each probe **GOOD / MODERATE / WEAK** with the concrete
  hit/miss (e.g. "returned the agent-roster table, NOT the worktree rule = WEAK").
- **Precision:** is the output free of noise (wrong-context substring matches, unrelated
  doc headings)? Note any literal-substring mismatches.
- **Verb usability:** record any `"No unique node match"` / `"No node matching"` for
  `affected`/`explain` (they need exact node labels, not file paths) — a stable
  usability caveat to track.
- **Structural quality:** god nodes should be the repo's real hubs; `diagnose` should
  stay 0/0/0/0.
- **Do NOT fabricate recall/precision percentages.** Hard numbers would require a
  controlled labeled benchmark (a gold set of correct surfaces per question, scored
  against graph output) — explicitly out of scope for this read-only assessment.

### 9.6 UNUSED-LOOP / LEDGER STATUS (MEASURED absence)
```bash
ls graphify-out/memory/ 2>&1        # ABSENT/empty => save-result feedback loop unused
ls ~/.graphify 2>&1                 # ABSENT => global cross-repo graph unused
ls graphify-out/cost.json 2>&1      # ABSENT => no cumulative token ledger
graphify global list                # "empty" => confirms global unused
stat -f "%Sm" graphify-out/GRAPH_REPORT.md  # vs graph.json mtime => report staleness
```
Each absence is a MEASURED finding; track whether status changes between runs.

### 9.7 PROCESS-HEALTH line (QUALITATIVE)
Re-derive the §8 read each run: (a) is the refresh still push-cadence (graph stale
between pushes)? — check `built_at_commit` vs HEAD + the `git push` "graph is STALE …
refreshing" signal; (b) do the agent instructions (`graph-first-context` rule +
`references/query.md`) include vocab-expansion and the feedback loop yet? Grep the
trinity for the rule and check whether Step-0 vocab-expansion was adopted.

### 9.8 What to compare between runs (the trend table)
Diff these figures run-over-run; a "meaningful change" guide:

| Figure | Label | Meaningful change = |
|---|---|---|
| benchmark reduction × (and avg query tokens) | MEASURED | ±20% in × or a node/edge swing tracking corpus growth — confirms compression holds at scale |
| per-build semantic `output_tokens` (latest + recent range) | MEASURED | a sustained rise in *incremental* cost (was ~10–70k) signals heavier doc churn or cache misses |
| `tokens.input` (latest build) | MEASURED | large jumps = bigger corpus or more re-extraction |
| cadence (snapshots/day + push refreshes) | MEASURED | more frequent refresh = less staleness (good) but more subscription draw (cost) |
| unused-loop/ledger status (memory/, global, cost.json, GRAPH_REPORT freshness) | MEASURED (absence) | any flips from ABSENT→present = a recommendation was adopted |
| accuracy probe scores (the 7 fixed probes) | QUALITATIVE | a probe moving WEAK↔GOOD = recall changed (often a vocab-expansion or freshness effect) |
| process-health line (freshness cadence + instruction gaps) | QUALITATIVE | vocab-expansion/feedback-loop adopted, or freshness moved from push-cadence toward work-cadence |

Keep the labels fixed so trends are honest: a MEASURED figure only ever compares to
another MEASURED figure; never promote an ESTIMATED or QUALITATIVE read to a hard trend.

---

## Appendix A — Method, confidence, and what is NOT knowable

- **MEASURED** = a command run in this assessment or a value read from a file/field
  (cited inline). **ESTIMATED** = derived (ratio, bound, or inference) with the method
  stated. **QUALITATIVE** = judgement from observed behavior, no metric.
- **Highest-confidence figures:** the 56× benchmark, the per-build `output_tokens`
  markers, node/edge counts, the `tokens:{input,output}` field, and all
  feature-presence/absence findings (memory/, cost.json, ~/.graphify, GRAPH_REPORT
  staleness) — all direct reads.
- **Lower-confidence figures (clearly flagged):** build *duration* (no duration field),
  per-query *realized* saving (no per-query log), all-time *input* tokens (markers store
  output only), the 660–877× realized-cap ratio (cap measured, ratio computed).
- **NOT knowable from current artifacts:** (1) a complete all-time token ledger
  (`cost.json` never written; snapshots are a sample); (2) realized cumulative query
  savings (no invocation log); (3) hard recall/precision numbers (no labeled benchmark
  was run, by design).

## Appendix B — Sources

Commands run (read-only): `graphify --version/--help`, `graphify benchmark`,
`graphify query` (×4 real questions), `graphify affected` (×2), `graphify explain`,
`graphify path`, `graphify diagnose multigraph`, `graphify global list/path`,
`graphify check-update`. Files read: `graphify-out/{.graphify_analysis.json,
.graphify_semantic_marker, .pack-refresh-status, manifest.json, GRAPH_REPORT.md,
graph.json (metadata), cache/}`, the 8 dated snapshot dirs, `backlog/BD-237.md`,
`pack-ops/OPTIONAL-FEATURES.md`, pack-root `CLAUDE.md` (`graph-first-context`),
`~/.claude/skills/graphify/SKILL.md` + `references/{query,update}.md`.

Web (graphify upstream, to confirm capabilities/recommendations vs v0.8.39):
- [graphify — GitHub (safishamsi/graphify)](https://github.com/safishamsi/graphify)
- [graphify CLI Reference — DeepWiki](https://deepwiki.com/safishamsi/graphify/4.1-cli-reference)
- [graphify.net — project site](https://graphify.net/)
- [Issue #1441 — self-improving work memory / reflect pass](https://github.com/safishamsi/graphify/issues/1441)
- [Issue #483 — watch mode does not trigger semantic re-extraction](https://github.com/safishamsi/graphify/issues/483)
- [Steve Scargall — Graphify token-reduction write-up](https://stevescargall.com/blog/2026/05/graphify--memmachine-79-token-reduction-zero-vector-database/)

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **scope-deliverables-to-the-ask** | Report leads with a 30-second bottom-line table (§1), then covers all 7 charges (§2 available data, §3 token-reduction benefit, §4 token/Claude cost, §5 time, §6 accuracy qualitative, §7 anything-else), the user-directed §8 process section, and the user-directed §9 Methodology; no unrelated graph analysis added. | COMPLIANT |
| **verify-availability-not-just-existence** | For each data source I confirmed whether it actually yields cost/benefit data and stated gaps: "**no per-query invocation log**"; "**no per-query timing/token meter**"; `cost.json` "**never created**" (ran `ls` → "No such file"); `memory/` "**No such file or directory**"; `~/.graphify` "**No such file or directory**"; `GRAPH_REPORT.md` "**STALE** (built `103cca8e`)". `check-update` ran EXIT=0 silent (verified it is not a "behind-HEAD" signal, per BD-237). | COMPLIANT |
| **prompts-grounded-in-facts / honesty** | Every figure carries a MEASURED/ESTIMATED/QUALITATIVE label and an inline source (command output or file/field). Benchmark quoted verbatim; per-build tokens quoted from `.graphify_semantic_marker` ×8; `tokens:{input:99101,output:13986}` from analysis.json. Realized-vs-potential gap surfaced honestly (staleness + unused loops). No recall/precision percentages fabricated (§6 explicitly states what a labeled benchmark would require). Appendix A states what is NOT knowable. | COMPLIANT |
| **agents-never-commit** | Only read-only graphify verbs + file Reads + WebSearch were run; no `extract`/`update`/`watch`/`label`/`cluster-only`/build/refresh; no `git add`/`commit`/`push`/any state-changing git verb. The sole write is this report at the caller-specified path. | COMPLIANT |
| **graph-first-context** | The graph IS the subject; I queried it read-only to assess it: `query` (×4), `affected` (×2), `explain`, `path`, `diagnose multigraph` against the injected `--graph /Users/.../graphify-out/graph.json`; used grep/Read for artifacts; never blocked (when `affected`/`explain` returned "no unique match" I noted it as evidence and moved on). | COMPLIANT |
| **methodology-reproducible + repo-write (follow-up)** | §9 gives an ordered, read-only recipe: exact commands per MEASURED figure (`graphify benchmark`; `.graphify_analysis.json` `tokens`; per-snapshot `.graphify_semantic_marker`; `GRAPH_REPORT.md` `Token cost` line; cadence from `ls -d graphify-out/2026-*`; the `--budget`/`--backend` query convention; `built_at_commit`-vs-HEAD staleness), a FIXED 7-probe accuracy set + judging rubric (GOOD/MODERATE/WEAK; no fabricated %), explicit read-only constraints (no `extract`/`update`/`watch`/build), and a run-over-run trend table — every figure keeps its MEASURED/ESTIMATED/QUALITATIVE label. Repo write: filename uniqueness verified (`git ls-files | grep -i GRAPHIFY-COST-BENEFIT` → RC=1, no match; no untracked collision in `maintenance-docs/`); dir `maintenance-docs/graphify-assessments/` created; canonical copy written to `maintenance-docs/graphify-assessments/GRAPHIFY-COST-BENEFIT-2026-06-28.md`. | COMPLIANT |
| **rules-applied-verification-block** | This block ends the report; each in-force rule has quoted evidence + a terminal COMPLIANT conclusion (no AMBIGUOUS, no empty evidence). | COMPLIANT |

*End of report.*
