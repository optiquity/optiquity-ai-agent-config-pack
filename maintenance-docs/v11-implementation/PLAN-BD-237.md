# PLAN-BD-237-FINAL — Graphify graph-freshness: `pre-push` background auto-refresh + LOCAL freshness check (NO CI gate)

**Agent:** FRESH `pack-planner` (RECONCILED FINAL; did NOT author the prior plan or the adversarial review)
**Repo:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Branch / HEAD:** `v11-dev` / `2f53788620e1bdb233eb8ed645801c995093bafe`
**Date:** 2026-06-20
**Charter:** `backlog/BD-237.md` (URGENT v11.0 pack-ops defect fix)
**Approved design (facts + the parts that stay):** `/tmp/pack-handoff-bd237-min/DESIGN-BD-237.md`
**Adversarial findings resolved:** `/tmp/pack-handoff-bd237-advplan/ADVERSARIAL-PLAN-REVIEW-BD-237.md`
**Capability source:** `/tmp/pack-handoff-bd237-research/CAPABILITY-REPORT-BD-237.md`
**Scope keyword:** `pack-only`

> **This plan is SELF-CONTAINED. The coder reads ONLY this plan.** Every amended design
> decision is embedded inline. There is NO "see the design doc" pointer for any decision.

> **NO REJECTED MACHINERY (the user rejected ALL of these; this plan reintroduces NONE):**
> NO CI gate; NO validate-pack freshness check / "Check 65"; NO committed sentinel; NO
> commit-count "N" / lag-tolerance; NO `fetch-depth` workflow edit; NO commit-count
> machinery. **The freshness check IS LOCAL-ONLY** — it lives in `pack-startup` readiness
> output and the hook's own next-run consult, both reading the graph's own
> `built_at_commit` field. Nothing is committed, nothing runs in CI. (Attestation
> re-affirmed in the Rules-Applied block.)

---

## 0. The six user-decided resolutions, folded (the reconciliation map)

This plan supersedes the prior `PLAN-BD-237.md` (which will be DELETED — do not depend on
it). The adversarial review returned NEEDS-REWORK; the user decided each finding. The six
resolutions, and where each lands in THIS plan:

| # | Resolution (user-decided) | Folded in (this plan) |
|---|---|---|
| 1 | **DROP cross-worktree tightening.** Root = `ROOT="$(git rev-parse --show-toplevel)"` (push-invoking worktree) + `[ -d "$ROOT/graphify-out" ] \|\| exit 0`. NO `git worktree list` scan, NO multi-owner branch, NO cross-worktree refresh. The wrapper `cd`s into `$ROOT` so graphify's `_git_head()` stamps the correct HEAD. | §3 (resolution algorithm replaced by the minimal-design root resolution); §4 step 3 + step 7 (`cd "$ROOT"` in the refresh subshell). Reverts the prior plan's M3-broken §3.2 tightening. |
| 2 | **ADD a LOCAL `built_at_commit`-vs-HEAD freshness check** (NOT a committed sentinel, NOT CI, NOT "N"). (a) pack-startup readiness line (O(1) `tail -c` read of `built_at_commit`, the LAST field, vs `git rev-parse HEAD`) → "graph: fresh" / "graph: STALE — built at <sha>, HEAD <sha>" + hook-installed status. (b) the hook's next-run consult ALSO checks `built_at_commit`-vs-HEAD (not only the `.pack-refresh-status` token), so a refresh killed mid-run is detected next push. | §5.1 (pack-startup freshness+install line, exact logic); §4 step 6 (hook next-run consult, dual-signal: token OR built_at_commit-behind). Closes adversary B1 (never-completed) + B2 (charter freshness criterion). |
| 3 | **M1 — `GRAPHIFY_OUT` is INERT on `extract`** (only `update` honors it; `extract` derives out-dir from its target/`--out`). Worktree-safety comes from CWD=`$ROOT` + the explicit `$ROOT` target arg, not from `GRAPHIFY_OUT`. State the exact invocation for BOTH `update` (code) and `extract` (semantic). | §4 step 7c (exact per-branch invocations, both pinned by CWD=`$ROOT` + explicit `"$ROOT"` arg; `GRAPHIFY_OUT` documented inert on `extract`). §6 (OPTIONAL-FEATURES rewrite corrects the conflated lever). |
| 4 | **M2 — Check 23.** Both new executables carry `# pack-internal: true`. Verify whether the hook body under `scripts/hooks/` is even reached by Check 23 (does it iterate subdirs?). | §5.4 + EE-3: Check 23 iterates `scripts/` TOP-LEVEL only (non-recursive `iterdir()`), executable-gated. INSTALLER (top-level) MUST carry the marker; HOOK BODY (subdir) is NOT reached but carries the marker anyway for forward-safety. |
| 5 | **M4 — test-wiring is SUBTRACTIVE.** `scripts/test*.sh` auto-wire by existing; the allowlist is a deny-list. Do NOT add an allowlist entry. Decide whether BD-237 even needs a new shell test. | §5.2: DECISION — NO new `scripts/test*.sh` is added (the resolution logic is now the minimal-design single-line root resolution; the remaining shell-logic legs are non-deterministic on CI — detach/real-graphify). Verification is in-fix coder-verify + orchestrator live checks. If the coder DOES add one, it auto-wires and MUST be offline-deterministic — NO allowlist entry. |
| 6 | **Pre-push edge cases.** Cover: new branch (all-zeros remote oid), DELETED ref (all-zeros local oid → skip/no-op), force-push, MULTIPLE refs (multi-line). Simplest safe policy: range unavailable/ambiguous/delete → full code `update` (or skip on a pure delete). Specify it. | §4 step 2 + step 7c (exact stdin-drain + range-derivation policy enumerating new-branch / delete / multi-ref / force / empty). |

**KEPT from the minimal design UNCHANGED:** background detach + `exit 0` (non-blocking);
the `mkdir`-atomic skip-lock pinned to `$ROOT/graphify-out` (flock absent on macOS —
measured EE-2); the gitignored `.pack-refresh-status` result record + single self-retry;
key-clean subshell (no API key; `--backend claude-cli`); the doc-gate semantic-vs-code
split; SINGLE commit; the install-for-this-clone step (orchestrator runs
`install-graphify-hook.sh` with user approval AFTER the commit + a one-time refresh to
clear current staleness — `built_at_commit 190e198` < HEAD `2f53788`).

---

## EE — Empirical-Evidence Blocks (repo-state claims this plan depends on; HEAD `2f53788`)

### EE-1 — Worktrees + ONE graph owner; current state needs no cross-worktree scan
- **Command:** `git worktree list --porcelain`
- **Output (verbatim):**
  ```
  worktree /Users/david/Developer/optiquity-ai-agent-config-pack
  HEAD fa817044ffaa6cc019f4cb975a4242be15060676
  branch refs/heads/main

  worktree /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev
  HEAD 2f53788620e1bdb233eb8ed645801c995093bafe
  branch refs/heads/v11-dev
  ```
  (`graphify-out/` exists ONLY in `…-v11-dev`; the `main` worktree has none.)
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** Two worktrees; ONE owns the graph (`…-v11-dev`). Pushes during the
  v11-dev phase originate FROM `…-v11-dev` (PACK-CHAT.md L156 "Push to v11-dev only"), so
  `git rev-parse --show-toplevel` inside `pre-push` resolves to the graph-owning root with
  no scan. Resolution 1: the cross-worktree branch is DROPPED — `--show-toplevel` +
  existence guard is the whole resolution.
