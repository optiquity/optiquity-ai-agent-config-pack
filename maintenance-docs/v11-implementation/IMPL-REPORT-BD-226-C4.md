# IMPL-REPORT — BD-226 COMMIT C4 (graph-path injection under worktree isolation, CLAUDE-only)

**Agent:** pack-coder (FRESH, READ-WRITE, isolated worktree). **BD:** BD-226 (sole). **Commit:** C4 — the LAST commit of the BD-226 batch. **Scope keyword:** `pack-only`.

## Runtime regime (verified at runtime — rule 8 / commit-discipline §1)

- **Worktree path (pwd):** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a803913f1484fa733`
- **Toplevel (`git rev-parse --show-toplevel`):** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a803913f1484fa733` (== pwd → confirmed isolated worktree, NOT the main `-v11-dev` checkout)
- **Branch (`git rev-parse --abbrev-ref HEAD`):** `worktree-agent-a803913f1484fa733` (a `worktree-agent-*` branch → ISOLATED, as required)
- **HEAD at start AND at report (`git rev-parse HEAD`):** `cf3527e3dbf47768186c13b6766dc9793e1b5ceb`
- **HEAD subject (`git log -1 --oneline`):** `cf3527e feat: v11 — BD-226 project feature doc + skill + prompts + agent-run launcher (project-only)` — matches the prompt's expected base `cf3527e`.
- **No patch produced.** No stage/commit/apply run. Read-only git verbs only. The patch is produced ONLY after review-clean when the orchestrator re-engages me (rule 4 / worktree-isolation-mergeback-ops).

Regime VERIFIED CORRECT against the prompt's expectation (HEAD = cf3527e, in a `worktree-agent-*` worktree). No STOP condition.

## What C4 is

C4 codifies the PACK-ONLY graph-path-injection addendum (BD-226 APPLICATION A addendum). Under worktree isolation, gitignored `graphify-out/` is NOT materialized in an isolated worktree, so a spawned agent's `$(git rev-parse --show-toplevel)/graphify-out/graph.json` self-derivation mis-resolves to the empty worktree root. Fix: the ORCHESTRATOR derives the real graph path AT RUNTIME in its canonical checkout and INJECTS the literal into every spawn prompt; agents query `graphify … --graph <injected literal>`, NEVER their own toplevel. **F-1 = USER OPTION A: CLAUDE-only.** C4 edits ONLY `CLAUDE.md` + `pack-ops/PACK-CHAT.md` + `pack-ops/PACK-AGENTS.md`. C4 does NOT touch `AGENTS.md`, `GEMINI.md`, or the `PACK-MEMORY-RATIONALE.md` `## graph-first-context` section. C4 depends on C1 + C2 (both committed at base cf3527e).

## Files changed (inventory)

| Path | Change type | Line delta |
|---|---|---|
| `CLAUDE.md` | modified (G1 + G4) | +40 / −5 |
| `pack-ops/PACK-CHAT.md` | modified (G2 — ADD) | +11 / −0 |
| `pack-ops/PACK-AGENTS.md` | modified (G3 — ADD) | +11 / −0 |

`git diff --stat`: 3 files changed, 57 insertions(+), 5 deletions(-). `git diff --name-only` = exactly the 3 named files (no AGENTS.md / GEMINI.md / PACK-MEMORY-RATIONALE.md / project-template path).

## Per-surface summary (G1 / G4 / G2 / G3)

### G1 — `CLAUDE.md` § "Graph-first context (BD-225)" (CLAUDE-only)

