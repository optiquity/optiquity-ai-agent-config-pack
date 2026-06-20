# ADVERSARIAL REVIEW — BD-240: Re-frame `graph-first-context` for genuine graph-first DISCOVERY/RECALL

**Reviewer:** FRESH independent `pack-architect` (READ-ONLY), empty-context adversary
**Repo:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Branch / HEAD at runtime (verified):** `v11-dev` / `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3`
**Placement:** MAIN checkout (work is on HEAD; clean tree confirmed — `git status --short` empty)
**Date:** 2026-06-20
**Design under review:** `/tmp/pack-handoff-bd240-arch/DESIGN-BD-240.md`
**Mandate:** adversarially challenge every state-claim + decision; re-measure independently; do not defer to the design's self-assessment.

---

## VERDICT: NEEDS-REWORK

**Findings: 1 BLOCKER, 3 MAJOR, 4 MINOR.**

The design's spine is sound — the phase-split diagnosis is correct, the bijection/anti-restate/parity green projection is well-measured, the BD-241 collision is real, and the measure-then-bound "no new CI check" conclusion is independently confirmed. **But the propagation surface census is INCOMPLETE in a way that re-opens the exact loophole BD-240 exists to close**, and the proposed re-framing text both (a) leaves a survivable agent rationalization and (b) introduces an unresolvable cross-reference into the trinity corpus. These must be fixed before the planner.

---

## What I independently CONFIRMED (re-measured, SUPPORTED)

| Design claim | My re-measurement | Verdict |
|---|---|---|
| HEAD = af73ffb | `git rev-parse HEAD` → `af73ffb5fd088b...` | CONFIRMED |
| Offending fall-through list byte-identical across trinity ×3 | `awk` extract of "Fall through…not in the graph" from CLAUDE/AGENTS/GEMINI — identical 5-line block | CONFIRMED |
| Per-CLI tails diverge by design (BD-226 injection on CLAUDE; non-injection on AGENTS/GEMINI) | Read CLAUDE.md L650-684 (injection + worktree caveat) vs AGENTS.md L568-584 / GEMINI.md L545-562 (non-injection `--graph` form) | CONFIRMED |
| `.spawn-rule-manifest.txt` does NOT track graph-first-context (EE-5 refutation) | `grep "^slug:"` → 7 records, none is graph-first; header L1-11 scopes it to the "6 former restatements collapsed by BD-196 C5" | CONFIRMED — refutation is correct |
| Check 46 anti-restate scans PACK-AGENTS.md + PACK-CHAT.md + 4 skills, ≥60-char body threshold | `validate-pack.py:7459-7484` `_CHECK_46_ANTI_RESTATE_SURFACES` + `_MIN_LEN = 60` | CONFIRMED |
| Bijection (Check 45) preserved: exactly one `## graph-first-context` rationale + one `[rationale: graph-first-context]` per trinity | `grep -n "^## graph-first-context"` → 1; `grep -c "rationale: graph-first-context"` → 1/1/1 | CONFIRMED |
| No per-run telemetry in validate-pack ⇒ mechanical "graph-queries-ran" check unbuildable + false-fires on no-graph clone | `grep` validate-pack for telemetry/handoff/queries-run → none; only Check 63 (graphify-out never-tracked) exists; graph is gitignored so not even a committed signal | CONFIRMED — measure-then-bound STRIP is correct |
| BD-241 HARD same-file collision (trinity ×3 + PACK-MEMORY-RATIONALE.md) | Read BD-241 Type + File/Symbol: trinity `## Pack memory` Claude-only sub-section + new rationale slug | CONFIRMED |
| docs-researcher carries `Bash` (can query) — no frontmatter change needed | `pack-docs-researcher.md` L4 `tools: Read, Grep, Glob, WebSearch, Bash` | CONFIRMED |
| No product-side (project-template/ supporting-docs/) graph-first refs — scope is correctly pack-ops-only | `grep -rln graph-first project-template/ supporting-docs/` → empty | CONFIRMED |
| No test/fixture/validator hardcodes the fall-through text (no extra encoding surface) | `grep` test-fixtures/ tests/ scripts/ for fall-through text → none | CONFIRMED |

The design did real measurement here; these are not in dispute. The problems are in what it did NOT measure.

---

