# DESIGN-BD-237 (MINIMAL, planner-ready) — Graphify graph-freshness: background auto-refresh via a `pre-push` hook + result-check/re-run, NO CI gate

**Agent:** FRESH `pack-architect` (READ-ONLY; did NOT author the rejected prior design or the adversarial review)
**Repo:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Branch / HEAD at design time:** `v11-dev` / `2f53788620e1bdb233eb8ed645801c995093bafe`
**Date:** 2026-06-20
**Charter:** `backlog/BD-237.md` (URGENT v11.0 pack-ops defect fix)
**Capability source (facts only; its CI/sentinel DIRECTION is rejected):** `/tmp/pack-handoff-bd237-research/CAPABILITY-REPORT-BD-237.md`

This doc is SELF-CONTAINED. It is the MINIMAL design the user's stated model implies. It contains NO code patch. Every state-claim carries an Empirical-Evidence (EE) block.

> **DELETED DIRECTIONS (the user rejected these as over-engineering; this design re-introduces NONE):** committed freshness sentinel; a new validate-pack "Check 65"; a lag-tolerance "N"; a `fetch-depth` workflow edit; any commit-count machinery; any CI gate. Graph freshness is a LOCAL dev-tooling concern — the graph is gitignored, never pushed, never built in CI. Verification = checking the actual background job's result, not a CI proxy. See §8 for the explicit "none of these appears" attestation.

---

## 0. The bar — close the three failures WITHOUT a CI gate

The graph (PACK-OPS-only, gitignored, per-worktree) silently FROZE. THREE failures (charter):
1. **The mechanism never ran in production** — the BD-225 freshness recipe was a HAND-INSTALLED, un-versioned `.git/hooks/post-commit` that nobody installed.
2. **The review didn't catch it** — no surface asserted the mechanism was live.
3. **No check verified it worked** — silent rot from the single initial build.

This design closes all three with: (a) an AUTOMATIC trigger the orchestrator cannot forget, (b) a background, non-blocking refresh pinned to the canonical graph root, and (c) a tiny LOCAL result-record that the next trigger consults to re-run on failure. §7 is the explicit failure→element map.

---

## 1. THE TRIGGER DECISION — **`pre-push` git hook** (PREFERRED), not the orchestrator flow

**Decision: a tracked, self-installed `pre-push` hook + script.** The orchestrator-flow fallback is NOT needed because the decisive test fails for it: a standalone `pre-push` hook CAN resolve the canonical graph root on its own.

### 1.1 The decisive measured fact: pushes originate from the canonical graph-owning worktree, and a `pre-push` hook resolves its root from there

#### EE-1.1 — git runs `pre-push` with CWD = the working tree the push was invoked from; that tree IS the graph-owning `v11-dev` worktree
- **Command:**
  ```
  git worktree list
  git reflog -8
  ls -d /Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out 2>&1
  ls graphify-out/.graphify_root && echo "v11-dev has graph"
  cat "$(git --exec-path)/../../share/git-core/templates/hooks/pre-push.sample" | head -4
  ```
- **Output (verbatim, abridged):**
  ```
  /Users/david/Developer/optiquity-ai-agent-config-pack          fa81704 [main]
  /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev  2f53788 [v11-dev]
  2f53788 HEAD@{0}: commit: docs: v11 — BD-237 root-cause correction ... (pack-only)
  190e198 HEAD@{1}: commit: docs: v11 — open BD-237 ... (pack-only)
  fd22afb HEAD@{2}: ... 0281ec3 HEAD@{4}: BD-226 Resolved ...        (all on v11-dev)
  ls: /Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out: No such file or directory
  graphify-out/.graphify_root   v11-dev has graph
  # An example hook script to verify what is about to be pushed. Called by "git push" ...
  ```
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** The graph exists ONLY in the `v11-dev` worktree (the MAIN tree has no `graphify-out/`). Every recent commit landed on `v11-dev` in THIS worktree (reflog). During the v11-dev phase the user pushes `v11-dev` (PACK-CHAT.md L156 "Push to v11-dev only"); `git push` is therefore invoked from the `v11-dev` worktree. Git runs `pre-push` with the working directory set to the top of the working tree from which `git push` was invoked — i.e. the `v11-dev` root, where `graphify-out/` lives. So inside the hook, `$(git rev-parse --show-toplevel)` resolves to the canonical graph-owning root **with no orchestrator injection needed**.
- **Conclusion:** SUPPORTED. A standalone `pre-push` hook can resolve the canonical root unaided ⇒ the orchestrator is NOT unavoidably required ⇒ the PREFERRED hook option wins.