- **Before anchor (verbatim):** the bullet opened `**Graph-first context when the knowledge graph exists (BD-225).** If \`$(git rev-parse --show-toplevel)/graphify-out/graph.json\` exists, prefer the graph …` and later carried `The \`--graph\` path is ALWAYS absolute (\`$(git rev-parse --show-toplevel)/graphify-out/graph.json\`) since a sub-agent may start in a different cwd; …`.
- **After (delta):**
  - **Constraint 2 (no self-derivation; orchestrator-derives-and-injects).** Reworded the opening `If $(…)/graphify-out/graph.json exists` → "When a knowledge graph exists" (the existence check is now run against the INJECTED path, not a self-derived path). Inserted a `**Path-injection under worktree isolation (BD-226):**` block: the orchestrator evaluates the derivation formula `$(git rev-parse --show-toplevel)/graphify-out/graph.json` AT RUNTIME in its canonical checkout and INJECTS the resulting absolute literal into every spawn prompt; the agent uses THAT injected `--graph <path>` verbatim and NEVER recomputes from its own `$(git rev-parse --show-toplevel)` — which under worktree isolation resolves to the empty worktree root where gitignored `graphify-out/` is NOT materialized. The surface carries the DERIVATION FORMULA + the injection contract — NO machine-specific literal is baked.
  - **F-8 graceful degradation.** The orchestrator injects the literal ONLY when its canonical `graphify-out/graph.json` exists; when absent (fresh clone / graphify not installed / feature off) it injects NO path (or an explicit "no graph available" token) and the agent proceeds with grep/Read. The agent runs the G1 existence check against the INJECTED path (never its own toplevel); the G2 fallback (query errors/empties ⇒ fall back to grep/Read, never block) is unchanged. The later `--graph` sentence reworded from `is ALWAYS absolute (\`$(...)/graphify-out/graph.json\`)` → "the `--graph` path the orchestrator injects is ALWAYS absolute (a sub-agent may start in a different cwd)" — removing the second self-derivation literal.
  - **F-1 Trinity-exempt note (added VERBATIM intent).** Added: "Worktree path-injection is Claude-only (only Claude runs worktrees); the `AGENTS.md`/`GEMINI.md` graph-first path-resolution intentionally stays as-is — correct for their in-place execution — and their worktree story is a future pack version. Do NOT 'restore parity' by porting this injection contract to them."
  - **KEPT VERBATIM:** budget tiers (2000 human/interactive, 1500 spawned agent, 1000 Pack-Chat prompt-construction); `--backend claude-cli` (NEVER `claude`) clause; the G2 fallback clause; the NEVER-preload-skill clause; the QUERY-not-BUILD clause; the invocation clause; the boundary note; **and the trailing `[roles: universal] [rationale: graph-first-context]` tag (UNTOUCHED — F-P5-b).**

### G4 — `CLAUDE.md` § "Agent invocation rules" spawn-syntax (CLAUDE-only; ADD)

- **Anchor:** the `- **Pack agent invocation.**` bullet (the `claude --agent pack-<name>` / Agent-tool `subagent_type=pack-<name>` spawn-syntax surface). No existing graph text there — this is an ADD (F-G).
- **After (delta):** Added a new bullet immediately after `Pack agent invocation`: `- **Inject the graph path into every spawn prompt (BD-226, Claude-only).**` — under worktree isolation a spawned agent's `$(git rev-parse --show-toplevel)` resolves to the empty worktree root where gitignored `graphify-out/` is absent, so the orchestrator MUST derive the real graph path AT RUNTIME in its canonical checkout (formula `$(git rev-parse --show-toplevel)/graphify-out/graph.json`) and INJECT the absolute literal into every spawn prompt — only when that canonical `graphify-out/graph.json` exists (else inject no path). The agent queries with `graphify <verb> … --graph <injected>`, NEVER its own toplevel. Cross-references § "Graph-first context (BD-225)" for the full contract + the Claude-only Trinity-exempt note.

### G2 — `pack-ops/PACK-CHAT.md` spawn-prompt construction (ADD)

- **Anchor:** the `- **Name the handoff dir in the prompt.**` bullet (the spawn-prompt-construction area). No existing graph text in PACK-CHAT.md (grep count = 0) — ADD (F-G).
- **After (delta):** Added a new bullet immediately after `Name the handoff dir in the prompt`: `- **Inject the graph path into the prompt (BD-226, Claude-only).**` — Pack Chat evaluates the derivation formula `$(git rev-parse --show-toplevel)/graphify-out/graph.json` AT RUNTIME in its canonical checkout and writes that resolved absolute path into the prompt, ONLY when that canonical `graphify-out/graph.json` exists (else inject no path / a "no graph available" token — F-8). The agent queries with `graphify <verb> … --graph <injected>` and NEVER recomputes from its own `$(git rev-parse --show-toplevel)` (the empty worktree root under isolation). Cross-references trinity `## Pack memory` § "Graph-first context (BD-225)".