## FINDINGS

### BLOCKER

#### B-1 — MISSED PROPAGATION SURFACE that re-opens the loophole: `OPTIONAL-FEATURES.md` "When to skip Graphify" (L565-573) restates the exact escape-hatch framing BD-240 closes.

**Location:** `pack-ops/OPTIONAL-FEATURES.md` L565-573 (`**When to skip Graphify.**`).
**Design's claim (§3.6 + Coder checklist step 5):** "pack-ops/OPTIONAL-FEATURES.md §'Graphify' (L354-376) — NO TEXT EDIT NEEDED … the by-name pointer stays accurate … coder VERIFIES the sentence still reads true."

**My measurement (HEAD af73ffb):** the design examined ONLY L354-376 (the high-level "WHEN to prefer the graph and when to fall through" pointer — which IS still accurate). It did not measure the SECOND graph block in the same file. `grep -n -i "fall through\|skip Graphify" pack-ops/OPTIONAL-FEATURES.md` surfaces L565-573:
```
565 **When to skip Graphify.**
566 - You are doing a one-off task and do not want to run the one-time build.
567 - The task is an exact-string / token search, an authoritative SSOT-field read
568   (a BD `Status`, the README version table, a `_rules.md` contract), a
569   freshly-changed / uncommitted file, or whole-file verbatim content — those
570   fall through to grep / Read / `git diff` per the graph-first rule's
571   exceptions, not the graph.
```

**Why this is a BLOCKER, not a nit:** L567-571 reproduces the SAME conflation the trinity phase-split is designed to neutralize — it presents "exact-string / token search" and "whole-file verbatim content" as reasons to **SKIP Graphify entirely** ("not the graph"), framed as the rule's "exceptions." After BD-240 re-scopes those two clauses to be VERIFICATION-phase-only fall-throughs (P2), this runbook section becomes **actively contradictory**: it tells a reader those clauses license skipping the graph (the precise BD-206 rationalization), while the re-framed trinity rule says they do not license skipping discovery. A docs-researcher reading OPTIONAL-FEATURES.md "When to skip Graphify" would re-derive the exact defect BD-240 fixed. Leaving it unedited ships a self-contradicting SSOT and defeats the BD's acceptance criterion ("the fall-throughs no longer swallow recall-critical enumeration"). The design's §1 EE-4 census + Empirical-Evidence discipline missed an in-scope live surface in a file it already enumerated.

