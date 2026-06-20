# ADVERSARIAL-PLAN-REVIEW-BD-237 — Graphify `pre-push` background graph-refresh

**Agent:** FRESH `pack-planner` (ADVERSARIAL review; did NOT author the design or the plan)
**Repo:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Branch / HEAD:** `v11-dev` / `2f53788620e1bdb233eb8ed645801c995093bafe`
**Date:** 2026-06-20
**Under review:** `/tmp/pack-handoff-bd237-plan/PLAN-BD-237.md` (the PLAN) resting on
`/tmp/pack-handoff-bd237-min/DESIGN-BD-237.md` (the DESIGN), informed by
`/tmp/pack-handoff-bd237-research/CAPABILITY-REPORT-BD-237.md` (the CAPABILITY report).
**Posture:** every load-bearing claim re-measured from the installed graphify-0.8.39
source + the live repo. A claim is unproven until re-verified. I read all three docs in
full and treat their EE blocks as CLAIMS, not facts.

---

## Verdict (up front)

**NEEDS-REWORK.** The plan is well-structured and re-introduces NONE of the rejected
machinery, and most of its repo-state EE blocks re-measure clean. BUT it carries **two
purpose-defeating gaps** that mean it does NOT genuinely close charter failure #3
(silent rot), plus **two concrete CI/source-fact errors** the coder would hit:

1. **BLOCKER (DESIGN+PLAN) — the "never-completed" refresh re-creates silent staleness.**
   The status record is written ONLY after the refresh finishes; a refresh killed mid-run
   (terminal close / sleep / reboot — the exact class that froze the graph originally)
   leaves NO `fail` token, the next-push consult sees nothing-or-stale-`ok`, and nothing
   detects the un-advanced `built_at_commit`. Failure #3 is RELOCATED, not closed.
2. **BLOCKER (DESIGN+PLAN) — the verification surface drops the `built_at_commit`-vs-HEAD
   comparison the charter explicitly named** as the freshness criterion, relying solely on
   the `.pack-refresh-status` token that goes missing in gap #1. The pack-startup advisory
   checks INSTALL-status only, never STALENESS — so an installed-but-frozen graph passes.
3. **MAJOR (DESIGN+PLAN) — `GRAPHIFY_OUT` is INERT on the `extract` (semantic) branch**;
   the plan/design name it as the worktree-safe write lever for BOTH branches. Measured
   false against source. Works by accident (the `$ROOT` target arg), but the stated
   mechanism is wrong and a coder leaning on it can mis-fix.
4. **MAJOR (PLAN) — Check 23 (`check_help_fragment_completeness`) WILL fail on the new
   top-level installer if it is committed executable**, unless it is marked
   `# pack-internal: true` or listed in HELP-FRAGMENT-PACK.md. The plan's EE-G checked
   only Check 63 and asserts "validate-pack stays green" — that conclusion is unproven and
   likely WRONG for the installer.

Plus the tightening's own cross-worktree semantics are a latent surprise (MAJOR, below),
the design↔plan disagree on the pack-startup Step placement (MINOR), and the OPTIONAL-
FEATURES rewrite leaves four out-of-range `post-commit` stragglers the plan under-specifies
(MINOR). Details, each with an independent re-measurement, follow.

---

## What re-measured CLEAN (the plan got these right)

