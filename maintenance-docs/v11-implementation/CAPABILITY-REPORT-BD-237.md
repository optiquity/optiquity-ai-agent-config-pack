# graphify 0.8.39 Capability Verification — BD-237

**Agent:** `pack-docs-researcher` (READ-ONLY capability verification)
**Repo:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Branch / HEAD at runtime:** `v11-dev` / `190e1985cbb8164d619d571a28d8c3228d3c6981`
**Tool under test:** `graphify 0.8.39` (uv tool `graphifyy`, launcher `/Users/david/.local/bin/graphify`)
**Package source inspected:** `/Users/david/.local/share/uv/tools/graphifyy/lib/python3.12/site-packages/graphify/`
**Date:** 2026-06-19

All claims below are grounded in (a) the installed CLI's actual output, (b) the
installed package source, or (c) the source guides — guides are treated as
CLAIMS-TO-VERIFY, never truth. Web/official docs were **not needed**: the CLI +
source settled every question.

---

## HEADLINE FINDING (corrects the BD-237 premise)

**A built-in git-hook installer DOES exist in 0.8.39, and the BD-237 task
premise is factually wrong on both counts.**

1. The BD-237 premise states *"the top-level `graphify --help` shows NO `hook`
   subcommand."* **This is FALSE for 0.8.39.** The top-level `graphify --help`
   explicitly lists three hook subcommands:
   ```
   hook install            install post-commit/post-checkout git hooks (all platforms)
   hook uninstall          remove git hooks
   hook status             check if git hooks are installed
   ```
2. The BD-237 premise states the *source guide over-promised `graphify hook
   install`*. **Also FALSE.** The guide (`REPO-QUICKSTART.md` §C, line 185 +
   line 235) correctly describes `graphify hook install` as the **code-only**
   built-in, and **correctly** says the SEMANTIC refresh needs a SEPARATE,
   hand-written `.git/hooks/post-commit` running `graphify extract . --backend
   claude-cli` ("This is **not** `graphify hook install` (that one is
   code-only)").

**The real BD-237 defect is therefore NOT a missing/over-promised capability.**
It is: the hand-written **semantic** post-commit hook (the guide's separate
recipe) was never installed and never verified, so the graph silently froze.
`graphify hook status` confirms NEITHER hook is installed in this repo:
```
$ graphify hook status
post-commit: not installed
post-checkout: not installed
```
And the graph is demonstrably behind HEAD: `graph.json` carries
`"built_at_commit": "fd22afb7…"` while HEAD is `190e1985…`.

**Consequence for the redesign:** the architect can choose between (a) the
built-in `graphify hook install` (code-only, robust, worktree-aware,
self-detaching, cross-platform) and (b) a hand-written semantic hook (LLM,
subscription cost). The built-in is real and reusable for the **code** layer;
the semantic layer still needs a custom hook OR a scheduled `extract` run. The
freshness/verification check should key on `graph.json`'s `built_at_commit`,
NOT on `check-update`/`needs_update` (see Q4/Q5 — those only signal pending
**non-code** changes, not general staleness).

---

## Capability Matrix