**Concrete fix:** add `OPTIONAL-FEATURES.md` L565-573 as an EDIT surface (not a verify-only). Re-scope the "When to skip Graphify" list to the phase model: the exact-string/SSOT-value/uncommitted/whole-file-verbatim items are VERIFICATION/precision or out-of-graph reads, NOT a license to skip graph-first DISCOVERY when the graph exists. Keep "one-off task, did not build the graph" and "fresh clone, no graph" (those are legitimate no-graph cases, G1). This must land in the SAME commit as the trinity edit (a half-applied state where trinity says P1-mandatory but OPTIONAL-FEATURES says "skip for exact-string" is exactly the incoherence the propagation procedure's atomic-commit rule forbids).

---

### MAJOR

#### M-1 — The proposed §2.3 re-framing leaves a SURVIVABLE rationalization (TARGET 1 not closed): the "completeness census" fall-through swallows recall, and BD-206 is precisely a census task.

**Location:** DESIGN §2.3, the proposed shared-core text, final fall-through item: *"a completeness census that REQUIRES literal-occurrence enumeration (e.g. a rename grep-zero gate per `rename-plans-measure-then-bound`) — which RUNS the grep but does NOT replace the graph-first discovery that scoped it."*

**The counterexample I constructed (and it holds):** BD-206 — the very task whose failed recall motivated BD-240 — is, by its own entry, a literal-occurrence census ("apply the no-monolithic-mirror STANDARD … find every surface that mentions the mirror"; the entry even cites `RESEARCH-ORDER-MD-RENAME-CENSUS.md = 56 refs / 14 files`). Under the proposed wording, a docs-researcher can rationalize: *"My whole task is a completeness census requiring literal-occurrence enumeration of pattern X. The rule lists that as a grep fall-through. The 'does NOT replace the graph-first discovery that scoped it' qualifier is satisfied — the pattern is already known, so 'scoping discovery' is trivial/empty, and the census IS the work."* The qualifier is too weak to stop this: it asserts discovery must precede the census but lets the agent declare discovery vacuous when the search pattern feels obvious. That is the identical move that produced zero graph queries on BD-206. **The loophole survives the proposed text.**

**Why it matters:** the directly-invoked agent (`claude --agent pack-docs-researcher`) reads ONLY the trinity rule + its agent def — the spawn-prompt DIRECT layer (§4.2) does not reach it. So the trinity text alone must be airtight for the census case, and it is not.

**Concrete fix:** tighten the census clause so it cannot be read as a discovery substitute. Two viable mechanics for the reconciliation architect to choose between (surface both, let the user pick):
  (a) Re-bind the census to the OUTPUT of discovery: "a literal-occurrence census is a VERIFICATION/completeness gate that runs AFTER graph-first discovery has established the candidate surface set — it widens to grep-zero on the surfaces discovery named; it is NEVER the discovery itself. When the graph exists, an enumeration task still runs the graph FIRST to find candidate surfaces, THEN greps each for the grep-zero gate." (b) Add an explicit anti-rationalization sentence: "'My task is exhaustive enumeration so I will grep the whole tree' is the prohibited move — the graph exists precisely to widen enumeration beyond your a-priori pattern; run it first." Whichever is chosen, the planner must verify a fresh agent cannot re-derive the BD-206 skip from the final text.

#### M-2 — MISSED same-file collision in the rule-10 map: BD-238 also edits trinity `## Pack memory` (+ likely PACK-MEMORY-RATIONALE.md) and is OPEN.

**Location:** DESIGN §7 ("No other open BD in the measured set edits these files concurrently") and the Rules-Applied row 7.
**Design's claim:** the only same-file collision is BD-241.

**My measurement:** `grep "Status: Open" backlog/BD-2*.md` → 14 open BDs. Reading each Type line: **BD-238** ("process / agent-development-lifecycle codification (PACK-SIDE) … Architect-first (it touches rules + operating docs + trinity)") explicitly edits trinity `## Pack memory` and, as a rule codification, almost certainly adds a PACK-MEMORY-RATIONALE.md slug. That is the SAME two-file class as the BD-241 collision the design flagged. The design measured the collision set as {BD-241} only; it did not enumerate the open-BD set for trinity-touching entries. BD-239 (project-side companion) touches project trinity, not pack trinity — no collision; BD-232 is out-of-repo memory — no collision; BD-222/BD-236 touch validate-pack / project-side guards — no pack-trinity collision. So the missed entry is specifically **BD-238**.

**Why it matters (MAJOR not MINOR):** the rule-10 map's whole purpose is to let Pack Chat schedule parallel-vs-serial waves without hand-merging concurrent trinity patches (the conflict the worktree-isolation protocol forbids). An incomplete map that omits a trinity-touching open BD invites exactly the concurrent-trinity-patch hand-merge it is meant to prevent. The Rules-Applied row 7 claims the map is complete; the empirical-evidence-blocks rule requires the state-claim "no other open BD edits these files" be backed by the open-BD census — which was not run.

**Concrete fix:** extend §7 to flag BD-238 as a HARD same-file serialization risk (trinity ×3 + PACK-MEMORY-RATIONALE.md), alongside BD-241. State the rule: any open BD whose Type names "trinity" or a new `## Pack memory` rule serializes with BD-240 on those files. Add the open-BD census as the Empirical-Evidence backing for the "no other concurrent editor" claim.

#### M-3 — The proposed trinity rule body introduces an UNRESOLVABLE cross-reference: `rename-plans-measure-then-bound` is a memory-cache-only slug, NOT a trinity/rationale rule.

**Location:** DESIGN §2.3 proposed shared-core text: *"(e.g. a rename grep-zero gate per `rename-plans-measure-then-bound`)"* — this slug would be written into CLAUDE.md / AGENTS.md / GEMINI.md.

**My measurement:** `grep -rn "rename-plans-measure-then-bound\|Rename plans" CLAUDE.md AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md` → **zero hits in the corpus**. The only occurrence anywhere in the repo's live surfaces is NONE; the slug exists solely in the out-of-repo memory cache (`~/.claude/projects/.../memory/MEMORY.md:37` "Rename plans = measure-then-bound"). The trinity is the SSOT and the memory cache is a derived, "trinity-wins" view. Citing a memory-only slug from INSIDE the trinity rule body creates a dangling reference: an agent (or reviewer) reading the trinity rule cannot resolve `rename-plans-measure-then-bound` in the corpus or PACK-MEMORY-RATIONALE.md.

**Why it matters:** the design's own `filename-uniqueness-heuristic` / SSOT-hygiene posture, and the trinity-as-SSOT principle, are violated by a corpus rule pointing at a non-corpus slug. It is also a latent reviewer trip: a thorough reviewer resolving cross-references would flag a broken pointer. (Note: the design also cites `external-rules-census` in §2.2's Option-B-rejection PROSE — that one is harmless because it stays in the design doc, not the rule body. Only the §2.3 in-rule citation is the defect.)