- **EE-B flock ABSENT → mkdir lock.** `command -v flock` → `ABSENT` (HEAD `2f53788`). CORRECT.
- **EE-C hooks dir empty / `core.hooksPath` unset / shared common dir.** `git rev-parse
  --git-path hooks` → `/Users/david/Developer/optiquity-ai-agent-config-pack/.git/hooks`;
  `ls` → `total 0`; `git config --get core.hooksPath` → exit 1. CORRECT (both worktrees
  share the `main` checkout's `.git`).
- **EE-D graph stale.** `built_at_commit` = `190e1985…`, HEAD = `2f53788…`. CORRECT.
- **EE-A worktrees / single owner.** Two worktrees; only `…-v11-dev` has `graphify-out/`. CORRECT.
- **claude-cli runs non-interactive in a detached hook (plan claim #5 / design §9.2-adjacent).**
  `llm.py:1104` `subprocess.run(cli_args, input=user_message, capture_output=True, ...)` with
  `claude -p --output-format json --no-session-persistence` (llm.py:1088-1090). It pipes the
  prompt via `input=` (own stdin pipe, not the hook's drained git stdin) and needs NO TTY.
  `claude` present + authenticated locally (`/Users/david/.local/bin/claude` v2.1.178);
  `ANTHROPIC_API_KEY` UNSET → the `claude-cli` no-key path is the one that runs. **SUPPORTED.**
  (Residual dependency: a one-time interactive `claude` login must already have happened —
  pre-existing, not a regression. Worth a one-line note in the runbook, not a blocker.)
- **`--backend claude-cli` is the no-key subscription path; `claude` ≠ `claude-cli`.** Matches
  the capability report; the doc-preserve instruction (OPTIONAL-FEATURES §1.1) is correct.

These are not re-litigated below.

---

## BLOCKER findings

### B1 — [DESIGN + PLAN] The "started-but-never-finished" refresh re-creates silent staleness (failure #3 RELOCATED, not closed)

- **Claim challenged:** PLAN §1 / §7 row #3 + DESIGN §5.2 / §7: "silent rot cannot persist —
  the next push surfaces the stale state" via the `.pack-refresh-status` record + next-push
  consult + single self-retry.
- **Re-measurement (plan ordering, HEAD `2f53788`):** PLAN §4-step7 writes the status line
  ONLY in sub-step **7e**, AFTER both refresh attempts (7c + the 7d retry) return:
  ```
  e. Result record: write a single line to $ROOT/graphify-out/.pack-refresh-status:
     `ok <HEAD-SHA> <ISO>` if the final attempt exited 0, else `fail <HEAD-SHA> <ISO>`.
  ```
  And PLAN §4-step6 (next-push consult) reacts ONLY to an explicit `fail` first token:
  ```
  If it is `fail`, emit ONE stderr line ... ; re-running. Proceed regardless.
  ```
  The lock is released by `trap 'rmdir "$LOCK"' EXIT` (step 7a) on ANY exit incl. kill.
- **Interpretation:** Trace the exact failure class the charter names (Provenance: "frozen
  since the initial build"; a refresh that simply never ran to completion). If the detached
  subshell is KILLED between launch and 7e — terminal close right after `git push` returns,
  laptop sleep, OOM, reboot, `kill` — then: (a) NO line is written for this run (or a STALE
  prior `ok <old-sha>` survives); (b) `trap` clears the lock, so the NEXT push proceeds
  normally and CONSULTS the record; (c) the consult sees nothing-or-`ok`, prints nothing,
  and the operator believes the graph is fresh. `built_at_commit` is still behind HEAD.
  **This is exactly failure #3** — installed mechanism, ran once, silently froze, no surface
  noticed. The design's own §9.2 flags detach-survival as "a reaped refresh just means the
  next push re-runs" (PLAN R1) — but that is only true if SOMETHING detects the previous run
  did not finish. Nothing does. The "never-completed" state has no token, and the consult is
  token-only. The verification keys on the wrong thing (see B2).
- **Wrong vs unproven:** WRONG (a design gap, not a coder-verify). The mechanism as specified
  cannot detect a never-completed run.
- **Fix (concrete, no rejected machinery):** Make the verification key on the TRUTH the
  charter named — `built_at_commit` vs HEAD — not on a self-reported token:
  1. The hook's next-push consult (and the pack-startup advisory, B2) compares
     `python3 -c 'json.load…["built_at_commit"]'` of `$ROOT/graphify-out/graph.json` against
     `git -C "$ROOT" rev-parse HEAD@{push-target}` (or simply the resolved-root HEAD). If the
     graph is BEHIND, surface it ("graphify: graph is N-or-more commits behind <root> HEAD;
     refreshing") and refresh — regardless of any token. This is O(1), no LLM, cron-cheap
     (`ci-check-runtime-compounding` satisfied), and is the explicit charter primitive.
  2. OPTIONALLY write a `running <sha> <ts>` token BEFORE launching the refresh and overwrite
     it with `ok/fail` at 7e; then a surviving `running` token at the next consult signals a
     never-completed run. (The `built_at_commit` check in (1) already covers it; the
     `running` token is belt-and-suspenders, optional.)
  The point is: the staleness SIGNAL must be the graph's own commit stamp, which cannot go
  missing, not a separate record that disappears with the process.

### B2 — [DESIGN + PLAN] Verification surface drops the charter-named `built_at_commit`-vs-HEAD freshness criterion; the pack-startup advisory checks INSTALL-status only, never STALENESS

- **Claim challenged:** PLAN §2 row 4 / §5.3 + DESIGN §1.3 / §6 row 5: the pack-startup
  readiness advisory prints "graphify pre-push hook: installed / NOT installed".
- **Re-measurement (charter, BD-237.md, HEAD `2f53788`):** the charter Scope + Acceptance
  criteria are explicit:
  > "Freshness criterion = `graph.json` `built_at_commit` vs `git rev-parse HEAD` (VERIFIED
  > reliable; NOT `check-update`/`needs_update`…), cheap O(1)…"
  > "a production-verification check (CI and/or `pack-startup`) that detects a stale or
  > never-refreshed graph (and/or a missing/inert refresh mechanism) and FAILS LOUD, so
  > silent rot cannot recur."
  The plan's advisory is gated on `[ -f graphify-out/graph.json ]` and prints install-status
  only; PLAN §5.3 closes "NOT a gate; never fails startup." Neither doc reads
  `built_at_commit` anywhere in the verification surface (grep of both docs: `built_at_commit`
  appears only in EE-D as the staleness EVIDENCE and in the §9.4 coder-verify-the-advance
  step — never as the live check).
- **Interpretation:** The user REJECTED a CI gate / validate-pack "Check 65" / sentinel —
  that part is correctly honored. But the charter's freshness CRITERION (built_at_commit vs
  HEAD) is independent of WHERE the check lives; it can live in the LOCAL pack-startup
  surface and the hook's consult without any CI. The design substituted "is the hook
  installed?" for "is the graph fresh?" — a strictly weaker signal. An installed hook whose
  background refresh silently froze (B1) reports "installed" and the operator is reassured.
  The single most reliable, zero-LLM, charter-named signal is omitted from the only surface
  a human sees. This is the systemic remedy for failures #2+#3, and it is missing.
- **Tension to surface to the user (NOT a unilateral planner call):** the user's "no CI
  gate / no validate-pack check" rejection and the charter's "FAILS LOUD" acceptance
  criterion are in apparent conflict. The MINIMAL reconciliation that honors BOTH: a
  pack-startup STALENESS check (built_at_commit vs HEAD) that LOUDLY prints "STALE — refresh
  did not complete; run …" (not merely "installed"), and is non-blocking (never fails the
  session) — "fails loud" in the human-surface sense, not the CI-gate sense. Whether
  "fails loud" must mean a non-zero exit anywhere is a user decision; the planner must
  PRESENT it, not silently downgrade the acceptance criterion to "installed/not-installed".
- **Wrong vs unproven:** WRONG (the verification design does not meet the charter's stated
  criterion). The downgrade from STALENESS to INSTALL-status is a substantive scope
  reduction made without surfacing it as a user decision.
- **Fix:** make the pack-startup line (and the hook consult) compare `built_at_commit` to the
  resolved-root HEAD and surface STALE loudly + offer the one-liner; keep it non-blocking.
  Combine with B1's fix — they are the same primitive.

---

## MAJOR findings

### M1 — [DESIGN + PLAN] `GRAPHIFY_OUT` is INERT on the `extract` (semantic) branch — the stated worktree-safe write lever is false for half the mechanism

- **Claim challenged:** PLAN §4-step7c + EE-3.2-derived: "ALWAYS pass the EXPLICIT absolute
  `"$ROOT"` arg + `GRAPHIFY_OUT` env (worktree-safe writer)"; the SEMANTIC line is
  `GRAPHIFY_OUT="$GRAPHIFY_OUT" graphify extract "$ROOT" --backend claude-cli`. DESIGN §3
  EE-3.2: "`GRAPHIFY_OUT` env + explicit path are the worktree-safe write levers."
- **Re-measurement (installed source, `__main__.py` extract handler, HEAD `2f53788`):**
  ```
  4094  out_root = (out_dir.resolve() if out_dir else target)
  4095  graphify_out = out_root / "graphify-out"
  4096  graphify_out.mkdir(parents=True, exist_ok=True)
  ```
  `extract` derives its output dir from the `--out DIR` flag or, absent it, the `target`
  path argument — appending a LITERAL `"graphify-out"`. It NEVER reads `_GRAPHIFY_OUT`
  (`GRAPHIFY_OUT` env) for the output path. Contrast the `update`/`_rebuild_code` path:
  `watch.py:398  out = watch_path / _GRAPHIFY_OUT` — that one DOES honor `GRAPHIFY_OUT`.
- **Interpretation:** On the SEMANTIC branch, `GRAPHIFY_OUT="$ROOT/graphify-out"` does
  nothing; the write lands at `$ROOT/graphify-out` ONLY because `$ROOT` is passed as the
  `extract` target arg. So the result is correct by accident, but the plan's STATED
  mechanism ("GRAPHIFY_OUT pins the writer") is FALSE for `extract`. A coder who, debugging,
  trusts the doc and "fixes" the write target by tweaking `GRAPHIFY_OUT` (instead of the
  target arg / `--out`) will chase a no-op. Also: for `update`, since `GRAPHIFY_OUT` is
  ABSOLUTE, pathlib discards the left operand (`Path('/r') / '/r/graphify-out'` →
  `/r/graphify-out`, re-measured) so it ALSO works — but again the load-bearing lever for
  `update` is the env, for `extract` it is the arg. The two branches use DIFFERENT levers;
  the docs conflate them.
- **Wrong vs unproven:** WRONG (source-measured). Not purpose-defeating (output is correct),
  but a false mechanism statement that will mislead the coder and any future maintainer.
- **Fix:** state the truth per branch: `update` is pinned by `GRAPHIFY_OUT` (absolute) AND
  the explicit `$ROOT` arg; `extract` is pinned by the explicit `$ROOT` target arg (or
  `--out "$ROOT"`) and `GRAPHIFY_OUT` has NO effect — either drop `GRAPHIFY_OUT` from the
  `extract` line or keep it harmlessly but DOCUMENT it as inert. Update DESIGN EE-3.2 +
  PLAN §4-step7c + the OPTIONAL-FEATURES rewrite.

### M2 — [PLAN] Check 23 (help-fragment completeness) will FAIL on `scripts/install-graphify-hook.sh` if committed executable; EE-G's "validate-pack stays green" is unproven (checked only Check 63)

- **Claim challenged:** PLAN EE-G + §5.4: "validate-pack stays green because no tracked-file
  invariant changes that Check 63 asserts … the two new tracked files are ordinary
  `scripts/` shell scripts under no content-invariant check."
- **Re-measurement (`scripts/validate-pack.py`, HEAD `2f53788`):** Check 23
  (`check_help_fragment_completeness`, L2137) iterates **top-level** `scripts/` (`for entry
  in sorted(scripts_dir.iterdir())` — NOT recursive), and for each `.sh`/`.py` that is
  EXECUTABLE (`if not os.access(entry, os.X_OK): continue`), requires it to either appear in
  HELP-FRAGMENT-PACK.md (`if entry.name in text`) or be marked `# pack-internal: true`
  (`_is_pack_internal`, regex `^#\s*pack-internal:\s*true` at L2019); else:
  ```
  2184  fail(f"scripts/ executables missing from HELP-FRAGMENT-PACK.md (or mark with `# pack-internal: true`):")
  ```
- **Interpretation:** Two concrete consequences:
  - `scripts/install-graphify-hook.sh` is a **top-level** `.sh`. PLAN §4.1 step 1 gives it a
    shebang and the orchestrator runs `bash scripts/install-graphify-hook.sh`; whether it is
    committed with the +x bit is UNSPECIFIED in the plan. If committed executable (the
    natural state for an installer), Check 23 FAILS unless the coder adds
    `# pack-internal: true` near the top OR lists it in HELP-FRAGMENT-PACK.md. The plan
    mentions NEITHER. EE-G's "stays green" conclusion is therefore unproven and most likely
    WRONG for the installer.
  - `scripts/hooks/graphify-pre-push.sh` lives in a SUBDIR; `iterdir()` does not descend, so
    Check 23 does not see it (exempt by nesting). The plan should STATE this so the coder
    knows the hook body is intentionally exempt — and that the installer is NOT.
- **Wrong vs unproven:** the "stays green" claim is UNPROVEN as written and WRONG if the
  installer is +x without the marker. A coder following the plan literally hits a red CI.
- **Fix (pick one, name it in the plan):** mark `scripts/install-graphify-hook.sh` with
  `# pack-internal: true` (it is pack-ops-only, never a user-facing verb — the correct
  marker; matches the `dependency-direction-placement` boundary the plan already asserts),
  OR commit it non-executable and document "run via `bash …`". Recommend the
  `# pack-internal: true` marker. Add a Check-23 line to the verification section.

### M3 — [DESIGN + PLAN] Cross-worktree refresh stamps the WRONG `built_at_commit` (a latent surprise the tightening introduces but never analyzes)

- **Claim challenged:** PLAN §3 (the user-directed tightening): when pushing from a worktree
  with no graph (e.g. `main`), resolve `$ROOT` to the graph-OWNING worktree (e.g. `v11-dev`)
  and refresh THAT graph. Presented as strictly safer than the design's `--show-toplevel`.
- **Re-measurement (installed source, HEAD `2f53788`):** graphify stamps `built_at_commit`
  via `_git_head()`, which runs `git rev-parse HEAD` against the PROCESS CWD with NO `-C` and
  NO path arg:
  ```
  export.py:474  def _git_head():
  export.py:478      r = _sp.run(["git","rev-parse","HEAD"], capture_output=True, text=True, timeout=3)
  export.py:532  commit = built_at_commit if built_at_commit is not None else _git_head()
  watch.py:179   (identical _git_head; used by _rebuild_code at watch.py:499 -> to_json built_at_commit=commit)
  ```
  `extract` calls `_to_json(..., force=True)` with NO `built_at_commit` (re-measured: the
  extract handler's only `to_json` call passes no commit), so `to_json` falls to `_git_head()`.
  There is NO `os.chdir` anywhere in `__main__.py`/`watch.py`/`extract.py` (grep → none).
  A `pre-push` hook runs with CWD = the push-invoking worktree.
- **Interpretation (the semantic question the orchestrator asked):** Push from worktree A
  (`main`, HEAD `fa81704`) → tightening resolves `$ROOT`=B (`v11-dev`) → `graphify
  extract B`/`update B` runs with CWD STILL = A → `_git_head()` resolves A's HEAD (`fa81704`,
  main) and stamps it into **B's** graph.json, even though the graph was BUILT from B's
  files. B's graph would then claim `built_at_commit = main-HEAD`. Worse, the very
  `built_at_commit`-vs-HEAD freshness check that B1/B2 want would then mis-fire: B's stamp
  (`fa81704`) compared against B's own HEAD (`2f53788`) reads "stale" forever, or against A's
  HEAD reads "fresh" against the wrong tree. The tightening "refresh B's graph on an A-push"
  is ALSO semantically odd on its own terms: B's graph reflects B's branch/HEAD, unrelated to
  what A just pushed — refreshing B because A pushed is a surprise, not a service, and (per
  EE-A) the branch is NEVER exercised today (one owner). The multi-owner tie-break (sort-
  first-by-path) compounds it: it would refresh an ARBITRARY graph unrelated to the push.
- **Wrong vs unproven:** the wrong-stamp is WRONG (source-measured); the "is refreshing B on
  an A-push desirable at all" is a DESIGN-judgment the tightening never made.
- **Fix (smallest correct):** scope the refresh to the push-invoking worktree's OWN graph
  and make a no-graph worktree a clean `exit 0` no-op (the design's original G-EXIST guard
  already did this). I.e. KEEP the design's `ROOT="$(git rev-parse --show-toplevel)"` +
  `[ -d "$ROOT/graphify-out" ] || exit 0`, and DROP the cross-worktree "find another owner
  and refresh it" branch. The user's stated intent — "the worktree that OWNS the graph" — is
  satisfied for the real cadence (pushes happen FROM the graph-owning `v11-dev` worktree,
  measured EE-A/EE-1.1), and a future MAIN-tree push safely no-ops instead of building a
  spurious or wrong-stamped graph. If the user genuinely wants A-pushes to refresh B, that
  needs (a) `git -C "$ROOT"` semantics PUSHED INTO graphify's `_git_head` (not possible
  without a graphify change) OR (b) the hook running the refresh with CWD=`$ROOT` (e.g.
  `( cd "$ROOT" && graphify update . )`) so `_git_head()` resolves B's HEAD — and even then
  the "why refresh B because A pushed" question stands. SURFACE this to the user; do not let
  the coder ship a tightening that silently mis-stamps. (Re-measure note: pushing FROM B with
  CWD=B works correctly today — the bug is ONLY the cross-worktree branch the tightening adds.)

### M4 — [PLAN] The proposed test-script governance is backwards and risks the explicitly-forbidden allowlist anti-pattern

- **Claim challenged:** PLAN §5.1 + R4: "the coder MAY add `scripts/test-install-graphify-
  hook.sh` … ci-test-wiring allowlist may need an entry for a new `scripts/test-*.sh` — coder
  adds if a new test file is introduced."
- **Re-measurement (`scripts/ci-test-wiring-allowlist.txt` header + validate-pack Check 42
  region L269-271, HEAD `2f53788`):** the CI test matrix is DISK-DERIVED:
  > "the CI matrix is DISK-derived at run time … a test is wired simply by existing on disk —
  > this list is what SUBTRACTS a test from that disk-derived set. The disk KEEP set is
  > {scripts/test*.sh + scripts/tests/*.sh + scripts/tests/fixture-dependent/*.sh} − THIS list."
  > "Adding a line here to dodge a failing KEEP test is the forbidden anti-pattern. A script
  > belongs here ONLY if it (a) touches a LIVE network/GH surface … or (b) is a manual-only
  > dev utility…"
- **Interpretation:** A new `scripts/test-install-graphify-hook.sh` matches `scripts/test*.sh`
  and is **auto-wired into CI by existing** — it MUST run offline-deterministic on a fresh
  runner. The plan's tests stub `graphify`, pre-create `mkdir` locks, and probe background
  detach; if any leg is non-deterministic on CI (e.g. relies on a real `graphify`, on macOS-
  specific detach behavior, or on a real `claude`), it fails the gate. R4's "add an allowlist
  entry" is exactly the FORBIDDEN move (the test is neither live-GH nor manual-only). The plan
  has the governance INVERTED: the allowlist subtracts; it does not enroll.
- **Wrong vs unproven:** R4's framing is WRONG (inverts the disk-derived-minus-allowlist
  model and points at the forbidden anti-pattern).
- **Fix:** either (a) write the test as offline-deterministic and let it auto-wire (no
  allowlist entry — the correct path), stubbing `graphify` and asserting only the hook's
  shell logic (resolution branches, lock skip, status-token write, doc-gate selection) with
  a fake `graphify` on PATH (mirrors `tracker-bd129-gh-repo-test.sh`'s fake-`gh` pattern the
  allowlist header cites); OR (b) if a leg is genuinely non-deterministic, put the
  deterministic assertions in the auto-wired test and keep the machine-only verification
  (detach survival, real refresh) as an orchestrator §6 manual step — NOT an allowlist dodge.
  Remove R4's "add an allowlist entry" suggestion.

---

## MINOR findings

### m1 — [DESIGN vs PLAN] Contradiction on the pack-startup advisory placement

- **Re-measurement (`.claude/skills/pack-startup/SKILL.md`, HEAD `2f53788`):** Step 3 = "Check
  CI tooling" (GitHub-MCP detection, prints into Step 4's report "CI tooling:" line). Steps
  5-7 RESERVED (HTML comment L72-79: "Steps 5 and 6 are open for future surface additions");
  Step 8 fixed/deferred (L81-87).
- **Interpretation:** DESIGN §6 row 5 says "ADD … to a RESERVED Step slot" (5/6). PLAN §2 row
  4 + §5.3 say "append to STEP 3's readiness block." These DISAGREE. Step 3 is the GitHub-MCP
  DETECTION step; bolting a graphify line onto it muddles two unrelated tooling concerns and
  the new line would not appear in the Step-4 report (which has fixed format lines L60-69, no
  graphify slot). The reserved Steps 5/6 are the architecturally correct home for a NEW
  readiness surface — AND if B2's staleness check lands, it needs a report line too.
- **Fix:** resolve to a reserved slot (Step 5 or 6) with a matching new line in the Step-4
  report block (or an explicit "graphify:" readiness line), per the reserved-slot comment's
  own intent. Reconcile design and plan so the coder is not handed two conflicting placements.

### m2 — [PLAN] OPTIONAL-FEATURES rewrite leaves four out-of-range `post-commit` stragglers under-specified

- **Re-measurement (`grep -n "post-commit" pack-ops/OPTIONAL-FEATURES.md`, HEAD `2f53788`):**
  matches at L357, L406, L432, L434, L444, L446-448, L457, L504, L506. The plan bounds the
  rewrite to **L444-513** (§2 row 3 / EE-F). FOUR references (L357, L406, L432-434) are
  ABOVE the rewrite range and describe the now-replaced `post-commit` mechanism:
  - L357 "The graph, the post-commit hook, and the initial build are…"
  - L406 "the post-commit hook unsets all…"
  - L432-434 "Per-clone / per-machine install. graphify-out/, the post-commit hook, … (they
    cannot be committed: gitignored plus `.git/hooks` is…)" — this last is now FALSE for the
    hook BODY (the new body IS committed/tracked).
- **Interpretation:** After the L444-513 rewrite, these four become stale dangling references
  to a mechanism that no longer exists. PLAN §8 says the coder "greps the file for
  `post-commit`/`HEAD~1 HEAD` after the rewrite and reconciles any straggler" — a correct
  catch-all but UNDER-SPECIFIED: the plan should ENUMERATE these four as KNOWN stragglers that
  MUST be reconciled (not "any straggler" as if optional), and flag L432-434's "cannot be
  committed" as now-incorrect for the tracked hook body. Per `rename-plans-measure-then-bound`
  the plan should carry the grep-zero completeness gate explicitly, not delegate it loosely.
- **Fix:** list L357 / L406 / L432-434 in the file-by-file change list as required edits, and
  add a coder PREFLIGHT + reviewer grep-zero gate: `grep -n "post-commit" OPTIONAL-FEATURES.md`
  returns only intentional historical references (if any) after the rewrite.

### m3 — [PLAN] Pre-push edge cases: delete-ref and multi-ref are under-covered

- **Re-measurement (authoritative `pre-push.sample`, git 2.50.1 template):** stdin lines are
  `<local ref> <local oid> <remote ref> <remote oid>`; the sample's canonical handling:
  - DELETE: `if test "$local_oid" = "$zero" then : (handle delete)` — local_oid all-zeros.
  - NEW branch: `if test "$remote_oid" = "$zero" then range="$local_oid"` (all commits).
  - UPDATE: `range="$remote_oid..$local_oid"`.
  - MULTIPLE refs: the `while read … do … done` loops over EVERY stdin line.
- **Interpretation:** PLAN §4-step2 / R2 handle new-branch (all-zeros remote_oid → full
  `update` fallback) — good. But: (a) DELETE-ref (local_oid all-zeros) is NOT addressed; a
  `<zeros>..<zeros>` or `<remote>..<zeros>` range is degenerate and `git diff` over it is
  meaningless — the hook should treat a delete-only push as "no doc range → full `update`" (or
  skip). (b) MULTI-REF: the plan reads "the pushed range" (singular) and does not say how it
  combines multiple ref lines (union of ranges? first ref only?). For the v11-dev cadence
  (single branch push) this is benign, but the doc-gate predicate over a mis-derived range
  could pick the wrong branch (`extract` vs `update`). Force-push is fine (still
  `remote..local`, possibly non-fast-forward — `git diff` still works).
- **Wrong vs unproven:** UNPROVEN/under-specified (coder-verify is appropriate, but the plan
  must NAME delete-ref and multi-ref as cases the fallback covers).
- **Fix:** specify: empty/unavailable stdin OR any all-zeros oid (new-branch or delete) OR
  multi-ref → fall back to a full code-only `update "$ROOT"` (no doc-gate); document it as the
  conservative default. Keep R2 but expand it to enumerate delete + multi-ref, not just
  new-branch.

### m4 — [NIT → MINOR, PLAN] `.pack-refresh-status` write is not atomic; a kill during the write can leave a torn line

- **Re-measurement:** PLAN §4-step7e writes "a single line" to `.pack-refresh-status`; no
  tmp-then-rename specified.
- **Interpretation:** Low-probability, but a kill mid-write leaves a partial first token the
  consult mis-parses. Cheap to fix; and B1's `built_at_commit`-keyed check makes the token
  non-load-bearing anyway.
- **Fix:** write to `.pack-refresh-status.tmp` then `mv` (atomic on same fs), OR adopt B1's
  fix and demote the token to advisory.

---

## NIT findings

- **N1 [PLAN §3.2]:** the resolution snippet uses bash arrays + process substitution
  `done < <(…)`; the installer copies the body to `pre-push` with `#!/usr/bin/env bash` — fine
  on macOS bash 3.2, but `mapfile`/`readarray` (mentioned as an alternative in §3.2 notes) is
  bash 4+ and ABSENT on stock macOS bash 3.2. The plan correctly says "may use any POSIX-or-
  bash form"; just ensure the coder does NOT reach for `mapfile`. (If M3's fix lands, the whole
  multi-worktree enumeration disappears and this is moot.)