| Capability | EXISTS in 0.8.39? | Command verified | Actual behavior (quoted/observed) | Source |
|---|---|---|---|---|
| Built-in git-hook installer (`hook install`) | **YES** | `graphify --help`; `graphify hook status` | Top-level help lists `hook install/uninstall/status`. `hooks.py:install()` writes BOTH `post-commit` + `post-checkout`, marker-guarded, `chmod 0755`, **detached** background rebuild, **code-only** (`_rebuild_code`, no LLM). Worktree-aware (`_hooks_dir` uses `git rev-parse --git-path hooks`, hooks.py:317-338). Honors `core.hooksPath`/Husky. `hook status` → `post-commit: not installed / post-checkout: not installed` here. | CLI + source (`hooks.py`) |
| `graphify install` (skill copy) | **YES** (distinct from hooks) | `graphify install --help` | `Usage: graphify install [--project] [--platform P|P]` — copies the **skill to a platform config dir** (claude, codex, gemini, …). Does **NOT** install git hooks. Confirms hooks are a SEPARATE `hook install` command. | CLI |
| `hook --help` / `hook install --help` | partial | `graphify hook --help` | Prints generic `Run 'graphify --help' for full usage.` (exit 0). Dispatch (`__main__.py:2647`) only matches `install`/`uninstall`/`status`; `--help` falls through to usage. No per-subcommand help — not a defect, just thin. | CLI + source |
| `update <path>` (code-only refresh) | **YES** | `graphify --help` (`update`); source `__main__.py:3294`, `watch.py:_rebuild_code` | "re-extract code files and update the graph (**no LLM needed**)". Deterministic AST/tree-sitter, ~0 tokens. **BUILDS if no graph exists** (full corpus when no change-list; `existing_graph_data` defaults to `{}`), AND refreshes incrementally. Recovers scan root from `graphify-out/.graphify_root`. | CLI + source |
| `update --force` | **YES** | `graphify --help` | "overwrite graph.json even if the rebuild has **fewer nodes** … use after refactors that delete code." Also `GRAPHIFY_FORCE=1` env. Bypasses the node-shrink safety check. | CLI + source (`__main__.py:3300`) |
| `update --no-cluster` | **YES** | `graphify --help` | "skip clustering, write **raw extraction** only" (`__main__.py:3303`; `watch.py:585`). | CLI + source |
| `extract <path>` (AST + semantic LLM) | **YES** | `graphify --help` (`extract`); source `extract.py`, `__main__.py:3930` | "headless full extraction (**AST + semantic LLM**) for CI/scripts." AST phase is deterministic; semantic phase calls the LLM backend ONLY for cache-miss files. | CLI + source |
| `extract` semantic cache (incremental) | **YES — content-keyed, gates re-extraction** | source `__main__.py:4274-4283`, `cache.py` | `check_semantic_cache(paths)` returns `(cached_nodes, …, uncached_paths)`; **only `uncached_paths` hit the LLM**. Prints exactly `[graphify extract] semantic cache: {N} hit / {M} miss` (`__main__.py:4283`) — matches the observed "1051 hit / 66 miss". Semantic cache is **content-hash keyed and NOT version-namespaced** (`cache.py:22-24`) so unchanged files never re-bill. AST cache IS version-namespaced (`cache/ast/v{version}/`). | source |
| `extract --backend claude-cli` (subscription, NO API key) | **YES** | source `llm.py:138-150`, `1030-1065`, `1290`, `1312` | Backend `claude-cli`: `default_model="claude-code-plan"`, `pricing {input:0,output:0}`, **no `env_key`**. `_call_claude_cli` shells out to local `claude -p --output-format json --no-session-persistence` on the **Pro/Max subscription**. `claude` CLI present locally (`/Users/david/.local/bin/claude`, v2.1.178) → operational. `--backend` enum in help OMITS `claude-cli` but it IS valid (guide §3.2 verified via invalid-backend error listing it). | source (+ guide cross-check) |
| `extract --backend claude` (REQUIRES `ANTHROPIC_API_KEY`) | **YES — distinct, API-billed** | source `llm.py:52-60`, `1290` | Backend `claude`: `env_key="ANTHROPIC_API_KEY"`, `pricing {input:3.0,output:15.0}`. `__main__`/`llm` require the key for all backends except `bedrock` and `claude-cli` (`if not key and backend not in ("bedrock","claude-cli")` — llm.py:1290, 1745). **`claude` ≠ `claude-cli`**; substituting `claude` for `claude-cli` silently switches to paid API. | source |
| claude-cli serial vs `GRAPHIFY_CLAUDE_CLI_PARALLEL` | **YES — serial by default** | source `llm.py:1663-1666` | `if backend == "claude-cli" and os.environ.get("GRAPHIFY_CLAUDE_CLI_PARALLEL","") != "1": max_concurrency = 1` — forced serial (parallel `claude -p` conflict over session state); opt-in parallel via env=1. | source |
| `check-update <path>` | **YES — but narrow** | `graphify check-update <repo>`; source `__main__.py:3355-3362`, `watch.py:775-787` | Runs `check_update()`; **always `sys.exit(0)`** (cron-safe by design). Prints a notice ONLY if `graphify-out/needs_update` exists (pending **non-code** changes). On this repo: **no output, exit 0** (flag absent). It does **NOT** detect code staleness, never compares HEAD, has no failing exit code. **NOT suitable as a general staleness gate.** | CLI + source |
| `needs_update` flag | **YES — file `graphify-out/needs_update`** | source `watch.py:783,792-798` (write), `617-620,654-656,756-759` (clear) | Written ONLY by `_notify_only()` when a **non-code** (doc/paper/image) file changes during `watch`/`update` (content "1"). **Cleared on every successful code rebuild.** Signals "semantic re-extraction pending," NOT "graph is stale vs HEAD." Absent on this repo right now. | source |
| `watch <path>` | **YES — foreground daemon, code-only** | `graphify --help` (`watch`); source `__main__.py:3113`, `watch.py:805-859` | "watch a folder and rebuild the graph on **code changes**." Long-running **foreground** watchdog observer; code change → incremental AST rebuild (no LLM); non-code change → writes `needs_update` + notifies. Honors `.graphifyignore`, debounce 3s. Needs `watchdog` extra. **NOT a detached/unattended service** — it blocks a terminal until Ctrl-C. Viable only as a manual "while I code" tool, not a background refresh mechanism. | CLI + source |
| `built_at_commit` in graph.json | **YES — the key staleness primitive** | live `grep` on `graph.json`; source `export.py:484-534`, `watch.py:499,680,684` | `to_json(..., built_at_commit=_git_head())` stamps `"built_at_commit": "<full sha>"` into `graph.json`; also rendered in `GRAPH_REPORT.md` as "Built from commit: `<sha8>`" (`report.py:77-81`). `_git_head()` = `git rev-parse HEAD` (watch.py:179-186). Live: graph=`fd22afb7…`, HEAD=`190e1985…` ⇒ stale, provable with zero LLM. | live + source |
| `.graphify_semantic_marker` | **YES** | live `cat`; source `export.py:27,36,50`, `__main__.py:4496` | Presence = "graph cost real LLM tokens" (semantic layer exists). Live content `{"output_tokens": 2040684}`. Used to protect a semantic graph from being clobbered by a code-only run. Secondary primitive (proves semantic layer present, not freshness). | live + source |
| `.graphify_root` / `.graphify_python` | **YES** | live `ls`; source `watch.py:583`, `hooks.py:28-41` | `.graphify_root` = saved scan root (lets `update` with no arg recover the corpus root). `.graphify_python` = pinned interpreter for hooks (PATH-independent). Operational metadata, not freshness. | live + source |
| `cache-check <files_from>` (UNDOCUMENTED) | **YES — hidden** | source `__main__.py:4559-4590` | NOT in `graphify --help`. Reads a file-list, runs `check_semantic_cache`, writes `.graphify_cached.json` + `.graphify_uncached.txt`, prints `Cache: N hit, M miss`. A low-level cache-introspection primitive (could report how many files would need semantic re-extraction). | source |
| `merge-driver <base> <current> <other>` | **YES — but NOT relevant here** | `graphify --help`; source `__main__.py:3420-3472`; `hooks.py` (full read) | Union-merges two `graph.json` files (git merge driver). Help says "set up via hook install" — **MISLEADING**: `hooks.py:install()` installs ONLY post-commit/post-checkout, it does NOT register the merge driver in `.git/config`/`.gitattributes`. Setup is actually manual git config. **Irrelevant to THIS repo: `graphify-out/` is gitignored**, so graph.json is never committed/merged across worktrees — there is nothing for the merge driver to merge. (Guides §5.3 already flag it UNVERIFIED and note the gitignore makes it moot.) | CLI + source (+ guide cross-check) |

