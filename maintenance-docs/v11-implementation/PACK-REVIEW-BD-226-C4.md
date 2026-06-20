# REVIEW — BD-226 COMMIT C4 (graph-path injection under worktree isolation, CLAUDE-only) — PRE-COMMIT

**Agent:** pack-reviewer (FRESH, READ-ONLY). **BD:** BD-226 (sole). **Commit under review:** C4 — the LAST commit of the BD-226 batch. **Scope keyword claimed:** `pack-only`.

**Runtime regime (verified — rule 8 / worktree-isolation-mergeback-ops):**
- **pwd / toplevel:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a803913f1484fa733` (`git rev-parse --show-toplevel` == pwd → isolated worktree, not the main `-v11-dev` checkout)
- **Branch:** `worktree-agent-a803913f1484fa733`
- **HEAD:** `cf3527e3dbf47768186c13b6766dc9793e1b5ceb` — MATCHES the prompt's expected base `cf3527e`.
- **Working tree:** exactly 3 files modified (` M CLAUDE.md`, ` M pack-ops/PACK-AGENTS.md`, ` M pack-ops/PACK-CHAT.md`); C4 is UNCOMMITTED, reviewed IN this worktree. No STOP condition.
- **Batch-order sanity:** `git log --oneline` shows the BD-226 batch landed C1 (`ba3bb08`) → C5 (`a149711`) → C2 (`28879ae`) → C3 (`46dce4d`) → C6 (`cf3527e`); C4 is the remaining uncommitted work — exactly the serial order `C1→C5→C2→C3→C6→C4` (plan §4.6). C4 correctly serializes AFTER C1 and C2, the commits it shares CLAUDE.md/PACK-AGENTS.md and PACK-CHAT.md with.

---

## VERDICT: **CLEAN**

Every C4 review dimension passes against the FINAL design (§2 APPLICATION A addendum G1-G4, Constraint 2, F-8, F-1, F-P5-b, the no-hardcoded-path gate, §6 trinity-divergence hand-verify), the plan COMMIT C4 (T-C4-G1..G4 + step-5 divergence record), and `backlog/BD-226.md` APPLICATION A addendum. `validate-pack.py` exits 0 in the worktree; Checks 18 / 45 / 36 / 63 green. No BLOCKER, MUST, SHOULD, or NIT finding. The IMPL-REPORT's claims were re-measured independently in the worktree and all reproduce.

---

## FINDINGS TABLE

| # | Severity | Dimension | Finding | Status |
|---|---|---|---|---|
| — | — | D1 Constraint 2 (no hardcoded path) | Orchestrator-derives-and-injects; agent uses injected verbatim, never recomputes; derivation FORMULA is the surface form, no baked literal | PASS |
| — | — | D2 F-8 graceful degradation | Inject only when canonical graph.json exists; "no graph available" token else; G1 existence check on INJECTED path; G2 fallback intact; budgets 2000/1500/1000 + `--backend claude-cli` (never `claude`) kept | PASS |
| — | — | D3 F-1 Trinity-exempt note | Explicit sentence present (incl. "Do NOT 'restore parity'") | PASS |
| — | — | D4 F-P5-b rationale tag (CRITICAL) | `[roles: universal] [rationale: graph-first-context]` preserved verbatim (grep -c = 1) | PASS |
| — | — | D5 G4/G2/G3 ADDs at correct anchors | G4 after "Pack agent invocation"; G2 after "Name the handoff dir"; G3 end of "Sub-agent invocation"; all use `--graph <injected>` never own toplevel; G2/G3 carry F-8 condition | PASS |
| — | — | D6 F-1 CLAUDE-only scope | diff = EXACTLY the 3 files; AGENTS.md/GEMINI.md/PACK-MEMORY-RATIONALE.md byte-unchanged from HEAD; AGENTS/GEMINI keep their 2 self-derivation refs each (intentional divergence) | PASS |
| — | — | D7 No-hardcoded-path gate | 0 machine-specific literals across the 3 files (incl. `/Developer/`); derivation formula is the surface form | PASS |
| — | — | D8 CI parity | validate-pack exit 0; Check 18 (H2 parity, body-agnostic) green; Check 45 (23↔23 bijection) green; Check 36 clean; Check 63 green; 62/62 checks ran | PASS |

---

## PER-DIMENSION EVIDENCE

### D1 — Constraint 2 (no hardcoded path): SUPPORTED
CLAUDE.md G1 (L650-664) and the G4 add (L249-259) both state the orchestrator evaluates the **derivation formula** `$(git rev-parse --show-toplevel)/graphify-out/graph.json` AT RUNTIME in its canonical checkout and INJECTS the resolved literal; the agent "uses THAT injected `--graph <path>` verbatim and NEVER recomputes from its own `$(git rev-parse --show-toplevel)`". The formula appears as a `$(...)` shell expression (4 occurrences of `$(git rev-parse` in CLAUDE.md), NOT a baked machine literal. G2 (PACK-CHAT.md L288-298) and G3 (PACK-AGENTS.md L62-72) restate the same contract. Matches design §2 G1 Constraint 2 + plan T-C4-G1.

### D2 — F-8 graceful degradation: SUPPORTED
`grep -nE "injects the literal ONLY when|no graph available|existence check against the INJECTED path" CLAUDE.md` → 3 hits (L659, L662, L663). The orchestrator "injects the literal ONLY when its canonical `graphify-out/graph.json` exists; when it is absent (fresh clone / graphify not installed / feature off) the orchestrator injects NO path (or an explicit 'no graph available' token) and the agent proceeds with grep/Read." "The agent runs the G1 existence check against the INJECTED path (never its own toplevel); the G2 fallback (query errors/empties ⇒ fall back to grep/Read, never block) is unchanged." Budgets kept at L671 (`2000 ... 1500 ... 1000`); backend at L673 (`--backend claude-cli ... NEVER \`claude\``). Matches design §2 G1 F-8.