### G3 — `pack-ops/PACK-AGENTS.md` spawn-syntax surface (ADD)

- **Anchor:** § "How to invoke pack agents" → end of "Sub-agent invocation (from pack chat)" subsection, immediately before "Separate terminal session (developer-initiated)" (covers both the Agent-tool and `claude --agent` spawn paths). No existing graph text in PACK-AGENTS.md (grep count = 0) — ADD (F-G).
- **After (delta):** Added a standalone bolded note `**Inject the graph path into every spawn prompt (BD-226, Claude-only).**` — the orchestrator MUST derive the real graph path AT RUNTIME in its canonical checkout (formula `$(git rev-parse --show-toplevel)/graphify-out/graph.json`) and INJECT the resolved absolute literal into every spawn prompt — only when that canonical `graphify-out/graph.json` exists (else inject no path). The agent uses the injected `--graph <path>`, NEVER its own toplevel. Cross-references trinity `## Pack memory` § "Graph-first context (BD-225)".

## Verification results

| Gate | Command | Result |
|---|---|---|
| validate-pack full suite (exit 0; all 62 checks) | `python3 scripts/validate-pack.py` | **PASS** — `PASSED — all checks clean`; explicit exit-code probe = `exit=0` |
| **Check 18** trinity H2 parity (both surfaces) | (within full run) | **OK** — `[pack-root] CLAUDE.md ↔ AGENTS.md H2 structures match (5 sections)`; `[pack-root] GEMINI.md adds 1 intrinsic H2; otherwise matches (5 sections)`; project-template both OK (26 sections). My CLAUDE.md edits stayed inside existing H2 sections — no structural change. |
| **Check 45** pack-memory rule↔rationale bijection | (within full run) | **OK** — `23 corpus [rationale: slug] pointer(s); 23 rationale ## <slug> section(s); sets are equal (bijection holds, no orphans)`. The `[rationale: graph-first-context]` tag is intact. |
| **Check 36** commit-scope honesty | (within full run) | **OK** — `1 scope-claiming commit(s) verified clean`. |
| F-P5-b rationale tag preserved VERBATIM | `grep -c "\[roles: universal\] \[rationale: graph-first-context\]" CLAUDE.md` | **1** (preserved exactly). |
| Constraint-2 no-hardcoded-path gate | `grep -rnE "/Users/\|/home/\|/private/" CLAUDE.md pack-ops/PACK-CHAT.md pack-ops/PACK-AGENTS.md \| grep -iE "graph\|toplevel\|graphify-out"` | **0 matches** (grep exit 1). The surfaces carry the DERIVATION FORMULA `$(git rev-parse --show-toplevel)/graphify-out/graph.json` + the injection narrative — never a baked machine-specific literal. |
| F-8 degradation wording present (G1) | `grep -nE "injects the literal ONLY when\|no graph available\|existence check against the INJECTED path" CLAUDE.md` | **3 hits** (L659 "injects the literal ONLY when its", L662 "no graph available token", L663 "existence check against the INJECTED path"). |
| F-1 CLAUDE-only scope | `git diff --name-only` | exactly `CLAUDE.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`. |
| F-1 AGENTS/GEMINI/RATIONALE untouched | `git diff --name-only AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md \| wc -l` | **0** (no diff on any of the three). |
| F-1 graph-first baselines UNCHANGED from HEAD | `grep -c "show-toplevel.*graphify-out\|graphify-out/graph.json" AGENTS.md GEMINI.md` + `grep -nc "## graph-first-context" pack-ops/PACK-MEMORY-RATIONALE.md` | AGENTS.md=**2**, GEMINI.md=**2** (unchanged from pre-edit baseline), RATIONALE `## graph-first-context`=**1** present (untouched). |
| No test asserts OLD graph-first prose | `grep -rnE "show-toplevel.*graphify-out\|graphify-out/graph.json\|Graph-first context" scripts/tests/` | only Check-63 tracked-path test hits (unrelated to prose; Check 63 green) — zero tests assert the reworded prose, so the flip needs no test edit. |