---

## Answers to the 8 questions (concise, evidence-anchored)

**Q1 — Git-hook installer:** Built-in installer **EXISTS**: `hook install`,
`hook uninstall`, `hook status` (top-level help + `hooks.py`). It installs
`post-commit` + `post-checkout` (code-only, detached, worktree-aware). It is a
SEPARATE command from `graphify install` (which only copies the skill to a
platform config dir). `hook --help`/`install --help` print generic usage (no
per-subcommand help). `hook status` here = both **not installed**. The
help-text contradiction in the premise does not exist in 0.8.39; the
`merge-driver` "set up via hook install" string is itself wrong (hook install
does not register the merge driver).

**Q2 — `update`:** Code-only / **no LLM** / ~0 tokens (deterministic AST).
`--force` overwrites even with fewer nodes (also `GRAPHIFY_FORCE=1`);
`--no-cluster` writes raw extraction. **It BUILDS a graph if none exists** (full
code corpus) AND refreshes an existing one incrementally.

**Q3 — `extract`:** AST + semantic. **Cache-aware/incremental** — content-keyed
semantic cache; only cache-miss files call the LLM; prints `semantic cache: N
hit / M miss` (the observed line). `--backend claude-cli` = headless `claude -p`
on the **subscription, NO API key**. `--backend claude` = **requires
`ANTHROPIC_API_KEY`** (paid API). claude-cli is **serial** unless
`GRAPHIFY_CLAUDE_CLI_PARALLEL=1`.