**Concrete fix:** in the §2.3 rule body, replace the slug citation with a PLAIN-LANGUAGE description that needs no cross-reference — e.g. "(e.g. a rename completeness gate that must grep-zero every literal occurrence)". Do NOT introduce a corpus reference to a slug that does not exist in the corpus. (If the user wants the rename rule promoted to a real trinity rule, that is a SEPARATE BD, not in-scope here.)

---

### MINOR

#### m-1 — `PACK-AGENTS.md` graph-injection bullet (L62-71) is an unenumerated reference surface; the design's DIRECT-use edit (§3.4) lands only in PACK-CHAT.md, diverging two parallel surfaces.

**Location:** `pack-ops/PACK-AGENTS.md` L62-71 ("**Inject the graph path into every spawn prompt (BD-226, Claude-only).**") vs the design's §3.4 PACK-CHAT.md edit. The design's EE-4 listed PACK-CHAT.md's injection bullet but NOT PACK-AGENTS.md's parallel one. The propagation procedure (PACK-CHAT.md L499-504, step 4) explicitly names **both** "`PACK-AGENTS.md` / `PACK-CHAT.md` one-line refs" as reference surfaces. Both bullets are byte-parallel BD-226 injection guidance ending "See trinity `## Pack memory` § 'Graph-first context (BD-225)'". The design adds DIRECT-use direction to PACK-CHAT.md only; it never considers PACK-AGENTS.md. Result: two orchestrator-guidance surfaces diverge (one directs graph use for recall-heavy spawns, one does not).
**Fix:** the design must explicitly DECIDE PACK-AGENTS.md's bullet — either make the parallel DIRECT-use edit (subject to the same Check 46 ≥60-char anti-restate bound, since PACK-AGENTS.md IS scanned), OR justify a no-edit (e.g., "PACK-CHAT.md is the authoritative spawn-construction surface; PACK-AGENTS.md is the routing-table pointer"). Silent omission is not a decision.

#### m-2 — Fall-through item count is stated as 6; the actual list has 5 items.

**Location:** DESIGN §2.1 ("a flat 'Fall through to grep/Read for: [6 items]'") and the brief's "original 6 fall-throughs."
**My measurement:** the list has exactly 5 semicolon-delimited items: (1) exact-string/token search, (2) authoritative SSOT fields, (3) freshly-changed/uncommitted files, (4) whole-file exact content, (5) archive-dir/excluded-category content. Not 6.
**Why it matters (MINOR):** an off-by-one in the count of the very list being re-scoped is an accuracy defect under empirical-evidence-blocks (the count is a state-claim). It does not change the design's logic but the planner/coder must re-scope all 5 (not enumerate a phantom 6th).
**Fix:** correct the count to 5 throughout; ensure each of the 5 is explicitly assigned to P2/out-of-graph in the re-framed text.

#### m-3 — The "graph used for discovery" Rules-Applied row in the design (row 6) overstates dogfooding precision.

**Location:** DESIGN §10 row 6: "Ran `graphify query` … returned 28 nodes."
**My measurement:** my own `graphify query "graph-first-context"` returned **25 nodes** (and a separate query returned 10). The exact count is immaterial to the design, but the design reports a specific figure ("28 nodes") as evidence. Under empirical-evidence-blocks, quoted measurements should be reproducible; mine differ. Likely the design ran a different query string/budget. MINOR — flagged for evidentiary hygiene, not a logic defect.
**Fix:** none required for correctness; if the design is revised, quote the exact query string used so the node count is reproducible.