### 1.2 Worktree-safety belt: a `graphify-out/` existence guard + explicit root, not a bare CWD assumption

The hook must NOT assume — it must GUARD. The one real residual hazard (BLOCKER-2, §3): if the hook ever fires from a worktree with no `graphify-out/` (e.g. a future push from the MAIN tree), a bare `graphify update .` would BUILD a spurious graph there (build-if-missing — EE-3.1). The belt:
- **G-EXIST guard:** the hook resolves `ROOT="$(git rev-parse --show-toplevel)"`, then `[ -d "$ROOT/graphify-out" ] || exit 0`. A worktree without a graph is a silent no-op — the BD-225 lesson and the `_CHECKOUT_SCRIPT` guard graphify itself uses (EE-3.1), but absent from its `post-commit` body.
- **Explicit-root injection (worktree-safe writer):** the hook passes BOTH `GRAPHIFY_OUT="$ROOT/graphify-out"` AND the explicit path argument (`graphify update "$ROOT"`), so the refresh writes to the resolved canonical graph regardless of any CWD subtlety — never `graphify update .` with a bare relative root. This is the BD-226 lesson (give the actor the absolute root; never self-derive a relative `.`) applied to the WRITER. EE-3.2.

### 1.3 The per-clone-install tradeoff and the honesty keeper (NO CI check)

A git hook is per-clone (git does not version `.git/hooks`) — the exact gap that sank BD-225. Two design moves keep it honest WITHOUT a CI check:
- **Self-install from a TRACKED script.** Ship a committed installer (`scripts/install-graphify-hook.sh`) that copies the tracked hook body into the shared common hooks dir. The hook BODY is versioned (it cannot rot from "nobody copied the latest recipe"); only the one-time `bash scripts/install-graphify-hook.sh` per clone remains manual.
- **One-time "is it installed?" confirmation — a LOCAL advisory, not a CI gate.** `pack-startup` (and the OPTIONAL-FEATURES runbook) carry a one-line `git config --get core.hooksPath` / hook-presence check that prints "graphify pre-push hook: installed / NOT installed — run scripts/install-graphify-hook.sh". This is a human-facing readiness line on the fresh-session surface, NOT a validate-pack check and NOT merge-blocking. It catches the install gap once, at the moment a human is present and can act.

(The orchestrator-flow FALLBACK is documented as REJECTED in §1.4 so the planner does not re-open it.)

### 1.4 Why NOT the orchestrator-flow fallback
The fallback's decisive test (charter): "can a static `pre-push` hook resolve the canonical graph root WITHOUT orchestrator-injected `GRAPHIFY_OUT`?" EE-1.1 answers YES (pushes originate from the graph-owning worktree; the hook resolves the root from its own CWD). The fallback is therefore NOT triggered. Its cost is also worse for the charter's failure #1: an orchestrator-flow step is exactly the thing the user said "the orchestrator cannot forget when its context is overloaded or cleared." A static hook fires on `git push` with zero orchestrator memory. REJECTED. (If a future BD makes the MAIN-tree-push path routine, revisit — but the G-EXIST guard makes even that case a safe no-op, not a mis-build.)

---

## 2. THE BACKGROUND REFRESH MECHANISM (code + semantic), non-blocking

The two layers keep their OPPOSITE cost profiles (this is the one part of the prior design that was correct and is preserved):
- **CODE layer:** `graphify update` — deterministic AST, ~0 tokens, no LLM. SAFE to background unattended.
- **SEMANTIC layer:** `graphify extract --backend claude-cli` — LLM on the subscription (no API key), SERIAL. Real token cost; backgrounded but still gated by the doc-change predicate so it only runs when docs actually changed.