**Full CI battery note (verify-full-ci-suite):** C4 touches only three prose docs — no scripts, no fixtures, no skill frontmatter, no `build.sh` inputs, no manifest inputs. `validate-pack.py` wires ALL 62 checks (Check 59 confirms `CHECK_REGISTRY has 62 entries == EXPECTED`) including the trinity/bijection/scope/destructive-verb-parity/manifest checks, and ran exit 0 with no `--only-check`. No fixture rebuild or sharded test is implicated by a prose-only graph-injection edit (confirmed: no test asserts the changed prose).

## C4 IMPL-REPORT divergence record (plan T-C4 step 5 / design §2 Gx)

By **USER DECISION F-1 (Option A)**, the following keep the SELF-DERIVATION wording intentionally (NOT an oversight) — a future maintainer must NOT "restore parity" or "fix" them as part of this addendum:

- `AGENTS.md` and `GEMINI.md` § "Graph-first context (BD-225)" — graph-first path-resolution stays as `$(git rev-parse --show-toplevel)/graphify-out/graph.json` (2 refs each, unchanged). Correct for their in-place execution; their worktree story is a future pack version.
- `pack-ops/PACK-MEMORY-RATIONALE.md` § `## graph-first-context` — keeps the self-derivation wording. Acceptable under F-1 because the live-worktree bug is Claude-only and the CLAUDE.md corpus bullet is the operative instruction for Claude agents. `graph-first-context` is NOT manifest-tracked → C4 triggers no `.spawn-rule-manifest.txt` update and Check 45 bijection is body-agnostic (slug unchanged).

The intentional divergence is also documented IN the CLAUDE.md G1 surface itself (the F-1 Trinity-exempt sentence) so the rule is durable, not reliant on this report.

## Boundary discipline check

C4 is `pack-only` — all three edited files are pack-ops surfaces (`CLAUDE.md` pack-repo root trinity, `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`). No project-template / supporting-docs surface was touched. The Graphify addendum is PACK-ONLY by design (Graphify never ships to clients), so no graph content was added to any project surface — consistent with `pack-project-separation-of-concerns`. No project-side SSOT investigation was required because no project-side file was edited.

## Plan deviations

**None.** All four C4 tasks (T-C4-G1, T-C4-G2, T-C4-G3, T-C4-G4) implemented exactly per plan §C4 + design §2 G-surfaces (Constraint 2, F-8, F-1, F-G, F-P5-b). The within-task G1→G4 same-file ordering (§4.5) was honored (both CLAUDE.md hunks edited in this one task). The T-C4 step-5 divergence record is captured above.

## New POQs introduced

**None.** No design gap encountered; the design §2 G-surfaces were self-contained and the anchors were present as documented.

## Unplanned modifications

**None.** Diff is exactly the 3 in-scope files; AGENTS.md / GEMINI.md / PACK-MEMORY-RATIONALE.md / all project-template paths untouched.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| G1 Constraint-2 self-derivation → orchestrator-derives-and-injects (CLAUDE.md) | **PASS** |
| G1 F-8 graceful degradation (inject only when graph.json exists; existence check on injected path; G2 fallback unchanged) | **PASS** |
| G1 F-1 Trinity-exempt note present | **PASS** |
| G1 budgets (2000/1500/1000) + `--backend claude-cli` + G2 fallback KEPT | **PASS** |
| G1 F-P5-b `[rationale: graph-first-context]` tag preserved VERBATIM | **PASS** (grep = 1) |
| G4 CLAUDE.md spawn-syntax inject note ADDED | **PASS** |
| G2 PACK-CHAT.md inject note ADDED near "Name the handoff dir" anchor | **PASS** |
| G3 PACK-AGENTS.md inject note ADDED near "How to invoke pack agents" / `claude --agent` block | **PASS** |
| Constraint-2 no-hardcoded-path gate = 0 machine-specific literals | **PASS** (grep exit 1) |
| F-1 CLAUDE-only: only the 3 named files; AGENTS/GEMINI/RATIONALE untouched | **PASS** |
| validate-pack exit 0; Check 18 + Check 45 green | **PASS** |
| Check 36 pack-only scope clean | **PASS** |
| No patch emitted; no stage/commit/apply | **PASS** |
| IMPL-REPORT written to `/tmp/handoff-bd226-C4/IMPL-REPORT.md` | **PASS** (this file) |