#### m-4 — `cross-cli-reference-normalization` interaction with the §2.3 byte-identical mandate is unaddressed.

**Location:** DESIGN §2.3 ("The text is IDENTICAL across all three files") vs the `cross-cli-reference-normalization` rule (CLAUDE.md `## Pack memory`; rationale L570) which requires per-CLI-path/command references in trinity be substituted to the audience-correct canonical value, NOT byte-copied.
**My measurement:** the §2.3 proposed text contains NO per-CLI path or command token (it references `graphify query`/`path`/`affected`, generic across CLIs, and the rule slug `rename-plans-measure-then-bound` which M-3 removes). So byte-identical is actually CORRECT here (no CLI-specific token to normalize). But the design asserts byte-identical without noting WHY normalization does not apply — a thorough reviewer/coder following the normalization rule might wrongly "normalize" something.
**Fix:** add one sentence to §2.3/§2.5 noting the shared-core text contains no per-CLI path/command tokens, so `cross-cli-reference-normalization` is N/A for it and byte-identical is the correct parity target (the per-CLI divergence stays confined to the untouched tails).

---

## Adversarial-target scorecard

| # | Target | Result |
|---|---|---|
| 1 | Does the phase-split actually close the loophole? | **NO** — M-1: the "completeness census" fall-through is a survivable rationalization, and BD-206 is a census task. Loophole survives. |
| 2 | Is every re-scoped fall-through airtight? | **Partially** — 4 of 5 are cleanly P2/out-of-graph; the census item (M-1) and the dangling slug (M-3) are defects; OPTIONAL-FEATURES's parallel list (B-1) is unaddressed. |
| 3 | DIRECT=YES / Attest-wording-NO-CIcheck correct? | **YES (correct)** — no per-run telemetry exists; mechanical check unbuildable + false-fires on no-graph clone (CONFIRMED). Role-def placement over a trinity role tag is the right call (keeps universal rule universal). Caveat: role-def covers only directly-invoked docs-researcher; other directly-invoked RO roles rely on the trinity text alone — which makes M-1's airtightness load-bearing. |
| 4 | Propagation completeness — is it really 6 surfaces? | **NO** — B-1 (OPTIONAL-FEATURES skip-list) and m-1 (PACK-AGENTS.md bullet) are missed; the `.spawn-rule-manifest.txt` and OPTIONAL-FEATURES-L354-376 refutations are CORRECT. True live edit-surface set is larger than the design's 6. |
| 5 | Trinity parity + Claude-only caveat preserved? | **YES with one defect** — parity model is correct, BD-226 tail preserved, no injection-port; but M-3 (dangling slug) would land identically in all 3 (parity-preserving but referentially broken), and m-4 (normalization N/A note) should be stated. |
| 6 | validate-pack green? | **YES** — Check 45 bijection, Check 46 anti-restate (≥60-char) + reference-resolution, trinity parity, Check 63, manifest (push-time) all stay green under the measured logic. The PACK-CHAT/PACK-AGENTS edits must remain paraphrase+name-pointer (no ≥60-char body copy) — coder PREFLIGHT must grep-confirm. No check at risk. |
| 7 | Rule-10 collision claim correct? | **Partially** — BD-241 collision CONFIRMED; but M-2: BD-238 (trinity-touching, open) is a missed same-file collision. |

---

## Required reconciliation before planner (ordered)

1. **B-1** — add OPTIONAL-FEATURES.md L565-573 "When to skip Graphify" as an EDIT surface; re-scope its escape-hatch list to the phase model; land in the same atomic commit.
2. **M-1** — tighten the §2.3 census fall-through so an exhaustive-enumeration task cannot be claimed as discovery; verify against the BD-206 counterexample.
3. **M-2** — add BD-238 to the §7 serialization map; back the "no other concurrent editor" claim with the open-BD census.
4. **M-3** — remove the `rename-plans-measure-then-bound` slug citation from the §2.3 rule body; use plain-language phrasing.
5. **m-1** — decide PACK-AGENTS.md's parallel injection bullet (edit-for-parity or justified no-edit).
6. **m-2 / m-3 / m-4** — correct the item count (5 not 6); reproducible-query hygiene; add the normalization-N/A note.