### D3 — F-1 Trinity-exempt note: SUPPORTED
CLAUDE.md L665-669: "**Worktree path-injection is Claude-only (only Claude runs worktrees); the `AGENTS.md`/`GEMINI.md` graph-first path-resolution intentionally stays as-is — correct for their in-place execution — and their worktree story is a future pack version. Do NOT 'restore parity' by porting this injection contract to them.**" Documents the intentional divergence durably on the surface itself. Matches design §2 G1 F-1 note.

### D4 — F-P5-b rationale tag preserved (CRITICAL): SUPPORTED
`grep -c "\[roles: universal\] \[rationale: graph-first-context\]" CLAUDE.md` → **1** (L684, the trailing tag on the graph-first bullet). The tag is the bijection anchor that maps the corpus bullet to RATIONALE `## graph-first-context`; preservation keeps Check 45 green (verified D8). Had it been dropped, Check 45 would have orphaned the `## graph-first-context` section.

### D5 — G4 / G2 / G3 ADDs at correct anchors: SUPPORTED
- **G4 (CLAUDE.md L249-259):** new bullet immediately after "Pack agent invocation" (L244) in § "Agent invocation rules" spawn-syntax. Agent "queries with `graphify <verb> … --graph <injected>`, NEVER its own toplevel"; cross-refs § "Graph-first context (BD-225)". Matches plan T-C4-G4.
- **G2 (PACK-CHAT.md L288-298):** new bullet immediately after "Name the handoff dir in the prompt" (L280) — the spawn-prompt-construction area. Carries the inject-only-when-graph-exists F-8 condition ("ONLY when that canonical `graphify-out/graph.json` exists (else inject no path / a 'no graph available' token)") and "NEVER recomputes from its own `$(git rev-parse --show-toplevel)`". Matches plan T-C4-G2 (ADD).
- **G3 (PACK-AGENTS.md L62-72):** standalone bolded note at the end of "Sub-agent invocation (from pack chat)" (L48), before "Separate terminal session" (L73) — covers both spawn paths. "The agent uses the injected `--graph <path>`, NEVER its own toplevel." Matches plan T-C4-G3 (ADD).

### D6 — F-1 CLAUDE-only scope: SUPPORTED
`git diff --name-only` = EXACTLY `CLAUDE.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`. `git diff HEAD -- AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md | wc -l` = **0** (all three byte-unchanged from HEAD `cf3527e`). The intentional divergence is verified intact: `grep -c "show-toplevel.*graphify-out\|graphify-out/graph.json"` = **2** in AGENTS.md and **2** in GEMINI.md (they keep self-derivation, correct for in-place execution); `grep -c "## graph-first-context" pack-ops/PACK-MEMORY-RATIONALE.md` = **1** (section present, untouched). Matches design §2 Gx + plan C4 row (d).