## Rules-Applied Verification Block

| Rule name | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No state-changing git verb run. Only `git rev-parse`, `git log`, `git status`, `git diff`, `git diff --name-only/--stat` executed. No patch emitted up front (`git diff > changes.patch` deferred to post-review-clean per prompt). `git status` at start = clean; no `git add`/`commit`/`apply`. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op attempted. Only Read/Edit/Write/read-only-Bash used; `mkdir -p /tmp/handoff-bd226-C4` is the named handoff dir creation (non-destructive, prompt-directed). | COMPLIANT |
| `preflight-stop-means-stop` | Emitted ONE PREFLIGHT line only after all 4 edits + verification PASS: `PREFLIGHT: 4/4 C4 edits complete; validate-pack PASS (Check 18/45 green); no-hardcoded-path gate 0; F-1 CLAUDE-only (AGENTS/GEMINI/RATIONALE untouched); rationale tag preserved; F-8 degradation present; pack-only scope; HEAD cf3527e…; worktree /…/agent-a803913f1484fa733; about to Write IMPL-REPORT…`. No parent stop/halt received. | COMPLIANT |
| `edit-in-place-not-full-rewrite` | Targeted in-place Edits on quoted anchors (4 edits across 3 files; `git diff --stat` = +57/−5, no full rewrite). Budget tiers + `--backend claude-cli` + G2-fallback wording + `[rationale: graph-first-context]` tag all KEPT (grep tag = 1; full-run shows budget/backend clauses intact via Check 45 green + manual preservation). | COMPLIANT |
| `ci-guard-measure-then-bound` | No-hardcoded-path gate measured: `grep -rnE "/Users/\|/home/\|/private/" <3 files> \| grep -iE "graph\|toplevel\|graphify-out"` → 0 matches (exit 1). The surfaces carry the derivation formula `$(git rev-parse --show-toplevel)/graphify-out/graph.json` + injection narrative, never a baked literal. | COMPLIANT |
| `worktree-isolation-mergeback-ops` | Verified runtime regime: pwd = toplevel = `/…/.claude/worktrees/agent-a803913f1484fa733` (isolated worktree); branch `worktree-agent-a803913f1484fa733`; HEAD `cf3527e3dbf47768186c13b6766dc9793e1b5ceb` (matches expected). Edited IN this worktree. No patch produced (deferred to post-review-clean). Report → named `/tmp/handoff-bd226-C4/IMPL-REPORT.md`. | COMPLIANT |
| `pack-project-separation-of-concerns` | `git diff --name-only` = `CLAUDE.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md` — all pack-ops surfaces; zero `project-template/` paths. Graph addendum kept PACK-only (no graph content on any project surface). | COMPLIANT |
| `graph-first-context` | grep/Read used as authoritative for the exact-string anchors (graphify-out not present in this worktree — fell back to grep/Read per the G2 fallback the rule itself prescribes). Editing this rule's own CLAUDE.md surface: preserved substance (prefer-graph; budgets 2000/1500/1000; `--backend claude-cli`; G1/G2 guards) while fixing path-resolution to the injection model; `[rationale: graph-first-context]` tag kept (grep = 1; Check 45 bijection 23↔23 green). | COMPLIANT |
| `rules-applied-verification-block` | This block: each prompt "Rules in force" rule has a name + quoted/measured evidence + a non-empty Conclusion. | COMPLIANT |

---

**Status:** C4 implementation complete, verified, review-ready. NO patch produced (per rule 4 / worktree-isolation-mergeback-ops — patch only after review-clean when the orchestrator re-engages). Awaiting the reviewer cycle; on re-engagement I will run `git diff > /tmp/handoff-bd226-C4/changes.patch`.
