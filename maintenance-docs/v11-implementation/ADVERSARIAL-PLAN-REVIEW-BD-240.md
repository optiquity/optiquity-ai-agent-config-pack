# ADVERSARIAL PLAN REVIEW — BD-240

**Reviewer:** FRESH, INDEPENDENT `pack-planner` (READ-ONLY), empty-context adversarial pass.
**Repo / branch / HEAD (verified at runtime):** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` / `v11-dev` / `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3`.
**Placement:** MAIN checkout (work on HEAD; `git status --short` clean except two untracked v11-impl planning docs — unrelated to BD-240 surfaces).
**Date:** 2026-06-20.
**Under review:** `/tmp/pack-handoff-bd240-plan/PLAN-BD-240.md`.
**Authoritative reference:** `/tmp/pack-handoff-bd240-arch/DESIGN-BD-240-RECONCILED.md` (M-1 resolved as (c) BOTH). I did NOT read the design-stage adversarial review.
**Baseline:** `python3 scripts/validate-pack.py` at HEAD af73ffb → exit 0, "PASSED — all checks clean" (captured `/tmp/vp-baseline.txt`).

---

## VERDICT: NEEDS-REWORK

**1 BLOCKER · 1 MAJOR · 4 MINOR.**

The plan is structurally sound, the surface census is complete and matches the
design, the atomic-commit and rule-10 reasoning are correct, and the CI-green
projection lands on the right answer. BUT one edit-boundary defect on Surface 4
(PACK-MEMORY-RATIONALE.md) will, if executed literally, produce a grammatically
broken / double-clause SSOT rationale, and one of the anti-restate analyses
mis-models the actual Check 46 mechanism (it reaches the right GREEN verdict for
the wrong reason, which masks where the real safety margin is). Neither is a CI
hard-fail, but both are exactly the class of defect an adversarial pass exists to
catch BEFORE the planner-to-coder gate. Fix the BLOCKER + MAJOR; the MINORs are
cheap hardening.

---

## What I independently re-measured and CONFIRMED (no finding)

These load-bearing plan claims survived independent re-measurement:

- **Surface census (8 EDIT surfaces) — CONFIRMED COMPLETE.** All 8 anchors located
  by content at HEAD af73ffb; matches design EE-R8. No 9th surface carries the
  framing (`grep -rln "graph-first|graphify" project-template/ supporting-docs/`
  → exit 1, 0 hits — `pack-only` scope claim HOLDS).
- **Trinity byte-identity boundary — CONFIRMED EXACTLY.** The shared-core
  sentence (`Fall through to grep/Read for: … deliberately not in the graph).`)
  is byte-identical (whitespace-normalized) across CLAUDE.md L645-650 /
  AGENTS.md L563-568 / GEMINI.md L540-545 (verified extract+compare → identical).
  The openers DIFFER (CLAUDE "When a knowledge graph exists, prefer…" vs
  AGENTS/GEMINI "If `$(git rev-parse…)/graphify-out/graph.json` exists, prefer…").
  The tails DIFFER (CLAUDE has `Path-injection under worktree isolation` ×1 +
  `restore parity` ×1, both 0 in AGENTS/GEMINI; AGENTS/GEMINI have
  `The \`--graph\` path is ALWAYS absolute` ×1 each, 0 in CLAUDE). The plan's
  §3.0 byte-identity claim and "replace ONLY this sentence" instruction are
  CORRECT. PREFLIGHT gate 6 markers verified accurate.
- **Check 45 bijection — CONFIRMED GREEN.** Logic compares the `[rationale: <slug>]`
  set in CLAUDE.md `## Pack memory` vs `## <slug>` headings in
  PACK-MEMORY-RATIONALE.md (validate-pack.py L7312-7345); baseline 23↔23 equal.
  BD-240 adds/removes NO slug and NO heading → stays 23↔23. The
  `rename-plans-measure-then-bound` removal is from RULE BODY PROSE, not a
  `[rationale:]` slug, so bijection is undisturbed. `grep` of that slug across
  all 6 corpus/rationale/reference files → 0 hits (exit 1): it is genuinely
  absent and must NOT be introduced (M-3 / PREFLIGHT gate 2 correct).