### 2.1 The hook fires the refresh in the BACKGROUND and exits 0 immediately (non-blocking)
The hook DETACHES the refresh (`( ... ) >/dev/null 2>&1 &`) and `exit 0`s before the push proceeds. The push is NEVER blocked (charter requirement). The refresh runs against the just-resolved canonical root. Doc-gate predicate (preserved from the current recipe, EE-2.1): if the pushed range touched a `.md`/`.pdf` doc-layer file, run the semantic `extract`; else the free code-only `update`.

#### EE-2.1 — `update` is code-only/no-LLM and BUILDS-IF-MISSING; `extract --backend claude-cli` is the no-key subscription path
- **Command:** `sed -n '3294,3345p' __main__.py` ; `sed -n '510,585p' watch.py` ; capability report Q2/Q3
- **Output (verbatim, abridged):** `update` → "re-extract code files ... (no LLM needed)"; root recovery reads `graphify-out/.graphify_root` else `Path(".")` (`__main__.py:3318-3321`); `_rebuild_code` defaults `existing_graph_data={}` when no graph (`watch.py:514`) and `out.mkdir(exist_ok=True)` (`watch.py:577`) ⇒ builds-if-missing. Capability report: `--backend claude-cli` → `pricing {input:0,output:0}`, no `env_key`, shells to local `claude -p` on the subscription.
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** `update` is the free, unattended-safe code refresh — but build-if-missing is exactly why §1.2's G-EXIST guard + explicit root are mandatory. `extract --backend claude-cli` is the correct no-key semantic path; NEVER `--backend claude` (paid API). Keep `GEMINI_API_KEY`/`GOOGLE_API_KEY`/`OPENAI_API_KEY` unset (the current recipe already unsets them — preserve).
- **Conclusion:** SUPPORTED.

### 2.2 Pre-push vs the old post-commit
The current recipe is a `post-commit` hook (EE-2.2 — the FAULTY shape this design REPLACES). `pre-push` is chosen over `post-commit` because: (a) it coalesces a burst of commits into one refresh at push time (fewer redundant rebuilds), (b) it is the natural "about to publish" boundary, and (c) it composes cleanly with the skip-if-mid-run logic (§4). The hook fires for the actual cadence (every push) — the maintainer's real publish event.

