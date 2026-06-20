# ADVERSARIAL-REVIEW-BD-237 — Graphify graph-freshness redesign

**Agent:** FRESH `pack-architect` (ADVERSARIAL review — did NOT author the design under review)
**Repo:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Branch / HEAD at review time:** `v11-dev` / `2f53788620e1bdb233eb8ed645801c995093bafe`
**Date:** 2026-06-20
**Design under review:** `/tmp/pack-handoff-bd237-arch/DESIGN-BD-237.md`
**Charter:** `backlog/BD-237.md`
**Capability source (re-verified, not trusted):** `/tmp/pack-handoff-bd237-research/CAPABILITY-REPORT-BD-237.md`

Every load-bearing claim was RE-MEASURED independently against HEAD `2f53788`. Where I confirm the design's EE, I say so with my own command output; where I refute or extend it, I show the divergence. Findings are graded BLOCKER / MAJOR / MINOR / NIT and tagged **[design-is-wrong]** vs **[design-is-unproven]**.

---

## Verdict (up front)

**NEEDS-REWORK.**

The design is empirically careful and most of its EEs reproduce exactly. But it has **one purpose-defeating gap** and **one purpose-defeating interaction** that, together, mean the design as written does NOT genuinely prevent recurrence of the BD-225 failure — it relocates two of the three fragilities into surfaces that the *actual maintainer's actual workflow* rarely or never exercises, and it adopts a refresh mechanism whose source code (re-read here) will actively mis-build a graph in the wrong worktree on the repo's documented commit path.

- **Purpose-defeating gap (BLOCKER-1):** the verification's *only human-facing, actionable* home is `pack-startup`, which by its own SSOT (`SKILL.md` line 3 + `PACK-CHAT.md` line 39) is **NOT run on normal same-machine resumes** — i.e. it is near-dead for the one maintainer who works this repo same-machine. This re-creates failure #3 (no check fires in production) in softer form.
- **Purpose-defeating interaction (BLOCKER-2):** the recommended CODE-layer mechanism (`graphify hook install`) writes a `post-commit` body that resolves `graphify-out/` **CWD-relative with NO existence guard** (source re-read: `hooks.py` `_HOOK_SCRIPT` lacks the `[ ! -d graphify-out ]` guard that `_CHECKOUT_SCRIPT` has, and `_rebuild_code` *builds-if-missing*). On the repo's documented worktree-isolation commit path (commits land in the MAIN tree, which has NO `graphify-out/`), the hook will **build a fresh code-only graph in the wrong tree** and leave the real semantic graph in `v11-dev` stale anyway. The design FLAGS this as "verify it no-ops" (§7.1) — but the source evidence says it will NOT no-op, so this is design-is-wrong, not merely design-is-unproven.

Neither gap is fatal to the *shape* of the design (two-layer split, `built_at_commit` primitive, O(1) tail-read, surface enumeration are all correct and re-verified). The rework is: (a) give the verification a home that fires on the maintainer's real cadence, and (b) make the freshness check teeth-bearing where it CAN bite (a committed sentinel lets CI assert something real), rather than conceding "WARN-only because CI can never see the graph." The WARN-not-FAIL conclusion is **refutable** — see MAJOR-1.


---

## Re-measured facts that the design got RIGHT (confirmed, not findings)

I reproduced the design's core EEs against HEAD `2f53788`. These are SUPPORTED — I am NOT challenging them:

| Design EE | My re-measurement (HEAD 2f53788) | Verdict |
|---|---|---|
| EE-0.1 graph stale | `built_at_commit` = `190e1985…`; HEAD = `2f53788…` ⇒ behind | CONFIRMED |
| EE-0.2 hooks not installed | `graphify hook status` → both "not installed"; common `.git/hooks` empty (`total 0`); `core.hooksPath` unset | CONFIRMED |
| EE-0.3 linked worktrees, graph per-worktree | `git worktree list` shows main+v11-dev sharing `/…/optiquity-ai-agent-config-pack/.git`; `graphify-out/` exists ONLY in v11-dev; `.gitignore:76 graphify-out/` | CONFIRMED |
| EE-0.4 `built_at_commit` is LAST field, O(1) tail | byte offset 19219373 of 19219436-byte file; `grep -c '"built_at_commit"'` = **1** (unique); tail-read returns it | CONFIRMED + STRENGTHENED (uniqueness verified — design didn't measure count) |
| EE-0.5 GRAPH_REPORT lag | `GRAPH_REPORT.md` = `fd22afb7` ≠ graph.json `190e1985` | CONFIRMED |
| EE-0.6 check-update exits 0 while stale | `graphify check-update .` → exit 0 | CONFIRMED |
| EE-2.4.1 registry tail / Check 64 highest | `(63, …W)`, `(64, …W)` present; new = 65 | CONFIRMED |
| EE-2.4.2 count constant lags max number | `CHECK_REGISTRY_EXPECTED_COUNT = 62`; one new entry ⇒ 62→63 (NOT →65) | CONFIRMED (see MINOR-2 re: the quoted comment) |
| EE-2.4.3 tests auto-wire by disk glob | `ci-shard-plan.py parse_wired_tests()` globs `scripts/tests/*.sh`; test-63 header confirms auto-wire; no workflow edit | CONFIRMED |
| EE-2.4.4 OPTIONAL-FEATURES ships faulty hand-install | L444-480 = the hand-written `.git/hooks/post-commit` recipe with UNVERIFIED caveats (a)(b) at L497-513 | CONFIRMED |
| EE-2.4.5 pack-startup Step 5/6 reserved | `SKILL.md:75` "Steps 5 and 6 are open for future surface additions" | CONFIRMED |
| `warn()` is non-gating | `warn()` (L426-435) does NOT append to `failures`; never changes exit code; Check 48 is the live precedent | CONFIRMED |
| CI never has a graph | `validate-pack.yml` uses `actions/checkout@v6` (fresh clone) then `python3 scripts/validate-pack.py`; `graphify-out/` gitignored ⇒ absent on runner | CONFIRMED |
| EE-5 pack-ops-only | target set = validate-pack.py, scripts/tests, OPTIONAL-FEATURES.md, pack-startup SKILL.md, maintenance-docs — none under `project-template/`/`supporting-docs/` | CONFIRMED |

The design's empirical discipline is real. The findings below are about whether the *mechanism + verification* actually close the three failures, not about EE accuracy.

---

## BLOCKER-1 — The verification's only actionable home (pack-startup) is near-dead for the actual maintainer  **[design-is-wrong]**

**Design claim challenged:** §2.2 + §1A-A3 + §6 — the systemic remedy for failures 2+3 is "WARN in validate-pack + a loud staleness PROMPT in pack-startup," and the design concedes (§1A-A3 cons, §2.2) pack-startup "is skipped on same-machine resumes" but rules this "acceptable: it is a PROMPT, not the sole gate."

**Re-measurement (HEAD 2f53788):**

`.claude/skills/pack-startup/SKILL.md` line 3 (frontmatter `description`):
```
Run when starting fresh, resuming on a new machine, or after compaction. … Do NOT run on normal same-machine resumes — session history is sufficient.
```
`pack-ops/PACK-CHAT.md` lines 33-40 ("When to run /pack-startup"):
```
Run /pack-startup when:
- Starting a fresh session on this machine for the first time
- Resuming on a machine where session history is absent or stale
- After compaction has summarized the conversation history
- After a gap where pack changes were committed without your involvement
Do not run /pack-startup on a normal same-machine resume — session history is sufficient.
```
`PACK-CHAT.md` lines 441-446 ("Normal resume (same machine)"):
```
cd /path/to/pack
git pull
claude --resume pack-chat        # <-- NO /pack-startup
```
And the maintainer's reality (re-measured): both worktrees live under `/Users/david/Developer/` — **same machine**. The recent commit reflog (`git reflog -5`) shows continuous same-machine pack-dev.

**Why this is purpose-defeating (not a nit):** The charter's whole point is "a check that FAILS LOUD … so silent rot cannot recur." The design splits the remedy into:
- a validate-pack WARN (non-gating, and — see MAJOR-1 — a structural no-op in CI), and
- a pack-startup PROMPT (the ONLY surface that is both human-facing AND actionable).

For the one human who maintains this repo, working same-machine, the documented workflow is `claude --resume pack-chat` with **no `/pack-startup`**. So the actionable prompt fires only on fresh-session / cross-machine / post-compaction / out-of-band-commit-gap — exactly the *rare* events. Between those, the graph can rot for arbitrarily long with nothing surfacing it. **This is BD-225's failure #3 reincarnated**: a verification mechanism whose trigger the maintainer does not routinely run. The design even names the defect ("pack-startup is an unreliable refresh TRIGGER… it may not run for long stretches", §1A-A3) and then reuses that same unreliable surface as the verification's actionable home.

**This is design-is-wrong**, not design-is-unproven: the SSOT explicitly forbids the trigger on the maintainer's dominant path; no measurement could make it fire there.

**Concrete stronger alternative (measure-then-bound):** the verification must live on a surface the maintainer hits *every* development cycle. Two candidates, both O(1):
1. **A post-commit/post-push self-verify that fails LOUD into the maintainer's face.** Pack Chat already gates every commit (`agents-never-commit` ⇒ only Pack Chat commits, with user approval). A freshness assertion can ride the commit-approval flow (Pack Chat already must print a next-steps plan per `commit-approval-includes-next-steps`). This fires on the actual cadence (every commit), not on the rare startup.
2. **A committed freshness sentinel that lets validate-pack FAIL in CI** — see MAJOR-1. This makes the *gate that actually blocks merge* carry teeth, independent of whether any human runs pack-startup.

The planner/user must choose, but the design's current single-home-on-pack-startup answer does not satisfy "verify the update works in production" for THIS maintainer.


---

## BLOCKER-2 — `graphify hook install` will mis-build a graph in the wrong worktree on the documented commit path  **[design-is-wrong, downgraded from the design's design-is-unproven framing]**

**Design claim challenged:** §1A recommends A1 (`graphify hook install`) as the PRIMARY code refresh, "verified worktree-aware." §4.1 flags as a HIGH gap (§7.1) that the *cross-worktree fire* is unverified and asks the coder to "confirm the hook cleanly NO-OPS" when a commit lands in a worktree with no `graphify-out/`. The design treats this as an open empirical question (design-is-unproven).

**Re-measurement — I read the installed hook source (`/Users/david/.local/share/uv/tools/graphifyy/lib/python3.12/site-packages/graphify/hooks.py`, mtime Jun 14, the 0.8.39 install):**

1. **The hooks DIR is resolved worktree-safely** (design correct): `_hooks_dir` (hooks.py:317-340) runs `git -C <root> rev-parse --git-path hooks` and resolves to the SHARED common dir. So one `hook install` serves both worktrees and the hook FIRES for commits in either tree. CONFIRMED.

2. **But the hook BODY resolves `graphify-out/` CWD-relative, and the post-commit body has NO existence guard.** Re-read of the two script templates:
   - `_CHECKOUT_SCRIPT` (hooks.py:238-285) HAS the guard:
     ```
     # Only run if graphify-out/ exists (graph has been built before)
     if [ ! -d "graphify-out" ]; then
         exit 0
     fi
     ```
   - `_HOOK_SCRIPT` (the **post-commit** body, hooks.py ~187-235) does **NOT** have that guard. Its only early-exits are: rebase/merge/cherry-pick in progress; `GRAPHIFY_SKIP_HOOK=1`; empty changeset; or "only graphify-out/ artifacts changed." There is **no `[ ! -d graphify-out ]` bail.** It proceeds to the detached rebuild.
   - The rebuild body (`_REBUILD_BODY_COMMIT`, hooks.py:90-112) sets `_root = Path('.')` then `_saved = Path('graphify-out/.graphify_root')` — **relative to CWD** (the committing worktree root). If `graphify-out/.graphify_root` is absent (the main tree), `_root` stays `Path('.')` and it calls `_rebuild_code(Path('.'), changed_paths=changed)`.

3. **`_rebuild_code` BUILDS-IF-MISSING.** Re-read `watch.py:_rebuild_code` (365+): line 514-515 `existing_graph_data: dict = {}` (defaults empty when no graph), line 577 `out.mkdir(exist_ok=True)` (creates `graphify-out/`). So calling it in a tree with no graph **creates a new code-only graph there.** (The capability report itself states `update`/`_rebuild_code` "BUILDS if no graph exists" — Q2.) This is the design's OWN cited behavior, turned against it.

**The interaction (the purpose-defeating part):** The repo's documented commit path under worktree isolation is — re-measured — `OPTIONAL-FEATURES.md:502-503`: *"the orchestrator applies the agent's patch and commits in the MAIN (parent) tree"* and L127-129 *"`git apply`s the reviewed-clean patch onto the parent branch and commits."* The MAIN tree has NO `graphify-out/` (EE-0.3, re-confirmed: `ls /…/optiquity-ai-agent-config-pack/graphify-out` → No such file or directory). So on that path:

- post-commit fires (shared hooks dir) with CWD = main tree;
- no `[ ! -d graphify-out ]` guard ⇒ it does NOT no-op;
- `_rebuild_code(Path('.'))` BUILDS a fresh **code-only** graph in the MAIN tree;
- the real graph in `v11-dev` (the one Pack Chat + agents consume, with the semantic layer — `.graphify_semantic_marker` present) is **never touched** and stays stale.

Net: the recommended mechanism, on the documented commit path, (a) creates a spurious graph in the wrong tree, (b) does NOT refresh the consumed graph, and (c) a code-only build would, if it ever landed in v11-dev, *strip the semantic layer* unless the semantic-marker protection kicks in. The design's §4.1 reconciliation rule ("commits in a graph-less worktree must NO-OP") is the CORRECT requirement — but the installed hook source does NOT meet it. The design assumed the hook might no-op; the source says it builds.

**Caveat in the maintainer's favor (re-measured, narrows but does not close the gap):** the *current* dominant commit path is NOT the worktree-isolation path. `git reflog -5` shows the recent BD-236/235/237 commits landing directly on `v11-dev` (where the graph lives) — i.e. Pack Chat committing in-tree, not via main-tree apply. On THAT path the hook would refresh correctly. So production has **two commit paths with opposite outcomes**: in-tree-on-v11-dev (hook refreshes correctly) vs worktree-isolation-apply-in-main (hook mis-builds + leaves v11-dev stale). The design models only the second and mislabels its risk as "verify no-op" when the source says "it builds."

**Why this is BLOCKER, not MAJOR:** the charter demands a *reliable* refresh. A mechanism whose correctness flips based on which of two routine commit paths was used is not reliable, and on one of those paths it actively corrupts (wrong-tree build) rather than degrades. The design ships this as the PRIMARY mechanism while flagging the exact failure as merely "to verify." A coder who "verifies" by committing on v11-dev will see it pass and ship the latent main-tree mis-build.

**Concrete stronger alternatives (the planner must weigh; all measure-then-bound):**
1. **Pin the hook (or a pack-owned refresh) to the graph-owning worktree via `GRAPHIFY_OUT` / explicit root**, not CWD. `watch.py:11` reads `GRAPHIFY_OUT` env (capability report confirms per-worktree redirect). A pack-controlled refresh can pass the absolute v11-dev root regardless of which tree committed — this is the hook analogue of the BD-226 path-INJECTION fix (the orchestrator knows the canonical graph root; inject it, don't let the hook self-derive from CWD). The design's §4 even cites BD-226 but stops short of applying its central lesson (inject, don't self-derive) to the HOOK.
2. **Drive the refresh from Pack-Chat's commit flow** (where the canonical v11-dev root is known) rather than a git hook whose CWD is whichever tree committed. This sidesteps the entire shared-hooks/CWD problem and fires on the real cadence (addresses BLOCKER-1 too). The design lists this as A3 and demotes it for being "Claude-only / Pack-Chat-discipline" — but the graph is pack-ops-only and pack-dev IS Pack Chat, and "discipline" becomes "mechanically enforced" the moment it is a required, verified step in the commit-approval flow (which the verification check then proves).
3. **At minimum, require the coder to verify the mis-build path explicitly** (commit in the MAIN tree, NOT v11-dev) and add a guard (e.g. the hook bails unless `graphify-out/.graphify_root` resolves to the canonical root) — but option 1 or 2 is structurally cleaner than patching a hook the pack does not own.


---

## MAJOR-1 — The "WARN-not-FAIL because CI can never see the graph" conclusion is REFUTABLE  **[design-is-wrong on the framing; the WARN-in-validate-pack piece is fine, but it is sold as the systemic remedy when it is structurally inert in CI]**

**Design claim challenged:** §2.2 + §6 — the central design conclusion: a hard FAIL is "structurally unreachable in the gate that matters for merge" because "CI never has the graph (EE-0.3)," therefore the check is WARN-only; "a FAIL band sized to a state CI can never observe would be theater."

**Re-measurement:** CONFIRMED that CI (fresh `actions/checkout@v6`) never has `graphify-out/` (gitignored). So a check that reads `graphify-out/graph.json` directly can indeed never FAIL in CI. The design's logic is internally valid **given its premise that the only observable is the gitignored graph file itself.**

**The refutation — the premise is a false constraint.** The design measured "the graph is gitignored" and concluded "therefore CI can assert nothing about freshness." But the question is not "can CI read the graph" — it is "can a COMMITTED artifact let CI assert the graph was refreshed for THIS commit." It can:

- **A committed freshness sentinel** (NOT the 19 MB graph — a tiny tracked file, e.g. `pack-ops/.graph-built-at` or a one-line field in an existing tracked file) recording the `built_at_commit` SHA at refresh time. The refresh mechanism updates the sentinel when it refreshes the graph; the sentinel is committed alongside the work. Then CI's check is: **does the committed sentinel SHA == the commit's own tree state / parent SHA per the agreed rule?** That is a comparison over two COMMITTED values — fully observable in CI, FAIL-able, and O(1) (read one tiny file + `git rev-parse`). The gitignored graph never needs to be present.

This is exactly the measure-then-bound pattern the design claims to honor: measured state (graph stale; CI graph-blind) → but the correct *bound* is not "WARN-only forever" — it is "make a committed proxy CI can gate on." The design dismissed this entire class without measuring it (no EE explores a sentinel), which is itself a `ci-guard-measure-then-bound` gap: it sized the FAIL band to "what the current gitignored-graph design allows" rather than re-designing the observable.

**Counter-stress (steelmanning the design's WARN):** a sentinel has real costs the planner must weigh:
- It adds a committed file the refresh must keep in lock-step (a new thing that can rot — but UNLIKE the graph, its staleness is CI-visible, which is the whole point);
- A "sentinel SHA must equal HEAD" rule is impossible to satisfy at commit-creation time (you can't know your own commit SHA before you make it) — so the rule must be "sentinel == parent commit" or "sentinel advanced within the last N commits," a bounded-lag band, not exact equality. That is a real design subtlety, not a blocker.
- The semantic layer (subscription cost) must stay human-gated — so the sentinel for the SEMANTIC layer cannot be a per-commit hard gate; it can be a "behind by > N commits" WARN. But the CODE layer (free, deterministic) CAN carry a tighter committed-sentinel gate.

**Conclusion:** the WARN-in-validate-pack check is *fine as a local-run advisory* and should stay. But the design's framing — that WARN-only is FORCED and a FAIL would be "theater" — is **refutable**: a committed sentinel makes a real, FAIL-able, O(1), CI-observable gate possible without ever shipping the graph. Whether to adopt it is a user decision (the design's §2.2 FLAG-to-user is the right instinct), but the design should present the sentinel as a measured option with pros/cons, not foreclose it as structurally impossible. As written, the design's "systemic remedy" reduces to: a WARN nobody sees in CI (no graph) + a WARN the maintainer rarely sees locally (BLOCKER-1's pack-startup gap) + an unenforced runbook. That is three soft surfaces, none of which would have caught BD-225.

---

## MAJOR-2 — Failure-to-design mapping: the three failures are not all closed by a reliable element  **[design-is-wrong on completeness]**

The charter names THREE failures; the design must map each to an element that reliably prevents recurrence. Re-doing that mapping against the design's own recommendations:

| Failure | Design's preventing element | Is that element itself reliable? |
|---|---|---|
| **#1 mechanism never ran in production** | `graphify hook install` (A1) + per-clone install step | **NO** — A1 is still a per-clone manual `hook install` (design admits §1A-A1 cons: "still requires a per-clone INSTALL STEP"), AND on the documented main-tree commit path it mis-builds (BLOCKER-2). It replaces "nobody ran the hand-install" with "nobody ran `hook install`" — the SAME failure class. The design says §2 closes this "by §2 failing loud when the hook is absent" — but §2's loud surface is the pack-startup `hook status` report, which (BLOCKER-1) the maintainer rarely runs. So the only thing that would catch "the install never ran" is a surface that itself rarely runs. **Not closed.** |
| **#2 review did not catch it** | the verification check existing as a CI/test surface | **PARTIAL** — a committed test (`test-check-65.sh`) + a registered check IS a durable review-independent surface, which is genuinely better than BD-225 (no check at all). But the check only WARNs and only locally bites (MAJOR-1 + BLOCKER-1), so a future reviewer still sees green CI with a stale graph. The *encoding-surface* improvement is real; the *teeth* are not. |
| **#3 no check verified it worked, silent rot** | validate-pack Check 65 (WARN) + pack-startup prompt | **NO** — Check 65 is a CI no-op (no graph in CI, MAJOR-1) and a rarely-seen local WARN; pack-startup rarely runs (BLOCKER-1). Silent rot can still recur: nothing the maintainer routinely runs surfaces it. **Not closed.** |

**Bottom line:** of the three failures, only #2 is partially closed (by the existence of a committed test/check), and even that is weakened by the WARN-only verdict. #1 and #3 are *relocated*, not closed — the fragility moves from "hand-copied hook" to "manually-run `hook install` + rarely-run pack-startup prompt." That is the precise pattern the charter calls out ("a broken shipped mechanism with a three-failure defect"). A reliable design must anchor at least one teeth-bearing, routinely-exercised surface — see BLOCKER-1 alt-1/alt-2 and MAJOR-1 sentinel.


---

## MINOR-1 — The BD-226 "three resolvers" reconciliation is correct but understates the missed lesson  **[design-is-unproven → actually sound, but incomplete]**

**Design claim:** §4.2 — three actors, three resolvers (hook via `.graphify_root`; check via `REPO_ROOT`/degrade; agents via BD-226 injection), "do NOT conflate them."

**Re-measurement:** The check's `REPO_ROOT` resolution + no-graph-degrade is correct (re-confirmed against Check 63's `cwd=REPO_ROOT` pattern, validate-pack.py:6963-6974). The agent-consumption path (BD-226) is genuinely untouched (re-confirmed `graph-first-context` lives in all three trinity files; the injection contract is Claude-only and not modified). So the "do not restore parity / do not conflate" instinct is right.

**The gap:** the design correctly identifies that BD-226's lesson is "the orchestrator injects the absolute path; the consumer never self-derives from its own toplevel/CWD." It then applies that lesson to the CHECK and AGENTS but **NOT to the HOOK** — yet the HOOK (BLOCKER-2) is the one actor that self-derives `graphify-out/` from CWD and gets it wrong cross-worktree. The design names BD-226 in §4 and then leaves the hook to self-derive, which is exactly the anti-pattern BD-226 fixed. So §4.2's "three resolvers" is correct as a taxonomy but the THIRD resolver (the hook) is the one carrying BLOCKER-2. The reconciliation is incomplete: it should conclude "the hook, like a spawned agent, must be GIVEN the canonical root, not self-derive it" — which points at BLOCKER-2's alt-1/alt-2.

## MINOR-2 — EE-2.4.2 quotes a stale comment; the bump value is right but the citation is to the OLD bump  **[design-is-unproven, harmless]**

**Design claim:** EE-2.4.2 quotes the count-derivation comment as saying *"bump it 61 -> 62, NOT to 64"* and concludes the coder must bump 62→63.

**Re-measurement (validate-pack.py:490-500):** the comment block is the **BD-231** comment describing the PREVIOUS bump (61→62 for Check 64). The current value is `CHECK_REGISTRY_EXPECTED_COUNT = 62`. The design's *conclusion* (one new entry ⇒ 62→63) is CORRECT. But its quoted evidence is the prior-bump comment, which a coder could misread as "the target is 62." The planner should hand the coder the *current* value (62) and the rule (one new W-tuple ⇒ +1 ⇒ 63), and require the coder to UPDATE the derivation comment to describe the BD-237 bump (62→63 for Check 65) — the design lists "update the count-derivation comment block" (surface #3) so this is covered, but the EE citation is to the wrong bump and should not be copied into the plan verbatim.

## MINOR-3 — "all checks register with W" is conflated with WARN-vs-FAIL verdict  **[design-is-wrong, immaterial to conclusion]**

**Design claim:** §2.2 parenthetical — "A WARN here is consistent with the W-budget registry convention — all checks register with `W`."

**Re-measurement:** the registry's `W` is the per-check **timing WARN budget** (`RUN_CHECK_PER_CHECK_WARN_BUDGET_S`, validate-pack.py:459), NOT a verdict-severity flag. Re-measured: all 54 W-tuples carry `W` as the timing budget; checks independently call `fail()` (hard gate, the majority) or `warn()` (soft advisory — Check 48 is the live precedent, validate-pack.py:7991+). So "register with W" says nothing about whether Check 65 should WARN or FAIL — those are orthogonal. The parenthetical is a category error. It does not change the WARN-vs-FAIL decision (which MAJOR-1 addresses on its merits), but the plan must not carry this false justification; the real precedent for a non-gating check is Check 48's `warn()` call, which the design should cite instead.

## MINOR-4 — Atomic-swap / concurrent-refresh concern is better than the design's "MEDIUM unverified"  **[design-is-unproven → mostly resolvable from source now]**

**Design claim:** §7.2 — atomic-swap under concurrent agent reads is a MEDIUM unverified flag carried over from OPTIONAL-FEATURES L508-513.

**Re-measurement (watch.py):** graphify has a per-repo advisory `_rebuild_lock` (`fcntl.flock`, watch.py:92-122) with a `.pending_changes` spill so a blocked rebuild's change set is not dropped (watch.py:11-25, 74), released automatically on process death (no stale-lock cleanup). This substantially de-risks the concurrent-refresh-pileup concern the design flags. The torn-read question (a reader mid-swap) still warrants a one-line confirm of the tmp-then-replace write, but the design's MEDIUM is closer to LOW given the flock + pending-changes machinery. Not a blocker; the planner should re-grade it LOW and still ask the coder to confirm the final replace is atomic (`os.replace`).

## NIT-1 — `hook status` exit code: the design's §7.3 is correct and I confirmed the ambiguity

`graphify hook status` exits **0 even when both hooks are "not installed"** (re-measured: `graphify hook status; echo exit=$?` → `exit=0`). So a script CANNOT rely on exit code to detect non-installation — it MUST string-parse the stdout (`not installed`). The design's §7.3 flags exactly this and proposes the string-parse fallback, which is correct. Confirmed, no change needed — just elevating it from "LOW flag" to "verified fact the planner should bake into the check (parse stdout, never trust exit code)."

## NIT-2 — `.graphify_semantic_marker` content drifted (harmless)

Design/capability report cite `{"output_tokens": 2040684}`; I re-measured `{"output_tokens": 100931}`. This is just a re-build delta (the manual refresh between research and now). The marker's PRESENCE (not its value) is the signal "a semantic layer exists." No design impact; noting for EE hygiene.


---

## What the design got RIGHT and should be PRESERVED through any rework

- **The `built_at_commit`-vs-HEAD primitive** (not `check-update`/`needs_update`) — re-confirmed correct (EE-0.6: check-update exits 0 while stale). KEEP.
- **The O(1) bounded `tail`-read, not a 19 MB `json.load()`** — re-confirmed (field is the unique LAST field). KEEP. Any sentinel approach (MAJOR-1) is even cheaper.
- **The code/semantic layer split** (code = free/auto-safe; semantic = subscription/human-gated, never on the auto-commit path; S3 cron REJECTED) — re-confirmed against the cost model. KEEP. This is the design's strongest, most defensible call.
- **The 8-surface encoding enumeration** (check body, registry entry, count constant+comment, per-check test, CI workflow confirm-only, OPTIONAL-FEATURES runbook, pack-startup step, maintenance-docs) — re-verified complete and lock-step-correct. KEEP (the pack-startup step's VALUE changes per BLOCKER-1, but it remains a surface to touch).
- **degrade-silently-on-no-graph** for fresh-clone / CI / main-checkout — correct and necessary regardless of the WARN/FAIL/sentinel decision (the graph-reading check must never hard-fail where the graph legitimately doesn't exist). KEEP.
- **pack-only scope** (EE-5) — re-confirmed; no `project-template/`/`supporting-docs/` touch; commits may carry `pack-only`. KEEP.

## The minimum rework to reach READY

1. **Anchor the verification on a routinely-exercised, teeth-bearing surface (BLOCKER-1 + MAJOR-1).** Either (a) a committed freshness sentinel that lets validate-pack FAIL in CI on a bounded-lag rule (code layer), with the semantic layer a "behind by > N" WARN; and/or (b) a freshness assertion in Pack-Chat's commit-approval flow that fires every commit. The pack-startup prompt stays as a SECONDARY surface, not the primary actionable one.
2. **Fix the cross-worktree mechanism (BLOCKER-2).** Do not let the hook self-derive `graphify-out/` from CWD. Apply BD-226's own lesson: GIVE the refresh the canonical v11-dev root (via `GRAPHIFY_OUT` / explicit path), or drive the refresh from Pack-Chat's commit flow (which knows the canonical root), instead of relying on `graphify hook install`'s CWD-relative, guard-less post-commit body. If `graphify hook install` is kept, the coder MUST empirically test the MAIN-tree commit path (not just v11-dev) and add a guard so a graph-less worktree commit cannot build in the wrong tree.
3. **Re-present WARN-vs-FAIL as a measured options table (MAJOR-1)** including the committed-sentinel option with pros/cons, rather than foreclosing FAIL as "theater." User decides; the design must not pre-empt the decision with a false-constraint argument.
4. **Cosmetic/accuracy (MINOR-2/3, NIT-1):** hand the coder the CURRENT count (62→63) not the stale BD-231 comment quote; cite Check 48's `warn()` as the non-gating precedent (not the timing-budget `W`); bake "parse `hook status` stdout, never trust exit code" into the check if hook-status is reported.

If the rework anchors at least one teeth-bearing + routinely-run surface (item 1) and closes the wrong-tree build (item 2), the design's preserved core (primitive, tail-read, layer split, surface enumeration, degrade band) is sound and the result is READY.

---

## Verdict

**NEEDS-REWORK** — purpose-defeating gap: *the verification's only actionable home (pack-startup) is, by its own SSOT, not run on the maintainer's dominant same-machine workflow, and the recommended refresh mechanism mis-builds in the wrong worktree on the documented main-tree commit path — so the design relocates failures #1 and #3 rather than closing them, leaving silent rot able to recur.*

The design is empirically honest and its core technical choices (the `built_at_commit` primitive, O(1) tail-read, code/semantic split, surface enumeration) are correct and re-verified — this is a rework of the *teeth and the trigger*, not a teardown of the shape.

The central WARN-not-FAIL conclusion is **REFUTABLE**: a tiny COMMITTED freshness sentinel (not the gitignored 19 MB graph) makes a real, FAIL-able, O(1), CI-observable gate possible without ever shipping the graph — the design dismissed this class without measuring it.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Commands run were read-only only: `git rev-parse`, `git worktree list`, `git config --get`, `git rev-parse --git-path/--git-common-dir`, `git log`, `git reflog`, `git ls-files`, `git grep`, `ls`, `cat`, `grep`, `tail`, `head`, `wc`, `sed -n` (read), `graphify hook status`, `graphify check-update .`, `graphify --help`, `graphify query` (read). NO `graphify update`/`extract`/`hook install`; NO graph mutation; NO `git add/commit/push/apply/...`; NO source edit. Sole write = this review doc + the `mkdir -p /tmp/pack-handoff-bd237-adv`. | COMPLIANT |
| 2 | empirical-evidence-blocks [architect] | Every finding carries an independent re-measurement: command + verbatim output + HEAD-SHA `2f53788` + interpretation. Confirmed-facts table re-runs the design's EE-0.1..0.6/2.4.1..5/5; BLOCKER-2 re-reads hooks.py:90-112/187-285/238-285/317-340 + watch.py:365-577 verbatim; BLOCKER-1 quotes SKILL.md:3 + PACK-CHAT.md:33-40/441-446; MAJOR-1 re-reads validate-pack.yml checkout+run; MINOR-2/3 re-read validate-pack.py:459/490-500/7991. | COMPLIANT |
| 3 | ci-guard-design-measure-then-bound | Held the verification check to the contract: re-measured the observable state (CI graph-blind; graph gitignored; built_at_commit unique LAST field). Showed the design sized its FAIL band to the gitignored-graph design rather than re-designing the observable (MAJOR-1), and proposed a committed-sentinel measure-then-bound gate (read one tiny tracked file + `git rev-parse`, O(1), CI-observable, FAIL-able with a bounded-lag rule) as the stronger, non-theater alternative — with its costs stated, not hand-waved. | COMPLIANT |
| 4 | ci-check-runtime-compounding | Confirmed the design's check is O(1) (unique last-field tail-read, ~5ms; one isfile; one regex; one `git rev-parse`). My counter-proposals are equal or cheaper: a committed sentinel is one small-file read + one `git rev-parse` (no 19 MB anything); no proposal introduces a tree scan or per-entry subprocess storm. No cost regression flagged. | COMPLIANT |
| 5 | graph-first-context | Queried the injected graph path verbatim (`graphify query "…freshness mechanism…" --backend claude-cli --budget 1500 --graph /Users/.../graphify-out/graph.json`) for orientation; it returned stale/noisy results (the graph is the very artifact under review, behind HEAD), so I fell through to grep/Read/git for all authoritative facts (SSOT fields, uncommitted design doc, hooks.py source). Did not block on the graph (G2 fallback). | COMPLIANT |
| 6 | separate-pack-ops-from-product | Re-verified the entire change is pack-ops-only (EE-5 reproduced: target set has no `project-template/`/`supporting-docs/` member; graph gitignored; graph-first rule pack-root-trinity-only). My counter-proposals (sentinel under `pack-ops/`, Pack-Chat commit-flow step, hook-root injection) are all pack-ops-side — none leaks into the client install. Flagged none needed. | COMPLIANT |
| 7 | verify-availability-not-just-existence | Re-verified every leaned-on graphify capability from installed 0.8.39 SOURCE, not docs: `hook install` body (CWD-relative, no post-commit existence guard — hooks.py); `_rebuild_code` builds-if-missing (watch.py:514-577); `_rebuild_lock` flock (watch.py:92-122); `hook status` exit 0 on not-installed (live); check-update exit 0 while stale (live). My sentinel counter-proposal relies only on plain `git rev-parse` + file read (no unverified graphify capability). | COMPLIANT |
| 8 | scope-deliverables-to-the-ask | Reviewed exactly the BD-237 design: defect state, hook mechanism, verification strength, verification home, three-failure mapping, BD-226 reconciliation, encoding-surface/count/parallel-map correctness. Did not redesign unrelated graphify features (query/merge-driver/path) or any client product. | COMPLIANT |
| 9 | deferral-is-scope-creep / no-deferral-without-user-direction | Judged the design against fixing this NOW in v11.0. Flagged that the design QUIETLY DEFERS failure-modes by relocating #1 and #3 to rarely-run surfaces (BLOCKER-1/MAJOR-2) and by labeling a likely mis-build as "verify later" (BLOCKER-2) — called each out for fix-now rather than accepting the soft relocation. No finding punted to a later BD/version. | COMPLIANT |
| 10 | rules-applied-verification-block | This block — one row per in-force rule with quoted/measured evidence + terminal conclusion. | COMPLIANT |

---

*End of ADVERSARIAL-REVIEW-BD-237. Read-only adversarial design review; no source edits, no state-changing git verbs, no graph mutation. Sole write = this file.*