**Q4 — `check-update`:** Checks ONLY the `needs_update` flag (pending **non-code**
re-extraction). Prints a notice if set; **always exits 0** ("cron-safe"). It
does **NOT** compare HEAD, does NOT detect code staleness, and has **no failing
exit code**. **NOT a suitable basis for a "is the graph stale?" gate** — it is
deterministic and no-LLM, but it answers the wrong question.

**Q5 — `needs_update`:** A file `graphify-out/needs_update` (content "1"),
**written only** when a non-code file changes during `watch`/`update`
(`_notify_only`), and **cleared on every successful code rebuild**. It signals
"semantic re-extraction pending," not "graph behind HEAD." Absent on this repo.

**Q6 — `watch`:** A **foreground, long-lived** watchdog daemon; code change →
incremental AST rebuild (no LLM); non-code change → writes `needs_update`. It is
**NOT a detached/unattended** refresh mechanism — it occupies a terminal until
Ctrl-C and does no semantic pass. Not viable as the production refresh.

**Q7 — Staleness-detection primitives (enumerated):**
1. **`graph.json` → `built_at_commit`** (full SHA) vs `git rev-parse HEAD` — the
   single reliable, deterministic, no-LLM staleness signal. **Recommended basis.**
2. **`GRAPH_REPORT.md` → "Built from commit: `<sha8>`"** — human-readable mirror
   of #1.
3. **`graphify-out/needs_update`** — pending **non-code** changes only (narrow).
4. **`.graphify_semantic_marker`** — proves a semantic layer exists (not freshness).
5. **`cache-check`** (hidden) — could count files needing semantic re-extraction.
6. **File mtime of `graph.json`** — weak/last-resort (no commit binding).
None of these is wired into a failing exit code today; a verification check must
implement the HEAD-vs-`built_at_commit` comparison itself.

**Q8 — `merge-driver`:** Union-merges two `graph.json` files as a git merge
driver; setup is **manual git config** (NOT done by `hook install`, despite the
help text). **Irrelevant to this repo** because `graphify-out/` is gitignored —
the graph is never committed, so linked worktrees never produce a graph.json
merge conflict. No action needed for the worktree-isolation setup.

---

## CLAIMED-BUT-ABSENT capabilities (per rule verify-availability)

- **NONE found that a doc actively over-promised.** The BD-237 premise's two
  claims (no `hook` subcommand; guide over-promised `hook install`) are
  themselves the only inaccuracies — and they are **incorrect**: the capability
  EXISTS and the guide describes it correctly.
- **Misleading-but-not-absent:** the `merge-driver` help string "set up via hook
  install" wrongly implies `hook install` registers the merge driver; it does
  not (it installs only post-commit/post-checkout). Flag this to the architect
  so the redesign docs don't repeat the CLI's own error.

---

## Implications for the BD-237 redesign