- **N2 [PLAN §4-step7a]:** `trap 'rmdir "$LOCK"' EXIT` inside the detached subshell is correct,
  but the FOREGROUND hook also created the lock (step 5) and exits immediately without a trap —
  intentional (the bg subshell owns teardown). Worth one comment in the body so a maintainer
  does not "fix" the missing foreground trap and double-rmdir.
- **N3 [DESIGN §4 / EE-4.1]:** the design notes graphify's own `_rebuild_lock` is non-blocking
  on `_rebuild_code` but BLOCKS on the `update` CLI (`block_on_lock=True`, `__main__.py:3331` —
  re-measured at L3333 in this build: `_rebuild_code(..., block_on_lock=True)`). The outer
  `mkdir` skip-lock makes this moot (the second push skips before reaching `graphify update`),
  which the plan correctly relies on. No action; recorded for completeness.

---

## Direct answers to the orchestrator's eight load-bearing probes

1. **Graph-owning-worktree resolution correct in every branch?** NO — see M3. The branch
   logic itself is deterministic, but the cross-worktree refresh stamps the WRONG
   `built_at_commit` (graphify's `_git_head` uses process CWD, not `$ROOT`), and refreshing
   B's graph on an A-push is a latent surprise; the tie-break refreshes an arbitrary graph.
   Spaces in paths: §3.2 quotes `"$wt"` and tests `[ -f "$wt/graphify-out/graph.json" ]` —
   safe for spaces; the `git worktree list --porcelain` `worktree ` field is a single
   absolute path per line (re-measured), so `${line#worktree }` is correct. The DEFECT is
   semantic, not quoting.
2. **Pre-push stdin / doc-gate edge cases all covered?** PARTIALLY — new-branch (all-zeros
   remote) IS handled; DELETE-ref (all-zeros local) and MULTI-REF are NOT (m3). Force-push is
   fine. Fallback-to-full-`update` is the right default but must name delete + multi-ref.
3. **Background-detach survival + never-completed state?** Detach survival is correctly
   flagged as coder-verify (legitimate). The NEVER-COMPLETED state is BROKEN (B1): a killed
   refresh leaves no `fail` token, the token-only consult misses it, and silent staleness
   recurs — failure #3 relocated. This is the single most important gap.
4. **Lock path vs resolved root?** The plan correctly pins LOCK + status to
   `$ROOT/graphify-out` (steps 5, 6, 7e). For a SAME-worktree push this is right. For the
   cross-worktree push it serializes on B's dir correctly — but the whole cross-worktree
   branch should be dropped (M3), at which point `$ROOT`=current and the pinning is trivially
   correct.
5. **`claude -p` non-interactive in a detached hook?** SOUND — `subprocess.run(input=…)`,
   `claude -p --output-format json --no-session-persistence`, no TTY, no API key, `claude`
   authenticated locally. SUPPORTED (with a one-time-login dependency note).
6. **pack-startup step placement?** DESIGN says reserved slot (5/6); PLAN says Step 3. They
   CONTRADICT (m1). Reserved Step 5/6 is correct per SKILL.md's own comment; Step 3 muddles
   GitHub-MCP detection and has no report line. Reconcile to a reserved slot + a report line.
7. **validate-pack stays green?** UNPROVEN/likely-NO for the installer — Check 23 fails on a
   committed-executable top-level `scripts/install-graphify-hook.sh` lacking the
   `# pack-internal: true` marker (M2). The hook BODY in `scripts/hooks/` is exempt
   (iterdir is non-recursive). EE-G checked only Check 63 and missed Check 23.
8. **6 surfaces + install step complete/correct?** Mostly enumerated correctly, but: the
   OPTIONAL-FEATURES rewrite range misses four upstream `post-commit` stragglers (m2); the
   post-install step (§6) re-runs the refresh but NOTHING verifies the hook is ACTIVE in this
   clone afterward beyond the install print + a manual `built_at_commit` check — and the
   pack-startup advisory it relies on checks install-status, not staleness (B2). The three
   failures are NOT all closed: #1 (auto-trigger) and #2 (tracked/review-visible) are closed;
   #3 (silent rot) is RELOCATED (B1+B2).

**Net on the three probed "is it sound or broken" axes:** graph-owning-worktree resolution =
BROKEN (M3); pre-push edge cases = PARTIALLY sound (delete/multi-ref gaps, m3); detach/never-
completed = BROKEN (B1) for the never-completed half.

---

## Required changes to reach READY-FOR-CODER

1. **B1+B2 (one fix):** key the verification on `built_at_commit` vs resolved-root HEAD (the
   charter primitive) in BOTH the hook consult and the pack-startup surface; surface STALE
   loudly + offer the one-liner; keep non-blocking. PRESENT the "no-CI-gate vs FAILS-LOUD"
   tension to the user as a decision before the coder runs.
2. **M3:** drop the cross-worktree "find another owner and refresh it" branch; KEEP the
   design's `--show-toplevel` + G-EXIST `exit 0` no-op. If the user truly wants A-pushes to
   refresh B, redesign the stamp (run with CWD=`$ROOT`) AND justify the cross-tree refresh —
   surface as a user decision.
3. **M1:** correct the per-branch write-lever statement (`extract` ignores `GRAPHIFY_OUT`;
   pinned by the target arg) in design, plan, and the OPTIONAL-FEATURES rewrite.
4. **M2:** mark `scripts/install-graphify-hook.sh` `# pack-internal: true` (or commit
   non-executable); add a Check-23 line to the verification plan.
5. **M4:** rewrite §5.1/R4 — the auto-wired offline-deterministic test path; remove the
   allowlist-entry suggestion (it is the forbidden anti-pattern).
6. **m1/m2/m3/m4:** resolve the Step placement contradiction; enumerate the four
   OPTIONAL-FEATURES `post-commit` stragglers + grep-zero gate; name delete-ref + multi-ref
   in the fallback; make the status write atomic (or demote it per B1).

---

## Empirical-Evidence Block (the re-measurements backing every finding; HEAD `2f53788`)

### EE-R1 — graphify stamps `built_at_commit` from process-CWD HEAD (B1/B2/M3)
- **Command:** `sed -n '474,534p' export.py`; `grep -n "_git_head\|built_at_commit\|to_json" watch.py`;
  `grep -rn "os.chdir\|chdir(" __main__.py watch.py extract.py`
- **Output (verbatim, abridged):** `export.py:478  _sp.run(["git","rev-parse","HEAD"], capture_output=True, text=True, timeout=3)` (no `-C`, no cwd);
  `export.py:532  commit = built_at_commit if built_at_commit is not None else _git_head()`;
  `watch.py:179 def _git_head()` (identical); `watch.py:499 commit = _git_head()` → `watch.py:680/684 to_json(..., built_at_commit=commit)`;
  `os.chdir` → **no matches** in the three files.
- **Interpretation:** the commit stamped into graph.json is the HEAD of the PROCESS CWD, not
  the scan-root arg; with no chdir, a hook running in worktree A that refreshes B's graph
  stamps A's HEAD into B's graph.json. Confirms M3's wrong-stamp and motivates B1/B2's
  HEAD-comparison fix being the only reliable signal.
- **Conclusion:** SUPPORTED.

### EE-R2 — `extract` output dir ignores `GRAPHIFY_OUT`; `update` honors it (M1)
- **Command:** `sed -n '4090,4096p' __main__.py`; `sed -n '396,399p' watch.py`;
  `python3 -c "from pathlib import Path; print(Path('/a/root') / '/a/root/graphify-out')"`
- **Output (verbatim):** `4094 out_root = (out_dir.resolve() if out_dir else target)` /
  `4095 graphify_out = out_root / "graphify-out"`; `watch.py:398 out = watch_path / _GRAPHIFY_OUT`;
  pathlib → `/a/root/graphify-out`.
- **Interpretation:** `extract`'s write target derives from `--out`/`target` only (no
  `_GRAPHIFY_OUT`); `update`'s derives from `watch_path / GRAPHIFY_OUT` (env honored; absolute
  env wins the join). The two branches use different levers; the docs conflate them.