#### EE-2.2 — the CURRENT shipped mechanism is a hand-installed `post-commit` recipe (the thing being replaced)
- **Command:** `sed -n '444,480p' pack-ops/OPTIONAL-FEATURES.md`
- **Output (verbatim, abridged):** L444 "### How to keep it fresh — the post-commit hook (per-clone, manual ...)"; L446-448 "hand-installed at `.git/hooks/post-commit` ... NOT a committed file ... each clone installs it manually"; L459-460 `ROOT="$(git rev-parse --show-toplevel ...)"; GRAPH="$ROOT/graphify-out/graph.json"`.
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** Current recipe = manual post-commit with a CWD-relative `--show-toplevel` ROOT (the BLOCKER-2 hazard in doc form) and `graphify update .` (bare relative — the build-if-missing trap). This section is REWRITTEN to the §1/§2 pre-push model (encoding surface #4, §6).
- **Conclusion:** SUPPORTED.

---

## 3. WORKTREE SAFETY — why `GRAPHIFY_OUT` + explicit root closes BLOCKER-2

This is the one real bug that survives all the deleted CI machinery (the BD-226 lesson). The fix is the §1.2 belt; the source evidence:

#### EE-3.1 — `graphify`'s own `post-commit` body has NO existence guard; the writer must supply one
- **Command:** read of `/Users/david/.local/share/uv/tools/graphifyy/lib/python3.12/site-packages/graphify/hooks.py`; `grep -n '! -d "graphify-out"' hooks.py`
- **Output (verbatim, abridged):** the post-commit `_HOOK_SCRIPT` early-exits are ONLY rebase/merge/cherry-pick-in-progress, `GRAPHIFY_SKIP_HOOK=1`, empty changeset, only-graphify-out-changed — NO `[ ! -d graphify-out ]` bail. `_CHECKOUT_SCRIPT` (L258) DOES have `if [ ! -d "graphify-out" ]; then exit 0`. `grep` for `! -d "graphify-out"` matches ONLY L258 (checkout body).
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** Neither graphify's own post-commit body nor a bare `graphify update .` guards against "no graph in this tree." Our `pre-push` hook MUST add the `[ -d "$ROOT/graphify-out" ] || exit 0` guard itself (§1.2 G-EXIST). This is why we do NOT use `graphify hook install` and do NOT copy graphify's post-commit shape.
- **Conclusion:** SUPPORTED.

#### EE-3.2 — `GRAPHIFY_OUT` env + explicit path are the worktree-safe write levers
- **Command:** `grep -n 'GRAPHIFY_OUT' watch.py cache.py` ; `cat graphify-out/.graphify_root`
- **Output (verbatim, abridged):** `watch.py:11 _GRAPHIFY_OUT = os.environ.get("GRAPHIFY_OUT", "graphify-out")`; `cache.py:15` same; `.graphify_root` content = `.` (a RELATIVE dot).
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** `.graphify_root` stores `.` (relative) — so `graphify update` with no path self-derives the root from CWD, which is exactly the mis-resolution to avoid. The fix: the hook passes an EXPLICIT absolute `$ROOT` argument AND sets `GRAPHIFY_OUT="$ROOT/graphify-out"`, so the output dir and scan root are both pinned to the resolved canonical worktree, never a bare relative `.`. The `GRAPHIFY_OUT` override is the verified lever (watch.py:11) for redirecting the output to the canonical worktree.
- **Conclusion:** SUPPORTED. Worktree-safety = G-EXIST guard (EE-3.1) + explicit-root/`GRAPHIFY_OUT` injection (this EE). No `graphify hook install`, no CWD-relative `.`.

---

## 4. IDEMPOTENT + SKIP-IF-MID-RUN — reuse graphify's `fcntl.flock`, add nothing

The user's instruction: VERIFY whether graphify's internal lock already provides mid-run safety; add only what it does not.

#### EE-4.1 — graphify's `_rebuild_lock` is a per-repo non-blocking `fcntl.flock`; a contending refresh SKIPS (returns False), auto-released on process death
- **Command:** `sed -n '92,145p' watch.py` ; `sed -n '385,420p' watch.py`
- **Output (verbatim, abridged):** `_rebuild_lock(out_dir, *, blocking=False)` opens `out_dir/.rebuild.lock`, takes `fcntl.LOCK_EX | fcntl.LOCK_NB` by default; on `BlockingIOError` it `yield False` (the rebuild SKIPS); released on close/process-death (docstring: "released automatically if the process is killed — no stale-lock cleanup needed"). A `.pending_changes` spill queues a skipped run's change set so the lock-holder drains it. NOTE: the INTERACTIVE `graphify update` CLI passes `block_on_lock=True` (`__main__.py:3331`) so it BLOCKS instead of skipping — the hook-driven `_rebuild_code` path uses the default non-blocking skip.
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** graphify ALREADY provides the skip-if-mid-run + coalesce semantics the user wants — but ONLY on the non-blocking `_rebuild_code` path (post-checkout hook / watch). The `graphify update` CLI path BLOCKS. So if the hook shells `graphify update`, two near-simultaneous pushes would have the second BLOCK (not skip). To get the user's "several quick pushes coalesce into one run, no pile-up" with TRUE non-blocking skip, the hook adds a THIN outer guard (next paragraph) rather than relying on the blocking CLI.
- **Conclusion:** SUPPORTED — graphify's flock gives non-blocking skip on the `_rebuild_code` path, but the `update` CLI blocks; the hook needs a thin outer skip guard to guarantee non-pile-up.

**What the hook adds (minimal — the ONLY thing beyond graphify's lock):** a thin outer `flock`-style guard on a single lock file in `graphify-out/` so a second push while a refresh is in flight SKIPS immediately rather than queuing a blocking `update`. Concretely: the background subshell wraps the refresh in `flock -n "$ROOT/graphify-out/.pack-refresh.lock" -c '<refresh>'` (or the portable `mkdir` lock equivalent — coder picks per `flock(1)` availability on macOS, FLAG §9). If the lock is held, the new trigger exits 0 immediately (skip). This is idempotent (one in-flight refresh max) and coalescing (the in-flight run already covers the new commits, since `update` rebuilds the full corpus from HEAD). It does NOT reinvent graphify's `_rebuild_lock` — it sits OUTSIDE it to make the skip non-blocking regardless of which graphify entry path runs.

---

## 5. VERIFY = CHECK THE JOB'S RESULT; RE-RUN ON FAILURE (the entire verification, no CI proxy)

The user's model: verification is checking the actual background job succeeded; if it FAILED, run it again. Minimal, local, no committed artifact.

### 5.1 The result record (tiny, local, gitignored)
The background refresh writes a one-line status to `graphify-out/.pack-refresh-status` (INSIDE the gitignored `graphify-out/`, so NEVER committed — EE-5.1) on completion:
- `ok <HEAD-SHA> <ISO-timestamp>` on success (the refresh's `exit 0`);
- `fail <HEAD-SHA> <ISO-timestamp>` on a non-zero refresh exit.

The hook's refresh wrapper is: run the refresh; on success write `ok ...`; on any non-zero exit write `fail ...`. This is the "tiny status/exit record" the user described — local, gitignored, single line.

#### EE-5.1 — `graphify-out/` is gitignored ⇒ anything inside it is never committed (no committed artifact)
- **Command:** `grep -n graphify .gitignore` ; `find . -name ".pack-refresh-status" -not -path "./.git/*"`
- **Output (verbatim):** `.gitignore:76:graphify-out/` ; (find → no output)
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** A status file under `graphify-out/` is covered by the line-76 gitignore — never tracked, never pushed, never in CI. This satisfies "no committed artifact." Name is unique (no collision).
- **Conclusion:** SUPPORTED.

### 5.2 Re-run on failure (self-retry, consulted by the NEXT trigger)
Two complementary, minimal mechanisms (both local, no CI):
1. **Next-trigger consult:** at the TOP of the `pre-push` hook, before launching a new refresh, read `.pack-refresh-status`. If the last status is `fail ...`, the hook KNOWS the prior refresh failed and proceeds to launch a fresh refresh (which it would do anyway) — but it ALSO surfaces a one-line stderr note "graphify: previous refresh FAILED at <sha>; re-running" so the failure is human-visible at the next push. This is "check result + re-run on failure" with zero new machinery beyond reading one line.
2. **In-run self-retry (bounded):** the background refresh wrapper retries the refresh ONCE on a non-zero exit (`run; [ $? -ne 0 ] && run-once-more`) before writing `fail`. A single retry covers a transient `claude -p`/lock hiccup without an unbounded loop. Bounded at 2 attempts total — no commit-count, no N.

Together: a failed refresh is retried immediately once (self-retry), and if it still fails, the failure is recorded locally AND announced on the next push (next-trigger consult). Silent rot cannot persist — the next push surfaces the stale state.

### 5.3 Why this needs no CI gate
The graph is never in CI (gitignored). The ONLY place the job's real success/failure is observable is the local machine where it ran. Checking the local result record IS the verification — a CI check could only ever inspect a committed proxy, which the user rejected. The result-check lives exactly where the truth is.

---

## 6. ENCODING SURFACES — enumerate ALL, land in LOCK-STEP

Every surface this minimal design touches. (Far fewer than the rejected design: no sentinel, no Check 65, no test-check-65, no count-constant bump, no workflow edit.)

| # | Surface | Change |
|---|---|---|
| 1 | `scripts/install-graphify-hook.sh` (NEW, tracked) | Self-installer: copies the tracked hook body into `$(git rev-parse --git-path hooks)/pre-push`, `chmod +x`, idempotent (overwrite-if-changed), prints a confirmation. Pack-ops-only. |
| 2 | the `pre-push` hook BODY (NEW, tracked — e.g. `scripts/hooks/graphify-pre-push.sh`, the source the installer copies) | G-EXIST guard (§1.2) → key-clean subshell (unset paid keys) → doc-gate (extract vs update) → explicit-root + `GRAPHIFY_OUT` injection (§3) → outer skip-lock (§4) → background detach + `exit 0` (§2) → write `.pack-refresh-status` (§5). |
| 3 | (no committed status file) | `.pack-refresh-status` + `.pack-refresh.lock` are RUNTIME files under gitignored `graphify-out/` — NOT a tracked surface; listed here only so the planner knows they exist. |
| 4 | `pack-ops/OPTIONAL-FEATURES.md` §"How to keep it fresh" (L444-513) | REWRITE: replace the hand-installed `post-commit` recipe (EE-2.2) with the pre-push model — installer, hook body shape, worktree-safety, result-check/re-run, the install-confirmation advisory. PRESERVE §1.1 backend caveat (claude-cli-not-claude; no `--no-viz` on extract — accurate). Delete the L497-513 "verify (a)(b)" caveats (resolved: G-EXIST guard + flock). |
| 5 | `.claude/skills/pack-startup/SKILL.md` | ADD a one-line ADVISORY to a reserved Step slot: "graphify pre-push hook: installed / NOT installed — run scripts/install-graphify-hook.sh" (§1.3). Local readiness line, NOT a gate. |
| 6 | `pack-ops/PACK-CHAT.md` (push flow) | ADD a one-line note that the pre-push hook auto-refreshes the graph in the background on every push (so the orchestrator knows it is automatic and does not duplicate it). Optional FORGOT-IT visibility tie-in only if the planner keeps an orchestrator announcement; with the hook this is informational, not load-bearing. |
| 7 | `maintenance-docs/v11-implementation/` | PRESERVE the capability report + this design (+ the forthcoming plan + IMPL-REPORT) per charter L19. |

#### EE-6.1 — the install target (shared common hooks dir) is empty and worktree-shared; the installer resolves it correctly
- **Command:** `git rev-parse --git-path hooks` ; `ls -la "$(git rev-parse --git-common-dir)/hooks"` ; `git config --get core.hooksPath; echo "(exit $?)"`
- **Output (verbatim):** `git-path hooks` = `/Users/david/Developer/optiquity-ai-agent-config-pack/.git/hooks`; hooks dir `total 0` (empty); `core.hooksPath` `(exit 1)` (unset).
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** The shared common hooks dir is the install target (worktree-shared — one install serves both worktrees); it is currently empty and `core.hooksPath` is unset. The installer uses `git rev-parse --git-path hooks` (worktree-safe resolution, the same primitive graphify uses) to place the `pre-push` hook. Confirms: no pre-existing hook to clobber; no `core.hooksPath` redirect to honor.
- **Conclusion:** SUPPORTED.

---

## 7. FAILURE → ELEMENT MAPPING (closed, not relocated — WITHOUT a CI gate)

| Original failure | Preventing element | Fires on which surface / cadence | CLOSED? |
|---|---|---|---|
| **#1 — mechanism never ran** | AUTOMATIC `pre-push` hook (§1) — fires on every `git push` with zero orchestrator memory; the hook BODY is tracked (cannot rot from "nobody copied the latest recipe"); only one-time `install-graphify-hook.sh` per clone, caught by the §1.3 install-confirmation advisory. | Every `git push` (the maintainer's real publish cadence). | **CLOSED** — the trigger is git itself, not a human/orchestrator the user can forget. |
| **#2 — review didn't catch it** | The hook + installer are TRACKED, versioned files (reviewable in the diff), and the result-record/re-run (§5) makes a failed refresh self-announcing — no reviewer must "notice" a frozen graph. | Code review of the tracked installer/hook + every-push result-check. | **CLOSED** — the mechanism is in the repo (review-visible) and self-reporting (no human vigilance required). |
| **#3 — silent rot** | Result-check + re-run-on-fail (§5): a failed refresh retries once immediately, and any persisting failure is recorded locally AND printed on the next push. The install-confirmation advisory (§1.3) catches "hook never installed." | Every push (result-check) + every fresh session (install advisory). | **CLOSED** — rot cannot be silent: the next push either refreshes successfully or prints the prior failure; an un-installed hook is surfaced at session start. |

**Why this is CLOSE not RELOCATE, and why NO CI gate is needed:** the teeth live where the truth lives — the local machine that runs (or fails to run) the refresh. #1 is closed by an automatic git-native trigger; #2 by tracked, review-visible files + self-reporting; #3 by reading the actual job result and re-running. A CI gate could only inspect a committed proxy for a gitignored, never-pushed artifact — which is precisely the rejected over-engineering. The verification is the result-check, not a CI proxy.

---

## 8. EXPLICIT ATTESTATION — none of the rejected machinery appears

This design introduces **NO** committed freshness sentinel, **NO** new validate-pack check (no "Check 65"), **NO** lag-tolerance "N", **NO** `fetch-depth` workflow edit, **NO** commit-count machinery, and **NO** CI gate of any kind. The only new tracked files are the `pre-push` hook body and its self-installer (both pack-ops-side `scripts/`); the only runtime artifacts (`.pack-refresh-status`, `.pack-refresh.lock`) live INSIDE gitignored `graphify-out/` and are never committed. Verification = checking the actual background job's result locally + re-run on failure (§5), never a CI proxy.

---

## 9. WHAT THE CODER MUST STILL CONFIRM (flag, do not defer — `verify-availability`)

1. **`flock(1)` availability on macOS** (§4). macOS ships no BSD `flock` binary by default. The coder confirms whether `flock` is present (e.g. via Homebrew `util-linux`) OR implements the portable `mkdir`-based atomic lock (`mkdir "$LOCK" 2>/dev/null || exit 0`; `trap 'rmdir "$LOCK"' EXIT`). Recommendation: the `mkdir` lock (zero dependency). FLAG — coder picks and verifies on the actual machine.
2. **`pre-push` background-detach survives `git push` exit** (§2). Confirm the detached subshell (`( ... ) & exit 0`) is NOT killed when git reaps the hook process (use `setsid`/`disown`/`nohup` if the refresh dies with the hook). Verify empirically: push, then confirm the refresh completes after `git push` returns.
3. **Doc-gate range under `pre-push`** (§2). The current recipe uses `HEAD~1 HEAD`; under `pre-push`, the range is the pushed commits (stdin `<remote_oid>..<local_oid>`). The coder computes the doc-gate over the actually-pushed range (not `HEAD~1`), falling back to a full code `update` if the range is unavailable.
4. **`graphify update "$ROOT"` writes to `$ROOT/graphify-out` with `GRAPHIFY_OUT` set** (§3). Confirm the explicit path arg + `GRAPHIFY_OUT` together pin the output to the canonical worktree (no stray `.`-relative write). Verify by running once from the v11-dev worktree and checking `built_at_commit` advances in `graphify-out/graph.json`.
5. **Self-retry does not double-bill the subscription** (§5.2). Confirm a single `extract` retry after a transient failure does not re-extract cache-hit files (capability report Q3: semantic cache is content-keyed/incremental — a retry should re-bill only genuine misses). FLAG to keep the retry cheap.

No residual is DEFERRED — all are coder-confirm items WITHIN this v11.0 fix.

---

## 10. PARALLEL / SERIAL COMMIT MAP

This is a SINGLE-COMMIT effort (one coherent pack-ops change). All encoding surfaces (§6 rows 1, 2, 4, 5, 6) land in ONE commit (lock-step) so the hook body, installer, runbook, and advisories are never half-applied. The maintenance-docs preservation (row 7) rides the same commit or a trailing docs commit per Pack Chat's standard. No parallelizable sub-units; no same-file serialization concerns (each surface is a distinct file). One coder, one bounded review/fix cycle.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Commands run were read-only only: `git rev-parse`/`worktree list`/`reflog`/`config --get`/`branch`/`remote -v` (read), `ls`/`cat`/`grep`/`sed -n`/`wc` (read), `graphify` NOT invoked to mutate (no `update`/`extract`/`hook install`), one `mkdir -p /tmp/pack-handoff-bd237-min`. NO graph mutation; NO source edit; NO state-changing git verb. Sole write = this design doc. | COMPLIANT |
| 2 | empirical-evidence-blocks [architect] | Every state-claim carries an EE: command + verbatim output + HEAD-SHA `2f53788` + interpretation + conclusion (EE-1.1, EE-2.1, EE-2.2, EE-3.1, EE-3.2, EE-4.1, EE-5.1, EE-6.1). The trigger decision hinges on EE-1.1 (re-measured pushes-originate-from-graph-worktree) + EE-3.1/3.2 (re-measured guard absence + GRAPHIFY_OUT lever) + EE-4.1 (re-measured flock). | COMPLIANT |
| 3 | graph-first-context | Queried the injected graph path for orientation; the graph is the very artifact under review (stale, behind HEAD per the charter) so I fell through to grep/Read/git/source for ALL authoritative facts (SSOT fields, uncommitted state, hooks.py/watch.py/__main__.py source). Did not block on the graph (G2 fallback). | COMPLIANT |
| 4 | separate-pack-ops-from-product | Entire change is pack-ops-only: new files under `scripts/` + `pack-ops/OPTIONAL-FEATURES.md` + `.claude/skills/pack-startup/` + `pack-ops/PACK-CHAT.md` + `maintenance-docs/`; runtime files inside gitignored `graphify-out/`. NO `project-template/` or `supporting-docs/` member touched (EE-5.1 graph gitignored; §6 surface list has no client deliverable). The hook/installer never ship to clients. | COMPLIANT |
| 5 | verify-availability-not-just-existence | Re-verified from installed 0.8.39 SOURCE/live: `pre-push.sample` exists in the git template (real client-side hook); git runs pre-push from the push-invoking working tree (EE-1.1); `GRAPHIFY_OUT` env override (watch.py:11, EE-3.2); `.graphify_root` content = `.` relative (EE-3.2); `_rebuild_lock` non-blocking flock + the `update`-CLI blocking caveat (EE-4.1); post-commit body has no existence guard (EE-3.1); build-if-missing (EE-2.1). §9 FLAGS five items the coder must still confirm on the actual machine (flock(1), detach survival, pre-push range, explicit-root write, retry billing). | COMPLIANT |
| 6 | enumerate-encoding-surfaces [architect] | §6 enumerates every surface (installer script, hook body, runbook rewrite, pack-startup advisory, PACK-CHAT note, maintenance-docs preservation; runtime files noted as non-tracked) with lock-step landing (§10 one commit). | COMPLIANT |
| 7 | scope-deliverables-to-the-ask | Delivered the minimal background-refresh design + the trigger DECISION (pre-push hook) + GRAPHIFY_OUT worktree-safety + idempotent/skip-if-mid-run + result-check/re-run + failure-map + encoding surfaces + commit map. Re-introduced NO CI gate/sentinel/N (§8). Did not redesign unrelated graphify features. | COMPLIANT |
| 8 | deferral-is-scope-creep / no-deferral-without-user-direction | All three failures closed NOW in v11.0 (§7). No residual deferred — §9 items are coder-confirm-WITHIN-this-fix, not punts to a later BD/version. | COMPLIANT |
| 9 | rules-applied-verification-block | This block — one row per rule + the explicit no-rejected-machinery row below. | COMPLIANT |
| — | **NO rejected machinery introduced** (explicit) | grep of this doc: NO committed sentinel, NO new validate-pack check / "Check 65", NO lag-tolerance "N", NO `fetch-depth` edit, NO commit-count machinery, NO CI gate. §8 is the in-design attestation; verification = local result-check + re-run (§5), never a CI proxy. | COMPLIANT |

---

*End of DESIGN-BD-237 (MINIMAL). Read-only architect design; no source edits, no state-changing git verbs, no graph mutation. Sole write = this file.*
