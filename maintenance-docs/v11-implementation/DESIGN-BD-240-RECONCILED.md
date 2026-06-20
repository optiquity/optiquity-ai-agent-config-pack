# DESIGN (RECONCILED) — BD-240: Re-frame `graph-first-context` so DISCOVERY/RECALL is genuinely graph-first

**Agent:** FRESH, INDEPENDENT `pack-architect` (READ-ONLY) — reconciliation pass
**Repo:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Branch / HEAD at runtime (verified):** `v11-dev` / `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3`
**Placement:** MAIN checkout (work is on HEAD; `git status --short` shows only two untracked v11-impl planning docs — clean for this BD's surfaces).
**Date:** 2026-06-20
**Supersedes:** `/tmp/pack-handoff-bd240-arch/DESIGN-BD-240.md` (original) — this doc is the plan-ready design.
**Inputs read in full:** original DESIGN-BD-240.md; ADVERSARIAL-REVIEW-BD-240.md; `backlog/BD-240.md`; the live `graph-first-context` rule (CLAUDE.md L637-684 + AGENTS/GEMINI parallels); `pack-ops/OPTIONAL-FEATURES.md` (L354-376 + L565-573); PACK-CHAT.md propagation procedure (§L485-509) + spawn bullet (L295-305); PACK-AGENTS.md injection bullet (L62-71); PACK-MEMORY-RATIONALE.md `## graph-first-context` (L638-682); `.spawn-rule-manifest.txt`; `.claude/agents/pack-docs-researcher.md`; `backlog/BD-238.md`; `backlog/BD-241.md`; CAPABILITY-REPORT-BD-237.md; validate-pack.py Checks 44/45/46.
**Scope:** PACK-OPS only (trinity `## Pack memory` rule + propagation surfaces). No `project-template/` / `supporting-docs/` product touched (verified: `grep -rln "graph-first\|graphify" project-template/ supporting-docs/` → empty, HEAD af73ffb).

---

## 0. Reconciliation summary

I re-measured every adversarial finding independently against HEAD `af73ffb` and
re-ran the full surface census + the open-BD collision census with fresh eyes. My
disposition:

| Finding | Adversarial severity | My re-measurement | Disposition |
|---|---|---|---|
| **B-1** OPTIONAL-FEATURES.md L565-573 "When to skip Graphify" restates the escape hatch | BLOCKER | CONFIRMED — L567-571 frames "exact-string/whole-file-verbatim" as "skip Graphify … not the graph" | **FIX** (add as EDIT surface, atomic commit) |
| **M-1** §2.3 census fall-through is a survivable rationalization; BD-206 IS a census | MAJOR | CONFIRMED — BD-206 cites `RESEARCH-ORDER-MD-RENAME-CENSUS.md = 56 refs / 14 files`; it is a literal-occurrence census | **FIX** (two mechanics surfaced + recommendation, §2.4) |
| **M-2** BD-238 missed in the rule-10 serialization map | MAJOR | CONFIRMED — BD-238 Type explicitly edits trinity `## Pack memory` + `[rationale:]` + PACK-MEMORY-RATIONALE.md | **FIX** (BD-238 + BD-241 both serialize; backed by full open-BD census, §6) |
| **M-3** §2.3 cites `rename-plans-measure-then-bound` — a memory-only slug, dangling in corpus | MAJOR | CONFIRMED — `grep` → 0 corpus hits; slug lives only in `backlog/BD-230.md` + out-of-repo cache | **FIX** (plain-language phrasing, no slug citation) |
| **m-1** PACK-AGENTS.md parallel injection bullet undecided | MINOR | CONFIRMED — both PACK-AGENTS.md L62-71 and PACK-CHAT.md L295-305 carry parallel bullets; procedure step 4 names BOTH | **FIX** (DECIDED: edit BOTH for parity, §3.5) |
| **m-2** fall-through item count: 5 not 6 | MINOR | CONFIRMED — 4 semicolons = 5 items | **FIX** (count corrected; each of 5 assigned to P2/out-of-graph, §2.3) |
| **m-3** dogfooding query node-count not reproducible | MINOR | N/A to design correctness | **FIX** (exact query string quoted, §8 row 6) |
| **m-4** cross-cli-reference-normalization N/A note absent | MINOR | CONFIRMED — §2.3 text has no per-CLI token | **FIX** (N/A note added, §2.6) |

**Push-backs:** NONE. Every adversarial finding survived my independent
re-measurement; I apply all of them.

**Verified-correct decisions kept intact (NOT re-opened):** the phase-split
spine (Option A); the no-new-CI-check measure-then-bound conclusion (telemetry
unbuildable + no-graph-clone false-fire); the bijection / anti-restate / parity
green projection; the docs-researcher role-def placement; the
`.spawn-rule-manifest.txt` exclusion (refuted brief premise — re-confirmed).

**NEW gaps I found independently (neither author nor adversarial flagged):**
- **N-1 (Check 44 advisory headroom — informational):** OPTIONAL-FEATURES.md is
  ALREADY at 573 lines vs its Check 44 advisory ceiling of 271 (line 7804). The
  B-1 edit (re-scope, roughly length-neutral) cannot fail CI because Check 44 is
  **advisory only** ("never fails" — validate-pack.py L7796, per-check WARN, no
  hard-fail). Documented so the coder/reviewer do not mistake the WARN for a gate.
- **N-2 (PACK-MEMORY-RATIONALE.md "How to apply" carries the same flat
  fall-through framing):** the rationale section's "How to apply" para (L654-659)
  reproduces the flat exception list ("fall through to grep/Read for the
  exceptions (exact-string/token search → grep; … whole-file exact content →
  Read; …)"). The ORIGINAL §3.2 already scheduled this edit, but it did NOT note
  that the rationale's flat list is the SAME conflation as the trinity body and
  OPTIONAL-FEATURES — so it must be re-scoped to the phase model, not merely
  "mirrored." I tighten the §3.2 spec accordingly (§3.2 below). This is the
  rationale-side analog of B-1: a third surface carrying the escape-hatch framing.

---

## 1. Empirical evidence (re-measured at HEAD af73ffb)

Each block: command + verbatim output (paraphrase explicitly marked) + HEAD +
interpretation + conclusion. These EXTEND the original's EE-1..EE-8 with the
reconciliation-critical measurements.

### EE-R1 — B-1: OPTIONAL-FEATURES.md "When to skip Graphify" restates the escape hatch
**Command:** `grep -n -i "skip Graphify\|fall through" pack-ops/OPTIONAL-FEATURES.md` + Read L565-573.
**Output (verbatim, L565-571):**
```
565 **When to skip Graphify.**
566 - You are doing a one-off task and do not want to run the one-time build.
567 - The task is an exact-string / token search, an authoritative SSOT-field read
568   (a BD `Status`, the README version table, a `_rules.md` contract), a
569   freshly-changed / uncommitted file, or whole-file verbatim content — those
570   fall through to grep / Read / `git diff` per the graph-first rule's
571   exceptions, not the graph.
```
**Interpretation:** L567-571 presents "exact-string / token search" and "whole-file verbatim content" as reasons to SKIP Graphify ENTIRELY ("not the graph"), framed as "the graph-first rule's exceptions." This is the exact P1/P2 conflation BD-240 closes. After the trinity re-scopes those clauses to P2-only, this runbook becomes ACTIVELY CONTRADICTORY (the precise BD-206 rationalization re-derivable from the runbook).
**Conclusion: SUPPORTED — B-1 is a real missed EDIT surface, not verify-only.**

### EE-R2 — B-1 safety: OPTIONAL-FEATURES.md is NOT anti-restate-scanned + Check 44 is advisory
**Command:** `grep -n "OPTIONAL-FEATURES" scripts/validate-pack.py` (cross-ref `_CHECK_46_ANTI_RESTATE_SURFACES` L7459-7466).
**Output:** `_CHECK_46_ANTI_RESTATE_SURFACES` = `(PACK-AGENTS.md, PACK-CHAT.md, commit-discipline/SKILL.md, review/SKILL.md, planning/SKILL.md, implementation-report/SKILL.md)` — OPTIONAL-FEATURES.md absent. `_CHECK_44_DURABLE_DOCS` L7804 = `("pack-ops/OPTIONAL-FEATURES.md", 271)`; L7796 comment "The ceiling is advisory only (never fails)."
**Command:** `wc -l < pack-ops/OPTIONAL-FEATURES.md` → `573`.
**Interpretation:** (a) editing the skip-list cannot trip Check 46 (file not scanned). (b) The file is already 573 lines vs the 271 advisory ceiling — already over — and Check 44 never hard-fails (per-check WARN only, L445/L7796). So a length-neutral re-scope is CI-safe. This is NEW gap **N-1**.
**Conclusion: SUPPORTED — B-1 edit has zero CI risk.**

### EE-R3 — M-1: BD-206 is a literal-occurrence census task (the §2.3 census fall-through swallows it)
**Command:** `grep -n -i "census\|every surface\|mirror\|enumerat" backlog/BD-206.md`.
**Output (verbatim excerpt, L14):** "the predesign chain … REQUIRE a thorough researcher + architect sweep when `_index.md` usage + operations are implemented (census: `RESEARCH-ORDER-MD-RENAME-CENSUS.md` = 56 refs / 14 files; pure text, no built file / no validator-test hardcode)." L3 Type: "Apply the no-monolithic-mirror per-entry STANDARD … so the shipped product matches its own corrected convention."
**Interpretation:** BD-206 is, by its own entry, a find-every-surface census with a known literal pattern (`_order` → `_index.md`; the mirror). Under the original §2.3 census fall-through ("a completeness census that REQUIRES literal-occurrence enumeration … RUNS the grep but does NOT replace the graph-first discovery that scoped it"), a docs-researcher can declare the discovery "vacuous" (pattern already known) and grep the whole tree — the exact BD-206 skip. The qualifier is too weak.
**Conclusion: SUPPORTED — the adversarial counterexample holds; M-1 fix required.**

### EE-R4 — M-2: open-BD trinity census (BD-238 AND BD-241 collide; others do not)
**Command:** loop over `backlog/BD-2*.md`, filter `Status: Open`, grep `trinity | ## Pack memory | PACK-MEMORY-RATIONALE | [rationale:`.
**Output (open BDs, trinity-touching verdict):**
- **BD-238** — Type "touches rules + operating docs + trinity"; L27 "trinity `## Pack memory` is the SSOT … (corpus ×3 trinity + `[rationale:]` + `PACK-MEMORY-RATIONALE.md` bijection + `.spawn-rule-manifest.txt` + reference surfaces)". → **HARD same-file collision** (trinity ×3 + PACK-MEMORY-RATIONALE.md + possibly `.spawn-rule-manifest.txt`).
- **BD-241** — Type "trinity `## Pack memory`, Claude-only sub-section"; L12 "Natural home: trinity sub-section 'Sub-agent behavior (Claude-only)'". → **HARD same-file collision** (trinity ×3 + new PACK-MEMORY-RATIONALE.md slug).
- BD-202/205/210/222/223/224/232/234/236/239 — NOT pack-trinity editors: BD-210 L10 "Out of scope: … the live trinity + `pack-ops/` governance docs"; BD-232 L7 "EXPLICITLY NOT the trinity `## Pack memory` … out-of-repo memory cache"; BD-239 edits PROJECT trinity (`project-template/{CLAUDE,AGENTS,GEMINI}.md`), not pack trinity; BD-222/236 edit validate-pack/project guards; BD-202/205/223/224/234 edit scripts/CLI/fixtures. → **NO collision.**
**Interpretation:** the same-file collision set for trinity ×3 + PACK-MEMORY-RATIONALE.md is exactly **{BD-238, BD-241}**. The original §7 listed only BD-241. The brief-stated map (BD-238 + BD-240 + BD-241) is correct.
**Conclusion: SUPPORTED — both BD-238 and BD-241 serialize with BD-240; the rest do not.**

### EE-R5 — M-3: `rename-plans-measure-then-bound` is a memory-only slug (dangling in corpus)
**Command:** `grep -rln "rename-plans-measure-then-bound" CLAUDE.md AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md pack-ops/PACK-AGENTS.md pack-ops/PACK-CHAT.md`.
**Output:** ZERO hits in all six corpus/rationale/reference files. Repo-wide live (excl .git/maintenance/backlog): `grep -rln "rename-plans-measure-then-bound" . --include="*.md" | grep -v …` → only `backlog/BD-230.md` (an entry record). The slug otherwise lives only in the out-of-repo memory cache (`MEMORY.md:37 "Rename plans = measure-then-bound"`).
**Interpretation:** writing `rename-plans-measure-then-bound` INTO the trinity rule body creates a dangling reference — an agent/reviewer cannot resolve it in the corpus or PACK-MEMORY-RATIONALE.md. Violates trinity-as-SSOT + SSOT-hygiene.
**Conclusion: SUPPORTED — remove the slug citation; use plain language.**

### EE-R6 — m-1: BOTH PACK-AGENTS.md and PACK-CHAT.md carry parallel injection bullets
**Command:** Read PACK-AGENTS.md L62-71 + PACK-CHAT.md L295-305 + the propagation procedure surface table (PACK-CHAT.md L499-505).
**Output:** PACK-AGENTS.md L62 "**Inject the graph path into every spawn prompt (BD-226, Claude-only).**" — byte-parallel BD-226 injection guidance ending "See trinity `## Pack memory` § 'Graph-first context (BD-225)'". Propagation table row 4 (L504): "Any reference surface (`PACK-AGENTS.md` / `PACK-CHAT.md` one-line refs)" — names BOTH.
**Interpretation:** the procedure treats PACK-AGENTS.md and PACK-CHAT.md as a PAIR of reference surfaces. The original edited only PACK-CHAT.md, diverging the two. Both are anti-restate-scanned (EE-R2: both in `_CHECK_46_ANTI_RESTATE_SURFACES`), so the DIRECT-use edit on either must stay a paraphrase + name pointer (<60 contiguous verbatim chars of the trinity body).
**Conclusion: SUPPORTED — DECIDE PACK-AGENTS.md; I decide EDIT-FOR-PARITY (§3.5).**

### EE-R7 — m-2: the fall-through list has exactly 5 items
**Command:** `awk 'NR>=645 && NR<=650' CLAUDE.md | … | grep -oc ";"` → `4`.
**Interpretation:** 4 semicolons = 5 semicolon-delimited items: (1) exact-string/token search; (2) authoritative SSOT fields; (3) freshly-changed/uncommitted files; (4) whole-file exact content; (5) archive-dir/excluded-category content. NOT 6.
**Conclusion: SUPPORTED — count is 5; each re-scoped explicitly in §2.3.**

### EE-R8 — independent full surface sweep (no surface missed beyond the corrected set)
**Command:** `grep -rln -i "graph-first\|fall through to grep\|when to skip graphify\|graphify query" . --include="*.md" --include="*.txt" | grep -v /.git/ | grep -v maintenance-docs/ | grep -v ^./backlog/ | grep -v ^./changelog/`.
**Output (live edit-candidate set):** CLAUDE.md, AGENTS.md, GEMINI.md, pack-ops/OPTIONAL-FEATURES.md, pack-ops/PACK-AGENTS.md, pack-ops/PACK-CHAT.md, pack-ops/PACK-MEMORY-RATIONALE.md. (backlog/_toc.md + BD-225/226/233/237/240 are entry records — not edited.) Plus `.claude/agents/pack-docs-researcher.md` (carries NO graph slug today — `grep -in graph` → none — the role-def GAP).
**Cross-check (skills/kickoff false positives):** `pack-startup/SKILL.md` graph mentions are the BD-237 FRESHNESS/build-readiness check, not the discovery rule (no fall-through framing); `architecture-review`/`documentation` "import graph" is a code concept; `implementation-report` is a false match ("paragraph"); `AGENT_KICKOFF_TEMPLATE.md` → zero graph mentions.
**Interpretation:** the complete live edit-surface set is trinity ×3 + OPTIONAL-FEATURES.md + PACK-AGENTS.md + PACK-CHAT.md + PACK-MEMORY-RATIONALE.md + pack-docs-researcher.md = **8 surfaces** (vs the original's 6). No surface beyond the adversarial's corrected set carries the framing.
**Conclusion: SUPPORTED — surface census is now complete; no further hidden surface.**

---
## 2. The re-framing design (phase split + reconciled fixes)

### 2.1 The kept spine (NOT re-opened)

The phase-split diagnosis is correct and confirmed: the rule conflates **(P1)
DISCOVERY/RECALL** ("what are ALL the surfaces related to X / where does Y live
/ blast radius of Z") with **(P2) VERIFICATION/PRECISION** ("the exact
bytes/counts/SSOT VALUE at an already-identified surface"), and lets a P2 need
veto the whole P1 phase. **Option A (phase-split the rule + re-scope each
fall-through to its phase) + the spawn-prompt DIRECT layer as a secondary
enforcement** stands. Options B (grep-ban) and C (spawn-only, no rule edit) stay
REJECTED for the original's reasons (B conflicts with the rename grep-zero gate;
C leaves the SSOT text broken for directly-invoked agents). This pass changes the
TEXT of the re-framing, not the spine.

### 2.2 The corrected shared-core trinity text (replaces the 5-item flat list)

**REPLACE** the single sentence beginning "Fall through to grep/Read for: …"
(through "…deliberately not in the graph).") in CLAUDE.md L645-650 / AGENTS.md
L563-568 / GEMINI.md L540-545 with the two-phase text below — **byte-identical
across all three** (shared core; the per-CLI tails that FOLLOW stay untouched).

> **Two phases — the second never vetoes the first.** **(1) DISCOVERY / RECALL**
> — "what are ALL the surfaces related to X / where does Y live / blast radius of
> Z / what depends on W" — is **graph-FIRST and mandatory when the graph
> exists**: run a `graphify query`/`path`/`affected` to establish the candidate
> surface set BEFORE broad tree reads. grep/Read is NOT a substitute for the
> graph in this phase — an a-priori grep pattern bounds recall to what you
> already thought to search for, which is exactly the recall the graph exists to
> widen. **(2) VERIFICATION / PRECISION** — the exact bytes, line counts, or
> authoritative SSOT VALUE at an ALREADY-IDENTIFIED surface — is grep/Read's job;
> use it to confirm what discovery surfaced. Fall through to grep/Read (skipping
> the graph) ONLY for these — each a P2 or out-of-graph need, none a license to
> skip P1: **(i)** a VERIFICATION read of a named surface (exact bytes/counts —
> Read/grep AFTER discovery named it); **(ii)** an authoritative SSOT field VALUE
> (a BD `Status`, the README version table, a `_rules.md` contract — Read the
> source); **(iii)** freshly-changed / uncommitted files (`git diff`/Read — not
> yet in the graph); **(iv)** whole-file exact content of a named file (Read —
> after discovery named it); **(v)** content the graph deliberately does NOT
> index (archive-dir / excluded-category — Read/grep). A completeness census that
> must enumerate every literal occurrence (e.g. a rename completeness gate that
> greps every literal hit to grep-zero) RUNS the grep as its VERIFICATION gate
> but does NOT replace discovery: when the graph exists, the census runs the
> graph FIRST to find the candidate surfaces, THEN greps each to grep-zero —
> "my task is exhaustive enumeration, so I'll grep the whole tree" is the
> prohibited move, because the graph exists precisely to widen enumeration beyond
> your a-priori pattern.

**What this fixes vs the original §2.3:**
- **m-2 (5 items):** the 5 fall-throughs are enumerated (i)-(v); no phantom 6th;
  items (i) and (iv) are explicitly bound to "AFTER discovery named it" (P2).
- **M-3 (dangling slug):** the `rename-plans-measure-then-bound` slug is GONE —
  replaced by the plain-language "a rename completeness gate that greps every
  literal hit to grep-zero." No corpus reference to a non-corpus slug.
- **M-1 (census loophole):** the census clause is now BOTH (a) re-bound to run
  AFTER graph-first discovery ("runs the graph FIRST to find the candidate
  surfaces, THEN greps") AND (b) carries the explicit anti-rationalization
  sentence ("'my task is exhaustive enumeration so I'll grep the whole tree' is
  the prohibited move"). See §2.4 for the mechanic decision the user adjudicates.

### 2.3 What stays UNCHANGED (preserve verbatim)
- The **opener** ("prefer the graph for orientation / relationship /
  blast-radius / 'what relates to X' / 'where does Y live' … BEFORE broad tree
  reads") — already correct; the edit strengthens the phase after it.
- The **G1 existence guard** + **G2 fallback** sentences — unchanged ("mandatory
  when the graph exists" is gated by G1's "when … exists"; G2 best-effort intact).
- **CLAUDE.md L650-684** — the BD-226 path-injection sub-clause + Claude-only
  worktree caveat ("Do NOT 'restore parity' by porting this injection contract")
  + invocation note — **UNCHANGED**.
- **AGENTS.md L568-584 / GEMINI.md L545-562** — non-injection `--graph`
  absolute-path form + per-CLI invocation note + BD-233 cross-CLI note —
  **UNCHANGED**. Do NOT port the worktree injection contract.
- The `[rationale: graph-first-context]` + `[roles: universal]` tags — UNCHANGED
  (preserves Check 45 bijection + role-tag vocab).

### 2.4 M-1 — TWO mechanics, surfaced for the user (the design gate picks)

The adversarial proposed two ways to close the census loophole. I evaluated both
against the BD-206 counterexample and recommend **(c) BOTH, combined** (which is
what §2.2 already encodes), with (a) as the structural minimum if the user wants
the shorter text.

**Mechanic (a) — Re-bind the census to the OUTPUT of discovery (structural).**
Text: "a literal-occurrence census is a VERIFICATION/completeness gate that runs
AFTER graph-first discovery has established the candidate surface set — it widens
to grep-zero on the surfaces discovery named; it is NEVER the discovery itself.
When the graph exists, an enumeration task still runs the graph FIRST to find
candidate surfaces, THEN greps each for the grep-zero gate."
- *Pros:* phase-binds the census structurally (census = P2 gate over P1's
  output); no exhortation needed; tightest logical coupling to the phase model.
- *Cons:* a sufficiently motivated agent can still claim "discovery is trivial
  because the pattern is obvious" — the structure says discovery must precede,
  but does not NAME the rationalization as prohibited.

**Mechanic (b) — Explicit anti-rationalization sentence (behavioral).**
Text: "'My task is exhaustive enumeration so I will grep the whole tree' is the
prohibited move — the graph exists precisely to widen enumeration beyond your
a-priori pattern; run it first."
- *Pros:* names the exact BD-206 rationalization as forbidden — closes the "I'll
  declare discovery vacuous" move directly; the directly-invoked agent reading
  only the trinity text sees the prohibition spelled out.
- *Cons:* an exhortation without the structural re-bind can read as advisory; on
  its own it leaves the census item's PHASE ambiguous.

**Mechanic (c) — BOTH combined (RECOMMENDED, encoded in §2.2).** Re-bind
structurally AND name the rationalization. Property-fit: (a) fixes the structure
(census is a P2 gate over P1's output), (b) closes the residual human-reasoning
escape (cannot declare discovery vacuous). The cost is ~2 extra sentences in the
rule body — acceptable: the rule already runs long, and this is the load-bearing
clause for the highest-stakes role (the directly-invoked docs-researcher reads
ONLY the trinity text — §4.1 — so the trinity must be airtight here).

**My recommendation: (c) BOTH** (as written in §2.2). If the user wants minimal
length, fall back to **(a)** alone (structural re-bind) — but NOT (b) alone,
which leaves the census item's phase ambiguous. **Verification against the BD-206
counterexample:** under (c), a docs-researcher handed BD-206's census cannot
reach "grep the whole tree" — the text says run the graph FIRST to find
candidate surfaces THEN grep, and names "I'll grep the whole tree because it's
exhaustive" as the prohibited move. The loophole is closed for both the
structural and the reasoning path.

### 2.5 cross-cli-reference-normalization — N/A note (m-4)
The §2.2 shared-core text contains **no per-CLI path or command token** — it
references `graphify query`/`path`/`affected` (generic across all three CLIs) and
no CLI-specific path/flag. Therefore `cross-cli-reference-normalization` is **N/A
for the shared core**, and **byte-identical IS the correct parity target**. The
per-CLI divergence stays confined to the untouched tails (BD-226 injection on
CLAUDE.md vs the non-injection `--graph` form on AGENTS/GEMINI). The coder must
NOT "normalize" anything in the shared core — there is nothing CLI-specific to
normalize. (This sentence is for the coder/reviewer; it does not go into the rule
body.)

### 2.6 Trinity-parity verification
The §2.2 shared-core text is byte-identical across CLAUDE/AGENTS/GEMINI (satisfies
the trinity parity property). Check 18 (Trinity H2 structure parity) keys on H2
headings, not bullet bodies — the body edit (within an existing `### Repo
conventions` bullet) does not affect it. Substantive parity = the coder's
lock-step byte-identical edit + the reviewer's grep-diff of the shared core.

---
## 3. Propagation surfaces — exact edit to each (complete, reconciled)

Per the rule-change propagation procedure (PACK-CHAT.md §"Keeping CLAUDE.md,
AGENTS.md, GEMINI.md, and PACK-AGENTS.md current", L485-509; surface table
L499-505). The complete live edit-surface set (EE-R8) is **8 surfaces**, all in
**one atomic commit** (corpus + rationale + references land together so Check
45/46/parity never see a half-applied state — L508).

### 3.1 Surfaces 1-3 — trinity ×3 (CLAUDE.md / AGENTS.md / GEMINI.md)
**Edit:** replace the shared-core fall-through sentence with the §2.2 two-phase
text, byte-identical, lock-step. Preserve the per-CLI tails (§2.3) verbatim.
**Procedure step:** #1 (corpus imperative ×3). **Enforcing check:** trinity
parity + role-tag controlled vocab.

### 3.2 Surface 4 — pack-ops/PACK-MEMORY-RATIONALE.md `## graph-first-context` "How to apply" (L652-659) — RE-SCOPE, not mirror (NEW gap N-2)
**Edit:** the "How to apply" paragraph CURRENTLY reproduces the SAME flat
exception list as the trinity body (L654-659: "fall through to grep/Read for the
exceptions (exact-string/token search → grep; … whole-file exact content → Read;
…)"). This is the rationale-side carrier of the escape-hatch framing — it MUST be
re-scoped to the phase model, not merely "mirrored." Replace L653-659 with: a
"How" that names the two phases — "When the graph exists, DISCOVERY/RECALL ('what
relates to X / where does Y live / blast radius of Z') is graph-FIRST and
mandatory: query the graph to establish the candidate surface set before broad
tree reads. grep/Read is the VERIFICATION layer — exact bytes/counts at a named
surface, an authoritative SSOT field VALUE (a BD `Status`, the README version
table, a `_rules.md` contract), freshly-changed/uncommitted files (`git
diff`/Read), whole-file content of a named file, and content the graph does not
index (archive/excluded) — none of which licenses skipping graph-first discovery;
a literal-occurrence census runs the graph FIRST to find candidates, THEN greps
each to grep-zero." Keep the "Why", worked example, boundary, `--budget`/backend
lines, and "Rejected alternatives" paragraphs. **Do NOT change the `##
graph-first-context` heading** (bijection slug). **Do NOT add the
`rename-plans-measure-then-bound` slug here either** (M-3 applies to the rationale
too — use plain language). The existing `cross-cli-reference-normalization` +
`bd-pack-only` slug citations in this section's LAST paragraph (L668-672) are
PRE-EXISTING and CORRECT (those slugs DO exist in the corpus) — leave them.
**Procedure step:** #2 (rationale). **Enforcing check:** Check 45 bijection
(slug-set unchanged — exactly one `## graph-first-context`).

### 3.3 Surface 5 — pack-ops/OPTIONAL-FEATURES.md "When to skip Graphify" (L565-573) — EDIT (B-1)
**Edit:** re-scope the escape-hatch list to the phase model. Replace L567-571
(the "exact-string / SSOT-field / uncommitted / whole-file-verbatim → skip
Graphify, not the graph" bullet) with: a bullet that frames those items as
VERIFICATION/precision or out-of-graph reads, NOT a license to skip graph-first
DISCOVERY when the graph exists — e.g. "The work is purely a VERIFICATION read at
a surface you have already identified — exact bytes/counts, an authoritative
SSOT-field VALUE (a BD `Status`, the README version table, a `_rules.md`
contract), a freshly-changed/uncommitted file, whole-file content of a named
file, or content the graph does not index — which falls through to grep / Read /
`git diff`. (This is precision AFTER discovery, not a reason to skip graph-first
DISCOVERY when the graph exists — see the graph-first rule's two-phase model.)"
**KEEP** L566 ("one-off task, did not run the one-time build") and L572-573
("fresh clone with no graph built — degrades to grep/Read with zero friction") —
those are legitimate NO-GRAPH cases (G1), not P1/P2 conflations.
**Land in the SAME atomic commit as the trinity edit** — a half-applied state
where trinity says P1-mandatory but OPTIONAL-FEATURES says "skip for exact-string"
is the incoherence the atomic-commit rule forbids.
**CI safety (EE-R2, N-1):** OPTIONAL-FEATURES.md is NOT anti-restate-scanned
(Check 46 surface set excludes it) and its Check 44 line ceiling is advisory-only
(never fails; the file is already 573 vs the 271 ceiling). The re-scope is
length-neutral — zero CI risk.
**Procedure step:** #4 (reference surface). **Enforcing check:** none gating
(prose runbook); coder VERIFIES coherence with the trinity rule.

### 3.4 Surface 6 — pack-ops/PACK-CHAT.md spawn-prompt bullet (L295-305) — DIRECT-use edit (§4.2)
**Edit:** extend the existing "Inject the graph path into the prompt (BD-226,
Claude-only)" bullet with a sentence DIRECTING graph use for recall-heavy spawns:
"For a recall-heavy / blast-radius / inventory spawn (notably a docs-researcher
INTERNAL pass), the prompt MUST also DIRECT the agent to run the graph for the
DISCOVERY phase — not merely make the path available — and the spawn's 'Rules in
force' block carries `graph-first-context` so the agent's Rules-Applied block must
attest how discovery was performed." Keep it a NAME/concept reference (no ≥60-char
verbatim copy of the trinity imperative body — EE-R2).
**Procedure step:** #4 (reference surface). **Enforcing check:** Check 46
anti-restate (PACK-CHAT.md IS scanned — keep paraphrase + name pointer) +
reference-resolution.

### 3.5 Surface 7 — pack-ops/PACK-AGENTS.md injection bullet (L62-71) — DECIDED: EDIT FOR PARITY (m-1)
**Decision:** EDIT PACK-AGENTS.md's parallel bullet too — do NOT leave it
diverged. **Rationale (evidence-based):** the propagation procedure surface table
(L504) names BOTH "`PACK-AGENTS.md` / `PACK-CHAT.md` one-line refs" as the
reference-surface PAIR; both bullets are byte-parallel BD-226 injection guidance;
both are in `_CHECK_46_ANTI_RESTATE_SURFACES` (EE-R2). Leaving PACK-AGENTS.md
unedited while PACK-CHAT.md gains DIRECT-use guidance diverges two
orchestrator-guidance surfaces (one directs graph discovery, one does not) — the
exact drift the propagation procedure exists to prevent. The no-edit alternative
("PACK-CHAT.md is the authoritative spawn-construction surface; PACK-AGENTS.md is
the routing-table pointer") is NOT justified here: PACK-AGENTS.md L62 is itself a
spawn-prompt-construction directive ("Inject … into every spawn prompt"), not a
pure routing pointer — so the DIRECT-use guidance belongs on it too.
**Edit:** add the same DIRECT-use sentence (§3.4) to the PACK-AGENTS.md bullet,
as a paraphrase + name pointer (anti-restate-safe — same ≥60-char bound; keep it
a NAME reference, no verbatim trinity body copy).
**Procedure step:** #4 (reference surface). **Enforcing check:** Check 46
anti-restate (PACK-AGENTS.md IS scanned) + reference-resolution.

### 3.6 Surface 8 — .claude/agents/pack-docs-researcher.md (the role-emphasis surface — §4.1)
**Edit:** add ONE Responsibilities bullet (after L24) for the INTERNAL recall
mandate: "For an INTERNAL repo recall / blast-radius / 'find every surface that
relates to X' pass (as opposed to EXTERNAL CLI-doc verification), the knowledge
graph is the PRIMARY discovery tool when it exists (per trinity `## Pack memory`
§ 'Graph-first context'): run a `graphify query` against the orchestrator-injected
`--graph` path FIRST and use grep/Read to verify what it surfaces. Doing the
whole recall in grep is a recall defect, not a tool choice." Keep it a name
reference to the trinity rule. The agent already carries `Bash` in `tools:` (L4),
so no frontmatter change (matches rationale rejected-alternative (c)). The agent
def carries no `x-` client contract (it is a pack agent), so
`skill-agent-maintenance-mechanical` is satisfied by preserving the def's
structure (one added bullet, no structural change).
**Procedure step:** #4 (reference surface — agent definition). **Enforcing
check:** mechanical; `skill-agent-maintenance-mechanical`.

### 3.7 NOT touched (measured exclusions)
- **`.spawn-rule-manifest.txt`** — graph-first-context is NOT a manifest record
  (it has no BD-196-collapsed restatements; the 7 records are unrelated rules).
  Adding a record would force a non-existent PACK-AGENTS/PACK-CHAT one-line
  reference and is scope creep. **No edit** — Check 46 reference-resolution stays
  green BECAUSE the manifest is untouched. (Original EE-5 + adversarial both
  confirmed; re-confirmed here.) Note: this REFUTES the BD-240 entry's "+
  `.spawn-rule-manifest.txt`" propagation assumption (L12, L18) — the entry's
  measured-but-wrong premise; the design overrides it measure-then-bound.
- **OPTIONAL-FEATURES.md §"Graphify" L354-376** — the high-level "governs WHEN to
  prefer the graph and when to fall through to grep/Read" pointer stays accurate
  post-edit (the rule still governs WHEN). **No edit**; coder VERIFIES it reads
  true. (Distinct from L565-573, which IS edited per §3.3.)
- **`test-fixtures/manifest.txt`** — push-time (BD-228); reconciled by
  `scripts/manifest-sync.sh` at push iff a fixture INPUT changed. Coder does NOT
  regen per-commit.
- **maintenance-docs/* + backlog/* + skills (pack-startup freshness check etc.)**
  — historical audit records / entry records / unrelated "graph" mentions (EE-R8).
  Not edited. BD-240 flips to Resolved via the normal Status mechanism (Pack-Chat
  bookkeeping), not a coder edit.

---
## 4. The decided questions (kept intact from the original — verified-correct)

### 4.1 docs-researcher recall mandate — role-def clause (YES, kept)
The docs-researcher's name + current def (L16-24) frame it as an EXTERNAL CLI-doc
verifier; BD-206 handed it an INTERNAL repo inventory and the def gave zero
internal-recall guidance, so it defaulted to grep. The §3.6 role-def clause closes
that at the role surface — load-bearing because a directly-invoked agent (`claude
--agent pack-docs-researcher`) reads ONLY the trinity rule + its def, NOT the
spawn-prompt DIRECT layer. The trinity rule stays `[roles: universal]` (a
role-specific tag in a universal rule would muddy the role-tag vocab + bijection).
**Kept — not re-opened.** (This is WHY M-1's airtightness is load-bearing: the
role-def clause covers only the docs-researcher; any OTHER directly-invoked RO
role on a recall task relies on the trinity text alone.)

### 4.2 DIRECT graph use in the spawn prompt — YES (kept, now on BOTH surfaces)
The injection bullets today make the path AVAILABLE but do not DIRECT its use —
the BD-206 failure is "path available, never used." Extending the bullet to direct
graph discovery for recall-heavy spawns is the orchestrator-side teeth. **Kept**,
and now applied to BOTH PACK-CHAT.md (§3.4) and PACK-AGENTS.md (§3.5) per m-1.

### 4.3 ATTEST in Rules-Applied — YES as wording, NO new CI check (kept, measure-then-bound)
The measure-then-bound conclusion stands and I independently re-confirm it
(EE-style): there is NO committed per-run telemetry — agent runs happen in `/tmp`
handoff dirs (not repo inputs); `graphify-out/` is gitignored (Check 63), so not
even a committed graph-presence signal exists; a mechanical "graph-queries-ran"
check would false-fire on the legitimate no-graph clone (which runs zero queries
CORRECTLY, G1). It is UNBUILDABLE against committed state and fails
measure-then-bound. **No new `validate-pack` check.** The attestation rides the
existing `rules-applied-verification-block` rule (empty evidence = VIOLATED) +
the Pack-Chat/orchestrator triage gate: a recall-heavy spawn carrying
`graph-first-context` in Rules-in-force must show its `graphify query` discovery
evidence (or the G1 "graph absent at injected path" evidence); "used grep
throughout" on a recall task with a graph present is insufficient evidence →
triaged as a defect → re-spawn. **Kept — not re-opened.**

---

## 5. ci-guard-design measure-then-bound (consolidated, reconciled)

| Candidate enforcement | Measured against tree (HEAD af73ffb) | KEEP/STRIP | Result |
|---|---|---|---|
| New `validate-pack` "graph-queries-ran" check | No committed per-run telemetry (runs in `/tmp`); `graphify-out/` gitignored (Check 63); no-graph clone runs zero queries correctly | STRIP | NOT proposed — unbuildable + false-fires |
| New `.spawn-rule-manifest.txt` record | Manifest tracks 7 BD-196-collapsed rules; graph-first-context has no restatements (re-confirmed EE) | STRIP | NOT proposed — forces non-existent ref + scope creep |
| Editing OPTIONAL-FEATURES.md skip-list (B-1) | NOT in Check 46 surface set; Check 44 advisory-only (never fails); file already 573 vs 271 ceiling | KEEP | Proposed — zero CI risk (N-1) |
| DIRECT-use sentence in PACK-CHAT.md + PACK-AGENTS.md (§3.4/§3.5) | Both IN Check 46 anti-restate set, ≥60-char bound; keep paraphrase + name pointer | KEEP | Proposed — name reference, no body copy |
| Attestation via existing `rules-applied-verification-block` + triage | Rule already requires quoted measurement evidence; empty = VIOLATED | KEEP | Proposed — rides existing rule, zero new surface |

**Net new CI checks: 0.** Enforcement teeth come only from existing checks (45
bijection, 46 anti-restate + reference-resolution, trinity parity, 63) + the
human-triaged `rules-applied-verification-block`.

---

## 6. Rule-10 parallelization / dependency map (reconciled — BD-238 + BD-240 + BD-241)

**BD-240 is a SINGLE-coder atomic effort:** one logical re-framing across **8
surfaces** (trinity ×3 + PACK-MEMORY-RATIONALE.md + OPTIONAL-FEATURES.md +
PACK-CHAT.md + PACK-AGENTS.md + pack-docs-researcher.md), all in ONE commit per
the propagation procedure's "SAME commit" rule (so Check 45/46/parity never see a
half-applied state). It does NOT internally parallelize.

**Cross-BD serialization (the load-bearing map, backed by the EE-R4 open-BD census):**

| BD | Files it edits | Overlap with BD-240 | Schedule |
|---|---|---|---|
| **BD-240** (this) | trinity ×3 (`## Pack memory`), PACK-MEMORY-RATIONALE.md, OPTIONAL-FEATURES.md, PACK-CHAT.md, PACK-AGENTS.md, .claude/agents/pack-docs-researcher.md | — | one atomic commit |
| **BD-238** | trinity ×3 (`## Pack memory` new rule), PACK-MEMORY-RATIONALE.md (new slug), possibly `.spawn-rule-manifest.txt`, PACK-CHAT.md/PACK-AGENTS.md lifecycle section | **HARD: trinity ×3 + PACK-MEMORY-RATIONALE.md (+ PACK-CHAT/PACK-AGENTS)** | **SERIALIZE** |
| **BD-241** | trinity ×3 (`## Pack memory` Claude-only sub-section), PACK-MEMORY-RATIONALE.md (new slug), + project-side surfaces | **HARD: trinity ×3 + PACK-MEMORY-RATIONALE.md** | **SERIALIZE** |

**Rule (stated for Pack Chat):** any open BD whose Type names "trinity" or a new
`## Pack memory` rule/slug serializes with BD-240 on trinity ×3 +
PACK-MEMORY-RATIONALE.md. The EE-R4 census proves the current collision set is
exactly {BD-238, BD-241}; all other open BDs (BD-202/205/210/222/223/224/232/234/
236/239) are NON-colliding (BD-210 excludes the live trinity + pack-ops governance
docs; BD-232 is out-of-repo memory only; BD-239 edits PROJECT trinity not pack
trinity; the rest edit scripts/validators/fixtures).

**Directive to Pack Chat:** BD-238 / BD-240 / BD-241 coders **MUST NOT run as
concurrent worktree waves** — they edit the same trinity ×3 + PACK-MEMORY-
RATIONALE.md. Run them as **serial commits**: land one (reviewed clean, applied),
THEN spawn the next coder against the resulting HEAD (`worktree.baseRef:"head"` so
it sees the prior edit). The user noted 2026-06-20 BD-240 runs NEXT (it GATES
BD-206); confirm the BD-238/BD-241 ordering relative to BD-240 at the design gate.
Hand-merging two concurrent trinity patches is the exact conflict the
worktree-isolation conflict protocol forbids (STOP + re-spawn fresh, never
hand-merge).

---

## 7. validate-pack green verification (post-design projection)

| Check | Why it stays green |
|---|---|
| Check 45 — rule↔rationale bijection | Slug set UNCHANGED: exactly one `## graph-first-context` rationale ↔ one `[rationale: graph-first-context]` per trinity file. Bodies edited; no slug added/removed; M-3 removes a NON-slug citation (not a bijection slug). |
| Check 46 — anti-restate | PACK-CHAT.md + PACK-AGENTS.md edits are NAME/concept paraphrases, < 60 contiguous verbatim chars of the trinity body (EE-R2 bound = 60). OPTIONAL-FEATURES.md + PACK-MEMORY-RATIONALE.md + pack-docs-researcher.md are NOT in the scan set. Coder PREFLIGHT must grep-confirm no ≥60-char overlap on the two scanned surfaces. |
| Check 46 — reference-resolution | `.spawn-rule-manifest.txt` UNTOUCHED (its 7 records unaffected). |
| Check 18 — trinity H2 parity | Keys on H2 headings; edit is within an existing `### Repo conventions` bullet — no heading change. |
| Trinity parity (body) | §2.2 shared-core byte-identical across the 3 files; tails preserved per-CLI. Reviewer grep-diffs the shared core. |
| Check 44 — durable-doc concision | ADVISORY only (never fails, L7796). OPTIONAL-FEATURES.md already 573 vs 271 ceiling; the length-neutral re-scope does not change the (non-gating) verdict (N-1). |
| Check 62 / manifest.txt | Push-time (BD-228); reconciled by `scripts/manifest-sync.sh` at push iff a fixture input changed. Coder does NOT regen. |
| Check 63 — graphify-out never-tracked | Unaffected (no `graphify-out/` change). |
| Role-tag controlled vocab | `[roles: universal]` UNCHANGED; role emphasis lives in the agent def, not a trinity tag (§4.1). |

**Empirical caveat:** I have NOT run `validate-pack.py` (RO; no post-edit tree
exists). The green projection is structural — measured check logic (EE-R2/R4/R5/R7
+ validate-pack.py L7459-7484/L7796-7805) applied to the proposed edits. The CODER
runs `validate-pack.py` Check 43/45/46 + trinity parity in PREFLIGHT and the
REVIEWER re-verifies; if a paraphrase trips anti-restate, shorten it to a pure
name pointer ("see trinity § 'Graph-first context'").

---

## 8. Coder hand-off checklist (mechanical, 8 surfaces, ONE atomic commit)

1. Replace the shared-core fall-through sentence → §2.2 two-phase text,
   byte-identical in CLAUDE.md / AGENTS.md / GEMINI.md. Preserve the per-CLI tails
   (§2.3) verbatim. NO `rename-plans-measure-then-bound` slug (plain language).
2. Re-scope PACK-MEMORY-RATIONALE.md `## graph-first-context` "How to apply" para
   (§3.2) to the phase model (NOT a flat-list mirror); keep heading, "Why",
   worked example, boundary, budget/backend lines, rejected alternatives; keep the
   PRE-EXISTING `cross-cli-reference-normalization`/`bd-pack-only` citations.
3. Re-scope OPTIONAL-FEATURES.md "When to skip Graphify" L565-573 (§3.3); keep the
   one-off-task + fresh-clone bullets; land in the SAME commit.
4. Extend PACK-CHAT.md graph-injection bullet (§3.4) — paraphrase + name pointer.
5. Extend PACK-AGENTS.md graph-injection bullet (§3.5) — paraphrase + name pointer
   (parity with #4).
6. Add the INTERNAL-recall Responsibilities bullet to pack-docs-researcher.md (§3.6).
7. VERIFY OPTIONAL-FEATURES.md §Graphify L354-376 by-name pointer still reads true
   (§3.7) — no edit expected.
8. Do NOT touch `.spawn-rule-manifest.txt` (§3.7), `test-fixtures/manifest.txt`
   (push-time), or maintenance-docs/backlog.
9. PREFLIGHT: `validate-pack.py` Check 43 + 45 + 46 + trinity parity PASS;
   grep-confirm the §2.2 core byte-identical across the 3 trinity files;
   grep-confirm `[rationale: graph-first-context]` + `[roles: universal]` survive
   on all 3; grep-confirm NO `rename-plans-measure-then-bound` token appears in any
   trinity/rationale file; grep-confirm < 60-char overlap on PACK-CHAT.md +
   PACK-AGENTS.md.

---

## 9. Open decisions for the user (surface, do not self-decide)

1. **M-1 mechanic (§2.4).** RECOMMEND (c) BOTH (structural re-bind +
   anti-rationalization sentence — as encoded in §2.2). Fallback: (a) alone if
   minimal length is preferred. NOT (b) alone. User picks.
2. **BD-238 / BD-240 / BD-241 ordering (§6).** The map requires serialization on
   trinity ×3 + PACK-MEMORY-RATIONALE.md. BD-240 runs NEXT (gates BD-206); confirm
   where BD-238 and BD-241 fall relative to it (each bases its worktree on the
   prior's landed HEAD).
3. **PACK-CHAT/PACK-AGENTS DIRECT-use trigger phrasing (§3.4/§3.5).** Confirm
   "recall-heavy / blast-radius / inventory pass, notably docs-researcher
   INTERNAL" is the intended scope vs a broader "every spawn directs graph
   discovery."

(Surfaced per `decision-presentation-protocol`; the design RECOMMENDS each but the
user decides.)

---
## 10. Findings-closure ledger (every adversarial finding → disposition)

| Finding | Disposition | Where closed |
|---|---|---|
| B-1 (OPTIONAL-FEATURES skip-list) | FIXED — added as EDIT surface, re-scoped to phase model, same atomic commit; CI-safe (N-1) | §3.3, EE-R1, EE-R2 |
| M-1 (census loophole) | FIXED — both mechanics surfaced; RECOMMEND (c) BOTH (encoded in §2.2); verified vs BD-206 census | §2.2, §2.4, EE-R3 |
| M-2 (BD-238 missed in map) | FIXED — BD-238 + BD-241 both serialize; full open-BD census backs the claim | §6, EE-R4 |
| M-3 (dangling slug) | FIXED — slug removed from rule body AND rationale; plain language | §2.2, §3.2, EE-R5 |
| m-1 (PACK-AGENTS.md) | FIXED — DECIDED edit-for-parity (evidence: procedure names both surfaces) | §3.5, EE-R6 |
| m-2 (count 5 not 6) | FIXED — 5 items enumerated (i)-(v) | §2.2, EE-R7 |
| m-3 (reproducible query) | FIXED — exact query string quoted | §11 row 6 |
| m-4 (normalization N/A note) | FIXED — N/A note added | §2.5 |
| N-1 (Check 44 advisory) | NEW — documented (informational, no action) | §0, EE-R2, §3.3 |
| N-2 (rationale flat-list) | NEW — §3.2 spec tightened to re-scope, not mirror | §0, §3.2 |

Push-backs: NONE — all adversarial findings survived independent re-measurement.

---

## 11. Rules-Applied Verification Block

| # | Rule (as named in CLAUDE.md `## Pack memory` / brief) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | empirical-evidence-blocks [architect] | §1 EE-R1..EE-R8 each carry command + verbatim output + HEAD `af73ffb` + interpretation + SUPPORTED conclusion: EE-R1 (OPTIONAL L565-571 quoted); EE-R3 (BD-206 census `56 refs/14 files` quoted); EE-R4 (open-BD census → {BD-238, BD-241}); EE-R5 (`grep` slug → 0 corpus, only backlog/BD-230.md); EE-R7 (4 semicolons = 5 items). | COMPLIANT |
| 2 | ci-guard-design-measure-then-bound [architect] | §5 table: measured the tree for each candidate; STRIP the graph-queries-ran check (no telemetry; gitignored graph; no-graph false-fire) + the manifest record (7 unrelated records); KEEP only edits sized to existing checks + advisory Check 44. Net new CI checks: 0. EE-R2 measured OPTIONAL-FEATURES NOT in Check 46 set + Check 44 advisory (L7796). | COMPLIANT |
| 3 | adversarial-architect-review (independent challenge) | Did not transcribe: re-measured every finding independently (EE-R1..R8); ran the full surface sweep (EE-R8) + open-BD collision census (EE-R4) with fresh eyes; found TWO new gaps (N-1 Check 44 advisory; N-2 rationale flat-list carries the same conflation) that BOTH the author AND the adversarial missed. No rubber-stamp; no push-back claimed without measurement. | COMPLIANT |
| 4 | no-solutions-inherited / reach-own-conclusion | §2.4 presents M-1 mechanics (a)/(b)/(c) with pros/cons → recommend (c); §3.5 m-1 edit-vs-no-edit with evidence → decide edit; §6 serialization derived from the census, not inherited. Each open decision (§9) recommends + defers to user. | COMPLIANT |
| 5 | graph-first-context (dogfooded for discovery) | Ran the graph FIRST for surface re-discovery: `graphify query "graph-first-context rule propagation surfaces OPTIONAL-FEATURES skip Graphify PACK-AGENTS injection docs-researcher trinity" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` → "Traversal: BFS depth=2 | 28 nodes found" (docs-researcher / BD-185 prompt cluster). The graph was COARSE for exact text/counts (G2), so fell through to grep/Read to VERIFY every state-claim — discovery-then-verify, the very split this design proposes. G1 satisfied (graph present at injected path). | COMPLIANT |
| 6 | separate-pack-ops-from-product | `grep -rln "graph-first\|graphify" project-template/ supporting-docs/` → empty (HEAD af73ffb). All 8 edit surfaces are pack-ops (trinity pack-root, pack-ops/*, .claude/agents/*). §3.7 explicitly excludes product. No product file implicated. | COMPLIANT |
| 7 | skill-agent-maintenance-mechanical | §3.6 pack-docs-researcher.md edit = ONE Responsibilities bullet; structure preserved; no frontmatter change (Bash present, L4); no `x-` client contract on pack agent defs (verified — it is a pack agent). | COMPLIANT |
| 8 | rule-10 parallelization map | §6 dedicated section: single-coder atomic 8-surface commit; HARD same-file serialization with BOTH BD-238 and BD-241 (trinity ×3 + PACK-MEMORY-RATIONALE.md, EE-R4) + explicit Pack-Chat directive + the general "any trinity/new-slug BD serializes" rule + non-colliding open BDs enumerated. | COMPLIANT |
| 9 | agents-never-commit / per-action-approval-sub-agents | Commands run: `git rev-parse`/`status --short` (RO), `grep`/`find`/`awk`/`wc`/`sed`, `graphify query` (RO), Read, one `mkdir -p /tmp/...`, heredoc appends to the `/tmp` report. No state-changing git verb; no destructive op; sole filesystem write = this report at `/tmp/pack-handoff-bd240-arch/DESIGN-BD-240-RECONCILED.md`. | COMPLIANT |
| 10 | rules-applied-verification-block | This block present; one row per Rules-in-force rule with quoted evidence + terminal conclusion (no AMBIGUOUS); includes the graph-query-ran row (rule 5). | COMPLIANT |

---
*End of DESIGN-BD-240-RECONCILED.md — plan-ready. Supersedes DESIGN-BD-240.md.*