- **Conclusion:** SUPPORTED.

### EE-R3 — Check 23 is top-level, executable-gated, marker-or-fragment required (M2)
- **Command:** `sed -n '2137,2189p' scripts/validate-pack.py`; `grep -n "_PACK_INTERNAL_RE" scripts/validate-pack.py`
- **Output (verbatim, abridged):** `for entry in sorted(scripts_dir.iterdir())` (non-recursive);
  `if entry.suffix not in (".sh",".py"): continue`; `if not os.access(entry, os.X_OK): continue`;
  `if _is_pack_internal(entry): flagged_internal.append…continue`; `if entry.name in text:
  listed… else: missing…`; `fail("scripts/ executables missing from HELP-FRAGMENT-PACK.md (or
  mark with `# pack-internal: true`):")`; `_PACK_INTERNAL_RE = re.compile(r"^#\s*pack-internal:\s*true\b", re.MULTILINE)`.
- **Interpretation:** a top-level executable `scripts/install-graphify-hook.sh` without the
  marker or a fragment listing FAILS Check 23; a subdir `scripts/hooks/*.sh` is not scanned.
- **Conclusion:** SUPPORTED.

### EE-R4 — CI test matrix is disk-derived; allowlist SUBTRACTS (M4)
- **Command:** `sed -n '1,22p' scripts/ci-test-wiring-allowlist.txt`; `sed -n '258,272p' scripts/validate-pack.py`
- **Output (verbatim, abridged):** "the CI matrix is DISK-derived at run time … a test is
  wired simply by existing on disk — this list is what SUBTRACTS … The disk KEEP set is
  {scripts/test*.sh + scripts/tests/*.sh + scripts/tests/fixture-dependent/*.sh} − THIS list";
  "Adding a line here to dodge a failing KEEP test is the forbidden anti-pattern."
- **Interpretation:** a new `scripts/test-install-graphify-hook.sh` auto-wires; it must be
  offline-deterministic; R4's "add an allowlist entry" inverts the model + risks the forbidden
  pattern.
- **Conclusion:** SUPPORTED.

### EE-R5 — pre-push stdin contract + edge cases (m3)
- **Command:** `sed -n '1,55p' "$(git --exec-path)/../../share/git-core/templates/hooks/pre-push.sample"`; `git --version`
- **Output (verbatim, abridged):** stdin "`<local ref> <local oid> <remote ref> <remote oid>`";
  `zero=$(git hash-object --stdin </dev/null | tr '[0-9a-f]' '0')`; delete `if test "$local_oid"
  = "$zero"`; new-branch `if test "$remote_oid" = "$zero" then range="$local_oid"`; else
  `range="$remote_oid..$local_oid"`; `while read … do … done` (multi-ref loop); `git version
  2.50.1 (Apple Git-155)`.
- **Interpretation:** delete-ref (local all-zeros) + multi-ref are first-class cases; the plan
  covers new-branch but not these two.
- **Conclusion:** SUPPORTED.

### EE-R6 — claude-cli runs non-interactive, no TTY, no key (probe #5 SOUND)
- **Command:** `sed -n '1086,1116p' llm.py`; `command -v claude && claude --version`;
  `[ -n "$ANTHROPIC_API_KEY" ] && echo SET || echo UNSET`
- **Output (verbatim, abridged):** `claude -p --output-format json --no-session-persistence`;
  `proc = subprocess.run(cli_args, input=user_message, capture_output=True, text=True, …)`;
  `/Users/david/.local/bin/claude` / `2.1.178 (Claude Code)`; `UNSET`.
- **Interpretation:** prompt piped via `input=`; no TTY; no key → `claude-cli` subscription path
  runs in a detached subshell. SOUND (one-time login dependency only).
- **Conclusion:** SUPPORTED.

### EE-R7 — pack-startup structure: Step 3 = CI tooling, Steps 5-7 reserved (m1)
- **Command:** `sed -n '41,87p' .claude/skills/pack-startup/SKILL.md`
- **Output (verbatim, abridged):** "## Step 3 — Check CI tooling" (GitHub-MCP detection →
  Step-4 report "CI tooling:" line); HTML comment "Steps 5–7 are reserved … Steps 5 and 6 are
  open for future surface additions."; "## Step 8 … (deferred)".
- **Interpretation:** reserved Steps 5/6 are the correct home; the plan's Step-3 placement
  contradicts the design and muddles GitHub-MCP detection with no report line.
- **Conclusion:** SUPPORTED.

### EE-R8 — OPTIONAL-FEATURES post-commit stragglers above the rewrite range (m2)
- **Command:** `grep -n "post-commit\|HEAD~1\|\.git/hooks" pack-ops/OPTIONAL-FEATURES.md`; `wc -l`
- **Output (verbatim, abridged):** matches at L357, L406, L432, L434, L444, L446-448, L457,
  L504, L506; total 555 lines.
- **Interpretation:** L357/L406/L432-434 sit ABOVE the plan's L444-513 rewrite range and
  describe the replaced mechanism (L432-434 claims the hook "cannot be committed" — now false).
- **Conclusion:** SUPPORTED.

### EE-R9 — status record written only post-refresh; consult is token-only (B1)
- **Command:** `sed -n '256,290p' /tmp/pack-handoff-bd237-plan/PLAN-BD-237.md`
- **Output (verbatim, abridged):** step 5 `mkdir "$LOCK" … || … skipping; exit 0`; step 6
  consult "If it is `fail`, emit … re-running. Proceed regardless."; step 7a `trap 'rmdir
  "$LOCK"' EXIT`; step 7e "write a single line … `ok …` if final attempt exited 0, else
  `fail …`."
- **Interpretation:** no token is written until BOTH attempts complete; a killed run writes
  nothing; the consult reacts only to an explicit `fail`; the never-completed run is invisible.
- **Conclusion:** SUPPORTED (B1 BLOCKER).

### EE-R10 — repo state baseline (EE-A/B/C/D re-confirmed)
- **Command:** `git rev-parse HEAD`; `git worktree list --porcelain`; `command -v flock`;
  `git rev-parse --git-path hooks`; `ls -la "$(git rev-parse --git-path hooks)"`;
  `git config --get core.hooksPath`; `python3 -c json built_at_commit`; `cat graphify-out/.graphify_root`
- **Output (verbatim, abridged):** HEAD `2f53788620e1bdb233eb8ed645801c995093bafe`; two
  worktrees (main `fa81704`, v11-dev `2f53788`); flock `ABSENT`; hooks `…/optiquity-ai-agent-
  config-pack/.git/hooks` `total 0`; `core.hooksPath` exit 1; `built_at_commit 190e1985…`;
  `.graphify_root` = `.`.
- **Interpretation:** the plan's EE-A/B/C/D re-measure CLEAN; the disagreements are in the
  source-behavior + CI-check claims, not the repo-state EE blocks.
- **Conclusion:** SUPPORTED.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | All commands were read-only: `git rev-parse`/`worktree list --porcelain`/`config --get`/`--version` (read); `sed -n`/`grep`/`cat`/`ls`/`wc`/`command -v`/`python3 -c` (read); `graphify --version` only (NO `update`/`extract`/`hook install`); one `mkdir -p /tmp/pack-handoff-bd237-advplan`. NO graph mutation, NO source edit, NO state-changing git verb. Sole write = this review doc. | COMPLIANT |
| 2 | empirical-evidence-blocks [planner] | Every finding carries an independent re-measurement (command + verbatim output + HEAD `2f53788` + interpretation + conclusion); consolidated in EE-R1..EE-R10. Each EE distinguishes WRONG (source-measured) from UNPROVEN (coder-verify). | COMPLIANT |
| 3 | graph-first-context | The graph is the STALE artifact under repair (built_at `190e198` < HEAD `2f53788`); fell through to grep/Read/git/installed-source for ALL authoritative facts (SSOT charter fields, validate-pack source, graphify source, uncommitted plan/design). Did not block on the graph (G2 path). | COMPLIANT |
| 4 | separate-pack-ops-from-product | Confirmed every reviewed surface is pack-ops (`scripts/`, `pack-ops/`, `.claude/skills/pack-startup/`, `maintenance-docs/`); NO `project-template/`/`supporting-docs/` touch; M2's `# pack-internal: true` recommendation reinforces the pack-ops boundary; runtime files gitignored (`.gitignore:76`). No leak flagged. | COMPLIANT |
| 5 | verify-availability-not-just-existence | Re-verified from installed 0.8.39 SOURCE/live, not the docs' say-so: `_git_head` CWD behavior (EE-R1), `extract` vs `update` out-dir lever (EE-R2), Check 23 glob/marker (EE-R3), CI disk-matrix governance (EE-R4), pre-push stdin contract (EE-R5), claude-cli non-interactive subprocess (EE-R6), pack-startup structure (EE-R7), flock ABSENT + hooks dir + graph staleness (EE-R10). Refuted M1/M2/M3 against source where the docs asserted otherwise. | COMPLIANT |
| 6 | scope-deliverables-to-the-ask | Reviewed THIS design+plan only; re-introduced NO rejected machinery (no CI gate, no validate-pack "Check 65", no sentinel, no N, no fetch-depth, no commit-count). B1/B2's fix uses the charter's OWN `built_at_commit`-vs-HEAD primitive on a LOCAL non-blocking surface — not a CI gate. No scope expansion. | COMPLIANT |
| 7 | deferral-is-scope-creep / no-deferral-without-user-direction | Judged against fixing NOW in v11.0; flagged failure #3 as RELOCATED-not-closed (B1) rather than letting it pass; flagged R4's allowlist-dodge as the forbidden defer-the-test pattern; no finding deferred to a later BD/version. | COMPLIANT |
| 8 | rules-applied-verification-block | This block — one row per in-force rule with measured/quoted evidence + terminal conclusion (no AMBIGUOUS). | COMPLIANT |

---

*End of ADVERSARIAL-PLAN-REVIEW-BD-237. Read-only planner output; no source edits, no
state-changing git verbs, no graph mutation. Sole write = this file.*