The design is well-structured and most of its measurement is sound; these are surgical fixes, not a redesign. After B-1 + M-1 + M-2 + M-3 are reconciled (and m-1 decided), the design is plan-ready.


---

## Rules-Applied Verification Block

| # | Rule (as named in CLAUDE.md `## Pack memory` / brief) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | empirical-evidence-blocks [architect] | Every finding carries the command + verbatim output + HEAD `af73ffb` + interpretation + conclusion: B-1 (`grep -n "skip Graphify" OPTIONAL-FEATURES.md` → L565-573 quoted verbatim, SUPPORTED missed-surface); M-2 (`grep "Status: Open" backlog/BD-2*.md` → 14 BDs, BD-238 Type "touches … trinity" quoted, SUPPORTED missed-collision); M-3 (`grep -rn "rename-plans-measure-then-bound" CLAUDE.md … PACK-MEMORY-RATIONALE.md` → 0 corpus hits, SUPPORTED dangling-ref); m-2 (`awk`/`nl` list extract → 5 items, NOT-SUPPORTED design's "6"). Confirmations table re-measured each design state-claim. | COMPLIANT |
| 2 | adversarial-architect-review (mandate) | Did not rubber-stamp: constructed the BD-206-census counterexample defeating §2.3 (M-1); re-ran the full surface census independently and found 2 missed surfaces the design declared complete (B-1, m-1); re-ran the open-BD collision census and found BD-238 (M-2); challenged the in-rule slug citation (M-3). Default-skepticism applied; confirmations are explicitly separated from challenges. | COMPLIANT |
| 3 | ci-guard-design-measure-then-bound [architect] | Contested the attest decision by measuring the tree: `grep` validate-pack.py for telemetry/handoff/queries-run → none; only Check 63 exists; graph is gitignored (not a committed signal). Concluded the design's STRIP (no new CI check) is CORRECT — backed by measurement, not assertion. | COMPLIANT |
| 4 | graph-first-context (dogfooded for discovery) | Ran graph FIRST for surface re-discovery: `graphify query "graph-first-context rule discovery recall fall-through grep Read propagation surfaces docs-researcher spawn-prompt" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` → 10 nodes (BD-185 researcher-prompt cluster); `graphify query "graph-first-context"` → 25 nodes (PACK-MEMORY-RATIONALE slug cluster). THEN grep/Read to VERIFY exact text/counts (EE-style) — discovery-then-verify, the very split under review. G1 (graph present at injected path, 19MB) satisfied; G2 not needed. | COMPLIANT |
| 5 | verify-availability-not-just-existence | Verified each capability against the actual file/CLI: docs-researcher `Bash` present (read L4); Check 46 surfaces + 60-char bound (read validate-pack.py L7459-7484); Check 45 bijection counts (grep, 1/1/1); manifest 7 records (read .spawn-rule-manifest.txt header + slugs). Quoted evidence throughout, not training-data inference. | COMPLIANT |
| 6 | separate-pack-ops-from-product | Verified BD-240 scope is pack-ops-only: `grep -rln graph-first project-template/ supporting-docs/` → empty; AGENT_KICKOFF_TEMPLATE.md graph count → 0. All flagged surfaces (trinity, pack-ops/*, .claude/agents/*) are pack-ops. No product file implicated. | COMPLIANT |
| 7 | agents-never-commit / per-action-approval-sub-agents | Commands run were read-only: `git rev-parse`/`branch`/`status --short` (RO), `grep`/`find`/`wc`/`awk`/`sed -n`/`nl`, `graphify query` (RO), `Read`, one `mkdir -p /tmp/...`, two heredoc writes to the `/tmp` report. No state-changing git verb; no destructive op; sole filesystem write = this review at the caller-specified `/tmp` path. | COMPLIANT |
| 8 | rules-applied-verification-block | This block present; one row per rule-in-force with quoted evidence + terminal conclusion (no AMBIGUOUS); includes the graph-query-ran row (rule 4) proving dogfooding. | COMPLIANT |

---
*End of ADVERSARIAL-REVIEW-BD-240.md — verdict: NEEDS-REWORK (1 BLOCKER, 3 MAJOR, 4 MINOR).*