**What a reliable refresh CAN be built on (verified real):**
- **Code layer:** built-in `graphify hook install` (post-commit + post-checkout,
  detached, worktree-aware, cross-platform, code-only, ~0 tokens) — robust and
  already production-grade; OR `graphify update` invoked on a schedule. Either is
  deterministic, no LLM.
- **Semantic layer:** there is **no built-in installer** — it requires either a
  hand-written `post-commit` running `graphify extract . --backend claude-cli`
  (the guide's recipe — subscription, no key, serial, slow) OR a scheduled/manual
  `extract`. The semantic hook is the piece BD-237 must make installed-and-verified.
- **Backend pin:** `--backend claude-cli` is the correct no-key subscription path;
  `--backend claude` is a paid-API trap and must never be substituted. Keep
  `GEMINI_API_KEY`/`GOOGLE_API_KEY`/`OPENAI_API_KEY` unset (graphify auto-routes
  to a paid API if set).

**What a verification check CAN be built on (verified real):**
- **Primary:** compare `graph.json`'s `built_at_commit` to `git rev-parse HEAD`.
  Deterministic, no LLM, cron-safe, and directly answers "is the graph behind the
  code?" (Live proof: `fd22afb7` ≠ `190e1985` ⇒ stale.) The check must read the
  JSON field and the HEAD itself — graphify ships no command that does this
  comparison or returns a failing exit code.
- **Do NOT base the staleness gate on `check-update`/`needs_update`** — they only
  flag pending **non-code** changes, always exit 0, and never compare HEAD. They
  are the wrong primitive (this conflation may be part of why BD-237's freeze went
  unnoticed).
- **Production-verification of hook installation:** `graphify hook status` is a
  real, scriptable check for the **code** hooks; the **semantic** hand-written
  hook needs a custom existence/recipe check (no built-in status for it).

**Worktree note (this repo runs linked worktrees):** `built_at_commit` +
`_git_head()` use `git rev-parse HEAD`, which is per-worktree correct. The
built-in hooks resolve the hooks dir via `git rev-parse --git-path hooks`
(worktree-safe, hooks.py:317-338). `GRAPHIFY_OUT` env var can redirect output per
worktree (`cache.py:15`). The merge-driver is moot (gitignored graph).

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/observed) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Only commands run: `git rev-parse HEAD`, `git branch --show-current` (read-only); `graphify --help`/`<cmd> --help`/`hook status`/`check-update` (read-only); `ls`/`grep`/`cat`/`which` on files; one `mkdir -p /tmp/...`. **No `graphify update`/`extract`/`build`; no write to `graphify-out/`; no state-changing git verb.** Sole write = this report at `/tmp/pack-handoff-bd237-research/CAPABILITY-REPORT-BD-237.md`. | COMPLIANT |
| 2 | verify-availability-not-just-existence | Every matrix row cites an actual command/source line (e.g. `graphify hook status` → "post-commit: not installed"; `llm.py:1665` serial gate; `__main__.py:4283` cache print). BD-237's two doc-claims tested against CLI+source and found INCORRECT (hook DOES exist). Misleading `merge-driver` help string flagged. No capability reported on a doc's say-so. | COMPLIANT |
| 3 | scope-deliverables-to-the-ask | Delivered: 8 answers + capability matrix + implications + CLAIMED-BUT-ABSENT list. Did NOT redesign the refresh mechanism or verification check (architect's job); did not sprawl into unrelated graphify features (query/path/explain/export omitted). | COMPLIANT |
| 4 | separate-pack-ops-from-product | Report concerns ONLY the pack-ops graph tooling (`graphify-out/` is gitignored, pack-ops-only). No `project-template/` deliverable implicated; explicitly notes the graph is not shipped to clients. | COMPLIANT |
| 5 | no-deferral-without-user-direction / deferral-is-scope-creep | No verification deferred. Every question answered from CLI+source. Where a capability is narrow (`check-update`) or absent (built-in semantic-hook installer), stated explicitly with evidence — not punted. No external confirmation needed (web docs not required). | COMPLIANT |
| 6 | rules-applied-verification-block | This block present; one row per rule with quoted evidence + terminal conclusion. | COMPLIANT |