- **Conclusion:** SUPPORTED.

### EE-2 — `flock(1)` is ABSENT on macOS ⇒ the skip-lock MUST be the `mkdir` primitive
- **Command:** `command -v flock && echo PRESENT || echo ABSENT`
- **Output (verbatim):** `ABSENT`
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** No BSD `flock` binary. The lock MUST be the portable `mkdir`-atomic
  lock (`mkdir "$LOCK" 2>/dev/null || exit 0`; `trap rmdir`). No Homebrew assumed. DECIDED,
  not a coder option.
- **Conclusion:** SUPPORTED.

### EE-3 — Check 23 iterates `scripts/` TOP-LEVEL only (non-recursive), executable-gated, marker-or-fragment required
- **Command:** `sed -n '2137,2190p' scripts/validate-pack.py` ; `grep -n '_PACK_INTERNAL_RE' scripts/validate-pack.py`
- **Output (verbatim, abridged):**
  ```
  2165  for entry in sorted(scripts_dir.iterdir()):       # NON-recursive (no rglob)
  2166      if not entry.is_file(): continue
  2168      if entry.suffix not in (".sh", ".py"): continue
  2170      if not os.access(entry, os.X_OK): continue      # executable-gated
  2176      if _is_pack_internal(entry): flagged_internal.append…continue
  2179      if entry.name in text: listed.append…
  2182      else: missing.append…
  2184  fail("scripts/ executables missing from HELP-FRAGMENT-PACK.md (or mark with `# pack-internal: true`):")
  2019  _PACK_INTERNAL_RE = re.compile(r"^#\s*pack-internal:\s*true\b", re.MULTILINE)
  ```
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** `iterdir()` does NOT descend → a `scripts/hooks/*.sh` SUBDIR file is
  NOT scanned by Check 23. A TOP-LEVEL `scripts/install-graphify-hook.sh` that is committed
  EXECUTABLE and lacks the `# pack-internal: true` marker (and is not in
  HELP-FRAGMENT-PACK.md) FAILS Check 23. `_is_pack_internal` scans the first ~2000 bytes
  for `^#\s*pack-internal:\s*true` — so the marker must be a comment line near the TOP.
  Resolution 4: installer carries the marker (MANDATORY); hook body carries it too
  (forward-safe though Check 23 does not reach it).
- **Conclusion:** SUPPORTED.

### EE-4 — Graph is STALE (the defect, live); `built_at_commit` is the LAST field in graph.json (O(1) `tail -c` read valid)
- **Command:** `python3 -c "import json;print(json.load(open('graphify-out/graph.json'))['built_at_commit'])"` ; `git rev-parse HEAD` ; `tail -c 200 graphify-out/graph.json`
- **Output (verbatim, abridged):** `190e1985cbb8164d619d571a28d8c3228d3c6981` ; HEAD `2f53788620e1bdb233eb8ed645801c995093bafe` ; tail ends `…"hyperedges": [],\n  "built_at_commit": "190e1985…"\n}`
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** Live graph built at `190e198`, behind HEAD `2f53788` — the silent-rot
  defect. `built_at_commit` is the FINAL field before the closing `}` (graphify's
  `export.py:532-534` appends it after `hyperedges`, then `json.dump(indent=2)`), so a
  bounded `tail -c <small>` read recovers it without parsing the whole file — the O(1)
  freshness read resolution 2a relies on. The §7 per-clone install + one refresh advances
  it to HEAD.
- **Conclusion:** SUPPORTED.

### EE-5 — Shared common hooks dir is EMPTY; `core.hooksPath` UNSET (no clobber, no redirect; one install serves both worktrees)
- **Command:** `git rev-parse --git-path hooks` ; `git rev-parse --git-common-dir` ; `git config --get core.hooksPath; echo "(exit $?)"` ; `ls -la "$(git rev-parse --git-common-dir)/hooks"`
- **Output (verbatim):**
  ```
  /Users/david/Developer/optiquity-ai-agent-config-pack/.git/hooks
  /Users/david/Developer/optiquity-ai-agent-config-pack/.git
  (exit 1)
  total 0      (hooks dir empty)
  ```
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** Both worktrees share `…/optiquity-ai-agent-config-pack/.git/hooks`;
  it is EMPTY (no `pre-push` to clobber); `core.hooksPath` unset (no redirect). The
  installer writes to `git rev-parse --git-path hooks` (worktree-safe). ONE install serves
  BOTH worktrees.
- **Conclusion:** SUPPORTED.

### EE-6 — Source facts: `extract` IGNORES `GRAPHIFY_OUT` for output (uses target/`--out`); `update` HONORS it; `_git_head()` uses process CWD (no `-C`); NO `os.chdir` anywhere
- **Command:** (site-packages `…/graphifyy/lib/python3.12/site-packages/graphify/`) `sed -n '4090,4096p' __main__.py` ; `sed -n '396,399p' watch.py` ; `grep -n 'def _git_head\|rev-parse.*HEAD' export.py watch.py` ; `grep -rn 'os.chdir\|chdir(' __main__.py watch.py extract.py` ; `sed -n '3314,3333p' __main__.py`
- **Output (verbatim, abridged):**
  ```
  __main__.py:4094  out_root = (out_dir.resolve() if out_dir else target)
  __main__.py:4095  graphify_out = out_root / "graphify-out"      # extract: from target/--out, NOT GRAPHIFY_OUT
  watch.py:398      out = watch_path / _GRAPHIFY_OUT               # update path: HONORS GRAPHIFY_OUT
  export.py:478     r = _sp.run(["git","rev-parse","HEAD"], …)    # no -C, no cwd= -> process CWD
  watch.py:183      r = _sp.run(["git","rev-parse","HEAD"], …)    # identical
  (os.chdir|chdir() -> no matches in the three files)
  __main__.py:3318  saved = Path(_GRAPHIFY_OUT) / ".graphify_root"  # update recovers root from CWD-relative if no arg
  __main__.py:3331  ok = _rebuild_code(watch_path, …, block_on_lock=True)  # update CLI BLOCKS on lock
  ```
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** (a) `extract`'s output dir derives from the `target` arg (or `--out`),
  appending literal `"graphify-out"` — it NEVER reads `GRAPHIFY_OUT` (resolution 3 / M1
  confirmed). (b) `update`/`_rebuild_code` DOES honor `GRAPHIFY_OUT` (watch.py:398). (c)
  `_git_head()` runs `git rev-parse HEAD` against PROCESS CWD with no `-C` (export.py:478,
  watch.py:183), and there is NO `os.chdir` — so the stamped `built_at_commit` is the HEAD
  of the process's CWD. Therefore the refresh subshell MUST `cd "$ROOT"` so `_git_head()`
  stamps `$ROOT`'s HEAD into `$ROOT`'s graph (resolution 1). (d) the `update` CLI BLOCKS on
  graphify's own lock (`block_on_lock=True`) — which is why the hook's OUTER `mkdir`
  skip-lock is needed to make a second push SKIP (non-blocking) before reaching `update`.
- **Conclusion:** SUPPORTED.

### EE-7 — pre-push stdin contract (authoritative sample) — new-branch / delete / multi-ref / update
- **Command:** `sed -n '14,52p' "$(git --exec-path)/../../share/git-core/templates/hooks/pre-push.sample"` ; `git --version`
- **Output (verbatim, abridged):**
  ```
  #   <local ref> <local oid> <remote ref> <remote oid>          (one line per ref)
  zero=$(git hash-object --stdin </dev/null | tr '[0-9a-f]' '0')
  while read local_ref local_oid remote_ref remote_oid
    if test "$local_oid" = "$zero"  then  : (Handle delete)
    elif test "$remote_oid" = "$zero"  then  range="$local_oid"          (New branch, all commits)
    else  range="$remote_oid..$local_oid"                                (Update)
  git version 2.50.1 (Apple Git-155)
  ```
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** stdin is one line per pushed ref: `<local ref> <local oid> <remote
  ref> <remote oid>`. DELETE = `local_oid` all-zeros. NEW BRANCH = `remote_oid` all-zeros.
  UPDATE = `remote..local`. MULTIPLE refs = multiple lines (the while loop). Resolution 6:
  the hook drains ALL stdin first, and the doc-gate range policy enumerates each case
  (§4 step 2/7c).
- **Conclusion:** SUPPORTED.

### EE-8 — Encoding surfaces exist where claimed; the two NEW files do NOT collide; Graphify runbook range
- **Command:** `wc -l pack-ops/OPTIONAL-FEATURES.md` ; `grep -n "post-commit\|HEAD~1\|How to keep it fresh\|## Graphify" pack-ops/OPTIONAL-FEATURES.md` ; `wc -l .claude/skills/pack-startup/SKILL.md` ; `grep -n "Push to v11-dev\|Check CI after" pack-ops/PACK-CHAT.md` ; `ls scripts/hooks scripts/install-graphify-hook.sh` (absent) ; `find . -name "install-graphify-hook.sh" -o -name "graphify-pre-push.sh"` ; `grep -n graphify-out .gitignore` ; `ls maintenance-docs/v11-implementation/`
- **Output (verbatim, abridged):** `OPTIONAL-FEATURES.md` 555 lines; Graphify section header
  `## Graphify` at L354; freshness header `### How to keep it fresh — the post-commit hook`
  at L444; post-commit refs at L357, L406, L432, L434, L444, L446-448, L457, L467(`HEAD~1`),
  L472, L504, L506; `### §1.1 backend caveat` at L515-523. `pack-startup/SKILL.md` 87 lines
  (Step 3 = "Check CI tooling" L41-52; Step 4 report block L54-70; Steps 5-7 RESERVED comment
  L72-79; Step 8 deferred L81-87). `PACK-CHAT.md`: L156 "Push to v11-dev only", L206 "Check CI
  after every push". `scripts/hooks/` absent; `scripts/install-graphify-hook.sh` absent;
  `find` → no collisions. `.gitignore:76:graphify-out/`. `maintenance-docs/v11-implementation/`
  exists (carries BD-225 design/plan/research — the preservation pattern).
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** All surfaces exist where claimed; both NEW files are
  filename-unique (no collision). The Graphify runbook §"How to keep it fresh" spans
  L444-L513; FOUR upstream `post-commit` references (L357, L406, L432, L434) sit ABOVE the
  rewrite range and become stale after it — they MUST be reconciled (resolution carried in
  §6). The maintenance-docs preservation dir exists with the established BD-225 pattern.
- **Conclusion:** SUPPORTED.

### EE-9 — `validate-pack.py` carries Check 63 (graphify-out never-TRACKED) ONLY; NO freshness check exists or is added
- **Command:** `grep -n "Check 63\|check_graphify_out_never_tracked\|built_at_commit\|pre-push\|Check 65" scripts/validate-pack.py`
- **Output (verbatim, abridged):** Check 63 = `check_graphify_out_never_tracked` (the ONLY
  graphify check; `git ls-files graphify-out/` must return 0 rows); NO `built_at_commit`
  reference, NO `pre-push`, NO "Check 65".
- **HEAD-SHA:** `2f53788` | **Date:** 2026-06-20
- **Interpretation:** This plan adds NO validate-pack check (no CI gate — the rejected
  machinery). Check 63 is UNTOUCHED and stays green: the new tracked files are ordinary
  `scripts/` shell scripts; the runtime files (`.pack-refresh-status`, `.pack-refresh.lock`)
  live inside gitignored `graphify-out/` and are never staged, so `git ls-files
  graphify-out/` still returns 0.
- **Conclusion:** SUPPORTED.

---

## 1. Goal + BD addressed

**Goal:** Replace the BD-225 hand-installed, un-versioned `post-commit` recipe with a
TRACKED, self-installed `pre-push` hook that auto-refreshes the gitignored Graphify graph
IN THE BACKGROUND (non-blocking), pinned to the push-invoking worktree via
`$(git rev-parse --show-toplevel)` + an existence guard + a `cd "$ROOT"` so the correct
HEAD is stamped; plus a LOCAL `built_at_commit`-vs-HEAD freshness signal in `pack-startup`
and the hook's own next-run consult so a stale/never-completed refresh cannot rot silently
— all WITHOUT any CI gate, committed sentinel, "N", or `fetch-depth` edit.

**BD addressed:** BD-237 (sole). Closes the three charter failures:
- **#1 mechanism-never-ran** → automatic git-native `pre-push` trigger + TRACKED hook body
  (can't rot from "nobody copied the recipe"); one-time `install-graphify-hook.sh` per clone
  surfaced by the pack-startup readiness line.
- **#2 review-didn't-catch** → tracked, review-visible installer + hook body + self-reporting
  result record + the local freshness check.
- **#3 silent-rot** → LOCAL `built_at_commit`-vs-HEAD check on BOTH the human-facing
  pack-startup surface (resolution 2a) AND the hook's next-run consult (resolution 2b),
  which detects a never-completed refresh (no token written) that the prior token-only
  design missed (adversary B1/B2). This is the charter's named freshness criterion, on a
  LOCAL non-blocking surface — "fails loud" in the human-surface sense, not a CI gate.

---

## 2. File-by-file change list (ALL and ONLY the design's surfaces — incl. the pack-startup freshness line)

| # | File (path) | New/Edit | Concrete change |
|---|---|---|---|
| 1 | `scripts/install-graphify-hook.sh` | **NEW (tracked)** | Self-installer. Carries `# pack-internal: true` near the top (resolution 4 / EE-3 — MANDATORY: it is a top-level executable). Resolves the shared common hooks dir via `git rev-parse --git-path hooks`; copies `scripts/hooks/graphify-pre-push.sh` → `<hooksdir>/pre-push`; `chmod +x`; idempotent (byte-compare; no-op if identical); prints `graphify pre-push hook: installed at <path>`. Pack-ops-only; NEVER ships to clients. Logic in §4.1. |
| 2 | `scripts/hooks/graphify-pre-push.sh` | **NEW (tracked)** | The `pre-push` hook BODY (source the installer copies). Carries `# pack-internal: true` (forward-safe; Check 23 does NOT reach a subdir per EE-3, but the marker costs nothing and documents intent). NEW dir `scripts/hooks/`. Logic in §4. |
| 3 | `pack-ops/OPTIONAL-FEATURES.md` | **EDIT (rewrite L444-L513 + reconcile 4 upstream stragglers)** | Rewrite §"How to keep it fresh" (L444-L513) to the `pre-push` model. Reconcile the FOUR upstream `post-commit` references (L357, L406, L432, L434 per EE-8) — they describe the replaced mechanism (L432-434's "cannot be committed: gitignored plus `.git/hooks` is per-clone" is now FALSE for the TRACKED hook BODY). PRESERVE §1.1 backend caveat (L515-523, claude-cli-not-claude / no `--no-viz`) verbatim. Details in §6. |
| 4 | `.claude/skills/pack-startup/SKILL.md` | **EDIT (add freshness+install readiness line, reserved Step 5)** | Add a NEW reserved Step (Step 5) that emits the LOCAL freshness+install readiness line, plus a matching `graph:` line in the Step-4 report block. Logic in §5.1. Reserved Step 5 per the SKILL's own L72-79 comment ("Steps 5 and 6 are open for future surface additions"). NOT a gate; never fails startup. |
| 5 | `pack-ops/PACK-CHAT.md` | **EDIT (one-line informational note near L156/L206)** | Add an informational note that the `pre-push` hook auto-refreshes the graph in the background on every push (so the orchestrator knows it is automatic and does NOT duplicate a manual refresh). Informational; adds NO orchestrator step. |
| 6 | `maintenance-docs/v11-implementation/` | **PRESERVE (new files)** | Copy the capability report + the design + THIS plan + the adversarial review + the forthcoming IMPL-REPORT into `maintenance-docs/v11-implementation/` per charter (preservation pattern matches BD-225's docs already there). Suggested names: `CAPABILITY-REPORT-BD-237.md`, `DESIGN-BD-237.md`, `PLAN-BD-237.md`, `ADVERSARIAL-PLAN-REVIEW-BD-237.md`, `IMPL-REPORT-BD-237.md`. |
| — | (runtime, NOT tracked) | n/a | `graphify-out/.pack-refresh-status` + `graphify-out/.pack-refresh.lock` (a DIR, from `mkdir`) live INSIDE gitignored `graphify-out/` (`.gitignore:76`) — never committed; listed only so the coder knows they exist. |

**Boundary attestation:** every surface is pack-ops-side (`scripts/`, `pack-ops/`,
`.claude/skills/pack-startup/`, `maintenance-docs/`). NO `project-template/` and NO
`supporting-docs/` file is touched. The hook + installer NEVER appear in any install map.
`pack-only` keyword is correct (Check 36).

---

## 3. Root resolution (resolution 1 — the minimal-design approach; the cross-worktree scan is DROPPED)

The prior plan added a `git worktree list` scan that resolved to "the worktree that owns
the graph." The adversary measured that this STAMPS THE WRONG `built_at_commit` (graphify's
`_git_head()` uses process CWD, not `$ROOT` — EE-6) and that refreshing worktree B's graph
on an A-push is a surprise. **The user DROPPED it.** The resolution is now exactly the
minimal design's:

```bash
ROOT="$(git rev-parse --show-toplevel)"        # the push-invoking worktree
[ -d "$ROOT/graphify-out" ] || exit 0          # existence guard: no graph here -> silent no-op
```

- NO `git worktree list` scan, NO multi-owner enumeration, NO cross-worktree refresh, NO
  lexicographic tie-break.
- The refresh subshell `cd`s into `$ROOT` (§4 step 7) BEFORE invoking graphify, so
  `_git_head()` (which runs `git rev-parse HEAD` against process CWD, no `-C`, no chdir —
  EE-6) stamps `$ROOT`'s OWN HEAD into `$ROOT`'s graph. Correct stamp, no cross-tree
  surprise.
- Real cadence is fully covered: pushes during the v11-dev phase originate FROM `…-v11-dev`
  (EE-1), so `--show-toplevel` IS the graph owner. A future MAIN-tree push (no
  `graphify-out/`) safely `exit 0` no-ops — never builds a spurious graph.

There is NO §3.2 multi-branch algorithm in this plan. The resolution is the two lines above.

---

## 4. The hook body logic (precise, no gaps) — `scripts/hooks/graphify-pre-push.sh`

Ordered stages. The hook MUST `exit 0` on every non-skip exit path — a refresh problem
NEVER blocks the push.

1. **Shebang + marker + safety.** First lines:
   ```bash
   #!/usr/bin/env bash
   # pack-internal: true
   # graphify pre-push background graph-refresh (BD-237). Never blocks a push.
   ```
   (`# pack-internal: true` is forward-safe even though Check 23 does not reach a subdir —
   EE-3.) Do NOT use `set -e` (a refresh non-zero must not abort the hook before `exit 0`).
   Stock macOS bash is 3.2 — do NOT use `mapfile`/`readarray` or bash-4 features.

2. **Drain stdin FIRST + derive the doc-gate range (resolution 6 / EE-7).** `pre-push`
   delivers ref-update lines on STDIN: `<local ref> <local oid> <remote ref> <remote oid>`,
   ONE per pushed ref. Read ALL of stdin into a variable immediately (so git's pipe never
   blocks). Compute `zero="$(git hash-object --stdin </dev/null | tr '0-9a-f' '0')"`. Then
   the range policy — **simplest safe default: a single doc-gate decision over the whole
   push:**
   - If stdin is EMPTY/unavailable → no range → fall back to a full code-only `update`
     (no doc-gate).
   - For each line: if `local_oid == zero` (DELETE) → contributes NO range (skip that ref).
   - else if `remote_oid == zero` (NEW BRANCH) → that ref's range = `local_oid` (all commits
     on the new branch).
   - else (UPDATE / force-push — same shape) → that ref's range = `remote_oid..local_oid`.
   - **Aggregation across MULTIPLE refs:** the doc-gate runs `git diff --name-only <range>`
     over EACH non-delete ref's range; if ANY ref's range touches a `.md`/`.pdf` doc-layer
     file → SEMANTIC branch; else → CODE branch. (Union semantics: any doc change anywhere
     in the push triggers the semantic refresh.)
   - **Conservative fallback (covers ambiguity):** if ANY range cannot be computed (a
     `git diff` over it errors), OR the push is delete-only (every line is a delete), fall
     back to a full code-only `update "$ROOT"` (no doc-gate) — never the more expensive
     semantic branch by accident, and never a hard error. A pure delete-only push MAY
     instead `exit 0` no-op (nothing was published that changes the corpus); the coder
     picks no-op-on-pure-delete OR full-`update`-on-pure-delete — full `update` is the
     safe default and is recommended (it costs ~0 tokens and keeps the code graph current).
   - **Force-push** is the same `remote..local` shape (possibly non-fast-forward); `git
     diff` over it still works — no special case needed.

3. **Resolve the root + existence guard (§3 / resolution 1).**
   ```bash
   ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
   [ -n "$ROOT" ] && [ -d "$ROOT/graphify-out" ] || exit 0
   ```

4. **graphify-executable guard.** `GFX="$(command -v graphify)"; [ -x "$GFX" ] || exit 0`
   (preserve the "silent no-op if graphify missing").

5. **Outer `mkdir` skip-lock (EE-2 — flock absent).**
   ```bash
   LOCK="$ROOT/graphify-out/.pack-refresh.lock"
   mkdir "$LOCK" 2>/dev/null || { echo "graphify: refresh already in flight; skipping" >&2; exit 0; }
   ```
   `.pack-refresh.lock` is a DIRECTORY (mkdir-atomic). It is removed by the BACKGROUND
   subshell's `trap 'rmdir "$LOCK" 2>/dev/null' EXIT` (step 7a), NOT the foreground hook
   (the foreground exits immediately — add a one-line comment so a maintainer does not "fix"
   the missing foreground trap and double-rmdir). A second push during an in-flight refresh
   SKIPS (non-blocking); the lock auto-clears when the background process dies.

6. **Next-run consult (resolution 2b — DUAL signal: token OR built_at_commit-behind).**
   Before launching, surface a prior stale state on stderr (human-visible at this push):
   ```bash
   # (a) token signal: a recorded fail from a completed-but-failed prior refresh
   STATUS_FILE="$ROOT/graphify-out/.pack-refresh-status"
   if [ -f "$STATUS_FILE" ] && [ "$(cut -d' ' -f1 "$STATUS_FILE" 2>/dev/null)" = "fail" ]; then
     echo "graphify: previous refresh FAILED at $(cut -d' ' -f2 "$STATUS_FILE"); re-running" >&2
   fi
   # (b) built_at_commit-behind signal: catches a refresh KILLED mid-run (no token written)
   GBC="$(tail -c 200 "$ROOT/graphify-out/graph.json" 2>/dev/null \
          | grep -o '"built_at_commit": *"[0-9a-f]*"' | grep -o '[0-9a-f]\{7,\}')"
   HEADC="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)"
   if [ -n "$GBC" ] && [ -n "$HEADC" ] && [ "$GBC" != "$HEADC" ]; then
     echo "graphify: graph is STALE (built at ${GBC}, HEAD ${HEADC}); refreshing" >&2
   fi
   ```
   Both are LOCAL reads of the graph's own field — no committed artifact. (b) is the
   adversary-B1 fix: a refresh killed before writing a token leaves the graph behind HEAD,
   and (b) detects it on the next push regardless of the token. Proceed to launch regardless
   (a fresh refresh runs anyway). NOTE: `built_at_commit` is the LAST JSON field (EE-4), so
   the bounded `tail -c 200` recovers it without parsing the whole graph; the grep extracts
   the SHA. (The coder MAY use `python3 -c 'json.load…'` instead if more robust — both are
   O(1)-bounded enough for a once-per-push hook; the `tail`+`grep` avoids a python spawn.)

7. **Background-detached refresh subshell.** Launch `( … ) >/dev/null 2>&1 &` then `exit 0`.
   **Coder-verify (§5.3-V1):** confirm the detached subshell SURVIVES `git push` exit; if it
   is reaped, wrap with `setsid`/`nohup`/`disown` (verify empirically on this machine —
   push, then confirm the refresh completes after `git push` returns and `built_at_commit`
   advances). Inside the subshell, in order:
   a. `trap 'rmdir "$LOCK" 2>/dev/null' EXIT` (release the skip-lock when done/killed).
   b. **Key-clean:** `unset GEMINI_API_KEY GOOGLE_API_KEY OPENAI_API_KEY` (subscription-only;
      defense-in-depth — every graphify line also pins `--backend claude-cli`).
   c. **`cd "$ROOT"` (resolution 1 / EE-6 — CRITICAL for the correct stamp), then run the
      branch chosen in step 2.** Both branches are pinned by CWD=`$ROOT` + the EXPLICIT
      `"$ROOT"` target arg. The EXACT invocations:
      - **SEMANTIC branch** (a `.md`/`.pdf` was in any pushed range):
        ```bash
        cd "$ROOT" || exit 0
        GRAPHIFY_CLAUDE_CLI_PARALLEL=0 graphify extract "$ROOT" --backend claude-cli
        ```
        `extract`'s output dir derives from the `"$ROOT"` target arg (it appends literal
        `graphify-out` → `$ROOT/graphify-out`); `GRAPHIFY_OUT` is INERT on `extract` (EE-6 /
        resolution 3 / M1) and is therefore NOT set on this line. NEVER `--backend claude`
        (paid API). NEVER `--no-viz` on `extract` (unknown-option error). NEVER
        `GRAPHIFY_FORCE` on `extract` (it ignores it and prunes removals natively).
      - **CODE-only branch** (no doc-layer change, OR the conservative fallback):
        ```bash
        cd "$ROOT" || exit 0
        GRAPHIFY_OUT="$ROOT/graphify-out" graphify update "$ROOT"
        ```
        `update`/`_rebuild_code` HONORS `GRAPHIFY_OUT` (watch.py:398 — EE-6) AND takes the
        explicit `"$ROOT"` scan-root arg; both pin the write to `$ROOT/graphify-out`. On a
        push whose range DELETED a file, add `GRAPHIFY_FORCE=1` to THIS line ONLY (bypasses
        the node-shrink safety check after refactors that delete code):
        ```bash
        GRAPHIFY_FORCE=1 GRAPHIFY_OUT="$ROOT/graphify-out" graphify update "$ROOT"
        ```
      **Why `cd "$ROOT"` matters for BOTH branches:** the stamped `built_at_commit` comes
      from `_git_head()` = `git rev-parse HEAD` in the process CWD (EE-6, no `-C`, no
      chdir). With CWD=`$ROOT` the stamp is `$ROOT`'s HEAD — correct. (Since the real cadence
      already pushes FROM `$ROOT`, CWD is usually already `$ROOT`; the explicit `cd` makes it
      robust and is the documented contract.)
   d. **Single self-retry:** capture the refresh exit; if non-zero, run the SAME branch
      ONCE more; capture that exit. Bounded at 2 attempts total — NO loop, NO "N".
      **Coder-verify (§5.3-V4):** confirm the single `extract` retry re-bills only genuine
      cache-misses (the semantic cache is content-keyed/incremental per the capability
      report Q3 — a retry should not re-extract cache-hit files), keeping the retry cheap.
   e. **Result record:** write a single line to `$ROOT/graphify-out/.pack-refresh-status`
      ATOMICALLY (write to `.pack-refresh-status.tmp` then `mv` — atomic on same fs — so a
      kill mid-write cannot leave a torn first token):
      `ok <HEAD-SHA> <ISO-8601>` if the final attempt exited 0, else `fail <HEAD-SHA>
      <ISO-8601>`. `<HEAD-SHA>` = `git -C "$ROOT" rev-parse HEAD`. The token is now ADVISORY
      (the load-bearing staleness signal is the `built_at_commit`-vs-HEAD check in step 6b
      and §5.1) — the token just gives a human-readable "the last run failed" message.

8. **Foreground `exit 0`** (already left after launching the subshell) — push proceeds.

### 4.1 The installer logic — `scripts/install-graphify-hook.sh`
```bash
#!/usr/bin/env bash
# pack-internal: true                  # MANDATORY (resolution 4 / EE-3: top-level executable)
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)/hooks/graphify-pre-push.sh"   # next to the installer
DEST="$(git rev-parse --git-path hooks)/pre-push"                 # shared common dir (EE-5)
mkdir -p "$(dirname "$DEST")"                                     # defensive (fresh clone)
if [ -f "$DEST" ] && cmp -s "$SRC" "$DEST"; then
  echo "graphify pre-push hook: already current at $DEST"; exit 0
fi
cp "$SRC" "$DEST"; chmod +x "$DEST"
echo "graphify pre-push hook: installed at $DEST"
```
- Idempotent (byte-compare via `cmp -s`; no-op if identical).
- NO state-changing git verb (a `cp`+`chmod`, not a git op) — but it mutates `.git/hooks`
  LIVE state, so the ORCHESTRATOR runs it with USER APPROVAL (§7), never a coder.

---

## 5. Verification strategy

### 5.1 The pack-startup freshness+install readiness line (resolution 2a — LOCAL, the human-facing surface)
**Placement:** a NEW reserved **Step 5** in `.claude/skills/pack-startup/SKILL.md` (the
SKILL's own L72-79 comment reserves Steps 5/6 "for future surface additions"). Do NOT bolt
it onto Step 3 (GitHub-MCP detection — unrelated concern, and Step 3 has no report slot for
it). Add a matching `graph:` line to the Step-4 report block (L60-69) so the readiness
appears in the summary.

**Exact Step-5 logic (LOCAL only — no CI, no committed artifact):**
1. Resolve `ROOT="$(git rev-parse --show-toplevel)"`. Existence-gate on
   `[ -f "$ROOT/graphify-out/graph.json" ]` — if absent (fresh clone / graphify not built),
   print `graph: not built (graphify is an optional pack-dev accelerator)` and continue
   (zero-friction degradation; never fails startup).
2. **Freshness:** read `built_at_commit` (the LAST field — EE-4) with a bounded
   `tail -c 200 "$ROOT/graphify-out/graph.json"` + extract the SHA (or `python3 -c
   'json.load…'`), compare to `git -C "$ROOT" rev-parse HEAD`:
   - equal → `graph: fresh`
   - differ → `graph: STALE — built at <built_sha8>, HEAD <head_sha8> (run: git push, or
     bash scripts/install-graphify-hook.sh then push)`
3. **Hook-installed:** check the hook is present —
   `[ -f "$(git rev-parse --git-path hooks)/pre-push" ]` →
   `pre-push hook: installed` / `pre-push hook: NOT installed — run
   scripts/install-graphify-hook.sh`.
4. Emit BOTH on a single readiness line (and the Step-4 report `graph:` line), e.g.
   `graph: STALE — built at 190e198, HEAD 2f53788 | pre-push hook: NOT installed — run scripts/install-graphify-hook.sh`.
   NOT a gate; Step 5 NEVER fails the session ("fails loud" = the human sees STALE/NOT
   installed, not a non-zero exit). This is the charter's freshness criterion
   (`built_at_commit` vs HEAD) on a LOCAL surface — honoring BOTH the "no CI gate" rejection
   AND the "FAILS LOUD" acceptance criterion.

### 5.2 Test-wiring (resolution 5 / M4 — SUBTRACTIVE; NO allowlist entry)
**DECISION: BD-237 adds NO new `scripts/test*.sh`.** Rationale (size/fit, not deferral):
- The root resolution is now the minimal-design two-liner (§3) — there is no multi-branch
  resolution algorithm left to unit-test (the prior plan's four-branch test existed only for
  the dropped tightening).
- The remaining shell-logic legs that COULD be unit-tested (skip-lock skip, status-token
  write, doc-gate selection) are testable with a stubbed `graphify` on PATH, BUT the
  highest-value legs (background-detach survival, real-`graphify`/real-`claude` refresh,
  `built_at_commit` advance) are non-deterministic on a CI runner. Splitting "the
  deterministic shell legs" from "the machine-only legs" into an auto-wired test is
  legitimate but is net new test infrastructure that the URGENT single-commit fix does not
  require for correctness — the in-fix coder-verify items (§5.3) + the orchestrator live
  checks (§7) cover the load-bearing behaviors.

**The governance fact the coder MUST honor (so no one mis-wires later):** `scripts/test*.sh`
+ `scripts/tests/*.sh` + `scripts/tests/fixture-dependent/*.sh` AUTO-WIRE into the CI
`tests` job by EXISTING on disk; `scripts/ci-test-wiring-allowlist.txt` is a DENY-list that
SUBTRACTS a test from that disk-derived set (a script belongs there ONLY if it touches a
live network/GH surface OR is a manual-only dev utility). **Do NOT add an allowlist entry
for any BD-237 file.** IF the coder DOES choose to add a `scripts/test-graphify-pre-push.sh`
for the deterministic shell legs, it AUTO-WIRES and MUST be offline-deterministic (stub
`graphify` on PATH; assert only the shell logic — lock skip, status write, doc-gate
selection, range derivation) — and it gets NO allowlist entry. Machine-only verification
stays an orchestrator live step (§7), never an allowlist dodge.

### 5.3 In-fix coder-verify items (all WITHIN this v11.0 fix — none deferred)
| # | Item | How the coder verifies (on this machine) |
|---|---|---|
| V1 | background-detach survives `git push` exit | Push (or invoke the hook), then confirm the refresh completes AFTER `git push` returns and `built_at_commit` advances; if reaped, add `setsid`/`nohup`/`disown`. NOT a blocker (a reaped refresh ⇒ next push re-runs; step 6b surfaces it). |
| V2 | pre-push stdin format + range edge cases | Confirm stdin lines = `<local ref> <local oid> <remote ref> <remote oid>` (EE-7); confirm the full-`update` fallback covers empty/unavailable range, delete-only, multi-ref. |
| V3 | explicit-root + `cd "$ROOT"` writes to `$ROOT/graphify-out` with the CORRECT stamp | Run once from `…-v11-dev`: confirm `built_at_commit` advances `190e198`→HEAD in `$ROOT/graphify-out/graph.json` AND no stray `.`-relative `graphify-out/` is created elsewhere AND the stamped SHA equals `$ROOT`'s HEAD. |
| V4 | self-retry does not double-bill the subscription | Confirm a single `extract` retry re-bills only genuine cache-misses (content-keyed incremental cache, capability report Q3); keep retry to ONE attempt. |

### 5.4 Check 23 handling (resolution 4 / M2 / EE-3)
- `scripts/install-graphify-hook.sh` is a TOP-LEVEL executable → Check 23 WOULD fail it
  unless marked. It carries `# pack-internal: true` (correct: pack-ops-only, never a
  user-facing verb) — `_is_pack_internal` matches `^#\s*pack-internal:\s*true` in the first
  ~2000 bytes, so the marker MUST be a comment line near the top (§4.1 shows it on line 2).
  Check 23 then counts it as `flagged_internal` and passes.
- `scripts/hooks/graphify-pre-push.sh` is in a SUBDIR → Check 23's `iterdir()` does NOT
  descend (EE-3), so it is not scanned. It carries the marker anyway (forward-safe).
- The coder's PREFLIGHT runs `scripts/validate-pack.py` and confirms Check 23 (and the full
  battery) exit 0.

### 5.5 validate-pack stays green (EE-9)
NO validate-pack check is added or changed. The two new tracked files are ordinary
`scripts/` shell scripts; the OPTIONAL-FEATURES / SKILL / PACK-CHAT edits are prose. Check
63 (`graphify-out/` never-TRACKED) stays green: the runtime files
(`.pack-refresh-status`, `.pack-refresh.lock`) live inside gitignored `graphify-out/`
(`.gitignore:76`) and are never staged, so `git ls-files graphify-out/` returns 0. Coder
PREFLIGHT = `scripts/validate-pack.py` (Check 43 + full battery, incl. Check 23 per §5.4 and
Check 63 untouched) exit 0, plus the full CI suite per `verify-the-full-ci-suite`.

---

## 6. The OPTIONAL-FEATURES rewrite (surface #3 — bounded range + the 4 upstream stragglers)

**Rewrite L444-L513** (`### How to keep it fresh — the post-commit hook` through the
L497-513 "Install + VERIFY (a)(b)" caveats) to the `pre-push` model:
- The TRACKED hook body + self-installer (replaces "hand-installed … NOT a committed file");
- the root resolution `$(git rev-parse --show-toplevel)` + existence guard + `cd "$ROOT"`;
- worktree-safety stated CORRECTLY PER BRANCH (resolution 3 / M1): `update` is pinned by
  `GRAPHIFY_OUT` (absolute) AND the explicit `"$ROOT"` arg; `extract` is pinned by the
  explicit `"$ROOT"` target arg and `GRAPHIFY_OUT` has NO effect on it — do NOT state
  `GRAPHIFY_OUT` pins both. The correct-stamp reason is `cd "$ROOT"` (because `_git_head()`
  uses process CWD);
- the `mkdir` skip-lock (NOT flock — absent on macOS);
- the gitignored `.pack-refresh-status` result record (advisory) + single self-retry;
- the LOCAL `built_at_commit`-vs-HEAD freshness check (the pack-startup line + the hook's
  next-run consult) — the systemic remedy, LOCAL not CI;
- the per-clone install step (`bash scripts/install-graphify-hook.sh`).
- DELETE the L497-513 "(a) does the hook fire under worktree isolation / (b) atomic-swap"
  caveats — resolved by the existence guard + `mkdir` lock + the install model.
- PRESERVE the §1.1 backend caveat (L515-523) verbatim — do NOT "correct" it.

**Reconcile the FOUR upstream `post-commit` stragglers (EE-8, ABOVE the rewrite range):**
- **L357** "The graph, the post-commit hook, and the initial build are a per-clone,
  gitignored, MANUAL opt-in" → change "post-commit hook" to "pre-push hook"; the hook BODY
  is now TRACKED (only the per-clone INSTALL is manual) — adjust the "MANUAL opt-in"
  framing to "tracked hook body + one-time per-clone install."
- **L406** "the post-commit hook unsets all three in its own subshell" → "the pre-push
  hook unsets all three in its own subshell."
- **L432-434** "`graphify-out/`, the post-commit hook, and the global graph do NOT sync …
  they cannot be committed: gitignored plus `.git/hooks` is per-clone" → the hook BODY IS
  now committed/tracked (`scripts/hooks/graphify-pre-push.sh`); only the INSTALLED
  `.git/hooks/pre-push` copy is per-clone. Rewrite so it no longer claims the hook "cannot
  be committed."
- Also reconcile the in-range `HEAD~1 HEAD` doc-gate (L467/L472) — under `pre-push` the
  range is the pushed range from stdin (§4 step 2), NOT `HEAD~1 HEAD`.

**Completeness gate (coder PREFLIGHT + reviewer):** after the rewrite,
`grep -n "post-commit\|HEAD~1" pack-ops/OPTIONAL-FEATURES.md` returns ONLY intentional
HISTORICAL references (if any are deliberately kept to describe the OLD mechanism); every
LIVE reference to the replaced mechanism must be gone. This is the grep-zero discipline —
do not rely on a loose "reconcile any straggler."

---

## 7. Commit shape + the per-clone install + parallel/dependency map (BD-226 rule 10)

**SINGLE COMMIT.** All five tracked surfaces (installer, hook body, OPTIONAL-FEATURES
rewrite, pack-startup Step-5 line, PACK-CHAT note) land in ONE commit so the mechanism is
never half-applied. Each surface is a DISTINCT file → no same-file serialization; one
coherent change → no parallelizable sub-units → **ONE coder, ONE bounded review/fix cycle,
ONE worktree** (per BD-226 sub-agent isolation: the first coder creates the worktree; the
whole review/fix cycle runs inside it; the patch is produced only after a reviewer confirms
CLEAN).

- **Commit subject:** `feat: v11 — BD-237 graphify pre-push background graph-refresh hook + LOCAL freshness check (pack-only)`
- **Scope keyword:** `pack-only` (Check 36 — diff is exclusively `scripts/`, `pack-ops/`,
  `.claude/skills/pack-startup/`, `maintenance-docs/`; NO `project-template/` /
  `supporting-docs/`).
- **maintenance-docs preservation (surface #6):** rides the SAME commit OR a trailing
  `docs:` commit (orchestrator's call) — either keeps `pack-only`.
- **Coder order within the commit:** (1) hook body `scripts/hooks/graphify-pre-push.sh` →
  (2) installer `scripts/install-graphify-hook.sh` (references the body) → (3)
  OPTIONAL-FEATURES rewrite + straggler reconcile → (4) pack-startup Step-5 + report line →
  (5) PACK-CHAT note → (6) maintenance-docs preservation → PREFLIGHT (validate-pack full
  battery + the §5.3 in-fix coder-verify items green).

**Post-commit (ORCHESTRATOR, user-approved — agents NEVER run state-changing setup):**
after the BD-237 commit lands (so the tracked source exists to copy):
1. `bash scripts/install-graphify-hook.sh` (a `cp`+`chmod`, not a git verb, but it mutates
   `.git/hooks` live state → user-approved orchestrator action) — makes the hook ACTIVE in
   THIS clone so the fix is not inert in the very clone that exposed the defect.
2. ONE manual refresh to clear current staleness (EE-4: `built_at_commit 190e198` < HEAD) —
   either `git push` (the hook fires) or a direct `cd <v11-dev-root> && GRAPHIFY_OUT=…
   graphify update <v11-dev-root>` — and confirm `built_at_commit` advances to HEAD (this is
   coder-verify V3 done live by the orchestrator).

**Parallel/dependency map:** single commit ⇒ no parallel wave; the install + refresh are
SERIAL post-commit orchestrator steps (the install depends on the commit landing; the
refresh depends on the install).

---

## 8. Cross-doc consistency + no-leak confirmation
- The plan touches ALL design surfaces (installer, hook body, OPTIONAL-FEATURES rewrite +
  stragglers, pack-startup Step-5 freshness line, PACK-CHAT note, maintenance-docs) and
  ONLY those (`enumerate-encoding-surfaces`, lock-step in one commit).
- NO client-deliverable leak: no `project-template/` or `supporting-docs/` file; the hook +
  installer are pack-ops `scripts/` and never appear in any install map; the graph + runtime
  files are gitignored (`.gitignore:76`).
- PRESERVE the OPTIONAL-FEATURES §1.1 backend caveat verbatim; keep the doc internally
  consistent (the grep-zero gate in §6 catches dangling `post-commit`/`HEAD~1` refs).
- The PACK-CHAT note adds NO orchestrator push STEP (the hook is the trigger; the note is
  informational so Pack Chat does not duplicate a manual refresh).

---

## 9. Open risks / unknowns (all in-fix, none deferred)
- **R1 (V1):** background-detach survival across `git push` exit — verify; add
  `setsid`/`nohup`/`disown` if reaped. Mitigated by step-6b's `built_at_commit`-behind
  consult (a reaped run is caught next push).
- **R2 (V2):** pre-push stdin range edge cases (delete-only / multi-ref / new-branch /
  force) — the conservative full-`update` fallback covers ambiguity.
- **R3 (V3):** correct-stamp write — `cd "$ROOT"` + explicit `"$ROOT"` arg pins the write
  AND the stamp; verify `built_at_commit` advances and equals `$ROOT`'s HEAD.
- **R4 (V4):** self-retry billing — single `extract` retry re-bills only genuine misses.
- **R5 (low):** the `tail -c 200`+grep `built_at_commit` extraction assumes the field stays
  the LAST JSON key (EE-4, current 0.8.39 behavior). If a future graphify reorders fields,
  the bounded read could miss it — the coder MAY use `python3 -c 'json.load…'` for
  robustness (both are O(1)-cheap for a once-per-push / once-per-startup read). NOT a
  blocker today (measured last-field at HEAD `2f53788`).

No risk is resolved by deferral; every coder-verify is WITHIN this v11.0 fix.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | All commands run were read-only: `git rev-parse`/`worktree list --porcelain`/`config --get`/`rev-parse HEAD`/`--version`/`--exec-path` (read); `ls`/`cat`/`grep`/`sed -n`/`wc`/`tail -c`/`python3 -c json.load`/`command -v` (read); `graphify` NOT invoked to mutate (NO `update`/`extract`/`hook install`); one `mkdir -p /tmp/pack-handoff-bd237-plan2`. NO graph mutation; NO source edit; NO state-changing git verb. Sole write = this plan doc. | COMPLIANT |
| 2 | empirical-evidence-blocks [planner] | EE-1..EE-9 each carry command + verbatim output + HEAD-SHA `2f53788` + interpretation + conclusion, backing every repo-state claim: worktrees/single-owner (EE-1), flock-absent (EE-2), Check 23 top-level/non-recursive/marker (EE-3), graph-stale + built_at_commit-is-last-field (EE-4), hooks-dir-empty/core.hooksPath-unset (EE-5), extract-ignores-GRAPHIFY_OUT + _git_head-uses-CWD + no-chdir (EE-6), pre-push stdin contract (EE-7), surfaces/line-ranges + 4 stragglers (EE-8), Check 63-only/no-freshness-check (EE-9). | COMPLIANT |
| 3 | graph-first-context | The graph is the STALE artifact under repair (EE-4: built_at `190e198` < HEAD `2f53788`); I fell through to grep/Read/git/installed-source for ALL authoritative facts (SSOT charter fields, validate-pack source, graphify source, uncommitted prior docs) per the G2/exception path. Did not block on the graph. | COMPLIANT |
| 4 | separate-pack-ops-from-product | §2 + §8: every surface is pack-ops (`scripts/`, `pack-ops/`, `.claude/skills/pack-startup/`, `maintenance-docs/`); NO `project-template/`/`supporting-docs/` touch; hook+installer never ship to clients (no install map); runtime files gitignored (`.gitignore:76`). `pack-only` keyword justified. | COMPLIANT |
| 5 | verify-availability-not-just-existence | Re-verified LIVE/from-source, not the docs' say-so: flock ABSENT (EE-2 → mkdir lock), Check 23 non-recursive `iterdir()`+marker regex (EE-3), `extract` out-dir derives from target NOT GRAPHIFY_OUT + `update` honors GRAPHIFY_OUT + `_git_head` uses process CWD + NO os.chdir (EE-6), pre-push stdin contract from the authoritative sample (EE-7), built_at_commit is the last JSON field (EE-4). FLAGGED 4 in-fix coder-verify items (§5.3 V1-V4) for behaviors only confirmable on the machine (detach survival, stdin range, correct-stamp write, retry billing) — none assumed. | COMPLIANT |
| 6 | enumerate-encoding-surfaces [planner] | §2 enumerates ALL and ONLY the design surfaces INCLUDING the pack-startup freshness line (Step 5) added by resolution 2a — installer, hook body, OPTIONAL-FEATURES rewrite+stragglers, pack-startup Step-5 + report line, PACK-CHAT note, maintenance-docs; runtime files noted non-tracked — landing lock-step in one commit (§7). | COMPLIANT |
| 7 | scope-deliverables-to-the-ask | Folded ALL 6 resolutions (§0 map); the freshness check is LOCAL-only (pack-startup §5.1 + hook consult §4-step6) — stated explicitly. Reintroduced NO CI gate / committed sentinel / "N" / fetch-depth / new validate-pack check (EE-9; §0 banner; row below). No scope expansion (dropped the cross-worktree scan, added no new test per resolution 5). | COMPLIANT |
| 8 | deferral-is-scope-creep / no-deferral-without-user-direction | All work lands in v11.0 single commit (§7); the 4 coder-verify items (§5.3) are in-fix; the "no new test" decision (§5.2) is size/fit-justified (the multi-branch algorithm was dropped; machine-only legs are non-deterministic on CI), NOT a punt to a later BD/version. | COMPLIANT |
| 9 | ci-check-runtime-compounding | N/A — this plan adds NO new CI/validate-pack check (EE-9). The freshness check is a LOCAL `tail -c`-bounded O(1) read (built_at_commit is the last field, EE-4) on the pack-startup surface + the once-per-push hook consult — not a CI battery check. | N/A: no new CI check |
| 10 | rules-applied-verification-block | This block — one row per in-force rule + the explicit no-rejected-machinery row below. | COMPLIANT |
| — | **NO rejected machinery; freshness is LOCAL-only** (explicit) | Plan-wide: NO committed freshness sentinel, NO new validate-pack check / "Check 65" (EE-9 confirms Check 63 is the only graphify check, UNTOUCHED), NO lag-tolerance "N" / commit-count, NO `fetch-depth` edit, NO CI gate of any kind. The freshness check is LOCAL ONLY: pack-startup Step-5 readiness line (§5.1) + the hook's next-run consult (§4-step6), both reading the gitignored graph's own `built_at_commit` field vs local HEAD — nothing committed, nothing in CI. | COMPLIANT |

---

*End of PLAN-BD-237-FINAL. Read-only planner output; no source edits, no state-changing
git verbs, no graph mutation. Sole write = this file.*