### D7 — No-hardcoded-path gate (ci-guard-measure-then-bound, re-run): SUPPORTED
`grep -rnE "/Users/|/home/|/private/" CLAUDE.md pack-ops/PACK-CHAT.md pack-ops/PACK-AGENTS.md` → 0 matches (exit 1). Tightened re-run including `/Developer/` → also 0 (exit 1). Graph/toplevel-scoped filter → 0. The derivation FORMULA `$(git rev-parse --show-toplevel)/graphify-out/graph.json` is the surface form (a shell expression, not a resolved machine path). Matches design §5.3.

### D8 — CI parity: SUPPORTED
`python3 scripts/validate-pack.py` → `exit=0`; final line `PASSED — all checks clean`.
- **Check 18 (trinity H2 parity):** `OK: [pack-root] CLAUDE.md ↔ AGENTS.md H2 structures match (5 sections)`; `OK: [pack-root] GEMINI.md adds 1 intrinsic H2(s); otherwise matches (5 sections)`. Check 18 verifies H2 names/order only (body-agnostic), so the body-level CLAUDE-only graph-first divergence does NOT break it — exactly as design §6 / plan §6 anticipate.
- **Check 45 (bijection):** `OK: Check 45 — 23 corpus \`[rationale: slug]\` pointer(s); 23 rationale \`## <slug>\` section(s); sets are equal (bijection holds, no orphans...)`. The preserved rationale tag (D4) keeps 23↔23.
- **Check 36 (commit-scope honesty):** `OK: Check 36 — 1 scope-claiming commit(s) verified clean; 0 implicit-scope commit(s) skipped`. (Note: Check 36 evaluates COMMITTED commits; C4 is uncommitted, so its `pack-only` claim is enforced at commit time. The working diff is confirmed pack-only here — zero `project-template/` or `supporting-docs/` paths — so the keyword will hold when C4 lands.)
- **Check 63 (graphify-out tracked-path guard):** `OK: Check 63 — graphify-out/ is not tracked (... 0 tracked paths).`
- **Check 59:** `CHECK_REGISTRY has 62 entr(y/ies)` and the no-flag full run executes every registered check — confirms the full battery ran, not a subset.
- **No test edit needed:** the only `scripts/tests/` hits for `graphify-out/graph.json` are in `test-validate-pack-check-63.sh` (the tracked-path guard test); zero tests assert the graph-first prose, so the prose flip implicates no test.

---

## TRINITY-DIVERGENCE HAND-VERIFICATION (design §6 / plan §6 — required of the C4 reviewer)

I hand-verify that the CLAUDE-only graph-first divergence introduced by C4 is the **INTENTIONAL F-1 tool-specific exemption**, NOT an accidental trinity-parity break:

1. **It is by user decision.** F-1 = USER OPTION A (design §0 ledger, §2 addendum header): the graph-path-injection fix lands in CLAUDE.md ONLY, with an explicit Trinity-exempt note; AGENTS.md/GEMINI.md graph-first stays as-is. `backlog/BD-226.md` APPLICATION A addendum + SCOPE/CLI both state the addendum is PACK-OPS-only and Claude-only.
2. **It is documented on the surface.** The divergence is recorded IN the CLAUDE.md G1 surface (L665-669 Trinity-exempt sentence), so a future maintainer cannot mistake it for drift, and is recorded in the IMPL-REPORT divergence section (plan T-C4 step 5).
3. **It is provably tool-specific.** The CLAUDE.md "## Pack memory" sub-agent worktree-isolation model is Claude-Code-specific (only Claude runs worktree isolation per BD-226 SCOPE/CLI; Codex/Antigravity run serially, tracked for a future pack version per BD-217). Path-injection exists ONLY because gitignored `graphify-out/` is not materialized in an isolated worktree — a Claude-only condition. This is exactly the trinity rule's "provably tool-specific" exemption.
4. **The check layer agrees it is not a structural break.** Check 18 (H2 names/order) and Check 45 (slug bijection) are body-agnostic and stay green; the divergence lives in body prose under an existing H2 with no `[rationale:]` slug churn. The 4 self-derivation refs in AGENTS.md (2) and GEMINI.md (2) are byte-unchanged from HEAD (D6) — the divergence is a one-sided CLAUDE.md addition, not a desync introduced by editing one trinity copy and not the others.

**Conclusion:** the CLAUDE-only graph-first divergence is the intentional, documented, provably-tool-specific F-1 exemption — NOT an accidental parity break.