- **Atomic single commit — CONFIRMED CORRECT.** A split that landed the trinity
  re-frame without OPTIONAL-FEATURES.md (skip-list) or PACK-MEMORY-RATIONALE.md
  (How-to-apply) re-scope would leave a live escape-hatch framing contradicting
  the re-framed corpus. No check hard-fails on the intermediate, but the
  coherence defect is real; the propagation procedure mandates same-commit. No
  reason to split. The 8-file path list is exact and excludes manifests/backlog.
- **rule-10 serialization — CONFIRMED COMPLETE.** BD-238 (Open) touches trinity
  `## Pack memory` + `[rationale:]` + PACK-MEMORY-RATIONALE.md + PACK-CHAT.md /
  PACK-AGENTS.md (BD-238 L27) → HARD collision on trinity ×3 + PMR + PACK-CHAT /
  PACK-AGENTS (the latter two BOTH BD-240-edited — additional collision the plan
  §6 captures). BD-241 (Open) touches trinity `## Pack memory` Claude-only
  sub-section + new slug (BD-241 L3/L12) → HARD collision on trinity ×3 + PMR.
  The plan states base-on-prior-landed-HEAD (`worktree.baseRef:"head"`) +
  never-hand-merge (§6, §7, R-4). Correct.
- **`.spawn-rule-manifest.txt` exclusion — CONFIRMED.** No graph-first-context
  record (grep exit 1); 7 records, all unrelated rules. Adding one would force a
  non-existent reference. Check 46 reference-resolution stays green BECAUSE the
  manifest is untouched. The plan's override of the BD-240 entry premise
  (entry L12/L18 "+ `.spawn-rule-manifest.txt`") is measure-then-bound-sound.