---

## EMPIRICAL-EVIDENCE BLOCKS (re-measured in the worktree; HEAD cf3527e; 2026-06-19)

**EB-1 — C4 scope is EXACTLY the 3 CLAUDE-only files; AGENTS/GEMINI/RATIONALE untouched.**
- Command: `git diff --name-only`; `git diff HEAD -- AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md | wc -l`.
- Output: diff = `CLAUDE.md` / `pack-ops/PACK-AGENTS.md` / `pack-ops/PACK-CHAT.md`; the 3-file HEAD-diff = `0`.
- Interpretation: F-1 Option A scope held exactly; no trinity-sibling or RATIONALE edit.
- Conclusion: **SUPPORTED**.

**EB-2 — Constraint 2: derivation formula present, no machine literal.**
- Command: `grep -rnE "/Users/|/home/|/private/|/Developer/" CLAUDE.md pack-ops/PACK-CHAT.md pack-ops/PACK-AGENTS.md` (exit 1, 0 matches); `grep -c '\$(git rev-parse' CLAUDE.md` = 4.
- Output: 0 machine literals; derivation formula `$(git rev-parse --show-toplevel)/graphify-out/graph.json` is the surface form (CLAUDE.md L254, L653; PACK-CHAT L291; PACK-AGENTS L67).
- Interpretation: the surface carries the formula + injection contract, not a baked path.
- Conclusion: **SUPPORTED**.

**EB-3 — F-8 degradation wording present.**
- Command: `grep -nE "injects the literal ONLY when|no graph available|existence check against the INJECTED path" CLAUDE.md`.
- Output: L659, L662, L663 (3 hits).
- Interpretation: inject-only-when-exists + no-graph token + existence-check-on-injected-path all present; G2 fallback explicitly "unchanged".
- Conclusion: **SUPPORTED**.

**EB-4 — F-P5-b rationale tag preserved verbatim.**
- Command: `grep -c "\[roles: universal\] \[rationale: graph-first-context\]" CLAUDE.md`.
- Output: `1` (L684).
- Interpretation: bijection anchor intact; Check 45 cannot orphan `## graph-first-context`.
- Conclusion: **SUPPORTED**.

**EB-5 — AGENTS/GEMINI graph-first self-derivation unchanged (intentional divergence).**
- Command: `grep -c "show-toplevel.*graphify-out\|graphify-out/graph.json" AGENTS.md GEMINI.md`; `grep -c "## graph-first-context" pack-ops/PACK-MEMORY-RATIONALE.md`.
- Output: AGENTS.md=2, GEMINI.md=2, RATIONALE section=1.
- Interpretation: the siblings keep self-derivation by design; RATIONALE section present, untouched.
- Conclusion: **SUPPORTED**.

**EB-6 — validate-pack exit 0; Check 18/45/36/63 green; 62 checks ran.**
- Command: `python3 scripts/validate-pack.py` (exit 0); grep for Check 18/45/36/63/59 in the log.
- Output: `PASSED — all checks clean`; Check 18 pack-root H2 match (5 sections) + GEMINI +1 intrinsic; Check 45 23↔23 no orphans; Check 36 1 scope-claiming clean; Check 63 0 tracked; Check 59 62 entries, full run executes every check.
- Interpretation: CI parity holds; the body-level CLAUDE-only divergence does not break trinity/bijection checks (body-agnostic).
- Conclusion: **SUPPORTED**.

**EB-7 — C4 working diff is pack-only; anchors correct.**
- Command: `git diff --name-only | grep -E '^project-template/|^supporting-docs/'` (none); anchor greps for "Name the handoff dir"/"Pack agent invocation"/"Sub-agent invocation".
- Output: zero project/supporting paths; G4 after "Pack agent invocation" (L244→L249), G2 after "Name the handoff dir" (L280→L288), G3 in "Sub-agent invocation" (L48→L62) before "Separate terminal session" (L73).
- Interpretation: pack-only scope clean; inject notes added near the design-named anchors.
- Conclusion: **SUPPORTED**.

---

## BOTTOM LINE: **CLEAN — C4 is review-clean and ready to commit.**