- **Check 18 / Check 44 — CONFIRMED.** The rule lives under `### Repo conventions`
  (H3, CLAUDE.md L529); the edit is inside an H3 bullet body → Check 18 (H2
  parity) unaffected. Check 44 OPTIONAL-FEATURES ceiling 271 is ADVISORY ("never
  fails", validate-pack.py L7796); baseline already WARNs at 573 lines and PASSES
  — the length-neutral re-scope keeps it advisory. Plan correct.
- **Dogfood (graph-first-context).** Ran `graphify query` against the injected
  graph FIRST (G1 satisfied); it returned a COARSE docs-researcher/BD-185 cluster
  (28 nodes, no exact rule surfaces), so per G2 I fell through to grep/Read for
  exact text/counts — discovery-then-verify, the split this BD designs.


---

## FINDINGS

### BLOCKER-1 — Surface 4 (PACK-MEMORY-RATIONALE.md) REPLACE-run produces a double-"When … exists" / orphaned clause

**Location:** PLAN §3.2 (Surface 4), the REPLACE-run instruction.

**Evidence (measured at HEAD af73ffb, PACK-MEMORY-RATIONALE.md L652-659):**
```
652 **How to apply.** When `$(git rev-parse --show-toplevel)/graphify-out/graph.json`
653 exists, query the graph FIRST for "what relates to X / where does Y live /
654 blast radius of Z" before broad tree reads; fall through to grep/Read for the
655 exceptions (exact-string/token search → grep; … whole-file exact content
658 → Read; archive-dir / excluded-category content → Read/grep, deliberately not
659 in the graph). If the graph is absent or a query fails or returns nothing …
```

The plan §3.2 says: *"Replace the run from `query the graph FIRST for "what relates
to X…` through `…deliberately not in the graph).`"* with replacement text whose
FIRST WORDS are *"When the graph exists, DISCOVERY/RECALL ('what relates to X …')
is graph-FIRST and mandatory: …"*.

**The defect:** the REPLACE-run as scoped LEAVES the L652 opener clause
`**How to apply.** When $(git rev-parse --show-toplevel)/graphify-out/graph.json
exists, ` intact (it begins BEFORE `query the graph FIRST`). The replacement text
then RE-OPENS with `When the graph exists, …`. Executed literally, the landed
SSOT reads:

> **How to apply.** When `$(git rev-parse …)/graphify-out/graph.json` exists,
> **When the graph exists, DISCOVERY/RECALL ('what relates to X …')** is graph-FIRST
> and mandatory: …

— a double-"When … exists, When the graph exists" stutter / orphaned dependent
clause. This corrupts the SSOT rationale prose. It does NOT trip a CI hard-fail
(PACK-MEMORY-RATIONALE.md is not anti-restate-scanned — verified absent from
`_CHECK_46_ANTI_RESTATE_SURFACES`, validate-pack.py L7459-7466 — and Check 45 keys
on the unchanged heading), so it would slip past validate-pack and ship a broken
rationale. The design §3.2 carried the same ambiguity ("Replace L653-659") without
reconciling the replacement's leading "When the graph exists"; the plan inherited
it. An adversarial pass must catch it before the coder bakes it in.

**Concrete fix (reconciliation planner picks one, state it explicitly):**
- **(a) preferred — extend the REPLACE-run leftward to the existing opener:**
  replace from L652 `When $(git rev-parse …)/graphify-out/graph.json exists,`
  through `…deliberately not in the graph).` with the §3.2 replacement text
  (which already self-supplies "When the graph exists, …"). Net: ONE "When …
  exists" clause, no stutter. Keep the literal `**How to apply.**` lead-in.
- **(b) alternative — drop the replacement's leading clause:** keep the L652
  `…exists,` opener and begin the replacement at `DISCOVERY/RECALL ('what relates
  to X …') is graph-FIRST and mandatory: query the graph …` (no second "When the
  graph exists,"). Dovetails into the preserved opener.
Either way the plan MUST give the coder an unambiguous start-anchor for the
replace so the two "When"-clauses do not coexist.

---

### MAJOR-1 — Anti-restate analysis (§3.4/§3.5, §5.1, PREFLIGHT gate 5) mis-models Check 46: it measures the wrong target text

**Location:** PLAN §3.4 + §3.5 ("ANTI-RESTATE CONSTRAINT … < 60 contiguous
verbatim chars of the trinity imperative BODY … the §2.2 body"), §5.1 Check 46
row ("< 60 contiguous verbatim chars of the trinity body"), PREFLIGHT gate 5
("does NOT contain a ≥60-char contiguous … substring of the §2.2 trinity body").

**Evidence (validate-pack.py L7521-7556, candidate extractor):** Check 46 does NOT
scan the appended sentence against "the §2.2 body." It extracts each `## Pack
memory` bullet's BODY (text AFTER the bold rule name), whitespace-normalizes, and
**truncates to the first 120 chars** (`normalized = re.sub(r"\s+"," ",body).strip()[:120]`),
keeping it iff ≥60 chars (L7553-7555). For the graph-first-context bullet the
candidate is therefore the FIRST 120 chars of the body — i.e. the per-CLI
**OPENER**, which BD-240 does NOT touch:

```
'When a knowledge graph exists, prefer the graph for orientation / relationship / blast-radius / "what relates to X" / "w'  (len 120)
```

The §2.2 two-phase replacement text sits DEEP in the bullet body (well past char
120) and is **never a Check 46 candidate at all.** So:
1. The plan's "< 60 chars of the §2.2 body" framing names a string Check 46 never
   examines. The real candidate is the unchanged opener.
2. The plan's GREEN verdict is nonetheless CORRECT — I simulated the actual check:
   the proposed PACK-CHAT/PACK-AGENTS append sentence contains ZERO 60-char window
   of the opener candidate (`candidate in append → False`; no 60-char window
   collides). Check 46 stays GREEN (baseline scans 49 candidate bodies, 0 hits).

**Why this is MAJOR not MINOR:** the plan reaches the right answer by reasoning
about the wrong text. The risk this masks: the coder, trusting the plan's model,
could append a sentence that paraphrases the §2.2 body freely (safe — never
scanned) yet accidentally reproduce ≥60 chars of the OPENER (e.g. "prefer the
graph for orientation / relationship / blast-radius / 'what relates to X'") — and
the plan's stated gate ("compare to §2.2 body") would pass it while the ACTUAL
Check 46 fails. The PREFLIGHT mitigant that SAVES this is gate 10 ("run
validate-pack.py Check 46 directly … PASS") — but gate 5's hand-check points at
the wrong string. Correct the model so the conceptual gate and the tool gate
agree.

**Concrete fix:** restate the anti-restate constraint in §3.4/§3.5/§5.1/gate 5 as:
"Check 46 scans the first-120-char whitespace-normalized OPENER of each `## Pack
memory` bullet (validate-pack.py `_check_46_extract_pack_memory_imperative_bodies`,
`[:120]`); for graph-first-context that opener is UNCHANGED by BD-240. The append
must not reproduce ≥60 contiguous chars of THAT opener
(`When a knowledge graph exists, prefer the graph for orientation / relationship /
blast-radius / "what relates to X" / "w`). Confirmed it does not; gate 10's direct
Check 46 run is the binding gate." Keep the empirical fallback (shorten to a pure
name pointer if it ever trips).

---

### MINOR-1 — PREFLIGHT gate 9 grep is malformed (matches the PRE-edit state; not a clean grep-zero/grep-confirm)

**Location:** PLAN §5.2 PREFLIGHT gate 9.

**Evidence:** the literal gate text is
`grep -c "skip Graphify … not the graph\|not the graph\." pack-ops/OPTIONAL-FEATURES.md`.
The `…` is a literal ellipsis char (won't match), and `not the graph\.` matches
the CURRENT escape-hatch bullet — run NOW at HEAD it returns `1` (exit 0),
matching `571:  exceptions, not the graph.` That is the text the edit REMOVES. So
the gate as written confirms the PRE-edit string, the opposite of its intent, and
provides no grep-zero teeth for the removed phrase. The prose intent ("confirm the
old escape-hatch bullet is gone and the new 'precision AFTER discovery, not a
reason to skip graph-first DISCOVERY' wording is present; one-off + fresh-clone
bullets remain") is correct and a coder can recover it — but the literal grep is a
defect in the measure-then-bound backstop for Surface 5.

**Concrete fix:** replace gate 9 with two clean checks:
`grep -c "exceptions, not the graph\." pack-ops/OPTIONAL-FEATURES.md` → EXPECT 0
(old escape-hatch phrasing GONE); and
`grep -c "precision AFTER discovery, not a reason to skip graph-first DISCOVERY" pack-ops/OPTIONAL-FEATURES.md`
→ EXPECT 1 (new wording present); plus
`grep -c "one-off task\|fresh clone with no graph" pack-ops/OPTIONAL-FEATURES.md`
→ EXPECT 2 (legitimate NO-GRAPH bullets retained).

---

### MINOR-2 — PACK-AGENTS.md injection target is a bold-headed PARAGRAPH, not a list bullet (terminology may mislead the append placement)

**Location:** PLAN §3.5 + §2 table row 7 ("graph-injection bullet").

**Evidence (PACK-AGENTS.md L62-71):** the injection guidance is a `**bold-lead.**`
PARAGRAPH (`**Inject the graph path into every spawn prompt (BD-226, Claude-only).**`
on its own line, prose continuing L63-71, ending `…for the full contract.` at
L71), NOT a `- ` list item. PACK-CHAT.md L295-305 IS a `- ` list bullet. The plan
calls both "bullet." The append target ("after 'for the full contract.'") is
unambiguous, so this is cosmetic — but a coder pattern-matching "bullet" might
hunt for a `- ` marker that isn't there, or mis-place the append at a list
boundary. Name the structure so the append lands at the end of the L62-71
paragraph body.

**Concrete fix:** in §3.5 say "the bold-headed PARAGRAPH at PACK-AGENTS.md L62-71
(NOT a `- ` list item, unlike PACK-CHAT.md); APPEND the sentence at the end of the
paragraph body, after `…for the full contract.`"

---

### MINOR-3 — The shared-core REPLACE target shares a PHYSICAL LINE with the per-CLI tail in CLAUDE.md (and with the tail in AGENTS/GEMINI) — call out the in-line boundary

**Location:** PLAN §3.1 (trinity REPLACE) + R-3.

**Evidence:** the sentence to replace ENDS mid-line, with the per-CLI tail
beginning on the SAME physical line:
- CLAUDE.md L650: `  deliberately not in the graph). **Path-injection under worktree isolation`
- AGENTS.md L568: `  deliberately not in the graph). The \`--graph\` path is ALWAYS absolute`
- GEMINI.md L545: `  deliberately not in the graph). The \`--graph\` path is ALWAYS absolute`

A line-oriented replace (e.g. an Edit keyed on the whole L645-650 block) risks
either truncating the tail's opening words or duplicating them. The plan's
"locate-by-content" + "replace ONLY this sentence" guidance is correct in spirit,
and PREFLIGHT gate 6 verifies the tail survived — but the in-line boundary
(`graph). ` is the literal split point, with the tail's first chars on the same
line) is a concrete coder trap worth naming so the coder edits at the
sentence-string boundary, not the line boundary.

**Concrete fix:** add to §3.1: "The replace boundary is the STRING
`deliberately not in the graph). ` — the per-CLI tail begins immediately after,
ON THE SAME LINE (CLAUDE: `**Path-injection…`; AGENTS/GEMINI: `The \`--graph\`
path is ALWAYS absolute`). Replace up to and including `not in the graph).` and
preserve everything from the following space onward verbatim."

---

### MINOR-4 — Line-number citations for Surface 4 drift slightly from measured (absorbed by content-anchoring; noted for accuracy)

**Location:** PLAN §3.2 ("citations measured L667-672"); §2.2 source claim.

**Evidence:** measured at HEAD af73ffb — `## graph-first-context` heading at
PACK-MEMORY-RATIONALE.md **L638** (plan implies near L652); the
`cross-cli-reference-normalization` / `bd-pack-only` citations at **L669 / L672**
(plan says L667-672). Drift is 1-2 lines and the plan EXPLICITLY anchors by
content ("locate by content, not line number"; §3 preamble), so this is
informational, not a correctness defect. Flagged only so the reconciliation
planner's measured-line annotations match the tree.

**Concrete fix (optional):** update the parenthetical line citations to L638
(heading) / L652 (How-to-apply) / L669-672 (citations). No behavioral change.

---

## Targeted answers to the 8 adversarial targets

1. **Surface fidelity** — 8 surfaces all correctly located and matched to the
   design; §2.2 two-phase text (M-1=(c) BOTH) is reproduced VERBATIM in plan §3.1
   vs design §2.2 (confirmed equal). DEFECT: Surface 4 replace-boundary
   (BLOCKER-1). All other surfaces faithful.
2. **Trinity byte-identity** — CORRECT. Only the shared-core sentence is
   byte-identical; openers + tails differ per-CLI and are correctly marked
   preserve-verbatim. No BD-226 injection-tail port risk in the spec (PREFLIGHT
   gate 6 guards it). MINOR-3 hardens the in-line boundary.
3. **Anti-restate (Check 46)** — GREEN, but the plan's MODEL is wrong (MAJOR-1):
   it measures against the §2.2 body; Check 46 actually scans the first-120-char
   OPENER. The append is safe against the real candidate (simulated: 0 collision).
   Gate 10's direct Check 46 run is the binding safety net.
4. **Bijection (Check 45)** — GREEN. 23↔23 unchanged; no slug/heading touched;
   `rename-plans-measure-then-bound` removal is body-prose, not a slug. Confirmed.
5. **Atomic commit** — CORRECT. Single commit required; no reason to split; 8-file
   path list exact. Confirmed.
6. **rule-10** — COMPLETE. BD-238 + BD-241 both serialize on trinity ×3 + PMR (+
   PACK-CHAT/PACK-AGENTS for BD-238); base-on-prior-landed-HEAD + never-hand-merge
   stated. Confirmed.
7. **PREFLIGHT gates** — mostly sufficient (gates 1-8, 10 sound). Gate 5 points at
   the wrong target text (MAJOR-1). Gate 9 grep malformed (MINOR-1). With those
   two corrected, the gate set catches every failure mode.
8. **Green-after-execute** — YES, the plan will pass the FULL validate-pack
   (baseline exit 0; Checks 18/44/45/46/62/63/36 all unaffected or GREEN as
   analyzed). No check is at unaddressed risk. The BLOCKER-1 prose defect is
   NOT CI-caught — which is precisely why it must be fixed at the plan gate.

---

## Required actions before planner-to-coder gate

- **BLOCKER-1:** fix the Surface 4 REPLACE-run boundary so no double-"When …
  exists" clause results (extend the run leftward, or drop the replacement's
  leading clause — state which).
- **MAJOR-1:** correct the anti-restate model in §3.4/§3.5/§5.1/gate 5 to scan
  against the first-120-char OPENER (the actual Check 46 candidate), keeping gate
  10's direct Check 46 run as binding.
- **MINOR-1:** repair PREFLIGHT gate 9 to a clean grep-zero (old phrase gone) +
  grep-confirm (new phrase present) pair.
- **MINOR-2:** name PACK-AGENTS.md L62-71 as a bold-headed paragraph (not a list
  bullet) for unambiguous append placement.
- **MINOR-3:** name the in-line sentence/tail boundary in §3.1.
- **MINOR-4 (optional):** refresh the Surface 4 line citations (L638/L652/L669-672).

Once BLOCKER-1 + MAJOR-1 are reconciled (the MINORs are cheap and advisable), the
plan is coder-executable.

---

## Rules-Applied Verification Block

| Rule (Rules-in-force) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| empirical-evidence-blocks [planner] | Every finding backed by a command + verbatim output at HEAD `af73ffb` (verified `git rev-parse HEAD` → `af73ffb5…`): trinity shared-core extract+compare → byte-identical; Check 46 extractor `[:120]` truncation read at validate-pack.py L7553; opener candidate computed via python (`len 120`, append-collision simulation → False); Check 45 23↔23 from baseline run; PMR L652-659 + OPTIONAL L565-573 + PACK-AGENTS L62-71 + PACK-CHAT L295-305 read directly; BD-238 L27 / BD-241 L3/L12 quoted; product-clean grep exit 1; spawn-manifest graph-first grep exit 1; full validate-pack exit 0. | COMPLIANT |
| adversarial-planner-review (mandate) | Challenged, did not confirm: constructed the double-"When" counterexample (BLOCKER-1) by mentally executing the literal replace; re-measured the Check 46 mechanism against source and found the plan's model targets the wrong string (MAJOR-1) despite a correct verdict; re-ran the live anti-restate simulation rather than trusting the plan's assertion. Did NOT read the design-stage adversarial review. | COMPLIANT |
| ci-guard-design-measure-then-bound | Measured the actual Check 46 candidate (first-120 opener, not §2.2 body), Check 45 set (23↔23), Check 44 advisory (L7796), Check 18 H3-home (L529) BEFORE concluding green; bounded each verdict to the measured logic, not the plan's prose claim. | COMPLIANT |
| rename-plans-measure-then-bound / measure-then-bound | Verified plan anchors every edit on content strings + grep-zero gates (gate 2 slug-zero confirmed exit 1; gate 1 parity diff; gate 6 tail preservation); flagged gate 9's malformed grep (MINOR-1) as a measure-then-bound gap. | COMPLIANT |
| graph-first-context (dogfooded) | Ran `graphify query "graph-first-context rule propagation surfaces …" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` FIRST → "BFS depth=2 | 28 nodes found" (coarse docs-researcher/BD-185 cluster). G1 satisfied (graph present at injected path); G2 → fell through to grep/Read for exact text/counts. | COMPLIANT |
| separate-pack-ops-from-product | `grep -rln "graph-first|graphify" project-template/ supporting-docs/` → exit 1 (0 hits). All 8 edit surfaces are pack-ops; `pack-only` scope claim holds. No product file implicated. | COMPLIANT |
| agents-never-commit / per-action-approval-sub-agents | Commands run: `git rev-parse`/`status --short`/`branch` (RO), `grep`/`sed`/`awk`/`wc`/`find`, `python3` (RO sims + the read-only baseline validate-pack), `graphify query` (RO), Read, one `mkdir -p /tmp/...`, heredoc appends to the `/tmp` review doc. No state-changing git verb; no destructive op; sole filesystem write = this review at `/tmp/pack-handoff-bd240-plan/ADVERSARIAL-PLAN-REVIEW-BD-240.md`. | COMPLIANT |
| rules-applied-verification-block | This block present; one row per Rules-in-force rule with quoted/measured evidence + terminal conclusion (no AMBIGUOUS); includes the graph-query-ran row. | COMPLIANT |

---
*End of ADVERSARIAL-PLAN-REVIEW-BD-240.md — verdict NEEDS-REWORK (1 BLOCKER, 1 MAJOR, 4 MINOR).*