C4 implements the BD-226 APPLICATION A graph-path-injection addendum exactly per the FINAL design and plan: Constraint 2 (orchestrator-derives-and-injects; derivation formula, no baked literal), F-8 graceful degradation (inject-only-when-exists; existence check on injected path; G2 fallback + budgets + `--backend claude-cli` kept), F-1 CLAUDE-only scope with an explicit on-surface Trinity-exempt note, F-P5-b rationale-tag preservation (Check 45 bijection 23↔23 intact), and G4/G2/G3 ADDs at the correct anchors. The CLAUDE-only graph-first divergence is hand-verified as the intentional, documented, provably-tool-specific F-1 exemption — not an accidental trinity-parity break. validate-pack exits 0 in the worktree with Checks 18/45/36/63 green. No findings of any severity.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule name | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | Ran read-only git verbs only: `git rev-parse HEAD/--show-toplevel/--abbrev-ref`, `git status --short`, `git diff`, `git diff --name-only`, `git diff HEAD -- ...`, `git log --oneline`. No add/commit/apply/stage/checkout/restore/branch/worktree. Sole write = this review at `/tmp/handoff-bd226-C4/REVIEW.md` (caller-specified, under `/tmp`). No repo state changed. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op attempted or run; nothing required surfacing. | COMPLIANT |
| `graph-first-context` | This is exact-string + uncommitted-file verification → used grep/Read (the rule's own fall-through for exact-string/SSOT/freshly-changed cases). `graphify-out/` is not materialized in this worktree (the injected-path condition the work itself describes), so fell back to grep/Read per G2 — no graph query needed for any orientation question. | COMPLIANT |
| `preflight-stop-means-stop` | No parent stop/halt received; review completed and written to the named path. | COMPLIANT |
| `rules-applied-verification-block` | This table; every row carries a measurement/quote + terminal conclusion (no empty cells, no AMBIGUOUS). | COMPLIANT |
| `empirical-evidence-blocks` | EB-1..EB-7: each review state-claim (CLAUDE-only scope; AGENTS/GEMINI unchanged; Constraint-2 no-literal; F-8 present; F-1 note; rationale tag preserved; Check 18/45 green) has command + verbatim output + HEAD cf3527e + 2026-06-19 + interpretation + SUPPORTED. Re-measured in the worktree, NOT trusted from the IMPL-REPORT. | COMPLIANT |
| `ci-guard-measure-then-bound` | Re-ran the no-hardcoded-path gate over the 3 C4 files (incl. `/Developer/`) → 0 machine literals (exit 1); confirmed the derivation formula `$(git rev-parse --show-toplevel)/graphify-out/graph.json` is the surface form, not a resolved literal. | COMPLIANT |
| `worktree-isolation-mergeback-ops` | RO reviewer operating IN the commit's live worktree: cd in + VERIFIED pwd == toplevel == `/…/agent-a803913f1484fa733`, branch `worktree-agent-a803913f1484fa733`, HEAD `cf3527e3dbf47768186c13b6766dc9793e1b5ceb` (matches expected). Emitted NO patch (RO). Report → named `/tmp/handoff-bd226-C4/REVIEW.md`. | COMPLIANT |
| `pack-project-separation-of-concerns` | `git diff --name-only` = 3 pack-ops surfaces (CLAUDE.md pack-root trinity, PACK-CHAT.md, PACK-AGENTS.md); zero `project-template/`/`supporting-docs/` paths; the graph addendum adds NO content to any project surface (PACK-ONLY by design — Graphify never ships to clients). Check 36 will hold at commit (working diff confirmed pack-only). | COMPLIANT |
| `trinity-rule` | Hand-verified (see "Trinity-divergence hand-verification" section): the CLAUDE-only graph-first divergence is the intentional, documented, provably-tool-specific F-1 exemption (path-injection exists only because of Claude-only worktree isolation); AGENTS.md/GEMINI.md graph-first byte-unchanged from HEAD; Check 18/45 body-agnostic and green; NOT an accidental parity break. | COMPLIANT |
| `edit-in-place-not-full-rewrite` | C4 is targeted in-place edits (diff +57/−5 across 3 files per the diff; G1 reworded the two self-derivation sentences + inserted the path-injection/F-8/F-1 blocks; G2/G3/G4 are pure ADDs). Budgets (2000/1500/1000), `--backend claude-cli`/never-`claude`, the G2-fallback clause, and the `[rationale: graph-first-context]` tag all KEPT — no needless full rewrite. | COMPLIANT |

---

*End of FRESH pack-reviewer report for BD-226 COMMIT C4. Read-only; no patch emitted; no git state changed. Verdict: CLEAN.*
